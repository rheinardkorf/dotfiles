return {
    'akinsho/toggleterm.nvim',
    keys = {
        { '<leader>tt', '<cmd>ToggleTerm<CR>', desc = 'Toggle terminal' },
        { '<leader>tf', '<cmd>ToggleTerm direction=float<CR>', desc = 'Float terminal' },
        { '<leader>th', '<cmd>ToggleTerm direction=horizontal<CR>', desc = 'Horizontal terminal' },
        { '<leader>tv', '<cmd>ToggleTerm direction=vertical<CR>', desc = 'Vertical terminal' },
    },
    opts = {
        size = 20,
        open_mapping = [[<c-\>]],
        hide_numbers = true,
        shade_filetypes = {},
        direction = 'horizontal',
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {
            border = 'curved',
            winblend = 0,
            highlights = {
                border = 'Normal',
                background = 'Normal',
            },
        },
    },
}


