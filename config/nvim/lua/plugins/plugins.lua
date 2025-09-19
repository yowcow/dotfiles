return {
  { "nvim-mini/mini.pairs", enabled = false },
  { "junegunn/fzf" },
  { "junegunn/fzf.vim" },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {},
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
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        perl = { "perltidy" },
        sql = { "sqlfmt" },
      },
    },
  },
}
