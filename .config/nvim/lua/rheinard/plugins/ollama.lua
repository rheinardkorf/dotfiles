return {
    dir = "/Users/rheinardkorf/Development/nvim/nvim-ollama",
    dependencies = {
        "MunifTanjim/nui.nvim"
    },
    config = function()
        require("ollama").setup({
            autostart = false,
            model = "mistral",
        })
    end
}

