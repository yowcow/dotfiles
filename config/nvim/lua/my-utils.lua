local function map(mode, lhs, rhs, opts)
  vim.api.nvim_set_keymap(mode, lhs, rhs, opts and opts or {noremap = true})
end

local function bufmap(bufnr, mode, lhs, rhs, opts)
  vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts and opts or {noremap = true})
end

--[[
local function t(str)
  vim.api.nvim_replace_termcodes(str, true, true, true)
end
]]--

return {
  map = map,
  bufmap = bufmap,
  -- t = t,
}
