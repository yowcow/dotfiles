local opt = vim.opt -- to set options
opt.autoindent = true
opt.backspace = "indent,start"
opt.backup = false
opt.completeopt = "menu,menuone,noselect"
opt.cursorline = true
opt.expandtab = true
opt.ignorecase = true
opt.joinspaces = false
opt.list = true
opt.listchars = "tab:>-,trail:^"
opt.number = true
opt.shiftwidth = 4
opt.showmode = false
opt.showtabline = 2
opt.signcolumn = "yes"
opt.smartcase = true
opt.smartindent = false
opt.softtabstop = 4
opt.splitbelow = true
opt.splitright = true
opt.swapfile = false
opt.tabstop = 4
opt.termguicolors = true
opt.visualbell = false
opt.writebackup = false
opt.mouse = ""
opt.encoding = "utf-8"
opt.fileencodings="utf8,iso-2022-jp,cp932,sjis,euc-jp"

vim.cmd([[filetype plugin indent on]])

-- https://www.reddit.com/r/neovim/comments/petq61/neovim_060_y_not_yanking_line_but_to_end_of_line/
vim.cmd('nnoremap Y Y')
