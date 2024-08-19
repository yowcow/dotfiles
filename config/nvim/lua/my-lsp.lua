local utils = require("my-utils")
local bufmap = utils.bufmap

local function on_attach(_, bufnr)
	vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

	--bufmap(bufnr, "i", "<C-p>", "<cmd>lua vim.lsp.buf.completion()<CR>")
	--bufmap(bufnr, "n", "<space>wa", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>")
	--bufmap(bufnr, "n", "<space>wl", "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>")
	--bufmap(bufnr, "n", "<space>wr", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>")
	bufmap(bufnr, "n", "<space>f", "<cmd>lua vim.lsp.buf.format({ async = true })<CR>")
	bufmap(bufnr, "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>")
	bufmap(bufnr, "n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
	bufmap(bufnr, "n", "gc", "<cmd>lua vim.lsp.buf.code_action()<CR>")
	bufmap(bufnr, "n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
	bufmap(bufnr, "n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
	bufmap(bufnr, "n", "gk", "<cmd>lua vim.lsp.buf.signature_help()<CR>")
	bufmap(bufnr, "n", "gn", "<cmd>lua vim.lsp.buf.rename()<CR>")
	bufmap(bufnr, "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>")
	bufmap(bufnr, "n", "gt", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
end

--
-- https://github.com/neovim/nvim-lspconfig
-- :help lsp
--
-- vim.lsp.set_log_level("debug")
local capabilities = require("cmp_nvim_lsp").default_capabilities()
local lspconfig = require("lspconfig")
local lspservers = {
	"ansiblels",
	"elmls",
	"erlangls",
	"eslint",
	"intelephense",
	"rust_analyzer",
	"terraformls",
	"tsserver",
	"volar",
}
for _, lsp in pairs(lspservers) do
	lspconfig[lsp].setup({
		capabilities = capabilities,
		on_attach = on_attach,
		flags = {
			debounce_text_changes = 150,
		},
	})
end
-- lspconfig.erlangls.setup {
--   cmd = {"/home/yowcow/repos/erlang_ls/_build/default/bin/erlang_ls", "-d", "/tmp/erlangls/", "-l", "debug"},
--   capabilities = capabilities,
--   on_attach = on_attach,
--   flags = {
--     debounce_text_changes = 150
--   },
-- }
lspconfig.gopls.setup({
	cmd = { "gopls", "serve" },
	settings = {
		gopls = {
			analyses = {
				unusedparams = true,
			},
			staticcheck = true,
		},
	},
	capabilities = capabilities,
	on_attach = on_attach,
	flags = {
		debounce_text_changes = 150,
	},
})
lspconfig.lua_ls.setup({
	cmd = {
		"lua-language-server",
		"--logpath",
		vim.fn.expand("~/.cache/lua_ls/log/"),
		"--metapath",
		vim.fn.expand("~/.cache/lua_ls/meta/"),
	},
})
lspconfig.perlnavigator.setup({
	cmd = { "perlnavigator" },
	settings = {
		perlnavigator = {
			enableWarnings = true,
			includePaths = "$workspaceFolder",
		},
	},
})

--
-- https://github.com/nvimtools/none-ls.nvim
--
local nullls = require("null-ls")
nullls.setup({
	sources = {
		-- nullls.builtins.diagnostics.eslint,
		nullls.builtins.diagnostics.staticcheck,
		-- nullls.builtins.diagnostics.tsc,
		nullls.builtins.formatting.prettier,
		nullls.builtins.formatting.stylua,
	},
})
