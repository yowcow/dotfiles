-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.backspace = "indent,start"
vim.opt.clipboard = ""
vim.opt.laststatus = 3
vim.opt.listchars = "tab:>-,trail:^"
vim.opt.mouse = ""
vim.opt.relativenumber = false
-- vim.opt.expandtab = true
-- vim.opt.tabstop = 4
-- vim.opt.shiftwidth = 4
vim.opt.wrap = true

vim.g.snacks_animate = false

vim.cmd("command! Todo TodoQuickFix")

---- disable treesitter indentation for specific languages
--vim.api.nvim_create_autocmd("FileType", {
--  pattern = {
--    "erlang",
--    "perl",
--  },
--  callback = function()
--    vim.opt_local.indentkeys = ""
--    vim.opt_local.indentexpr = ""
--  end,
--})

local function force_erlang_pretty_print()
  -- 1. 選択範囲を取得
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local input = table.concat(lines, "\n")

  -- 2. Erlang スクリプト
  -- 標準入力から読み込み、パースして整形して標準出力に出す
  -- io:get_chars で全データを確実に拾う
  local erl_script = [[
    io:setopts([{encoding, unicode}]),
    Data = io:get_chars(standard_io, "", 1024*1024),
    %% 末尾にドットがなければ付与する処理
    CleanData = case lists:reverse(string:trim(Data)) of
        "." ++ _ -> Data;
        _ -> Data ++ "."
    end,
    case erl_scan:string(CleanData) of
        {ok, T, _} ->
            case erl_parse:parse_exprs(T) of
                {ok, E} ->
                    %% lineWidth を小さくすることで強制改行
                    io:format("~ts~n", [erl_pp:exprs(E, [{indent, 2}, {lineWidth, 80}])]);
                _ -> halt(1)
            end;
        _ -> halt(1)
    end,
    halt().
  ]]

  -- 3. 安全に実行（リスト形式で渡すことでエスケープを回避）
  local output = vim.fn.system({ "erl", "-noshell", "-eval", erl_script }, input)

  if vim.v.shell_error ~= 0 then
    print(
      "Format Error: 選択範囲が Erlang の式として正しくありません（括弧の閉じ忘れ等を確認してください）"
    )
    return
  end

  -- 4. 結果をバッファに反映
  local output_lines = vim.split(output, "\n")
  -- 末尾の空行を削除
  if output_lines[#output_lines] == "" then
    table.remove(output_lines)
  end

  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, output_lines)
end

vim.keymap.set("v", "<leader>e", force_erlang_pretty_print, { desc = "Force Erlang Pretty Print" })
