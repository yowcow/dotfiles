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
}
