local vim = vim
local Plug = vim.fn["plug#"]

vim.call("plug#begin")

Plug("CopilotC-Nvim/CopilotChat.nvim")
Plug("HakonHarnes/img-clip.nvim")
Plug("MeanderingProgrammer/render-markdown.nvim")
Plug("MunifTanjim/nui.nvim")
Plug("akinsho/toggleterm.nvim")
Plug("github/copilot.vim")
Plug("godlygeek/tabular")
Plug("hashivim/vim-terraform")
Plug("hashivim/vim-vagrant")
Plug("hrsh7th/cmp-buffer")
Plug("hrsh7th/cmp-cmdline")
Plug("hrsh7th/cmp-nvim-lsp")
Plug("hrsh7th/cmp-nvim-lua")
Plug("hrsh7th/cmp-path")
Plug("hrsh7th/cmp-vsnip")
Plug("hrsh7th/nvim-cmp")
Plug("hrsh7th/vim-vsnip")
Plug("junegunn/fzf", { ["dir"] = "~/.fzf/" })
Plug("junegunn/fzf.vim")
Plug("lewis6991/gitsigns.nvim")
Plug("mattn/vim-gist")
Plug("mattn/vim-goimports")
Plug("mattn/webapi-vim")
Plug("neovim/nvim-lspconfig")
Plug("nvim-lua/plenary.nvim")
Plug("nvim-lualine/lualine.nvim")
Plug("nvim-tree/nvim-web-devicons")
Plug("nvim-treesitter/nvim-treesitter")
Plug("nvimtools/none-ls.nvim")
Plug("rust-lang/rust.vim")
Plug("stevearc/dressing.nvim")
Plug("tanvirtin/monokai.nvim")
Plug("yetone/avante.nvim", {
	["branch"] = "main",
	["do"] = "make",
	["opts"] = {
		["provider"] = "copilot",
		["auto_suggestions_provider"] = "copilot",
	},
})
Plug("yowcow/partial.nvim")
Plug("zbirenbaum/copilot.lua")

vim.call("plug#end")

vim.g.fzf_history_dir = vim.fn.expand("~/.fzf-history")

require("avante").setup()

require("toggleterm").setup({
	start_in_insert = false,
	direction = "float",
})

--
-- tanvirtin/monokai.vim
-- https://github.com/tanvirtin/monokai.nvim
-- https://github.com/tomasr/molokai/blob/master/colors/molokai.vim
-- https://www.color-hex.com/
-- https://www.ditig.com/256-colors-cheat-sheet
--
local monokai = require("monokai")
local palette = monokai.classic
monokai.setup({
	custom_hlgroups = {
		Identifier = {
			fg = palette.orange,
		},
		Special = {
			fg = palette.aqua,
		},
		TabLine = {
			fg = palette.grey,
		},
		Visual = {
			bg = palette.base4,
		},
		Normal = {
			fg = palette.white,
			bg = "#101214",
		},
		LineNr = {
			fg = palette.base5,
			bg = "#101214",
		},
		SignColumn = {
			fg = palette.white,
			bg = "#101214",
		},
		Search = {
			-- explicitly highlight matches in visual selection
			style = "reverse",
			fg = palette.yellow,
			bg = palette.black,
		},
	},
})

require("lualine").setup({
	sections = {
		lualine_c = {
			{ "filename", path = 1 },
		},
	},
	options = {
		icons_enabled = false,
		theme = "molokai",
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
	},
})

--
-- https://github.com/nvim-treesitter/nvim-treesitter
-- :help treesitter
--
require("nvim-treesitter.configs").setup({
	-- one of: all, maintained, or a list of languages
	ensure_installed = {},
	sync_install = false,
	highlight = {
		enable = true,
		disable = { "perl", "erlang" },
		additional_vim_regex_highlighting = true,
	},
})

--
-- https://github.com/hrsh7th/nvim-cmp
-- :help nvim-cmp
--
local cmp = require("cmp")
cmp.setup({
	snippet = {
		expand = function(args)
			vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
		end,
	},
	mapping = {
		["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
		["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
		["<C-k>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
		["<C-y>"] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
		["<C-l>"] = cmp.mapping({
			i = cmp.mapping.abort(),
			c = cmp.mapping.close(),
		}),
		["<C-n>"] = cmp.mapping(cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }), { "i", "c" }),
		["<C-p>"] = cmp.mapping(cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }), { "i", "c" }),
		["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
	},
	sources = cmp.config.sources({
		{ name = "nvim_lua" },
		{ name = "nvim_lsp" },
		{ name = "vsnip" }, -- For vsnip users.
		{ name = "path" },
		{ name = "buffer", keyword_length = 4 },
	}, {}),
})

-- Use buffer source for `/` (if you enabled `native_menu`, this won"t work anymore).
cmp.setup.cmdline("/", {
	sources = {
		{ name = "buffer" },
	},
})

-- Use cmdline & path source for ":" (if you enabled `native_menu`, this won"t work anymore).
cmp.setup.cmdline(":", {
	sources = cmp.config.sources({
		{ name = "path" },
	}, {
		{ name = "cmdline" },
	}),
})

--
-- https://github.com/yowcow/partial.nvim
--
require("partial").setup({
	json = { "jq", "." },
	sql = { "sql-formatter", "--config", vim.fn.expand("~/.config/sql-formatter/config.json") },
	sqlfmt = { "vacuum", "--", "sqlfmt", "--no-jinjafmt", "--quiet", "--safe", "-" },
	xml = { "xmllint", "--format", "-" },
	yaml = { "yamlfmt", "-in" },
})

--
-- https://github.com/lewis6991/gitsigns.nvim
--
require("gitsigns").setup()

--
-- "github/copilot.vim",
--
vim.g.copilot_no_tab_map = true
vim.keymap.set("i", "<C-g>", 'copilot#Accept("<CR>")', { silent = true, expr = true })

--
-- "CopilotC-Nvim/CopilotChat.nvim"
--
require("CopilotChat").setup()
vim.keymap.set("n", "<Leader>cc", ":CopilotChatToggle<CR>", { noremap = true })
