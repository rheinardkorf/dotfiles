return {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install",
    init = function()
        vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
    config = function()
        vim.keymap.set("n", "<leader>mp", vim.cmd.MarkdownPreview);
        vim.keymap.set("n", "<leader>ms", vim.cmd.MarkdownPreviewStop);
        vim.keymap.set("n", "<leader>mt", vim.cmd.MarkdownPreviewToggle);
    end
}

