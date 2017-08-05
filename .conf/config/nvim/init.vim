call plug#begin('~/.vim/plugged')

Plug 'editorconfig/editorconfig-vim'

Plug 'tpope/vim-sensible'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

Plug 'pgdouyon/vim-evanesco'

Plug 'junegunn/vim-peekaboo'

Plug 'joonty/vim-phpqa'

Plug 'vim-php/vim-composer'

Plug 'StanAngeloff/php.vim'

Plug 'powerman/vim-plugin-autosess'

Plug 'idanarye/vim-merginal'

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

nnoremap Q <Nop>
nnoremap <silent> <C-r> :BLines function <CR>
nnoremap <silent> <C-p> :GFiles<CR>
nnoremap <silent> <C-b> :Buffers<CR>
nnoremap <leader>ev :e $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>
nnoremap <S-PageUp> :bprevious<CR>
nnoremap <S-PageDown> :bnext<CR>

nnoremap <C-w> :bd<CR>
nnoremap <C-t> :enew<CR>

" FZF
let g:fzf_buffers_jump = 1

" Airline
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#fnamemod = ':t'

" Git/Fugitive aliases
nnoremap <leader>g :MerginalToggle<CR>
nnoremap <silent> <leader>gb :Git checkout <C-R>+

" PHP settings
let g:phpqa_messdetector_autorun = 0
let g:phpqa_codesniffer_args = "--standard=phpcs.xml"

nnoremap <leader>pc :Phpcs<cr>

function! PhpSyntaxOverride()
  hi! def link phpDocTags  phpDefine
  hi! def link phpDocParam phpType
endfunction

augroup phpSyntaxOverride
  autocmd!
  autocmd FileType php call PhpSyntaxOverride()
augroup END

" Autosession

