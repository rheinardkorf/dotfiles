return {

    {
        'nvim-telescope/telescope-fzf-native.nvim', 
        build = 'make' 
    },
    
    {
        'nvim-telescope/telescope.nvim', tag = '0.1.0',
        -- or                            , branch = '0.1.x',
        dependencies = { { 'nvim-lua/plenary.nvim' } }
    },
    
    {
        'rose-pine/neovim',
        name  = 'rose-pine',
    },
    
    
    -- tmux & split window nav
    'christoomey/vim-tmux-navigator',
    
    -- maximize and restore window
    'szw/vim-maximizer',
    
    {
        'nvim-treesitter/nvim-treesitter', 
        build = ':TSUpdate' 
    },
    
    'nvim-treesitter/playground',
    
    'theprimeagen/harpoon',
    
    'mbbill/undotree',
    
    -- 'tpope/vim-fugitive',
    
    'kyazdani42/nvim-web-devicons',
    
    {
        'VonHeikemen/lsp-zero.nvim',
        dependencies = {
            -- LSP Support
            { 'neovim/nvim-lspconfig' },
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },
    
            -- Autocompletion
            { 'hrsh7th/nvim-cmp' },
            { 'hrsh7th/cmp-buffer' },
            { 'hrsh7th/cmp-path' },
            { 'saadparwaiz1/cmp_luasnip' },
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'hrsh7th/cmp-nvim-lua' },
    
            -- Snippets
            { 'L3MON4D3/LuaSnip' },
            { 'rafamadriz/friendly-snippets' },
        }
    },
    
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'kyazdani42/nvim-web-devicons'  }
    },
    
    -- Markdown Preview
    -- install without yarn or npm
    {
        'iamcco/markdown-preview.nvim',
        build = function() vim.fn['mkdp#util#install']() end,
    },
    
    
    -- Prettier
    'jose-elias-alvarez/null-ls.nvim',
    'MunifTanjim/prettier.nvim',
    
    -- VimBeGood
    'ThePrimeagen/vim-be-good',

    -- folke plugins
    'folke/which-key.nvim',
    -- {
    --     'folke/neoconf.nvim',
    --     cmd = 'Neoconf'
    -- },
    -- 'folke/neodev.nvim',
}
