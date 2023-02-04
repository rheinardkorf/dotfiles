# make sure AWS CLI outputs to STDOUT
export AWS_PAGER=""

## Local DynamoDB
alias dynamoup="(cd ~/Development/dynamodb-local && yarn start)"
alias dynamodown="(cd ~/Development/dynamodb-local && yarn start)"
alias dynamoadmin="(cd ~/Development/dynamodb-local && yarn admin)"
