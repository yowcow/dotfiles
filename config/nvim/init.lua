local cmd = vim.cmd -- to execute vim command
local fn = vim.fn -- to all vim function
local g = vim.g -- to access global variables
local opt = vim.opt -- to set options

opt.autoindent = true
opt.backspace = 'indent,start'
opt.backup = false
opt.completeopt = 'menu,menuone,noselect'
opt.cursorline = true
opt.expandtab = true
opt.ignorecase = true
opt.joinspaces = false
opt.list = true
opt.listchars = 'tab:>-,trail:^'
opt.number = true
opt.shiftwidth = 4
opt.showmode = false
opt.showtabline = 2
opt.signcolumn = 'yes'
opt.smartcase = true
opt.smartindent = false
opt.softtabstop = 4
opt.splitbelow = true
opt.splitright = true
opt.swapfile = false
opt.tabstop = 4
opt.termguicolors = true
opt.visualbell = false
opt.writebackup = false
opt.mouse = ''
opt.encoding = 'utf-8'
opt.fileencodings='utf8,iso-2022-jp,cp932,sjis,euc-jp'

cmd('filetype plugin indent on')

-- https://www.reddit.com/r/neovim/comments/petq61/neovim_060_y_not_yanking_line_but_to_end_of_line/
cmd('nnoremap Y Y')

--
-- https://github.com/savq/paq-nvim
-- :help paq
--
require 'paq' {
  'cheap-glitch/vim-v';
  'godlygeek/tabular';
  'hashivim/vim-terraform';
  'hashivim/vim-vagrant';
  'hrsh7th/cmp-buffer';
  'hrsh7th/cmp-cmdline';
  'hrsh7th/cmp-nvim-lsp';
  'hrsh7th/cmp-nvim-lua';
  'hrsh7th/cmp-path';
  'hrsh7th/cmp-vsnip';
  'hrsh7th/nvim-cmp';
  'hrsh7th/vim-vsnip';
  'jose-elias-alvarez/null-ls.nvim';
  'junegunn/fzf.vim';
  'kyazdani42/nvim-web-devicons';
  'mattn/vim-gist';
  'mattn/vim-goimports';
  'mattn/webapi-vim';
  'neovim/nvim-lspconfig';
  'nvim-lua/plenary.nvim';
  'nvim-lualine/lualine.nvim';
  'nvim-treesitter/nvim-treesitter';
  'rust-lang/rust.vim';
  'savq/paq-nvim';
  'tanvirtin/monokai.nvim';
  {'junegunn/fzf', dir = '~/.fzf/'};
  -- {'prettier/vim-prettier', do = 'npm install --frozen-lockfile --production'};
}

--
-- tanvirtin/monokai.vim
-- https://github.com/tanvirtin/monokai.nvim
-- https://github.com/tomasr/molokai/blob/master/colors/molokai.vim
-- https://www.color-hex.com/
-- https://www.ditig.com/256-colors-cheat-sheet
--
local monokai = require 'monokai'
local palette = monokai.classic
monokai.setup {
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
      bg = '#101214',
    },
    LineNr = {
      fg = palette.base5,
      bg = '#101214',
    },
    SignColumn = {
      fg = palette.white,
      bg = '#101214',
    },
    Search = {
      -- explicitly highlight matches in visual selection
      style = 'reverse',
      fg = palette.yellow,
      bg = palette.black,
    },
  },
}

require 'lualine'.setup {
  sections = {
    lualine_c = {
      {'filename', path = 1}
    },
  },
  options = {
    icons_enabled = false,
    theme = 'molokai',
    component_separators = {left = '', right = ''},
    section_separators = {left = '', right = ''},
  },
}

--
-- https://github.com/nvim-treesitter/nvim-treesitter
-- :help treesitter
--
require 'nvim-treesitter.configs'.setup {
  -- one of: all, maintained, or a list of languages
  ensure_installed = {},
  sync_install = false,
  highlight = {
    enable = true,
    disable = {'perl', 'erlang'},
    additional_vim_regex_highlighting = true,
  }
}

