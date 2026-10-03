return {
  "theprimeagen/harpoon",
  lazy = false,
  config = function()
    local mark = require("harpoon.mark")
    local ui = require("harpoon.ui")

    vim.keymap.set("n", "<leader>aa", mark.add_file, { desc = "Harpoon: Add file" })
    vim.keymap.set("n", "<leader>ar", mark.rm_file, { desc = "Harpoon: Remove file" })
    vim.keymap.set("n", "<leader>h", ui.toggle_quick_menu, { desc = "Harpoon: Toggle menu" })

    for i = 1, 9 do
      vim.keymap.set("n", "<leader>" .. i, function() ui.nav_file(i) end, { desc = "Harpoon: Go to file " .. i })
    end
  end,
}
