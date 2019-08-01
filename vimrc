set t_Co=256
set background=dark

syntax on
colorscheme zellner

set nobackup
set noswapfile
set novisualbell
set showtabline=2
"set spell
set foldmethod=manual
"set foldmethod=syntax
"set foldlevelstart=2
"set ambiwidth=double

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

au BufNewFile,BufRead *.psgi set filetype=perl
au BufNewFile,BufRead *.t set filetype=perl
au BufNewFile,BufRead *.twig set filetype=html
au BufNewFile,BufRead *.tx set filetype=html
au BufNewFile,BufRead *.md set filetype=markdown
au BufNewFile,BufRead *.coffee set filetype=coffee
au BufNewFile,BufRead *.es6 set filetype=javascript
au BufNewFile,BufRead *.go set filetype=go

autocmd FileType make setlocal noexpandtab
autocmd FileType go setlocal noexpandtab
autocmd FileType xml setlocal softtabstop=2 tabstop=2 shiftwidth=2
autocmd FileType xhtml setlocal softtabstop=2 tabstop=2 shiftwidth=2
autocmd FileType html setlocal softtabstop=2 tabstop=2 shiftwidth=2
autocmd FileType ruby setlocal softtabstop=2 tabstop=2 shiftwidth=2
autocmd FileType javascript setlocal softtabstop=2 tabstop=2 shiftwidth=2
autocmd FileType json setlocal softtabstop=2 tabstop=2 shiftwidth=2
autocmd FileType yaml setlocal softtabstop=2 tabstop=2 shiftwidth=2
autocmd FileType markdown setlocal softtabstop=4 tabstop=4 shiftwidth=2
autocmd FileType markdown hi! def link markdownItalic LineNr

"=== Server dependent vim profile
if filereadable(expand('~/.vimenv'))
  source ~/.vimenv
endif


"=== tabs and buffers
nnoremap tj :bnext<CR>
nnoremap tk :bprev<CR>
nnoremap tq :bd<CR>
nnoremap tl :tabnext<CR>
nnoremap th :tabprev<CR>
nnoremap tn :tabnew<Space>
nnoremap tt :tabedit<Space>
nnoremap tm :tabm<Space>
nnoremap td :tabclose<CR>


"=== For term
tnoremap <C-\><C-\> <C-\><C-n>


"=== Perl::Tidy
map ;pt <Esc>:%! perltidy -se<CR>
map ;ptv <Esc>:'<,'>! perltidy -se<CR>


"=== Plug
if &compatible
  set nocompatible               " Be iMproved
endif

call plug#begin()

" Add or remove your plugins here:
Plug 'Shougo/neosnippet.vim'
Plug 'Shougo/neosnippet-snippets'
Plug 'Honza/vim-snippets'

" JavaScript
Plug 'pangloss/vim-javascript'
Plug 'mxw/vim-jsx'
Plug 'leafgarland/typescript-vim'
Plug 'kchmck/vim-coffee-script'
" Perl
Plug 'vim-perl/vim-perl'
"Plug 'hotchpotch/perldoc-vim'
"Plug 'c9s/perlomni.vim'
" Go
"Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
"Plug 'stamblerre/vim-go', { 'do': ':GoUpdateBinaries' }
" Erlang
Plug 'vim-erlang/vim-erlang-omnicomplete'
Plug 'vim-erlang/vim-erlang-runtime'
" Language Server Protocol (LSP)
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
" LSP for Go (go get -u golang.org/x/tools/gopls)
if executable('gopls')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'gopls',
        \ 'cmd': {server_info->['gopls', '-mode', 'stdio']},
        \ 'whitelist': ['go'],
        \ })
    autocmd BufWritePre *.go LspDocumentFormat
endif
"" LSP for Go (go get -u github.com/sourcegraph/go-langserver)
"if executable('go-langserver')
"    au User lsp_setup call lsp#register_server({
"        \ 'name': 'go-langserver',
"        \ 'cmd': {server_info->['go-langserver', '-gocodecompletion']},
"        \ 'whitelist': ['go'],
"        \ })
"    autocmd BufWritePre *.go LspDocumentFormatSync
"endif
" LSP for PHP (npm -g i intelephense)
if executable('intelephense')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'intelephense',
        \ 'cmd': {server_info->['intelephense', '--stdio']},
        \ 'initialization_options': {},
        \ 'whitelist': ['php'],
        \ })
    autocmd BufWritePre *.php LspDocumentFormat
endif
" DBGP
Plug 'joonty/vdebug'
" Others
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'zchee/deoplete-go', { 'do': 'make' }
Plug 'editorconfig/editorconfig-vim'
Plug 'scrooloose/nerdtree'
Plug 'junegunn/fzf', { 'dir': '~/.fzf' }
Plug 'junegunn/fzf.vim'
Plug 'szw/vim-tags'
Plug 'prettier/vim-prettier', {
  \ 'do': 'yarn install',
  \ 'for': ['javascript', 'typescript', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue'] }

call plug#end()


"=== For ctags
nnoremap <C-]> g<C-]>
nnoremap <C-w>] <C-w><C-]><C-w>T
let g:vim_tags_auto_generate = 0
let g:vim_tags_directories = []
"command GenTags execute "! [ -d .git ] && cd .git && ctags -R tags ../ || ctags -R -o tags"


"=== For vdebug
let g:vdebug_options = {}
let g:vdebug_options["port"] = 9000
let g:vdebug_options["path_maps"] = {}


"=== For FZF
let g:fzf_command_prefix = 'Fzf'
nnoremap ;b :FzfBuffers<CR>
nnoremap ;w :FzfWindows<CR>
nnoremap ;t :FzfFiles<CR>
nnoremap ;g :FzfGFiles<CR>
nnoremap ;f :FzfTags<CR>
nnoremap ;h :FzfHistory<CR>
nnoremap ;c :FzfCommits<CR>
nnoremap ;r :Rg<CR>

" This is the default extra key bindings
let g:fzf_action = {
  \ 'ctrl-o': 'split',
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

" Default fzf layout
" - down / up / left / right
let g:fzf_layout = { 'down': '~50%' }

" In Neovim, you can set up fzf window using a Vim command
"let g:fzf_layout = { 'window': 'enew' }
"let g:fzf_layout = { 'window': '-tabnew' }

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

" :Rg or :Rg!
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview('up:60%')
  \           : fzf#vim#with_preview('right:50%:hidden', '?'),
  \   <bang>0)


"=== For NERDTree
nnoremap ;nt :NERDTreeToggle<CR>

"=== For deoplete
let g:deoplete#enable_at_startup = 1
inoremap <expr> <C-j> pumvisible() ? "\<C-n>" : "\<C-j>"
inoremap <expr> <C-k> pumvisible() ? "\<C-p>" : "\<C-k>"
"inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<CR>"

"=== For neosnippet
let g:neosnippet#snippets_directory='~/.config/nvim/plugged/vim-snippets/snippets/'

imap <C-l> <Plug>(neosnippet_expand_or_jump)
smap <C-l> <Plug>(neosnippet_expand_or_jump)
xmap <C-l> <Plug>(neosnippet_expand_target)
"smap <expr> <TAB> neosnippet#expandable_or_jumpable() ? "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"

"=== For omnicomplete
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType php setlocal omnifunc=phpcomplete#CompletePHP
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

"=== Just to make sure
filetype indent off
