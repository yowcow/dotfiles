vim.cmd([[filetype plugin indent on]])

-- https://www.reddit.com/r/neovim/comments/petq61/neovim_060_y_not_yanking_line_but_to_end_of_line/
vim.cmd("nnoremap Y Y")

-- some global variables
vim.g.terraform_fmt_on_save = 1
vim.g.rustfmt_autosave = 1
vim.g.mapleader = ";"

require("my-options")
require("my-packages")
require("my-lsp")
require("my-autocmd")
require("my-maps")
