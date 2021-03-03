let mapleader = ","
set encoding=utf-8

" CONFIG 
set number "Show rows number at sidebar
set relativenumber "Show line number on the current line and relative
" numbers on all other lines
set autoindent	
set autoread                                                 " reload files when changed on disk, i.e. via `git checkout`
set backspace=2
set tabstop=2
set smartcase 
set noerrorbells					     " Disable error sounds set noswapfile 
set ruler
set laststatus=2
set mouse=a
set autoread
set ruler                                                    " show where you are
set scrolloff=3                                              " show context above/below cursorline
set shiftwidth=2                                             " normal mode indentation commands use 2 spaces
set showcmd
set smartcase                                                " case-sensitive search if any caps
set softtabstop=2                                            " insert mode tab and backspace use 2 spaces
set tabstop=8
syntax enable
highlight ColorColumn ctermbg=red

" auto-install vim-plug
call plug#begin()
	Plug 'glepnir/galaxyline.nvim' , {'branch': 'main'}

	" If you want to display icons, then use one of these plugins:
	Plug 'kyazdani42/nvim-web-devicons' " lua
	Plug 'ryanoasis/vim-devicons' " vimscript

	Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
	Plug 'glepnir/zephyr-nvim'

	Plug 'neoclide/coc.nvim', {'branch': 'release'}

	Plug 'kyazdani42/nvim-tree.lua'

	Plug 'nvim-lua/popup.nvim'
	Plug 'nvim-lua/plenary.nvim'
	Plug 'nvim-telescope/telescope.nvim'


	Plug 'npxbr/glow.nvim', {'do': ':GlowInstall'}

	Plug 'terryma/vim-multiple-cursors'

	Plug 'christoomey/vim-tmux-runner'

	Plug 'yggdroot/indentline'

	Plug 'tpope/vim-surround'

	Plug 'tpope/vim-fugitive'

	Plug 'junegunn/vim-easy-align'

	Plug 'kristijanhusak/vim-carbon-now-sh'

	Plug 'thoughtbot/vim-rspec'

	Plug 'mattn/webapi-vim'

	Plug 'tmux-plugins/vim-tmux-focus-events'
call plug#end()

set colorcolumn=80
set cursorline
colorscheme zephyr
syntax on

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

" EasyAlign
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

"NerdTree
map <leader>. :NERDTreeToggle<CR>
map <leader>o :NERDTreeFind<CR>

" Rspec
map <Leader>rr :call RunCurrentSpecFile()<CR>
map <Leader>rn :call RunNearestSpec()<CR>


" CarbonNowSh
vnoremap <leader>1 :CarbonNowSh<CR>

" Run Exercism
map <f4> :w<cr>:call system("tmux resize-pane -y 20 -t2 && tmux send -t2 'ruby -r minitest/pride *_test.rb && tmux resize-pane -Z -t1' c-j")<cr>

" NerdTree
nnoremap <Leader>o :NvimTreeToggle<CR>
nnoremap <leader>r :NvimTreeRefresh<CR>
nnoremap <leader>n :NvimTreeFindFile<CR>
" NvimTreeOpen and NvimTreeClose are also available if you need them

set termguicolors " this variable must be enabled for colors to be applied properly

" a list of groups can be found at `:help nvim_tree_highlight`
highlight NvimTreeFolderIcon guibg=blue
""""" 

" CoC
" NOTE: Use tab for trigger completion with characters ahead and navigate.

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
" NerdTree
let g:NERDTreeIgnore = [
    \ '.git',
    \ ]
" VimCarbonNowSh
let g:carbon_now_sh_options =
\ { 'ln': 'true',
  \ 'fm': 'Source Code Pro' }

:lua require('status-line')
:lua require('nvim-treesitter-conf')
