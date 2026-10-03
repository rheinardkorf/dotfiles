return {
  "theprimeagen/harpoon",
  lazy = false,
  config = function()
    local mark = require("harpoon.mark")
    local ui = require("harpoon.ui")

    vim.keymap.set("n", "<leader>aa", mark.add_file, { desc = "Harpoon: Add file" })
    vim.keymap.set("n", "<leader>ar", mark.rm_file, { desc = "Harpoon: Remove file" })
    vim.keymap.set("n", "<leader>h", ui.toggle_quick_menu, { desc = "Harpoon: Toggle menu" })

    vim.keymap.set("n", "<C-n>", function() ui.nav_file(1) end, { desc = "Harpoon: Go to file 1" })
    vim.keymap.set("n", "<C-e>", function() ui.nav_file(2) end, { desc = "Harpoon: Go to file 2" })
    vim.keymap.set("n", "<C-i>", function() ui.nav_file(3) end, { desc = "Harpoon: Go to file 3" })
    vim.keymap.set("n", "<C-o>", function() ui.nav_file(4) end, { desc = "Harpoon: Go to file 4" })
  end,
}
