require("packer").startup(function()
    use { 'lewis6991/impatient.nvim' } 
    use { 'glepnir/galaxyline.nvim', branch = 'main' } 
    use { 'kyazdani42/nvim-web-devicons' } 
    use { 'ryanoasis/vim-devicons' } 
    use { 'nvim-treesitter/nvim-treesitter' } 
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
    use { 'hrsh7th/nvim-cmp' }
    use { 'hrsh7th/cmp-nvim-lsp' }
    use { 'jiangmiao/auto-pairs' }
    use { 'jose-elias-alvarez/null-ls.nvim' }
    use { 'glepnir/dashboard-nvim' }
    use { 'rebelot/kanagawa.nvim', commit = 'fc2e308' }
    use { 'folke/lsp-colors.nvim' }
    use { 'voldikss/vim-floaterm' }
    use { "nvim-neorg/neorg" }
    use { "mfussenegger/nvim-lint" }
    use { "https://github.com/nat-418/boole.nvim" }
    use { 'nvim-tree/nvim-tree.lua', requires = { 'nvim-tree/nvim-web-devicons' } }
    use { 'sebdah/vim-delve' }
    use { "rcarriga/nvim-dap-ui", requires = {"mfussenegger/nvim-dap"} }
    use { "folke/neodev.nvim" }
  end)
