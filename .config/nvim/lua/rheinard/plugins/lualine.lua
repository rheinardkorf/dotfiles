local config = function()
    local theme = require("lualine.themes.gruvbox")

    -- set bg transparency in all modes
    theme.normal.c.bg = nil
    theme.insert.c.bg = nil
    theme.visual.c.bg = nil
    theme.replace.c.bg = nil
    theme.command.c.bg = nil

    require('lualine').setup {
        options = {
            icons_enabled = true,
            theme = 'auto',
            component_separators = { left = '⌇', right = '⌇' },
            section_separators = { left = '', right = '' },
            disabled_filetypes = {
                statusline = {},
                winbar = {},
            },
            ignore_focus = {},
            always_divide_middle = true,
            globalstatus = true,
            refresh = {
                statusline = 1000,
                tabline = 1000,
                winbar = 1000,
            }
        },
        sections = {
            lualine_a = { 'mode', '' },
            lualine_b = { 'branch', 'diff', 'diagnostics' },
            lualine_c = {
                {
                    'filename',
                    file_status = true,  -- displays file status (readonly status, modified status)
                    path = 1,            -- 0 = just filename, 1 = relative path, 2 = absolute path
                    -- shorting_target = 215
                    -- Shortens path to leave 40 space in the window
                    -- for other components. Terrible name any suggestions?
                }
            },
            lualine_x = { 
                'filetype', 
                -- "os.date('%y/%m/%d%l:%M%p')" 
            },
            lualine_y = {},
            lualine_z = { 'location', 'filename' }
        },
        inactive_sections = {
            lualine_a = {},
            lualine_b = {},
            lualine_c = { 'filename' },
            lualine_x = { 'location' },
            lualine_y = {},
            lualine_z = {}
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {}
    }

end

return {
    "nvim-lualine/lualine.nvim",
    lazy = false,
    config = config,
    dependencies = { 'nvim-tree/nvim-web-devicons'  }
}
