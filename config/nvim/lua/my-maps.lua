local map = require("my-utils").map

--[[
function _G.smarttab()
  print(vim.inspect(vim.fn.pumvisible()))
  return vim.fn.pumvisible() == 1 and t"<C-n>" or t"<Tab>"
end
]]--

-- map("i", "<tab>", "v:lua.smarttab()", {expr = true, noremap = true})
map("n", "ge", "<cmd>lua vim.diagnostic.open_float()<CR>")
map("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>")
map("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>")
map("n", "gq", "<cmd>lua vim.diagnostic.setloclist()<CR>")


--
-- FZF
-- :help fzf
--
map("n", "<Leader>;", ":Buffers<CR>")
map("n", "<Leader>w", ":Windows<CR>")
map("n", "<Leader>f", ":Files<CR>")
map("n", "<Leader>h", ":History<CR>")
map("n", "<Leader>r", ":Rg<CR>")
map("n", "<Leader>gs", ":GFiles?<CR>")
map("n", "<Leader>gl", ":Commits<CR>")
map("n", "<Leader>gf", ":GFiles<CR>")

-- tabs/buffers
map("n", "<Leader>e", ":tabnew<space>")
map("n", "<Leader>p", ":tabprev<CR>")
map("n", "<Leader>n", ":tabnext<CR>")
map("n", "<Leader>d", ":tabclose<CR>")
-- map("n", "<Leader>l", ":tabs<CR>")
-- map("n", "<Leader>n", ":tabedit<space>")
-- map("n", "<Leader>m", ":tabmove<space>")
-- map("n", "bl", ":buffers<CR>")
-- map("n", "bn", ":e<space>")
-- map("n", "bl", ":bnext<CR>")
-- map("n", "bh", ":bprev<CR>")
-- map("n", "bd", ":bd<CR>")

-- term
map("n", "<Leader>t", ":ToggleTerm<CR>")
map("t", "<Leader>t", "<C-\\><C-n>")
