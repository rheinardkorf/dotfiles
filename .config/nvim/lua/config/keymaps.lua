-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Clipboard operations
vim.keymap.set("n", "<leader>y", '"+y', { noremap = true, desc = "Copy to system clipboard" })
vim.keymap.set("v", "<leader>y", '"+y', { noremap = true, desc = "Copy to system clipboard" })
vim.keymap.set("n", "<leader>Y", '"+Y', { noremap = true, desc = "Copy line to system clipboard" })
vim.keymap.set("n", "<leader>p", '"_dP', { noremap = true, desc = "Paste without yanking" })
vim.keymap.set("x", "<leader>p", '"_dP', { noremap = true, desc = "Paste without yanking" })
vim.keymap.set("n", "<leader>d", '"_d', { noremap = true, desc = "Delete without yanking" })
vim.keymap.set("v", "<leader>d", '"_d', { noremap = true, desc = "Delete without yanking" })

-- Scrolling centered
vim.keymap.set("n", "<C-d>", "<C-d>zz", { noremap = true, desc = "Scroll down and center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { noremap = true, desc = "Scroll up and center" })

-- Search and replace word under cursor
vim.keymap.set("n", "<leader>ss", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>", { noremap = true, desc = "Replace word under cursor" })

-- Redo
vim.keymap.set({ "n", "v", "o" }, "U", ":redo<CR>", { noremap = true, desc = "Redo" })
