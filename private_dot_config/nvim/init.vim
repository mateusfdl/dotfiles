let mapleader = ","
syntax on
syntax enable

" CONFIG 
set encoding=utf-8
set number						     " Show rows number at sidebar
set relativenumber					     " Show line number on the current line and relative
set autoindent	
set autoread                                                 " Reload files when changed on disk, i.e. via `git checkout`
set backspace=2
set tabstop=2
set smartcase 
set noerrorbells					     " Disable error sounds set noswapfile 
set ruler
set laststatus=2
set mouse=a
set autoread
set ruler                                                    " Show where you are
set scrolloff=3                                              " Show context above/below cursorline
set shiftwidth=2                                             " Normal mode indentation commands use 2 spaces
set showcmd
set smartcase                                                " Case-sensitive search if any caps
set softtabstop=2                                            " Insert mode tab and backspace use 2 spaces
set tabstop=8
set noswapfile
set guicursor=
set termguicolors					     " this variable must be enabled for colors to be applied properly
set colorcolumn=80
set cursorline


highlight ColorColumn ctermbg=red

call plug#begin()
  Plug 'glepnir/galaxyline.nvim' , {'branch': 'main'}

  " If you want to display icons, then use one of these plugins:
  Plug 'kyazdani42/nvim-web-devicons' " lua
  Plug 'ryanoasis/vim-devicons' " vimscript

  Plug 'nvim-treesitter/nvim-treesitter'
  Plug 'dracula/vim', { 'name': 'dracula' }

  Plug 'neoclide/coc.nvim', {'branch': 'release'}

  Plug 'kyazdani42/nvim-tree.lua'

  Plug 'nvim-lua/popup.nvim'
  Plug 'nvim-lua/plenary.nvim'
  Plug 'nvim-telescope/telescope.nvim'

  Plug 'christoomey/vim-tmux-runner'
  Plug 'yggdroot/indentline'

  Plug 'tpope/vim-surround'

  Plug 'tpope/vim-fugitive'

  Plug 'junegunn/vim-easy-align'

  Plug 'tmux-plugins/vim-tmux-focus-events'

  Plug 'mhinz/vim-signify'

  Plug 'github/copilot.vim'

  " Languages
  Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
call plug#end()

colorscheme dracula


""""" KEYMAP
nmap <leader>p :Glow<CR>

nnoremap ; <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <leader>; <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>, <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>

nnoremap <Left> :echoe "this --> h"<CR>
nnoremap <Right> :echoe "this --> l"<CR>
nnoremap <Up> :echoe "this --> k"<CR>
nnoremap <Down> :echoe "this --> j"<CR>

"STOP BLOWING MA MIND

nnoremap <leader>cn :tn<cr> " next definition
inoremap ii <esc>
nnoremap cn <S-v>/\n\n<CR>
noremap <Leader>s :update<CR>


" Run Exercism
map <f4> :w<cr>:call system("tmux resize-pane -y 20 -t2 && tmux send -t2 'ruby -r minitest/pride *_test.rb' c-j")<cr>
map <f1> :w<cr>:call system("tmux resize-pane -y 10 -t1 && tmux send -t1 'go test -v --bench .' c-j")<cr>
nnoremap <silent><leader>1 :source ~/.config/nvim/init.vim \| :PlugInstall <CR>

" NerdTree
" NvimTreeOpen and NvimTreeClose are also available if you need them


" a list of groups can be found at `:help nvim_tree_highlight`
""""" 

" CoC
inoremap <silent><expr> <TAB>
      \ pumvisible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Tmux Runner
let g:VtrUseVtrMaps = 1
let g:VtrPercentage = 50
let g:VtrOrientation = "h"

" EasyAlign
let g:indentLine_color_gui = '#454545'
let g:indentLine_char = '.'
nmap ga <Plug>(EasyAlign)
xmap ga <Plug>(EasyAlign)

" NerdTree
let g:NERDTreeIgnore = [
    \ '.git',
    \ ]
nnoremap <Leader>o :NvimTreeToggle<CR>
nnoremap <leader>r :NvimTreeRefresh<CR>
nnoremap <leader>n :NvimTreeFindFile<CR>
highlight NvimTreeFolderIcon guibg=blue

" Language config

" Golang
autocmd FileType go setlocal shiftwidth=4
autocmd FileType go setlocal tabstop=4
let g:go_fmt_command = "goimports" 


:lua require('status-line')
:lua require('nvim-treesitter-conf')
:lua require('devilicons')
:lua require('nvim-tree-conf')
