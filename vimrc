set t_Co=256
set background=dark

syntax on
colorscheme zellner

set nobackup
set noswapfile
set novisualbell

set showmatch
set hlsearch
set ignorecase
set smartcase
set backspace=
set backspace=indent

set list
set listchars=tab:>-,trail:^

set laststatus=2
set statusline=%f\ [%{strlen(&fenc)?&fenc:'none'},%{&ff}]%h%m%r%y%=%c,%l/%L\ %P

set ai
set shiftwidth=4
set softtabstop=4
set tabstop=4
set expandtab
"set tw=80

set wildmode=list:longest

au BufNewFile,BufRead *.psgi set filetype=perl
au BufNewFile,BufRead *.t set filetype=perl
au BufNewFile,BufRead *.tx set filetype=html
au BufNewFile,BufRead *.md set filetype=markdown
au BufNewFile,BufRead *.coffee set filetype=coffee

autocmd FileType make setlocal noexpandtab
autocmd FileType xhtml setlocal softtabstop=2
autocmd FileType xhtml setlocal tabstop=2
autocmd FileType html setlocal softtabstop=2
autocmd FileType html setlocal tabstop=2
autocmd FileType ruby setlocal softtabstop=2
autocmd FileType ruby setlocal tabstop=2
autocmd FileType yaml setlocal softtabstop=2
autocmd FileType yaml setlocal tabstop=2
autocmd FileType markdown setlocal softtabstop=4
autocmd FileType markdown setlocal tabstop=4
autocmd FileType markdown hi! def link markdownItalic LineNr

"=== Server dependent vim profile
if filereadable(expand('~/.vimenv'))
  source ~/.vimenv
endif

"=== Perl::Tidy
map ,pt <Esc>:%! perltidy -se<CR>
map ,ptv <Esc>:'<,'>! perltidy -se<CR>

filetype plugin on

"=== Vundle
set rtp+=~/.vim/vundle
call vundle#rc('~/.vim/bundle')

Bundle 'petdance/vim-perl'
Bundle 'hotchpotch/perldoc-vim'
Bundle 'Shougo/neocomplcache'
Bundle 'Shougo/neosnippet'
Bundle 'Shougo/neosnippet-snippets'
Bundle 'thinca/vim-quickrun'
Bundle 'kchmck/vim-coffee-script'


"=== For neocomplcache
" Disable AutoComplPop.
let g:acp_enableAtStartup = 0
" Use neocomplcache.
let g:neocomplcache_enable_at_startup = 1
" Use smartcase.
let g:neocomplcache_enable_smart_case = 1
" Set minimum syntax keyword length.
let g:neocomplcache_min_syntax_length = 3
let g:neocomplcache_lock_buffer_name_pattern = '\*ku\*'

" Define dictionary.
let g:neocomplcache_dictionary_filetype_lists = {
  \ 'default' : ''
  \ }

" Plugin key-mappings.
inoremap <expr><C-g>     neocomplcache#undo_completion()
inoremap <expr><C-l>     neocomplcache#complete_common_string()

" Recommended key-mappings.
" <CR>: close popup and save indent.
inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
function! s:my_cr_function()
  return neocomplcache#smart_close_popup() . "\<CR>"
endfunction
" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><C-h> neocomplcache#smart_close_popup()."\<C-h>"
inoremap <expr><BS> neocomplcache#smart_close_popup()."\<C-h>"
inoremap <expr><C-y>  neocomplcache#close_popup()
inoremap <expr><C-e>  neocomplcache#cancel_popup()
