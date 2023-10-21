return {
    'theprimeagen/harpoon',
    -- keys = {
    --     {'<leader>aa', mark.add_file, mode = 'n'},
    --     {'<leader>ar', mark.rm_file, mode = 'n'},
    --     {'<C-m>', ui.toggle_quick_menu, mode = 'n'},
    --
    --     {'<C-n>', function() ui.nav_file(1) end, mode = 'n'},
    --     {'<C-e>', function() ui.nav_file(2) end, mode = 'n'},
    --     {'<C-i>', function() ui.nav_file(3) end, mode = 'n'},
    --     {'<C-o>', function() ui.nav_file(4) end, mode = 'n'},
    -- },
    lazy = false,
    config = function()
        local mark = require("harpoon.mark")
        local ui = require("harpoon.ui")

        vim.keymap.set("n", "<leader>aa", mark.add_file)
        vim.keymap.set("n", "<leader>ar", mark.rm_file)
        vim.keymap.set("n", "<C-m>", ui.toggle_quick_menu)

        vim.keymap.set("n", "<C-n>", function() ui.nav_file(1) end)
        vim.keymap.set("n", "<C-e>", function() ui.nav_file(2) end)
        vim.keymap.set("n", "<C-i>", function() ui.nav_file(3) end)
        vim.keymap.set("n", "<C-o>", function() ui.nav_file(4) end)
    end
}
