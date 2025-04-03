local vim = vim

-- vim.keymap.set("i", "<tab>", "v:lua.smarttab()", {expr = true, noremap = true})
vim.keymap.set("n", "ge", "<cmd>lua vim.diagnostic.open_float()<CR>")
vim.keymap.set("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>")
vim.keymap.set("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>")
vim.keymap.set("n", "gq", "<cmd>lua vim.diagnostic.setloclist()<CR>")
vim.keymap.set("n", "<Space>f", "<cmd>lua vim.lsp.buf.format()<CR>")

--
-- FZF
-- :help fzf
--
vim.keymap.set("n", "<Leader>b", ":Buffers<CR>")
vim.keymap.set("n", "<Leader>w", ":Windows<CR>")
vim.keymap.set("n", "<Leader>t", ":Files<CR>")
vim.keymap.set("n", "<Leader>h", ":History<CR>")
vim.keymap.set("n", "<Leader>r", ":Rg<CR>")
vim.keymap.set("n", "<Leader>gs", ":GFiles?<CR>")
vim.keymap.set("n", "<Leader>gl", ":Commits<CR>")
vim.keymap.set("n", "<Leader>gf", ":GFiles<CR>")

-- tabs/buffers
vim.keymap.set("n", "tn", ":tabnew<space>")
vim.keymap.set("n", "th", ":tabprev<CR>")
vim.keymap.set("n", "tl", ":tabnext<CR>")
vim.keymap.set("n", "td", ":tabclose<CR>")
-- vim.keymap.set("n", "tl", ":tabs<CR>")
-- vim.keymap.set("n", "tn", ":tabedit<space>")
-- vim.keymap.set("n", "tm", ":tabmove<space>")
-- vim.keymap.set("n", "bl", ":buffers<CR>")
-- vim.keymap.set("n", "bn", ":e<space>")
-- vim.keymap.set("n", "bl", ":bnext<CR>")
-- vim.keymap.set("n", "bh", ":bprev<CR>")
-- vim.keymap.set("n", "bd", ":bd<CR>")

-- window/term
vim.keymap.set("n", "<C-\\><C-\\>", ":ToggleTerm<CR>")
vim.keymap.set("t", "<C-\\><C-\\>", "<C-\\><C-n>")
vim.keymap.set("n", "<C-w>+", "5<C-w>+")
vim.keymap.set("n", "<C-w>-", "5<C-w>-")
vim.keymap.set("n", "<C-t>", ":sp | term ")
