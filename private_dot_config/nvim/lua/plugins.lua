require("packer").startup(function()
    use { 'lewis6991/impatient.nvim' } 
    use { 'glepnir/galaxyline.nvim', branch = 'main' } 
    use { 'kyazdani42/nvim-web-devicons' } 
    use { 'ryanoasis/vim-devicons' } 
    use { 'nvim-treesitter/nvim-treesitter' } 
    use { 'dracula/vim', as = 'dracula' } 
    use { 'nvim-lua/popup.nvim' } 
    use { 'nvim-lua/plenary.nvim' } 
    use { 'nvim-telescope/telescope.nvim' } 
    use { 'christoomey/vim-tmux-runner' } 
    use { 'yggdroot/indentline' } 
    use { 'tpope/vim-surround' } 
    use { 'tpope/vim-fugitive' } 
    use { 'junegunn/vim-easy-align' } 
    use { 'tmux-plugins/vim-tmux-focus-events' } 
    use { 'mhinz/vim-signify' } 
    use { 'fatih/vim-go', run = ':GoUpdateBinaries' } 
    use { 'neovimhaskell/haskell-vim' } 
    use { 'neovim/nvim-lspconfig' }
    use { 'hrsh7th/nvim-compe' }
    use { 'jiangmiao/auto-pairs' }
    use { 'jose-elias-alvarez/nvim-lsp-ts-utils' }
    use { 'mattn/efm-langserver'}
    use { 'glepnir/dashboard-nvim' }
    use { 'rebelot/kanagawa.nvim', commit = 'fc2e308' }
    use { 'folke/lsp-colors.nvim' }
    use { 'glepnir/lspsaga.nvim' }
    use { 'voldikss/vim-floaterm' }
    use { "nvim-neorg/neorg" }
    use { "mfussenegger/nvim-lint" }
    use { "https://github.com/nat-418/boole.nvim" }
    use { "mateusfdl/spongebob-stupid-nvim" }
    use { 'nvim-tree/nvim-tree.lua', requires = { 'nvim-tree/nvim-web-devicons' } }
end)
