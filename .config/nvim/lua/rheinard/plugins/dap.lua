return {
    {
        "mfussenegger/nvim-dap",
        dependencies = { "nvim-neotest/nvim-nio" }
    },
    {
        "rcarriga/nvim-dap-ui",
        dependencies = {
            { "mfussenegger/nvim-dap" }
        },
        config = function()
            require("dapui").setup()
        end
    },
    {
        "theHamsta/nvim-dap-virtual-text",
        dependencies = {
            { "mfussenegger/nvim-dap" }
        },
        config = function()
            require("nvim-dap-virtual-text").setup()
        end
    },
    {
        "mxsdev/nvim-dap-vscode-js",
        dependencies = {
            { "mfussenegger/nvim-dap" }
        },
        build = "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out",
        config = function()
            require("dap-vscode-js").setup({
                -- node_path = "node", -- Path of node executable. Defaults to $NODE_PATH, and then "node"
                -- debugger_path = "(runtimedir)/site/pack/packer/opt/vscode-js-debug", -- Path to vscode-js-debug installation.
                debugger_path = "/Users/rheinardkorf/.local/share/nvim/lazy/nvim-dap-vscode-js/vscode-js-debug", -- Path to vscode-js-debug installation.
                -- debugger_cmd = { "js-debug-adapter" }, -- Command to use to launch the debug server. Takes precedence over `node_path` and `debugger_path`.
                adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' },     -- which adapters to register in nvim-dap
                -- log_file_path = "(stdpath cache)/dap_vscode_js.log" -- Path for file logging
                -- log_file_level = false -- Logging level for output to file. Set to false to disable file logging.
                -- log_console_level = vim.log.levels.ERROR -- Logging level for output to console. Set to false to disable console output.
            })

            for _, language in ipairs({ "typescript", "javascript" }) do
                require("dap").configurations[language] = {
                    {
                        type = "pwa-node",
                        request = "launch",
                        name = "Launch file",
                        program = "${file}",
                        cwd = "${workspaceFolder}",
                    },
                    {
                        type = "pwa-node",
                        request = "attach",
                        name = "Attach",
                        processId = require 'dap.utils'.pick_process,
                        cwd = "${workspaceFolder}",
                    },
                    {
                        type = "pwa-node",
                        request = "launch",
                        name = "Debug Jest Tests",
                        -- trace = true, -- include debugger info
                        runtimeExecutable = "node",
                        runtimeArgs = {
                            "./node_modules/jest/bin/jest.js",
                            "--runInBand",
                        },
                        rootPath = "${workspaceFolder}",
                        cwd = "${workspaceFolder}",
                        console = "integratedTerminal",
                        internalConsoleOptions = "neverOpen",
                    } }
            end
        end
    },
    {
        "jay-babu/mason-nvim-dap.nvim",
        dependencies = {
            { "mfussenegger/nvim-dap", "williamboman/mason.nvim" }
        },
        config = function()
            require("mason-nvim-dap").setup({
                ensure_installed = { "delve" },
                automatic_installation = true,
                handlers = {
                    function(config)
                        require('mason-nvim-dap').default_setup(config)
                    end,
                    -- Example python overrides...
                    -- python = function(config)
                    --     config.adapters = {
                    --         type = "executable",
                    --         command = "/usr/bin/python3",
                    --         args = {
                    --             "-m",
                    --             "debugpy.adapter",
                    --         },
                    --     }
                    --     require('mason-nvim-dap').default_setup(config) -- don't forget this!
                    -- end,
                }
            })
        end
    }
}
