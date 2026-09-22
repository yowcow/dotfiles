# #277 計測記録: #276 未測定 5 項目

対象リビジョン: `171ba97`。挙動修正なし (観察と記録まで)。各項目の修正要否は #280 / #279 への入力。

## 1. `brew upgrade -y` (`local/bin/update-env:11`)

- 現行 manpage (`docs.brew.sh/Manpage`, 2026-09-21 取得) の `upgrade` 節に `-y, --no-ask` が文書化されている
  (`install` 節にも同名オプションあり)。`-y` は有効なオプション。
- 当ホストは Linux で brew 未導入のため実行確認は不可。文書ベースの計測。
- **判定: 修正不要。** #280 の対象から除外してよい。

## 2. blink.cmp `sources.default = { "copilot" }` (`config/nvim/lua/plugins/ai.lua:75`)

- LazyVim の blink extra (`lua/lazyvim/plugins/extras/coding/blink.lua`, main, 2026-09-22 取得) は
  `opts_extend = { "sources.completion.enabled_providers", "sources.compat", "sources.default" }` を宣言し、
  既定 `default = { "lsp", "path", "snippets", "buffer" }` を持つ。
- lazy.nvim は `opts_extend` 指定のリスト系テーブルを上書きではなく拡張マージする。
  よって自前の `default = { "copilot" }` は追加になり、lsp/path/snippets/buffer は落ちない。
  `providers.copilot` (dict) は deep-merge で追加される。
- **判定: 修正不要。**「lsp を落とす」は不成立。

## 3. sway `output *` × kanshi (`config/sway/config:46-51,303` / `config/kanshi/config:1-4`)

- sway は起動時に `output * { scale 1, ... }` を全出力のフォールバックとして適用し、
  `exec kanshi` でデーモンを起動する。
- kanshi(1/5): プロファイルに列挙した出力がすべて接続されている場合に自動適用し、
  wlr-output-management 経由でコンポジタの出力状態を上書きする。
  本プロファイルは `HDMI-A-2` + `Dell U2720Q` 接続時のみ成立し、`HDMI-A-2` の `scale 1.5` のみ上書きする
  (Dell 側に scale 指定なしのため sway の `scale 1` が残る)。
  不成立時は何もせず sway の `output *` が残る。
- 出典: kanshi(5) manpage (wlr-output-management による上書きの記述。2026-09-22 取得)。
- **判定: 修正不要 (文書ベース。live compositor での実行確認はなし)。**
  衝突ではなく「合致時は kanshi が上書き、非合致時は sway がフォールバック」の関係で破綻なし。

## 4. `perltidyProfile = ""` (`config/nvim/lua/plugins/lsp.lua:34`)

- PerlNavigator `server/src/formatting.ts` の `getTidyProfile` は `if (settings.perltidyProfile)` で分岐する。
  空文字は falsy のため `--profile` を付けず、perltidy 既定設定で整形が実行される (無効化ではない)。
- 上流 README も「カスタム整形したい場合に設定、未設定なら既定」と説明し、
  設定例自体が `perltidyProfile = ''`。意図的な LSP-off でも conform との衝突でもない
  (conform の `perl = { "perltidy" }` は別経路で `perltidyrc` を読む)。
- 出典: PerlNavigator リポジトリ内 `server/src/formatting.ts` (`getTidyProfile`) および README の設定例 (2026-09-22 取得)。
- **判定: 修正不要。**

## 5. OpenCode `rm *` と `rm -rf` (`config/opencode/opencode.jsonc:4-10`)

- 権限ドキュメント: `*` は任意文字の 0 文字以上に一致し、ルールは後に一致したものが勝つ。
  例 `grep *` が引数付きコマンド全体に一致するのと同様、`rm *` は `rm ` で始まる全文に一致する。
- よって `rm -rf <path>` は `bash: "rm *": "deny"` に一致し拒否される
  (前の `"*": "allow"` を上書き)。`rm <path>` も同様に拒否。
  ドキュメント上の挙動であり matcher の実行確認はなし。監査時の「未測定」は解消。
- 出典: OpenCode docs の Permissions 節 (`*` の一致規則と後勝ちの記述。2026-09-22 取得)。
- 残留リスク (#279 への申送り、本 Issue では直さない):
  `rm *` は前方一致のため `/bin/rm -rf` や `command rm` 等の別表記には一致しない。
- **判定: 修正不要 (本 Issue の `rm -rf` 照合に限る。文書ベースで matcher 未実行。
  別表記バイパスは未解決のため #279 に申送り)。**
