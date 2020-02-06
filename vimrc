set t_Co=256
set background=dark

syntax on

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

set ai
set shiftwidth=4
set softtabstop=4
set tabstop=4
set expandtab
"set tw=80

set wildmode=list:longest

filetype plugin indent on

augroup FileTyping
    autocmd!
    autocmd BufNewFile,BufRead *.psgi set filetype=perl
    autocmd BufNewFile,BufRead *.t set filetype=perl
    autocmd BufNewFile,BufRead *.twig set filetype=html
    autocmd BufNewFile,BufRead *.tx set filetype=html
    autocmd BufNewFile,BufRead *.md set filetype=markdown
    autocmd BufNewFile,BufRead *.coffee set filetype=coffee
    autocmd BufNewFile,BufRead *.json set filetype=javascript.json
    autocmd BufNewFile,BufRead *.es6 set filetype=javascript
    autocmd BufNewFile,BufRead *.jsx set filetype=javascript.jsx
    autocmd BufNewFile,BufRead *.tsx set filetype=typescript.tsx
    autocmd BufNewFile,BufRead *.go set filetype=go
augroup END

augroup TabStop
    autocmd!
    autocmd FileType make,go setlocal noexpandtab
    autocmd FileType xml,xhtml,html,smarty setlocal softtabstop=2 tabstop=2 shiftwidth=2
    autocmd FileType ruby setlocal softtabstop=2 tabstop=2 shiftwidth=2
    autocmd FileType javascript,javascript.jsx,javascript.json,typescript,typescript.tsx setlocal softtabstop=2 tabstop=2 shiftwidth=2
    autocmd FileType yaml setlocal softtabstop=2 tabstop=2 shiftwidth=2
    autocmd FileType markdown setlocal softtabstop=4 tabstop=4 shiftwidth=2
    autocmd FileType markdown hi! def link markdownItalic LineNr
augroup END

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


"=== For term/window
tnoremap <C-\><C-\> <C-\><C-n>
nnoremap <C-w>- :sp<CR>
nnoremap <C-w>\| :vsp<CR>
nnoremap <C-w>J <C-w>20+
nnoremap <C-w>K <C-w>20-
nnoremap <C-w>H <C-w>20<
nnoremap <C-w>L <C-w>20>


"=== Perl::Tidy
nnoremap ;ptt <Esc>:%! perltidy -se<CR>
nnoremap ;ptv <Esc>:'<,'>! perltidy -se<CR>


"=== Plug
if &compatible
  set nocompatible               " Be iMproved
endif

call plug#begin()

" Add or remove your plugins here:
Plug 'Shougo/neosnippet.vim'
Plug 'Shougo/neosnippet-snippets'
Plug 'Honza/vim-snippets'
Plug 'jremmen/vim-ripgrep'
Plug 'itchyny/lightline.vim'

" JavaScript
Plug 'pangloss/vim-javascript'
Plug 'mxw/vim-jsx'
Plug 'leafgarland/typescript-vim'
Plug 'kchmck/vim-coffee-script'

" Perl
Plug 'vim-perl/vim-perl'
"Plug 'hotchpotch/perldoc-vim'
Plug 'c9s/perlomni.vim'

" Go
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
let g:go_info_mode = 'gopls'

" Erlang
Plug 'vim-erlang/vim-erlang-omnicomplete'
Plug 'vim-erlang/vim-erlang-runtime'

" LSP
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

" DBGP
Plug 'joonty/vdebug'

" Others
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
"Plug 'zchee/deoplete-go', { 'do': 'make' }
Plug 'editorconfig/editorconfig-vim'
Plug 'scrooloose/nerdtree'
Plug 'junegunn/fzf', { 'dir': '~/.fzf' }
Plug 'junegunn/fzf.vim'
Plug 'szw/vim-tags'
Plug 'prettier/vim-prettier', {
  \ 'do': 'yarn install',
  \ 'for': ['javascript', 'typescript', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue'] }
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'jacoborus/tender.vim'

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


"=== For vim-ripgrep
nnoremap ;f :Rg 


"=== For FZF
let g:fzf_command_prefix = 'Fzf'
nnoremap ;b :FzfBuffers<CR>
nnoremap ;w :FzfWindows<CR>
nnoremap ;t :FzfFiles<CR>
nnoremap ;g :FzfGFiles<CR>
"nnoremap ;f :FzfTags<CR>
nnoremap ;h :FzfHistory<CR>
nnoremap ;c :FzfCommits<CR>
nnoremap ;/ :FzfRg<CR>

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
nnoremap ;n :NERDTreeToggle<CR>


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


""=== For omnicomplete
"autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
"autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
"autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
"autocmd FileType php setlocal omnifunc=phpcomplete#CompletePHP
"autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
"autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags


"=== For vim-lsp
" LSP for Go (go get -u golang.org/x/tools/gopls)
if executable('gopls')
    function! ToggleLspGo()
        if !exists('#LspGo#User')
            augroup LspGo
                autocmd!
                autocmd User lsp_setup call lsp#register_server({
                    \ 'name': 'gopls',
                    \ 'cmd': {server_info->['gopls', '-mode', 'stdio']},
                    \ 'whitelist': ['go'],
                    \ })
                autocmd FileType go setlocal omnifunc=lsp#complete
            augroup END
            echo 'Enabled LspGo!!'
        else
            augroup LspGo
                autocmd!
            augroup
            echo 'Disabled LspGo!!'
        endif
    endfunction
    command! ToggleGo call ToggleLspGo()
    ToggleGo
