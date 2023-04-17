
/* eslint-disable node/no-unpublished-import */
/* eslint-disable no-new */
/* eslint-disable node/no-unsupported-features/es-syntax */
import { aws_iam as iam, aws_codebuild as codebuild, Stack, StackProps, aws_ec2 as ec2, aws_rds as rds, CfnOutput, aws_s3 as s3 } from 'aws-cdk-lib'
import { Construct } from 'constructs'

/**
 * WARNING: Only set this to true the first time the stack is deployed to create the new report groups.
 *          DO NOT set to true unless you know why you are doing it.
 *          NEVER commit this with the value set to true.
 */
const GENERATE_REPORT_GROUPS = false

export interface JobsIntegrationTestsStackProps extends StackProps {
  stage?: string,
  vpcId: string,
  securityGroupIds: string[],
  dbInstanceIdentifier: string,
  dbInstanceEndpointAddress: string,
  dbUsernameParameter: string,
  dbPasswordParameter: string,
}

export class JobsIntegrationTestsStack extends Stack {
  constructor (scope: Construct, id: string, props: JobsIntegrationTestsStackProps) {
    super(scope, id, props)

    const {
      vpcId = '',
      stage = 'test',
      env,
      securityGroupIds,
      dbInstanceIdentifier,
      dbInstanceEndpointAddress,
      dbUsernameParameter,
      dbPasswordParameter,
    } = props

    const vpc = ec2.Vpc.fromLookup(this, `vpc-${stage}`, {
      vpcId,
      region: env?.region
    })

    /**
     * ====================================================================
     * DB INSTANCE
     * ====================================================================
     *
     * Instance needs to exist in AWS.
     */
    const dbEngine = rds.DatabaseInstanceEngine.mysql({ version: rds.MysqlEngineVersion.VER_5_7 })

    const dbInstance = rds.DatabaseInstance.fromDatabaseInstanceAttributes(this, `db-${stage}`, {
      instanceIdentifier: dbInstanceIdentifier,
      port: 3306,
      securityGroups: [],
      engine: dbEngine,
      instanceEndpointAddress: dbInstanceEndpointAddress
    })

    // Attach security groups.
    securityGroupIds.forEach((groupId, idx) => {
      const sg = ec2.SecurityGroup.fromSecurityGroupId(this, `sg-${idx}-${stage}`, groupId)
      dbInstance.connections.allowFrom(sg, ec2.Port.allTraffic())
    })
    // Allow 3306 access.
    dbInstance.connections.allowFromAnyIpv4(ec2.Port.tcp(3306), 'Allow all inbound MySQL connections.')

    /**
     * ====================================================================
     * CODE BUILD
     * ====================================================================
     */
    const baseBranch = 'main'
    const gitHubSource = codebuild.Source.gitHub({
      owner: 'x-team',
      repo: 'xp-jobs-api',
      branchOrRef: baseBranch,
      webhook: true,
      webhookFilters: [
        // Only PRs on the `main` branch.
        codebuild.FilterGroup
          .inEventOf(
            codebuild.EventAction.PULL_REQUEST_CREATED,
            codebuild.EventAction.PULL_REQUEST_REOPENED,
            codebuild.EventAction.PULL_REQUEST_UPDATED
          )
          .andBaseBranchIs(baseBranch)
      ]
    })

    // S3.
    let resultBucket
    const bucketName = 'jobs-api-ci-reports'

    if (GENERATE_REPORT_GROUPS) {
      resultBucket = new s3.Bucket(this, 'reportBucket', {
        bucketName
      })
    } else {
      resultBucket = s3.Bucket.fromBucketName(this, 'reportBucket', bucketName)
    }

    let testReportGroupRef = 'jobs-api-tests'
    let coverageReportGroupRef = 'jobs-api-coverage'

    /**
     * Report groups.
     */
    let testRG: codebuild.IReportGroup
    let coverageRG: codebuild.IReportGroup

    if (GENERATE_REPORT_GROUPS) {
      testRG = new codebuild.ReportGroup(this, 'junit', {
        exportBucket: resultBucket,
        reportGroupName: testReportGroupRef,
        type: codebuild.ReportGroupType.TEST,
      })

      coverageRG = new codebuild.ReportGroup(this, 'clover', {
        exportBucket: resultBucket,
        reportGroupName: coverageReportGroupRef,
        type: codebuild.ReportGroupType.CODE_COVERAGE,
      })

    } else {
      testRG = codebuild.ReportGroup.fromReportGroupName(this, 'junit', testReportGroupRef)
      coverageRG = codebuild.ReportGroup.fromReportGroupName(this, 'clover', coverageReportGroupRef)
    }

    const builder = new codebuild.Project(this, 'codebuild', {
      vpc,
      source: gitHubSource,
      buildSpec: codebuild.BuildSpec.fromObject({
        version: '0.2',
        env: {
          'parameter-store': {
            TEST_DATABASE_USERNAME: dbUsernameParameter,
            TEST_DATABASE_PASSWORD: dbPasswordParameter,
          },
          variables: {
            TEST_DATABASE_HOST: dbInstance.instanceEndpoint.hostname,
            TEST_DATABASE_PORT: dbInstance.instanceEndpoint.port,
            TEST_DATABASE_NAME: 'jobsApiTests',
            TEST_DATABASE_SSL: false,
            NODE_ENV: 'test',
            NODE_OPTIONS: '--max-old-space-size=7168',
            STRAPI_LOG_LEVEL: 'debug',
            KNEX_DEVELOP_DEBUG: false,
            APP_FRONTEND_URL: 'https://jobs-dev.x-team.com/jobs/',
          },
        },
        phases: {
          install: {
            'runtime-versions': {
              nodejs: 14,
            },
            commands: [
              'echo "Installing tooling and dependencies..."',
              // MySQL Shell for DB ops.
              'sudo apt-get update',
              'sudo apt-get install -y mysql-client',
              // Git version seems to require identity, so lets set one.
              'git config --global user.email "no-reply@x-team.com"',
              'git config --global user.name "CodeBuild"',
              // Get the current HEAD.
              'export PREV_GIT_HEAD=$(git rev-parse --short HEAD)',
              // Ensure we are on `main`.
              `git checkout ${baseBranch}`,
              // Merge PR branch to main.
              // eslint-disable-next-line no-template-curly-in-string
              // 'git merge "${CODEBUILD_WEBHOOK_HEAD_REF#refs/*/}"',
              'git merge $PREV_GIT_HEAD',
              'yarn',
            ],
          },
          pre_build: {
            commands: [
              'echo "Resetting database..."',
              'echo "DROP DATABASE IF EXISTS $TEST_DATABASE_NAME" | mysql --host=$TEST_DATABASE_HOST --port=$TEST_DATABASE_PORT --user=$TEST_DATABASE_USERNAME --password=$TEST_DATABASE_PASSWORD',
              'echo "CREATE DATABASE IF NOT EXISTS $TEST_DATABASE_NAME" | mysql --host=$TEST_DATABASE_HOST --port=$TEST_DATABASE_PORT --user=$TEST_DATABASE_USERNAME --password=$TEST_DATABASE_PASSWORD',
            ],
          },
          build: {
            commands: [
              'echo "Running lint checks..."',
              'yarn lint',
              'echo "Running integration tests..."',
              'yarn jest tests/service --coverage',
            ],
          }
        },
        reports: {
          [testRG.reportGroupArn]: {
            files: '**/*',
            'base-directory': './tests/reports',
            'file-format': 'JUNITXML'
          },
          [coverageRG.reportGroupArn]: {
            files: '**/*',
            'base-directory': './coverage',
            'file-format': 'CLOVERXML'
          },
        }
      }),
      environment: {
        // @see https://docs.aws.amazon.com/codebuild/latest/userguide/available-runtimes.html
        buildImage: codebuild.LinuxBuildImage.STANDARD_5_0,
        // computeType: codebuild.ComputeType.MEDIUM,
      },
      allowAllOutbound: true,
      description: 'XP Jobs API Integration Tests',
    })

    // Allow CodeBuild to access secure SSM parameters.
    builder.addToRolePolicy(new iam.PolicyStatement({
      actions: ['ssm:GetParameters', 'kms:Decrypt'],
      resources: ['*']
    }))

    // Allow CodeBuild to write to Reporting Groups.
    builder.addToRolePolicy(new iam.PolicyStatement({
      actions: [
        'codebuild:CreateReportGroup',
        'codebuild:CreateReport',
        'codebuild:UpdateReport',
        'codebuild:BatchPutTestCases',
        'codebuild:BatchPutCodeCoverages'
      ],
      resources: ['*']
    }))

    // Ensure CodeBuild is allowed to connect to DB.
    dbInstance.grantConnect(builder)

    // Allow CodeBuild to write to the S3 bucket.
    resultBucket.grantWrite(builder)

    // DB output in the event we need to debug.
    new CfnOutput(this, 'dbEndpoint', { value: dbInstance.instanceEndpoint.hostname })
    new CfnOutput(this, 'dbPort', { value: `${dbInstance.instanceEndpoint.port}` })
    new CfnOutput(this, 'dbSocket', { value: dbInstance.instanceEndpoint.socketAddress })
  }
}
