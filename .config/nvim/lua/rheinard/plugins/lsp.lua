return {
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        lazy = false,
        config = false,
        dependencies = {
            { 'williamboman/mason.nvim', },
            -- Remove mason-lspconfig from here to fix loading order
        },
        init = function()
            -- Disable automatic setup, we are doing it manually
            vim.g.lsp_zero_extend_cmp = 0
            vim.g.lsp_zero_extend_lspconfig = 0
        end,
    },
    -- Autocompletion
    {
        'hrsh7th/nvim-cmp',
        event = 'InsertEnter',
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer", -- source for text in buffer
            "hrsh7th/cmp-path",   -- source for file system paths
            {

                "L3MON4D3/LuaSnip",
                -- follow latest release.
                -- version = "2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
                -- install jsregexp (optional!).
                -- build = "make install_jsregexp",
            },
            "saadparwaiz1/cmp_luasnip",     -- for autocompletion
            "rafamadriz/friendly-snippets", -- useful snippets
            "onsails/lspkind.nvim",         -- vs-code like pictograms
            "hrsh7th/cmp-cmdline",
        },
        config = function()
            -- Here is where you configure the autocompletion settings.
            local lsp_zero = require('lsp-zero')
            lsp_zero.extend_cmp()

            -- And you can configure cmp even more, if you want to.
            local cmp = require('cmp')
            -- local cmp_action = lsp_zero.cmp_action()
            local cmp_select = { behavior = cmp.SelectBehavior.Select }
            require("luasnip").filetype_extend("ejs", {"htmx","html"})
            require("luasnip").filetype_extend("javascript", { "jsdoc" })
            require("luasnip.loaders.from_vscode").load({})

            cmp.setup({
                formatting = {
                    format = function(entry, vim_item)
                        vim_item.menu = ({
                            nvim_lsp = '[LSP]',
                            luasnip  = '[LuaSnip]',
                            emoji    = '[E]',
                            path     = '[Path]',
                            calc     = '[C]',
                            vsnip    = '[S]',
                            buffer   = '[Buffer]',
                        })[entry.source.name]
                        vim_item.dup = ({
                            buffer = 1,
                            path = 1,
                            nvim_lsp = 0,
                            lusnip = 0,
                        })[entry.source.name] or 0
                        return vim_item
                    end
                },
                mapping = cmp.mapping.preset.insert({
                    ['<C-Space>'] = cmp.mapping.complete(),
                    -- ['<C-u>'] = cmp.mapping.scroll_docs(-4),
                    -- ['<C-d>'] = cmp.mapping.scroll_docs(4),
                    -- ['<C-f>'] = cmp_action.luasnip_jump_forward(),
                    -- ['<C-b>'] = cmp_action.luasnip_jump_backward(),
                    ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                    ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
                    ['<C-y>'] = cmp.mapping.confirm({ select = true }),
                }),
                snippet = {
                    -- REQUIRED - you must specify a snippet engine
                    expand = function(args)
                        -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
                        require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                        -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
                        -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
                    end,
                },
                -- sources = cmp.config.sources({
                --     { name = 'nvim_lsp', dup = 0 },
                --     -- { name = 'vsnip' }, -- For vsnip users.
                --     { name = 'luasnip',  dup = 0 }, -- For luasnip users.
                --     -- { name = 'ultisnips' }, -- For ultisnips users.
                --     -- { name = 'snippy' }, -- For vsnip users.
                -- }, {
                --     { name = 'buffer' },
                -- }),
                sources = {
                    {
                        name = 'buffer',
                        option = {
                            get_bufnrs = function()
                                local bufs = {}
                                for _, win in ipairs(vim.api.nvim_list_wins()) do
                                    bufs[vim.api.nvim_win_get_buf(win)] = true
                                end
                                return vim.tbl_keys(bufs)
                            end
                        }
                    },
                    { name = 'nvim_lsp' },
                    { name = 'luasnip' },
                    { name = 'path' },
                },
            })
        end
    },
    -- LSP
    {
        'neovim/nvim-lspconfig',
        cmd = 'LspInfo',
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = {
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'williamboman/mason.nvim' },
            -- Removed mason-lspconfig to fix loading order issues
        },
        config = function()
            -- This is where all the LSP shenanigans will live
            local lsp_zero = require('lsp-zero')
            lsp_zero.extend_lspconfig()

            lsp_zero.on_attach(function(_, bufnr)
                -- see :help lsp-zero-keybinding
                -- to learn the available actions
                lsp_zero.default_keymaps({ buffer = bufnr })

                local opts = { buffer = bufnr, remap = false }

                vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
                vim.keymap.set("n", "I", function() vim.lsp.buf.hover() end, opts)
                vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
                vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
                vim.keymap.set("n", "<leader>vq", function() vim.diagnostic.setloclist() end, opts)
                vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
                vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
                vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
                vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
                vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
                vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
            end)

            -- Format on save is now handled by conform.nvim
            -- lsp_zero.format_on_save({
            --     format_opts = {
            --         async = false,
            --         timeout_ms = 10000,
            --     },
            --     servers = {
            --         -- ['tsserver'] = { 'javascript', 'typescript' },
            --         -- ['rust_analyzer'] = { 'rust' },
            --         ['gopls'] = { 'go' },
            --     },
            -- })

            local lspconfig = require('lspconfig')

            lspconfig.lua_ls.setup(lsp_zero.nvim_lua_ls())
            
            -- Configure individual LSP servers
            lspconfig.gopls.setup({
                settings = {
                    gopls = {
                        completeUnimported = true,
                        usePlaceholders = true,
                        analyses = {
                            unusedparams = true,
                        },
                        staticcheck = true,
                        gofumpt = true,
                    },
                },
            })

            lspconfig.ts_ls.setup({
                settings = {
                    implicitProjectConfiguration = {
                        checkJs = true
                    },
                },
            })

            lspconfig.emmet_ls.setup({
                filetypes = { 'html', 'typescriptreact', 'javascriptreact', 'css', 'sass', 'scss', 'less', 'ejs'}
            })

            lspconfig.htmx.setup({
                filetypes = { 'html', 'htmx', 'ejs'}
            })

            -- Add TOML LSP server
            lspconfig.taplo.setup({
                settings = {
                    evenBetterToml = {
                        formatter = {
                            alignEntries = false,
                            alignComments = false,
                            compactArrays = false,
                            compactInlineTables = false,
                            indentEntries = true,
                            indentTables = true,
                            reorderArrays = false,
                            reorderTables = false,
                            columnWidth = 80,
                            columnAlignment = false,
                            compactArrays = false,
                        },
                    },
                },
            })

            -- Let mason handle the rest automatically
            require('mason').setup({})
            -- Removed mason-lspconfig setup to fix loading order issues
        end
    }
}
