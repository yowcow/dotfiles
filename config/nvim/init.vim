set t_Co=256
set background=dark

syntax on

set history=200
set nobackup
set nowritebackup
set noswapfile
set novisualbell
set nrformats=
set showtabline=2
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

set wildmenu
set wildmode=longest:full
"set wildmode=list:longest

filetype plugin indent on

augroup FileTyping
    autocmd!
    autocmd BufNewFile,BufRead *.psgi set filetype=perl
    autocmd BufNewFile,BufRead *.t set filetype=perl
    autocmd BufNewFile,BufRead *.twig set filetype=html
    autocmd BufNewFile,BufRead *.tx set filetype=html
    autocmd BufNewFile,BufRead *.md set filetype=markdown
    autocmd BufNewFile,BufRead *.coffee set filetype=coffee
    autocmd BufNewFile,BufRead *.jsx set filetype=javascript.jsx
    autocmd BufNewFile,BufRead *.tsx set filetype=typescript.tsx
    autocmd BufNewFile,BufRead *.go set filetype=go
augroup END

augroup TabStop
    autocmd!
    autocmd FileType make,go setlocal noexpandtab
    autocmd FileType xml,xhtml,html,smarty setlocal softtabstop=2 tabstop=2 shiftwidth=2
    autocmd FileType ruby setlocal softtabstop=2 tabstop=2 shiftwidth=2
    autocmd FileType javascript,javascript.jsx,typescript,typescript.tsx setlocal softtabstop=2 tabstop=2 shiftwidth=2
    autocmd FileType json,yaml setlocal softtabstop=2 tabstop=2 shiftwidth=2
    autocmd FileType markdown setlocal softtabstop=4 tabstop=4 shiftwidth=2
    autocmd FileType markdown hi! def link markdownItalic LineNr
augroup END


"=== Plug
if &compatible
  set nocompatible " Be iMproved
endif

call plug#begin()
"Plug 'fatih/vim-go'
"Plug 'hyhugh/coc-erlang_ls', {'do': 'yarn install --frozen-lockfile'}
Plug 'itchyny/lightline.vim'
Plug 'jremmen/vim-ripgrep'
Plug 'junegunn/fzf', { 'dir': '~/.fzf' }
Plug 'junegunn/fzf.vim'
Plug 'mattn/vim-goimports'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'szw/vim-tags'
Plug 'vim-erlang/vim-erlang-runtime'
Plug 'ziglang/zig.vim'
call plug#end()


"=== For coc.nvim
let g:coc_global_extensions = [
            \'coc-erlang_ls',
            \'coc-diagnostic',
            \'coc-go',
            \'coc-json',
            \'coc-snippets',
            \'coc-tsserver'
            \]

"--- Begin https://github.com/neoclide/coc.nvim Example ---
" TextEdit might fail if hidden is not set.
set hidden

" Some servers have issues with backup files, see #649.
set nobackup
set nowritebackup

" Give more space for displaying messages.
set cmdheight=2

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
"inoremap <silent><expr> <TAB>
"      \ pumvisible() ? "\<C-n>" :
"      \ <SID>check_back_space() ? "\<TAB>" :
"      \ coc#refresh()
"inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
"
"function! s:check_back_space() abort
"  let col = col('.') - 1
"  return !col || getline('.')[col - 1]  =~# '\s'
"endfunction

" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <silent><expr> <c-n> coc#refresh()
else
  inoremap <silent><expr> <c-n> coc#refresh()
endif

" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying codeAction to the current buffer.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Remap <C-f> and <C-b> for scroll float windows/popups.
" Note coc#float#scroll works on neovim >= 0.4.0 or vim >= 8.2.0750
nnoremap <nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
nnoremap <nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
inoremap <nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
inoremap <nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"

" NeoVim-only mapping for visual mode scroll
" Useful on signatureHelp after jump placeholder of snippet expansion
if has('nvim')
  vnoremap <nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#nvim_scroll(1, 1) : "\<C-f>"
  vnoremap <nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#nvim_scroll(0, 1) : "\<C-b>"
