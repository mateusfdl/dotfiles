require "packer".startup(function()
    use { 'lewis6991/impatient.nvim' } 
    use { 'glepnir/galaxyline.nvim', branch = 'main' } 
    use { 'kyazdani42/nvim-web-devicons' } 
    use { 'ryanoasis/vim-devicons' } 
    use { 'nvim-treesitter/nvim-treesitter' } 
    use { 'dracula/vim', as = 'dracula' } 
    use { 'neoclide/coc.nvim', branch = 'release' } 
    use { 'nvim-lua/popup.nvim' } 
    use { 'nvim-lua/plenary.nvim' } 
    use { 'kyazdani42/nvim-tree.lua' } 
    use { 'nvim-telescope/telescope.nvim' } 
    use { 'christoomey/vim-tmux-runner' } 
    use { 'yggdroot/indentline' } 
    use { 'tpope/vim-surround' } 
    use { 'tpope/vim-fugitive' } 
    use { 'junegunn/vim-easy-align' } 
    use { 'tmux-plugins/vim-tmux-focus-events' } 
    use { 'mhinz/vim-signify' } 
    use { 'github/copilot.vim' } 
    use { 'fatih/vim-go', run = ':GoUpdateBinaries' } 
    use { 'neovimhaskell/haskell-vim' } 
end)