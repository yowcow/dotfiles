return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {
          settings = {
            gopls = {
              hints = {
                -- assignVariableTypes = false,
                -- compositeLiteralFields = false,
                -- compositeLiteralTypes = false,
                -- constantValues = false,
                -- functionTypeParameters = false,
                -- parameterNames = false,
                -- rangeVariableTypes = false,
              },
              usePlaceholders = false, -- this annoys me as ####
            },
          },
        },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        perlnavigator = {
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
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "perl" } },
  },
}