--
-- https://github.com/hrsh7th/nvim-cmp
-- :help nvim-cmp
--
local cmp = require 'cmp'
cmp.setup {
  snippet = {
    expand = function(args)
      vim.fn['vsnip#anonymous'](args.body) -- For `vsnip` users.
    end,
  },
  mapping = {
    ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), {'i', 'c'}),
    ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), {'i', 'c'}),
    ['<C-k>'] = cmp.mapping(cmp.mapping.complete(), {'i', 'c'}),
    ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
    ['<C-l>'] = cmp.mapping({
      i = cmp.mapping.abort(),
      c = cmp.mapping.close(),
    }),
    ['<C-n>'] = cmp.mapping(cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }), { 'i', 'c' }),
    ['<C-p>'] = cmp.mapping(cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }), { 'i', 'c' }),
    ['<CR>'] = cmp.mapping.confirm({select = true}), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  },
  sources = cmp.config.sources({
    {name = 'nvim_lua'},
    {name = 'nvim_lsp'},
    {name = 'vsnip'}, -- For vsnip users.
    {name = 'path'},
    {name = 'buffer', keyword_length = 4},
  }, {
  })
}

-- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline('/', {
  sources = {
    {name = 'buffer'}
  }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
  sources = cmp.config.sources({
    {name = 'path'}
  }, {
    {name = 'cmdline'}
  })
})

local function map(mode, lhs, rhs, opts)
  vim.api.nvim_set_keymap(mode, lhs, rhs, opts and opts or {noremap = true})
end

local function bufmap(bufnr, mode, lhs, rhs, opts)
  vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts and opts or {noremap = true})
end

