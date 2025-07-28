return {
  -- colorschemes
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      transparent_background = false,
      dim_inactive = {
        enabled = true,
      },
      color_overrides = {
        mocha = {
          base = "#0a0a0f",
        },
      },
    },
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } },
}
