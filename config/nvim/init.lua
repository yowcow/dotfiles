local cmd = vim.cmd -- to execute vim command
local fn = vim.fn -- to all vim function
local g = vim.g -- to access global variables
local opt = vim.opt -- to set options

opt.autoindent = true
opt.backspace = 'indent'
opt.backup = false
opt.completeopt = 'menu,menuone,noselect'
opt.expandtab = true
opt.joinspaces = false
opt.list = true
opt.listchars = 'tab:>-,trail:^'
opt.shiftwidth = 4
opt.showtabline = 2
opt.signcolumn = 'yes'
opt.smartcase = true
opt.softtabstop = 4
opt.tabstop = 4
opt.visualbell = false
opt.wildmenu = true
opt.wildmode = 'longest:full'
opt.writebackup = false

require 'paq' {
    'hrsh7th/cmp-buffer';
    'hrsh7th/cmp-cmdline';
    'hrsh7th/cmp-nvim-lsp';
    'hrsh7th/cmp-path';
    'hrsh7th/cmp-vsnip';
    'hrsh7th/nvim-cmp';
    'hrsh7th/vim-vsnip';
    'itchyny/lightline.vim';
    'junegunn/fzf.vim';
    'neovim/nvim-lspconfig';
    'nvim-treesitter/nvim-treesitter';
    'savq/paq-nvim';
    {'junegunn/fzf', dir = '~/.fzf/'};
}

require 'nvim-treesitter.configs'.setup {
    ensure_installed = 'all',
    sync_install = false,
    highlight = {
        enable = true
    }
}

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
        ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), {'i', 'c'}),
        ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
        ['<C-e>'] = cmp.mapping({
            i = cmp.mapping.abort(),
            c = cmp.mapping.close(),
        }),
        ['<CR>'] = cmp.mapping.confirm({select = true}), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    },
    sources = cmp.config.sources({
        {name = 'nvim_lsp'},
        {name = 'vsnip'}, -- For vsnip users.
    }, {
        {name = 'buffer'},
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

-- Setup lspconfig.
local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

local function map(mode, lhs, rhs, opts)
    local options = {noremap = true}
    if opts then
        options = vim.tbl_expand('force', options, opts)
    end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

local function bufmap(bufnr, mode, lhs, rhs, opts)
    local options = {noremap = true}
    if opts then
        options = vim.tbl_expand('force', options, opts)
    end
    vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, options)
end

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
    bufmap(bufnr, 'n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
end

local lspconfig = require 'lspconfig'
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
    on_attach = on_attach,
    flags = {
        debounce_text_changes = 150
    },
    capabilities = capabilities,
}


--
-- personal maps
--
map('n', 'tl', ':tabs<CR>')
map('n', 'tn', ':tabnew<space>')
map('n', 'tt', ':tabedit<space>')
map('n', 'tj', ':tabnext<CR>')
map('n', 'tk', ':tabprev<CR>')
map('n', 'tm', ':tabmove<space>')
map('n', 'td', ':tabclose<CR>')
map('n', 'bl', ':buffers<CR>')
map('n', 'bn', ':e<space>')
map('n', 'bj', ':bnext<CR>')
map('n', 'bk', ':bprev<CR>')
map('n', 'bd', ':bd<CR>')

map('n', ';b', ':Buffers<CR>')
map('n', ';w', ':Windows<CR>')
map('n', ';t', ':Files<CR>')
map('n', ';g', ':GFiles<CR>')
map('n', ';h', ':History<CR>')
map('n', ';c', ':Commits<CR>')
map('n', ';r', ':Rg<CR>');
g.fzf_history_dir = '~/.fzf-history'