endif
"" LSP for Go (go get -u github.com/sourcegraph/go-langserver)
"if executable('go-langserver')
"    autocmd User lsp_setup call lsp#register_server({
"        \ 'name': 'go-langserver',
"        \ 'cmd': {server_info->['go-langserver', '-gocodecompletion']},
"        \ 'whitelist': ['go'],
"        \ })
"    autocmd BufWritePre *.go LspDocumentFormatSync
"endif
" LSP for PHP (npm -g i intelephense)
if executable('intelephense')
    function! s:toggle_lsp_php()
        if !exists('#LspPHP#User')
            augroup LspPHP
                autocmd!
                autocmd User lsp_setup call lsp#register_server({
                    \ 'name': 'intelephense',
                    \ 'cmd': {server_info->['intelephense', '--stdio']},
                    \ 'initialization_options': {},
                    \ 'whitelist': ['php'],
                    \ })
                autocmd BufWritePre *.php LspDocumentFormat
                autocmd FileType php setlocal omnifunc=lsp#complete
            augroup END
            echo 'Enabled LspPHP!!'
        else
            augroup LspPHP
                autocmd!
            augroup END
            echo 'Disabled LspPHP!!'
        endif
    endfunction
    command! TogglePHP call s:toggle_lsp_php()
    TogglePHP
endif
" LSP for JavaScript (npm -g t javascript-typescript-langserver)
if executable('javascript-typescript-stdio')
    function! s:toggle_lsp_javascript()
        if !exists('#LspJavaScript#user')
            augroup LspJavaScript
                autocmd!
                autocmd User lsp_setup call lsp#register_server({
                    \ 'name': 'javascript-typescript-langserver',
                    \ 'cmd': {server_info->['javascript-typescript-stdio']},
                    \ 'root_uri':{server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'package.json'))},
                    \ 'whitelist': ['javascript', 'javascript.jsx'],
                    \ })
                autocmd FileType javascript,javascript.jsx setlocal omnifunc=lsp#complete
            augroup END
            echo 'Enabled LspJavaScript!!'
        else
            augroup LspJavaScript
                autocmd!
            augroup
            echo 'Disabled LspJavaScript!!'
        endif
    endfunction
    command! ToggleJavaScript call s:toggle_lsp_javascript()
    ToggleJavaScript
endif
" LSP for TypeScript (npm -g i typescript-language-server)
if executable('typescript-language-server')
    function! s:toggle_lsp_typescript()
        if !exists('#LspTypeScript#User')
            augroup LspTypeScript
                autocmd!
                autocmd User lsp_setup call lsp#register_server({
                    \ 'name': 'typescript-language-server',
                    \ 'cmd': {server_info->[&shell, &shellcmdflag, 'typescript-language-server --stdio']},
                    \ 'root_uri':{server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'package.json'))},
                    \ 'whitelist': ['typescript', 'typescript.tsx'],
                    \ })
                autocmd FileType typescript,typescript.tsx setlocal omnifunc=lsp#complete
            augroup END
            echo 'Enabled LspTypeScript!!'
        else
            augroup LspTypeScript
                autocmd!
            augroup
            echo 'Disabled LspTypeScript!!'
        endif
    endfunction
    command! ToggleTypeScript call s:toggle_lsp_typescript()
    ToggleTypeScript
endif


"=== For lightline
set laststatus=2
set noshowmode
"set statusline=%f\ [%{strlen(&fenc)?&fenc:'none'},%{&ff}]%h%m%r%y%=%c,%l/%L\ %P
let g:lightline = {
    \ 'component': {
    \     'filename': '%f',
    \ },
    \ }
let g:lightline.tab = {
    \ 'active': [ 'tabnum', 'filename', 'modified' ],
    \ 'inactive': [ 'tabnum', 'filename', 'modified' ]
    \ }
let g:lightline.tab_component_function = {
    \ 'filename': 'LightlineTabFilename',
    \ 'modified': 'lightline#tab#modified',
    \ 'readonly': 'lightline#tab#readonly',
    \ 'tabnum': 'lightline#tab#tabnum'
    \ }

function! LightlineTabFilename(n) abort
  let buflist = tabpagebuflist(a:n)
  let winnr = tabpagewinnr(a:n)
  let _ = pathshorten(expand('#'.buflist[winnr - 1].':f'))
  return _ !=# '' ? _ : '[No Name]'
endfunction


"=== For colorscheme
set termguicolors
colorscheme molokai
hi Normal guibg=NONE ctermbg=NONE
"hi NonText gui=NONE guifg=#ff6060
hi NonText gui=NONE guifg=#888888
"hi SpecialKey gui=NONE guifg=#ff3399
