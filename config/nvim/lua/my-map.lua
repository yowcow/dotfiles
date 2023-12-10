local utils = require("my-utils")
local map = utils.map

--[[
function _G.smarttab()
  print(vim.inspect(vim.fn.pumvisible()))
  return vim.fn.pumvisible() == 1 and t"<C-n>" or t"<Tab>"
end
]]--

-- map("i", "<tab>", "v:lua.smarttab()", {expr = true, noremap = true})
map("n", "ge", "<cmd>lua vim.diagnostic.open_float()<CR>")
map("n", "]g", "<cmd>lua vim.diagnostic.goto_next()<CR>")
map("n", "[g", "<cmd>lua vim.diagnostic.goto_prev()<CR>")
map("n", "gq", "<cmd>lua vim.diagnostic.setloclist()<CR>")


--
-- FZF
-- :help fzf
--
map("n", ";b", ":Buffers<CR>")
map("n", ";w", ":Windows<CR>")
map("n", ";t", ":Files<CR>")
map("n", ";g", ":GFiles<CR>")
map("n", ";h", ":History<CR>")
map("n", ";c", ":Commits<CR>")
map("n", ";r", ":Rg<CR>")

vim.g.fzf_history_dir = vim.fn.expand("~/.fzf-history")

-- tabs/buffers
-- map("n", "tl", ":tabs<CR>")
map("n", "tn", ":tabnew<space>")
map("n", "tt", ":tabedit<space>")
map("n", "tl", ":tabnext<CR>")
map("n", "th", ":tabprev<CR>")
map("n", "tm", ":tabmove<space>")
map("n", "td", ":tabclose<CR>")
-- map("n", "bl", ":buffers<CR>")
-- map("n", "bn", ":e<space>")
-- map("n", "bl", ":bnext<CR>")
-- map("n", "bh", ":bprev<CR>")
-- map("n", "bd", ":bd<CR>")

-- term
map("t", "<C-\\><C-\\>", "<C-\\><C-n>")
