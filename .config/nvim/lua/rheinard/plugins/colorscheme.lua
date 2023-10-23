return {
    'rose-pine/neovim',
    name = 'rose-pine',
    lazy = false,
    priority = 999,
    opts = {
        highlight_groups = {
            Visual = { fg = "text", bg = "highlight_high" },
        }
    },
    config = function()
        vim.cmd([[colorscheme rose-pine]])
    end
}
