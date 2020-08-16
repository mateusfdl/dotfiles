let $VIM = $HOME.'/.vim'

"leader
let mapleader = ","

set encoding=utf-8

" CONFIG 
set number "Show rows number at sidebar
set relativenumber "Show line number on the current line and relative numbers on all other lines
set autoindent	
set tabstop=2
set smartcase 
set smartindent
set noerrorbells
set novisualbell
set noswapfile 
set ignorecase
set incsearch
set ruler
set laststatus=2
set shiftwidth=2

autocmd BufNewFile,BufRead *py, *yaml 
	\ set tabstop=8
	\ set shiftwidth=2
  \ set expandtab
	\ set autoindent

so $VIM/plug.vim

