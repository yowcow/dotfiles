local vim = vim

vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")

--
-- https://github.com/neovim/nvim-lspconfig
-- :help lsp
--
-- vim.lsp.set_log_level("debug")
local capabilities = require("cmp_nvim_lsp").default_capabilities()
local lspconfig = require("lspconfig")
local lspservers = {
	"ansiblels",
	"cssls",
	"elmls",
	"erlangls",
	"eslint",
	"html",
	"intelephense",
	"jsonls",
	"pylsp",
	"pyright",
	"rust_analyzer",
	"terraformls",
	"ts_ls",
	"volar",
}
for _, lsp in pairs(lspservers) do
	lspconfig[lsp].setup({
		capabilities = capabilities,
		flags = {
			debounce_text_changes = 100,
		},
	})
end

-- lspconfig.erlangls.setup {
--   cmd = {"/home/yowcow/repos/erlang_ls/_build/default/bin/erlang_ls", "-d", "/tmp/erlangls/", "-l", "debug"},
--   capabilities = capabilities,
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
	flags = {
		debounce_text_changes = 100,
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
			perlPath = "perl",
			enableWarnings = true,
			perltidyProfile = "",
			perlcriticProfile = "",
			perlcriticEnabled = false,
			includePaths = {
				"lib",
				"local/lib/perl5",
				vim.fn.getcwd() .. "/lib",
				vim.fn.getcwd() .. "/local/lib/perl5",
			},
		},
	},
	capabilities = capabilities,
	flags = {
		debounce_text_changes = 100,
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
