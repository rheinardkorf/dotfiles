vim.filetype.add({
    extension = {
        ejs = "ejs"
    }
})

-- Treesitter filetype
vim.treesitter.language.register('html', 'ejs')

