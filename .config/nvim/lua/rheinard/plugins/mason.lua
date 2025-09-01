return {
    {
        "williamboman/mason.nvim",
        cmd = "Mason",
        event = "BufReadPre",
        opts = {
            ui = {
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗",
                },
            },
            -- Ensure TOML tools are available
            ensure_installed = {
                "taplo", -- TOML language server and formatter
            },
        },
    },
    -- Removed mason-lspconfig to fix loading order issues
}
