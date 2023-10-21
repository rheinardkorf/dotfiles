local keymap = vim.keymap -- easier :D

-- Colemak bindings
keymap.set({ "n", "v", "o" }, "n", "h") -- h
keymap.set({ "n", "v", "o" }, "e", "j") -- j
keymap.set({ "n", "v", "o" }, "i", "k") -- k
keymap.set({ "n", "v", "o" }, "o", "l") -- l
keymap.set({ "n", "v", "o" }, "N", "H") -- h
keymap.set({ "n", "v", "o" }, "E", "J") -- j
keymap.set({ "n", "v", "o" }, "I", "K") -- k
keymap.set({ "n", "v", "o" }, "O", "L") -- l
keymap.set({ "n", "v", "o" }, "H", "zz") -- l


-- Motions
keymap.set({ "n", "v", "o" }, "u", "i")       -- Insert mode
keymap.set({ "n", "v", "o" }, "U", "I")       -- Insert mode
keymap.set({ "n", "v", "o" }, "l", "u")       -- Undo
keymap.set({ "n", "v", "o" }, "L", ":redo<CR>") -- Redo
keymap.set({ "n", "v", "o" }, "j", "o")       -- Line Insert mode
keymap.set({ "n", "v", "o" }, "J", "O")       --
-- e, E --
keymap.set({ "n", "v", "o" }, "f", "e")
keymap.set({ "n", "v", "o" }, "F", "E")

-- Window bindings
keymap.set("n", "<leader>st", "<C-w>v")               -- split window vertically
keymap.set("n", "<leader>sd", "<C-w>s")               -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=")               -- make split windows equal width
keymap.set("n", "<leader>sc", ":close<CR>")           -- close current split window
keymap.set("n", "<leader>sm", ":MaximizerToggle<CR>") -- min/max a window
keymap.set("n", "<leader>sn", "<C-w>h")               -- move to window: right
keymap.set("n", "<leader>se", "<C-w>j")
keymap.set("n", "<leader>si", "<C-w>k")
keymap.set("n", "<leader>so", "<C-w>l")

-- Buffer actions
keymap.set("n", "<leader>bb", ":b#<CR>")  -- toggle previous buffer
keymap.set("n", "<leader>bp", ":bp<CR>")  -- previous buffer
keymap.set("n", "<leader>bn", ":bn<CR>")  -- next buffer

keymap.set("n", "<leader>pb", vim.cmd.Ex) -- File explorer

-- Move in Visual Mode
keymap.set("v", "E", ":m '>+1<CR>gv=gv")
keymap.set("v", "I", ":m '<-2<CR>gv=gv")

keymap.set("n", "E", "mzJ`z") -- Replace "J" behavior. Append below to this line.
keymap.set("n", "<C-d>", "<C-d>zz")
keymap.set("n", "<C-u>", "<C-u>zz")
keymap.set("n", "k", "nzzzv")
keymap.set("n", "K", "Nzzzv")

-- greatest remap ever
keymap.set("x", "<leader>p", "\"_dP")

-- next greatest remap ever : asbjornHaland
keymap.set("n", "<leader>y", "\"+y")
keymap.set("v", "<leader>y", "\"+y")
keymap.set("n", "<leader>Y", "\"+Y")

keymap.set("n", "<leader>d", "\"_d")
keymap.set("v", "<leader>d", "\"_d")

-- This is going to get me cancelled
keymap.set("i", "<C-c>", "<Esc>")

keymap.set("n", "Q", "<nop>")
keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
keymap.set("n", "<leader>f", function()
    vim.lsp.buf.format()
end)
--
-- -- keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
-- -- keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
-- -- keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
-- -- keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")
--
-- -- keymap.set("n", "<leader>s", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>")
-- -- keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- ====== netrw remap =======
local function netrw_mapping()
    local bufmap = function(lhs, rhs)
        local opts = { buffer = true, remap = true }
        vim.keymap.set('n', lhs, rhs, opts)
    end

    -- close window
    bufmap('<leader>dd', ':Lexplore<CR>')
    bufmap('<leader>da', ':Lexplore<CR>')

    -- Better navigation
    -- bufmap('H', 'u')
    -- bufmap('h', '-^')
    -- bufmap('l', '<CR>')
    -- bufmap('L', '<CR>:Lexplore<CR>')

    -- Toggle dotfiles
    bufmap('.', 'gh')

    -- Remap up and down
    bufmap('i', '<Up>')
    bufmap('e', '<Down>')
end

local user_cmds = vim.api.nvim_create_augroup('user_cmds', { clear = true })
vim.api.nvim_create_autocmd('filetype', {
    pattern = 'netrw',
    group = user_cmds,
    desc = 'Keybindings for netrw',
    callback = netrw_mapping
})
