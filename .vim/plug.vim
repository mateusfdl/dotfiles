" Install vim-plug if not installed
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" https://github.com/joaofnds/dotfiles
" Ty for it



call plug#begin()
	Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
	Plug 'junegunn/fzf.vim'
	
	Plug 'terryma/vim-multiple-cursors'
	Plug 'christoomey/vim-tmux-runner'

	Plug 'itchyny/lightline.vim'

	Plug 'preservim/nerdtree'

	Plug 'lifepillar/vim-solarized8'
	Plug 'morhetz/gruvbox'
	Plug 'altercation/vim-colors-solarized'

	Plug 'neoclide/coc.nvim', {'branch': 'release'}

	Plug 'yggdroot/indentline'

	Plug 'junegunn/vim-easy-align'
	
	Plug 'tpope/vim-surround'
	
	"" VIM RSPEC 
	Plug 'thoughtbot/vim-rspec'
	"
	"" VIM SUPPORT FOR RUST LANG
	Plug 'rust-lang/rust.vim'

	Plug 'mattn/webapi-vim'
call plug#end()

let config = $VIM.'/config'

for fpath in split(globpath(config, '*.vim'), '\n')
  exe 'source' fpath
endfor
