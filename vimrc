syntax on

set nobackup
set noswapfile
set novisualbell

set showmatch
set hlsearch
set ignorecase
set smartcase

set list
set listchars=tab:>-,trail:^

set laststatus=2
set statusline=%f\ [%{strlen(&fenc)?&fenc:'none'},%{&ff}]%h%m%r%y%=%c,%l/%L\ %P

set ai
set shiftwidth=4
set softtabstop=4
set tabstop=4
set expandtab

set wildmode=list:longest

au BufNewFile,BufRead *.psgi set filetype=perl
au BufNewFile,BufRead *.t set filetype=perl
au BufNewFile,BufRead *.tx set filetype=html

autocmd FileType make setlocal noexpandtab
autocmd FileType html setlocal softtabstop=2
autocmd FileType html setlocal tabstop=2
autocmd FileType ruby setlocal softtabstop=2
autocmd FileType ruby setlocal tabstop=2
