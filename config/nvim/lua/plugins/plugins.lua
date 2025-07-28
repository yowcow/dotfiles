return {
  { "echasnovski/mini.pairs", enabled = false },
  { "junegunn/fzf" },
  { "junegunn/fzf.vim" },
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
}