local function t(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

function _G.smarttab()
  print(vim.inspect(vim.fn.pumvisible()))
  return vim.fn.pumvisible() == 1 and t'<C-n>' or t'<Tab>'
end

-- map('i', '<tab>', 'v:lua.smarttab()', {expr = true, noremap = true})
map('n', '<space>e', '<cmd>lua vim.diagnostic.open_float()<CR>')
map('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>')
map('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>')
map('n', '<space>q', '<cmd>lua vim.diagnostic.setloclist()<CR>')

local on_attach = function(client, bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  bufmap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  bufmap(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  bufmap(bufnr, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  bufmap(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  bufmap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  bufmap(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  bufmap(bufnr, 'n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  bufmap(bufnr, 'n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  bufmap(bufnr, 'n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  bufmap(bufnr, 'n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  bufmap(bufnr, 'n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  bufmap(bufnr, 'n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  bufmap(bufnr, 'n', '<space>f', '<cmd>lua vim.lsp.buf.format({ async = true })<CR>', opts)
end

--
-- https://github.com/neovim/nvim-lspconfig
-- :help lsp
--
-- vim.lsp.set_log_level('debug')
local capabilities = require('cmp_nvim_lsp').default_capabilities()
local lspconfig = require 'lspconfig'
local lspservers = {
  'ansiblels',
  'elmls',
  'erlangls',
  'eslint',
  'intelephense',
  'terraformls',
  'tsserver',
}
for _, lsp in pairs(lspservers) do
  lspconfig[lsp].setup {
    capabilities = capabilities,
    on_attach = on_attach,
    flags = {
      debounce_text_changes = 150
    },
  }
end
-- lspconfig.erlangls.setup {
--   cmd = {'/home/yowcow/repos/erlang_ls/_build/default/bin/erlang_ls', '-d', '/tmp/erlangls/', '-l', 'debug'},
--   capabilities = capabilities,
--   on_attach = on_attach,
--   flags = {
--     debounce_text_changes = 150
--   },
-- }
lspconfig.gopls.setup {
  cmd = {'gopls', 'serve'},
  settings = {
    gopls = {
      analyses = {
        unusedparams = true
      },
      staticcheck = true
    }
  },
  capabilities = capabilities,
  on_attach = on_attach,
  flags = {
    debounce_text_changes = 150
  },
}

--
-- https://github.com/jose-elias-alvarez/null-ls.nvim
--
local nullls = require('null-ls')
nullls.setup {
  sources = {
    nullls.builtins.diagnostics.staticcheck,
    nullls.builtins.diagnostics.tsc,
  }
}

--
-- FZF
-- :help fzf
--
map('n', ';b', ':Buffers<CR>')
map('n', ';w', ':Windows<CR>')
map('n', ';t', ':Files<CR>')
map('n', ';g', ':GFiles<CR>')
map('n', ';h', ':History<CR>')
map('n', ';c', ':Commits<CR>')
map('n', ';r', ':Rg<CR>');
g.fzf_history_dir = '~/.fzf-history'

--
-- personal things
--
cmd('augroup filetyping')
cmd('autocmd!')
cmd('autocmd BufNewFile,BufRead *.psgi set filetype=perl')
cmd('autocmd BufNewFile,BufRead *.t set filetype=perl')
cmd('augroup END')

cmd('augroup tabstop')
cmd('autocmd!')
cmd('autocmd FileType make,go setlocal noexpandtab')
cmd('autocmd FileType xml,xhtml,html,smarty,json,yaml setlocal softtabstop=2 tabstop=2 shiftwidth=2')
cmd('autocmd FileType javascript,javascript.jsx,javascriptreact,typescript,typescript.tsx,typescriptreact,ruby,lua,sql setlocal softtabstop=2 tabstop=2 shiftwidth=2')
cmd('autocmd FileType markdown setlocal softtabstop=4 tabstop=4 shiftwidth=2')
cmd('autocmd FileType yaml setlocal indentkeys-=0#')
cmd('augroup END')

cmd('augroup bufwritepre')
cmd('autocmd!')
cmd('autocmd FileType php autocmd BufWritePre <buffer> lua vim.lsp.buf.format({ async = false })')
-- cmd('autocmd FileType go autocmd BufWritePre <buffer> silent! %!goimports')
-- cmd('autocmd FileType go autocmd BufWritePre <buffer> silent! %!gofmt')
cmd('autocmd FileType javascript,typescript,typescript.tsx autocmd BufWritePre <buffer> silent! EslintFixAll')
cmd('autocmd FileType json autocmd BufWritePre <buffer> silent! %!jq "."')
cmd('augroup END')

cmd('augroup term')
cmd('autocmd!')
cmd('autocmd TermOpen * startinsert')
cmd('augroup END')

-- tabs/buffers
-- map('n', 'tl', ':tabs<CR>')
map('n', 'tn', ':tabnew<space>')
map('n', 'tt', ':tabedit<space>')
map('n', 'tl', ':tabnext<CR>')
map('n', 'th', ':tabprev<CR>')
map('n', 'tm', ':tabmove<space>')
map('n', 'td', ':tabclose<CR>')
-- map('n', 'bl', ':buffers<CR>')
-- map('n', 'bn', ':e<space>')
-- map('n', 'bl', ':bnext<CR>')
-- map('n', 'bh', ':bprev<CR>')
-- map('n', 'bd', ':bd<CR>')

-- term
map('t', '<C-\\><C-\\>', '<C-\\><C-n>')

-- some global variables
g.terraform_fmt_on_save = 1
g.rustfmt_autosave = 1

local function get_selection(from, to)
  local header = {}
  local body = {}
  local footer = {}
  for i, v in ipairs(vim.fn.getline(from['line'], to['line'])) do
    local current_line = from['line'] + i - 1
    local from_col = 1
    local to_col = nil
    if current_line == from['line'] then
      if from['col'] ~= nil and from['col'] ~= 1 then
        table.insert(header, string.sub(v, 0, from['col'] -1))
        from_col = from['col']
      end
    end
    if current_line == to['line'] then
      if to['col'] ~= nil and to['col'] < string.len(v) then
        table.insert(footer, string.sub(v, to['col'] + 1))
        to_col = to['col']
      end
    end
    table.insert(body, string.sub(v, from_col, to_col))
  end
  return unpack({header, body, footer})
end

local function get_range(range, line1, line2)
  local from = { line = line1 }
  local to = { line = line2 }
  if range == 0 then
    return unpack({from, to})
  end
  local _, _, from_col = unpack(vim.fn.getpos("'<"))
  local _, _, to_col = unpack(vim.fn.getpos("'>"))
  from.col = from_col
  to.col = to_col
  return unpack({from, to})
end

local function split_string(input, sep)
  local output = {}
  for str in string.gmatch(input, "([^" .. sep .. "]+)") do
    table.insert(output, str)
  end
  return output
end

local function merge_tables(t1, t2)
  for _, v in ipairs(t2) do
    table.insert(t1, v)
  end
  return t1
end

function _G.do_format(command, range, line1, line2)
  local from, to = get_range(range, line1, line2)
  local header, body, footer = get_selection(from, to)
  local result = split_string(vim.fn.system(command, table.concat(body, "\n")), "\r\n")
  cmd(line1 .. "," .. line2 .. "delete")
  fn.append(line1 - 1, merge_tables(merge_tables(header, result), footer))
end

cmd('command! -range=% FSQL <line1>,<line2>lua do_format("sql-formatter --config ~/.config/sql-formatter/config.json", <range>, <line1>, <line2>)')
