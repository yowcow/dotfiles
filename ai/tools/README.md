# ai/tools

AI アシスタントの運用を測るための道具を置く。`Makefile` の install 対象ではない — `$HOME` へ symlink して使う dotfile ではなく、このリポジトリ内から直接走らせる道具である。

## measure.py

Claude Code のセッションコスト（token 消費と subagent dispatch）を集計する。

### 出所

[yowcow/dude#159 の測定報告](https://github.com/yowcow/dude/issues/159#issuecomment-5518651417) に貼られたコードブロックからの**逐語コピー**である。追跡 issue は [yowcow/dude#162](https://github.com/yowcow/dude/issues/162)。測定報告のコメントは唯一の記録であり、元のスクリプトはセッション破棄とともに消える一時ディレクトリにあったため、この場所を durable な置き場とした。

機能追加（測定項目の追加、可視化）は上記 issue のスコープ外である。変更する場合は、測定報告の数値との再現性が失われることを承知のうえで行うこと。

### 何を測るか

Claude Code の transcript（`~/.claude/projects/<作業ディレクトリ由来の名前>/*.jsonl`）を走査し、`type` が `assistant` のレコードから次を集計する。

- model ごとのターン数と token（`input` / `output` / `cache_read` / `cache_creation`、および cache write の TTL 別内訳）
- Claude Opus 5 の API 単価によるコスト換算と、1 セッション・1 ターンあたりの派生値
- `Agent` / `Task` の tool_use から、subagent dispatch の件数と `model` 指定の分布、および `description` と prompt 冒頭 300 字による役割別の内訳

既定の transcript ディレクトリは `~/.claude/projects/-home-yowcow-repos-dude`。第 1 引数で差し替える。

### 起動形

```
python3 ai/tools/measure.py [transcript-dir] [--since ISO8601] [--until ISO8601]
```

`--since` / `--until` は半開区間 `[since, until)` に絞る。標準ライブラリのみを使う。

### 窓を固定する理由

transcript は追記式であり、測定しているセッション自身の transcript も同じディレクトリに含まれる。**窓を固定しないと数字は毎回増え、前後比較が成立しない。**

前後比較では `--since` と `--until` の**両方**を与える。`--until` だけを動かすと後者の窓が前者を含む入れ子区間になり、どちらも変更前のデータに支配されて差が出ない。

### 固定窓での再現

`python3 ai/tools/measure.py --until 2026-09-02T00:00:00Z` が測定報告の表を再現することを 2026-09-03 に確認した（観測範囲 2026-08-24T05:45:08Z 〜 2026-09-01T08:45:08Z）。

| 項目 | 値 |
| --- | ---: |
| sessions with assistant turns in window | 85 |
| `isSidechain` | 全 16,026 件が `false` |
| `claude-opus-5` turns | 16,016 |
| `input_tokens` | 31,964 |
| `output_tokens` | 16,632,621 |
| `cache_read_input_tokens` | 3,022,385,810 |
| `cache_creation_input_tokens` | 77,048,985（`ttl_1h` 77,048,985 / `ttl_5m` 0） |
| `<synthetic>` turns | 10（6 項目すべて 0） |
| コスト換算 TOTAL | $2,697.66（input $0.16 / output $415.82 / cache_read $1,511.19 / cache_creation $770.49） |
| 比率 | 0.0% / 15.4% / 56.0% / 28.6% |
| per session / turns per session | $31.74 / 188.4 |
| cache_read/turn / cache_creation/turn / output/turn | 188,710 / 4,811 / 1,039 |
| dispatch 合計 | 422（省略 284 / opus 68 / sonnet 65 / haiku 5） |
| 役割別 | review-plan 156 / review-code 130 / simplify-code 72 / pr-to-ready 19 / implement 15 / investigate 6 / explore 5 / unknown 19 |
| 印なし役割への opus 明示 | 5 件 |

**再現の対象はスクリプトの出力に限る。** 測定報告のうち subagent 消費量の数字は 8 標本からの外挿であってスクリプトの出力ではなく、再現の対象外である。

**`files=` は一致しない。** これは走査したファイル数であり、transcript ディレクトリへの追記で増える（確認時点で 106、測定報告時点で 102）。窓の中のレコードは変わらないため、表の値には影響しない。

### 単価の前提

コスト換算は Claude Opus 5 の API 単価を `RATE` にハードコードしている — input $5.00 / output $25.00 per MTok、cache read は base input の 0.1×（$0.50）、cache write は 1 時間 TTL の 2×（$10.00）。実測では cache write の 100% が 1 時間 TTL であったため 2× を当てている。

単価が変わった場合、また別の model のセッションを測る場合は `RATE` の前提も変わる。**金額は API 単価での換算であり、実際の課金形態とは別である。** 比率と相対比較は課金形態に依存せず成立する。
