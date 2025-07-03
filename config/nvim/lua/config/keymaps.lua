-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- vim.keymap.set("n", "tn", ":tabnew<space>")
-- vim.keymap.set("n", "th", ":tabprev<CR>")
-- vim.keymap.set("n", "tl", ":tabnext<CR>")
-- vim.keymap.set("n", "td", ":tabclose<CR>")

vim.keymap.set("n", "th", ":bprev<CR>")
vim.keymap.set("n", "tl", ":bnext<CR>")
vim.keymap.set("n", "td", ":bdelete<CR>")

vim.keymap.set("t", "<C-\\><C-\\>", "<C-\\><C-n>")
vim.keymap.set("n", "<C-w>+", "5<C-w>+")
vim.keymap.set("n", "<C-w>-", "5<C-w>-")
vim.keymap.set("n", "<C-t>", ":sp | term <CR>")

vim.keymap.set("n", ";b", ":Buffers<CR>")
vim.keymap.set("n", ";w", ":Windows<CR>")
vim.keymap.set("n", ";t", ":Files<CR>")
vim.keymap.set("n", ";h", ":History<CR>")
vim.keymap.set("n", ";r", ":Rg<CR>")
vim.keymap.set("n", ";gs", ":GFiles?<CR>")
vim.keymap.set("n", ";gl", ":Commits<CR>")
vim.keymap.set("n", ";gf", ":GFiles<CR>")

vim.keymap.set("n", ";gb", ":Gitsigns blame<CR>")
