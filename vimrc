set t_Co=256
set background=dark

syntax on
colorscheme zellner

set nobackup
set noswapfile
set novisualbell
"set spell

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

filetype on
filetype plugin on
"filetype indent on

au BufNewFile,BufRead *.psgi set filetype=perl
au BufNewFile,BufRead *.t set filetype=perl
au BufNewFile,BufRead *.tx set filetype=html
au BufNewFile,BufRead *.md set filetype=markdown
au BufNewFile,BufRead *.coffee set filetype=coffee
au BufNewFile,BufRead *.es6 set filetype=javascript

autocmd FileType make setlocal noexpandtab
autocmd FileType xhtml setlocal softtabstop=2
autocmd FileType xhtml setlocal tabstop=2
autocmd FileType html setlocal softtabstop=2
autocmd FileType html setlocal tabstop=2
autocmd FileType ruby setlocal softtabstop=2
autocmd FileType ruby setlocal tabstop=2
autocmd FileType javascript setlocal softtabstop=2
autocmd FileType javascript setlocal tabstop=2
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

"=== JavaScript tidy
"map ,jt <Esc>:%call JsBeautify()<CR>
"map ,jtv <Esc>:'<,'>call RangeJsBeautify()<CR>
map ,jt <Esc>:%! jq .<CR>
map ,jtv <Esc>:'<,'>! jq .<CR>

"=== dein
if &compatible
  set nocompatible               " Be iMproved
endif

" Required:
set runtimepath^=~/.vim/dein/repos/github.com/Shougo/dein.vim

" Required:
call dein#begin(expand('~/.vim/dein'))

" Let dein manage dein
" Required:
call dein#add('Shougo/dein.vim')

" Add or remove your plugins here:
call dein#add('Shougo/neosnippet.vim')
call dein#add('Shougo/neosnippet-snippets')

" You can specify revision/branch/tag.
"call dein#add('Shougo/vimshell', { 'rev': '3787e5' })

" Crystal
call dein#add('rhysd/vim-crystal')
" JavaScript
call dein#add('pangloss/vim-javascript')
call dein#add('mxw/vim-jsx')
call dein#add('leafgarland/typescript-vim')
call dein#add('kchmck/vim-coffee-script')
" Elixer
call dein#add('elixir-lang/vim-elixir')
" Perl
call dein#add('petdance/vim-perl')
call dein#add('hotchpotch/perldoc-vim')
call dein#add('c9s/perlomni.vim')
" Go
call dein#add('fatih/vim-go')
" Erlang
call dein#add('vim-erlang/vim-erlang-omnicomplete')
call dein#add('vim-erlang/vim-erlang-runtime')
" Others
call dein#add('Shougo/neocomplete.vim')
call dein#add('Shougo/neosnippet.vim')
call dein#add('Shougo/neosnippet-snippets')
"call dein#add('thinca/vim-quickrun')
call dein#add('scrooloose/nerdtree')
call dein#add('junegunn/fzf', { 'build': './install --all', 'merged': 0 })
call dein#add('junegunn/fzf.vim', { 'depends': 'fzf' })
call dein#add('szw/vim-tags')

" Required:
call dein#end()

" Required:
filetype plugin on

" If you want to install not installed plugins on startup.
if dein#check_install()
  call dein#install()
endif


"=== For ctags
nnoremap <C-]> g<C-]>
let g:vim_tags_auto_generate = 0
command GenTags execute "! [ -d .git ] && cd .git && ctags -R tags ../ || ctags -R -o tags"


"=== For FZF
nnoremap ,t :FZF<CR>

" This is the default extra key bindings
let g:fzf_action = {
  \ 'ctrl-o': 'split',
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

" Default fzf layout
" - down / up / left / right
let g:fzf_layout = { 'down': '~40%' }

" In Neovim, you can set up fzf window using a Vim command
let g:fzf_layout = { 'window': 'enew' }
let g:fzf_layout = { 'window': '-tabnew' }

"" Customize fzf colors to match your color scheme
"let g:fzf_colors =
"\ { 'fg':      ['fg', 'Normal'],
"  \ 'bg':      ['bg', 'Normal'],
"  \ 'hl':      ['fg', 'Comment'],
"  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
"  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
"  \ 'hl+':     ['fg', 'Statement'],
"  \ 'info':    ['fg', 'PreProc'],
"  \ 'prompt':  ['fg', 'Conditional'],
"  \ 'pointer': ['fg', 'Exception'],
"  \ 'marker':  ['fg', 'Keyword'],
"  \ 'spinner': ['fg', 'Label'],
"  \ 'header':  ['fg', 'Comment'] }

" Enable per-command history.
" CTRL-N and CTRL-P will be automatically bound to next-history and
" previous-history instead of down and up. If you don't like the change,
" explicitly bind the keys to down and up in your $FZF_DEFAULT_OPTS.
let g:fzf_history_dir = '~/.fzf-history'


"=== For NERDTree
map <C-n><C-n> :NERDTreeToggle<CR>


"=== For neosnippet
let g:neosnippet#snippets_directory='~/.vim/dein/repos/github.com/Shougo/neosnippet-snippets/snippets/'


"=== For omnicomplete


"=== For neocomplete
let g:acp_enableAtStartup = 0
let g:neocomplete#enable_at_startup = 1
let g:neocomplete#enable_smart_case = 1
let g:neocomplete#sources#syntax#min_keyword_length = 3

if !exists('g:neocomplete#keyword_patterns')
    let g:neocomplete#keyword_patterns = {}
endif
let g:neocomplete#keyword_patterns['default'] = '\h\w*'

inoremap <expr><C-g>     neocomplete#undo_completion()
inoremap <expr><C-l>     neocomplete#complete_common_string()

autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType php setlocal omnifunc=phpcomplete#CompletePHP
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

"if !exists('g:neocomplete#sources#omni#input_patterns')
"  let g:neocomplete#sources#omni#input_patterns = {}
"endif
"let g:neocomplete#sources#omni#input_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
"let g:neocomplete#sources#omni#input_patterns.perl = '\h\w*->\h\w*\|\h\w*::'
