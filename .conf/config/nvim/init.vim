call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-sensible'

Plug 'tpope/vim-surround'

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

Plug 'pgdouyon/vim-evanesco'

Plug 'junegunn/vim-peekaboo'

call plug#end()

language en_US.UTF-8

set nowrap
set ruler relativenumber number
set noswapfile
set cursorline

set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab

nnoremap <silent> <C-p> :GFiles<CR>
