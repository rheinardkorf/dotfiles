vim.cmd('colorscheme rose-pine')
function SetColorScheme(color) 
	color = color or "rose-pine"

    if color == 'rose-pine' then
        vim.g.rose_pine_variant = "moon"
    end

    local status_ok, _ = pcall(vim.cmd, "colorscheme " .. color)

    if status_ok then
        -- https://neovim.io/doc/user/syntax.html
        vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
        -- vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
        -- vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
    else
        vim.notify("colorsheme " .. color .. " not found!")
        return
    end
end

SetColorScheme()
