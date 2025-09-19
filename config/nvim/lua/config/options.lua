-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.backspace = "indent,start"
vim.opt.clipboard = ""
vim.opt.laststatus = 3
vim.opt.listchars = "tab:>-,trail:^"
vim.opt.mouse = ""
vim.opt.relativenumber = false
-- vim.opt.expandtab = true
-- vim.opt.tabstop = 4
-- vim.opt.shiftwidth = 4
vim.opt.wrap = true

vim.g.snacks_animate = false

vim.cmd("command! Todo TodoQuickFix")

-- disable treesitter indentation for specific languages
vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "erlang",
    "perl",
  },
  callback = function()
    vim.opt_local.indentkeys = ""
    vim.opt_local.indentexpr = ""
  end,
})
