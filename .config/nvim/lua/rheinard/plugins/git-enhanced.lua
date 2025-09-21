return {
    'sindrets/diffview.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
        { '<leader>gd', '<cmd>DiffviewOpen<CR>', desc = 'Open diff view' },
        { '<leader>gc', '<cmd>DiffviewClose<CR>', desc = 'Close diff view' },
        { '<leader>gh', '<cmd>DiffviewFileHistory<CR>', desc = 'File history' },
        { '<leader>gf', '<cmd>DiffviewFocusFiles<CR>', desc = 'Focus files' },
    },
    opts = {
        enhanced_diff_hl = true,
        use_icons = true,
        icons = {
            folder_closed = "📁",
            folder_open = "📂",
        },
        signs = {
            fold_closed = "▶",
            fold_open = "▼",
        },
        file_panel = {
            win_config = {
                width = 35,
            },
        },
        file_history_panel = {
            win_config = {
                width = 35,
            },
        },
    },
}