endif

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of language server.
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Mappings for CoCList
" Show all diagnostics.
nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions.
nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
" Show commands.
nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document.
nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols.
nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list.
nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>
"--- End https://github.com/neoclide/coc.nvim Example ---

" Use <C-l> for trigger snippet expand.
imap <C-l> <Plug>(coc-snippets-expand)


"=== For ctags
nnoremap <C-]> g<C-]>
nnoremap <C-w>] <C-w><C-]><C-w>T
let g:vim_tags_auto_generate = 0
let g:vim_tags_directories = []
"command GenTags execute "! [ -d .git ] && cd .git && ctags -R tags ../ || ctags -R -o tags"


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
nnoremap ;r :FzfRg<CR>

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


"=== For lightline
set laststatus=2
set noshowmode
"set statusline=%f\ [%{strlen(&fenc)?&fenc:'none'},%{&ff}]%h%m%r%y%=%c,%l/%L\ %P
let g:lightline = {
    \ 'component': {
    \   'filename': '%f',
    \ },
    \ 'tab': {
    \   'active': [ 'tabnum', 'filename', 'modified' ],
    \   'inactive': [ 'tabnum', 'filename', 'modified' ],
    \ },
    \ 'tab_component_function': {
    \   'filename': 'LightlineTabFilename',
    \   'modified': 'lightline#tab#modified',
    \   'readonly': 'lightline#tab#readonly',
    \   'tabnum':   'lightline#tab#tabnum',
    \ },
    \ 'active': {
    \   'right': [
    \       ['lineinfo'],
    \       ['percent'],
    \       ['coc', 'fileformat', 'fileencoding', 'filetype', 'charvaluehex']
    \   ]
    \ },
    \ 'component_function': {
    \   'coc': 'coc#status'
    \ },
    \ }

function! LightlineTabFilename(n) abort
  let buflist = tabpagebuflist(a:n)
  let winnr = tabpagewinnr(a:n)
  let _ = pathshorten(expand('#'.buflist[winnr - 1].':f'))
  return _ !=# '' ? _ : '[No Name]'
endfunction


"=== For colorscheme
"Disable termguicolors for TERM=urxvt-256color
"set termguicolors
colorscheme molokai
hi Normal guibg=NONE ctermfg=NONE ctermbg=NONE
"hi NonText gui=NONE guifg=#ff6060
hi NonText gui=NONE guifg=#888888
"hi SpecialKey gui=NONE guifg=#ff3399
hi Visual ctermbg=238 guibg=#444444 ctermfg=255 guifg=#eeeeee
hi Comment ctermfg=246
hi Delimiter ctermfg=246
hi String ctermfg=222
hi Underlined ctermfg=75


let mapleader = ","

"=== tabs and buffers
nnoremap tj :bnext<CR>
nnoremap tk :bprev<CR>
nnoremap tq :bd<CR>
nnoremap tl :tabnext<CR>
nnoremap th :tabprev<CR>
nnoremap tn :tabnew<Space>
nnoremap tt :tabedit<Space>
nnoremap tm :tabmove<Space>
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
"nnoremap ;ptt <Esc>:%! perltidy -se<CR>
"nnoremap ;ptv <Esc>:'<,'>! perltidy -se<CR>


"=== various formatting
function! s:format(cmd, range, l1, l2) range
    let in = join(getline(a:l1, a:l2), "\n")
    let out = system(a:cmd, in)
    if v:shell_error != 0
        echoerr substitute(out, '[\r\n]', ' ', 'g')
        return
    endif
    execute a:l1 . "," . a:l2 . "delete"
    if a:range == 0
        call setline(a:l1, split(out, "\n"))
    else
        call append(a:l1 - 1, split(out, "\n"))
    endif
endfunction

command! -range=% SQL <line1>,<line2>call <SID>format("sqlformat -k upper -r -s -", <range>, <line1>, <line2>)
