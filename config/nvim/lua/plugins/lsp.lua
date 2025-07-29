return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {
          settings = {
            gopls = {
              -- hints = {
              --   assignVariableTypes = true,
              --   compositeLiteralFields = true,
              --   compositeLiteralTypes = true,
              --   constantValues = true,
              --   functionTypeParameters = true,
              --   parameterNames = true,
              --   rangeVariableTypes = true,
              -- },
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
}
