return {
  { "echasnovski/mini.pairs", enabled = false },
  { "junegunn/fzf" },
  { "junegunn/fzf.vim" },
  {
    "yetone/avante.nvim",
    enabled = true,
    ---- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    ---- ⚠️ must add this setting! ! !
    build = "make",
    --build = function()
    --  -- conditionally use the correct build system for the current OS
    --  if vim.fn.has("win32") == 1 then
    --    return "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
    --  else
    --    return "make"
    --  end
    --end,
    event = "VeryLazy",
    version = false, -- Never set this value to "*"! Never!
    ---@module 'avante'
    ---@type avante.Config
    opts = {
      -- add any opts here
      -- for example
      provider = "gemini",
      providers = {
        -- claude = {
        --   endpoint = "https://api.anthropic.com",
        --   model = "claude-sonnet-4-20250514",
        --   timeout = 30000, -- Timeout in milliseconds
        --   extra_request_body = {
        --     temperature = 0.75,
        --     max_tokens = 20480,
        --   },
        -- },
        gemini = {
          -- model = "gemini-2.5-flash-lite-preview-06-17",
          model = "gemini-2.5-flash",
        },
        copilot = {},
      },
      web_search_engine = {
        provider = "google",
      },
      auto_suggestions_provider = "copilot",
      behaviour = {
        auto_focus_sidebar = true,
        auto_suggestions = false,
        auto_set_highlight_group = true,
        auto_set_keymaps = true,
        auto_apply_diff_after_generation = true,
        support_paste_from_clipboard = true,
      },
      windows = {
        position = "right",
        width = 35,
        sidebar_header = {
          align = "center",
          rounded = false,
        },
        ask = {
          floating = false,
          start_insert = true,
          border = "rounded",
        },
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      "echasnovski/mini.pick", -- for file_selector provider mini.pick
      "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
      "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
      "ibhagwan/fzf-lua", -- for file_selector provider fzf
      "stevearc/dressing.nvim", -- for input provider dressing
      "folke/snacks.nvim", -- for input provider snacks
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
      {
        "zbirenbaum/copilot.lua",
        opts = {
          panel = {
            auto_refresh = true,
            layout = {
              position = "bottom",
              ratio = 0.3,
            },
          },
          suggestion = {
            auto_trigger = true,
            keymap = {
              accept = "<C-l>",
              next = "<C-n>",
              prev = "<C-p>",
              dismiss = "<C-h>",
            },
          },
        },
      }, -- for providers='copilot'
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
      {
        -- Make sure to set this up properly if you have lazy=true
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  },
  {
    "yowcow/partial.nvim",
    opts = {
      json = { "jq", "." },
      sql = { "sql-formatter", "--config", vim.fn.expand("~/.config/sql-formatter/config.json") },
      sqlfmt = { "vacuum", "--", "sqlfmt", "--no-jinjafmt", "--quiet", "--safe", "-" },
      xml = { "xmllint", "--format", "-" },
      yaml = { "yamlfmt", "-in" },
    },
  },
  { "stevearc/conform.nvim", opts = {
    formatters_by_ft = {
      go = { "goimports" },
    },
  } },

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
