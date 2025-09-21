return {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    keys = {
        { '<leader>e', '<cmd>NvimTreeToggle<CR>', desc = 'Toggle file tree' },
    },
    opts = {
        sort_by = 'case_sensitive',
        view = { 
            width = 30,
            side = 'left',
        },
        renderer = { 
            group_empty = true,
            icons = {
                show = {
                    file = true,
                    folder = true,
                    folder_arrow = true,
                    git = true,
                },
            },
        },
        filters = { 
            dotfiles = false,
            git_ignored = true,
        },
        git = {
            enable = true,
            ignore = false,
        },
        actions = {
            open_file = {
                quit_on_open = false,
            },
        },
    },
}


