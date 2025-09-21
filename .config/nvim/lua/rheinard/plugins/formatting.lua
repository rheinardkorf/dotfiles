return {
    -- Modern formatting with conform.nvim
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        keys = {
            {
                "<leader>f",
                function()
                    require("conform").format({ async = true, lsp_fallback = true })
                end,
                mode = "",
                desc = "Format buffer",
            },
        },
        opts = {
            -- Define formatters
            formatters_by_ft = {
                lua = { "stylua" },
                go = { "goimports", "gofmt" },
                javascript = { "prettierd", "prettier" },
                typescript = { "prettierd", "prettier" },
                javascriptreact = { "prettierd", "prettier" },
                typescriptreact = { "prettierd", "prettier" },
                json = { "prettierd", "prettier" },
                yaml = { "prettierd", "prettier" },
                html = { "prettierd", "prettier" },
                css = { "prettierd", "prettier" },
                scss = { "prettierd", "prettier" },
                markdown = { "prettierd", "prettier" },
                ejs = { "prettierd", "prettier" },
                toml = { "taplo" }, -- Add TOML support
            },
            -- Set up format-on-save
            format_on_save = function(bufnr)
                -- Disable with a global or buffer-local variable
                if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                    return
                end
                return { timeout_ms = 500, lsp_fallback = true }
            end,
            -- Customize formatters
            formatters = {
                sh = {
                    prepend_args = { "-", "-ci", "-si" },
                },
            },
        },
        init = function()
            vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
        end,
    },
    -- Modern linting with nvim-lint
    {
        "mfussenegger/nvim-lint",
        event = { "BufWritePost", "BufReadPost", "InsertLeave" },
        config = function()
            local lint = require("lint")

            lint.linters_by_ft = {
                javascript = { "eslint" },
                typescript = { "eslint" },
                javascriptreact = { "eslint" },
                typescriptreact = { "eslint" },
                lua = { "luacheck" },
                go = { "golangci-lint" },
                python = { "flake8" },
            }

            -- Create autocmd to run linting
            vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
                callback = function()
                    require("lint").try_lint()
                end,
            })

            -- Keybinding to manually run linting
            vim.keymap.set("n", "<leader>l", function()
                require("lint").try_lint()
            end, { desc = "Lint buffer" })
        end,
    },
}
