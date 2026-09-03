# ai/tools

AI アシスタントの運用を測るための道具を置く。`Makefile` の install 対象ではない — `$HOME` へ symlink して使う dotfile ではなく、このリポジトリ内から直接走らせる道具である。

## measure-claude-code.py

Claude Code のセッションコスト（token 消費と subagent dispatch）を集計する。

**Claude Code 専用である。** 走査対象は Claude Code の transcript（`~/.claude/projects/*/*.jsonl`）で、レコード形（`type` / `message.usage` / `isSidechain`）と dispatch を数える tool 名（`Agent` / `Task`）を決め打ちしている。他のアシスタント（Gemini / Codex / Grok）の記録には当たらない。

### 出所

[yowcow/dude#159 の測定報告](https://github.com/yowcow/dude/issues/159#issuecomment-5518651417) に貼られたコードブロックに由来する。追跡 issue は [yowcow/dude#162](https://github.com/yowcow/dude/issues/162)。測定報告のコメントは唯一の記録であり、元のスクリプトはセッション破棄とともに消える一時ディレクトリにあったため、この場所を durable な置き場とした。

**もはや逐語コピーではない。** 設置時点では逐語コピーであり、測定報告の数値と一致することが検証機構であったが、その性質は[計上単位の訂正](https://github.com/yowcow/dude/issues/159#issuecomment-5521143212)によって意図的に手放した。測定報告の数値との一致は、もはや守るべき性質ではない。

測定報告のコードブロックからの差分は次の 3 点である。

1. ファイル名を `measure.py` から `measure-claude-code.py` へ改め、docstring の使い方の 1 行を合わせた。
2. **usage の合算を assistant レコード単位から API リクエスト単位に改めた。** Claude Code は 1 レスポンスを content ブロックごとに別レコードとして書き、各レコードに同一の usage の複製を持たせるため、レコード単位の合算は絶対値を過大に計上する。`requestId` の初出だけを数え、ファイルを跨いだ複製も一度だけ数える。
3. 出力ラベルを `turns` から `requests` に改め、`per request $`（1 リクエストあたりの換算後 $）の行を加えた。

機能追加（測定項目の追加、可視化）は上記 issue のスコープ外である。**ただし 3 の `per request $` の 1 行だけは例外として追加した** — [訂正コメント](https://github.com/yowcow/dude/issues/159#issuecomment-5521143212)が判定をこの単位で行うべきと定め、[yowcow/dude#161](https://github.com/yowcow/dude/issues/161) の判定指標がこの値に依存するためである。この行を落としてはならない。

### 何を測るか

Claude Code の transcript（`~/.claude/projects/<作業ディレクトリ由来の名前>/*.jsonl`）を走査し、`type` が `assistant` のレコードから次を集計する。**usage は `requestId` の初出のみを数える**（ファイル横断で重複除去する）一方、**dispatch は全レコードを走査する** — 重複レコードもそれぞれ別の content ブロックを運ぶためである。

- model ごとの API リクエスト数と token（`input` / `output` / `cache_read` / `cache_creation`、および cache write の TTL 別内訳）
- Claude Opus 5 の API 単価によるコスト換算と、1 セッション・1 リクエストあたりの派生値
- `Agent` / `Task` の tool_use から、subagent dispatch の件数と `model` 指定の分布、および `description` と prompt 冒頭 300 字による役割別の内訳

既定の transcript ディレクトリは `~/.claude/projects/-home-yowcow-repos-dude`。第 1 引数で差し替える。

### 起動形

```
python3 ai/tools/measure-claude-code.py [transcript-dir] [--since ISO8601] [--until ISO8601]
```

`--since` / `--until` は半開区間 `[since, until)` に絞る。標準ライブラリのみを使う。

### 窓を固定する理由

transcript は追記式であり、測定しているセッション自身の transcript も同じディレクトリに含まれる。**窓を固定しないと数字は毎回増え、前後比較が成立しない。**

前後比較では `--since` と `--until` の**両方**を与える。`--until` だけを動かすと後者の窓が前者を含む入れ子区間になり、どちらも変更前のデータに支配されて差が出ない。

### 固定窓での再現

`python3 ai/tools/measure-claude-code.py --until 2026-09-02T00:00:00Z` の出力を 2026-09-03 に記録した（観測範囲 2026-08-24T05:45:08Z 〜 2026-09-01T08:45:08Z）。**再現の対象はこの表、すなわち本スクリプト自身の出力である。**

| 項目 | 値 |
| --- | ---: |
| sessions with assistant turns in window | 85 |
| `isSidechain` | 全 16,026 レコードが `false` |
| `claude-opus-5` requests | 6,885 |
| `input_tokens` | 13,748 |
| `output_tokens` | 6,039,592 |
| `cache_read_input_tokens` | 1,361,634,616 |
| `cache_creation_input_tokens` | 27,284,222（`ttl_1h` 27,284,222 / `ttl_5m` 0） |
| `<synthetic>` requests | 10（6 項目すべて 0） |
| コスト換算 TOTAL | $1,104.72（input $0.07 / output $150.99 / cache_read $680.82 / cache_creation $272.84） |
| 比率 | 0.0% / 13.7% / 61.6% / 24.7% |
| per session / requests per session | $13.00 / 81.0 |
| per request | $0.1605 |
| cache_read/request / cache_creation/request / output/request | 197,768 / 3,963 / 877 |
| dispatch 合計 | 422（省略 284 / opus 68 / sonnet 65 / haiku 5） |
| 役割別 | review-plan 156 / review-code 130 / simplify-code 72 / pr-to-ready 19 / implement 15 / investigate 6 / explore 5 / unknown 19 |
| 印なし役割への opus 明示 | 5 件 |

**親 issue の測定報告の表は再現の対象ではない。むしろ再現してはならない** — あの表は assistant レコード単位で合算された過大計上値である（`claude-opus-5` 16,016 ターン、cache_read 3,022,385,810、換算合計 $2,697.66）。

`sessions with assistant turns in window` と `isSidechain` はレコード単位の診断であり、リクエスト単位への訂正の影響を受けない。dispatch と役割別も、全レコードを走査するため不変である。

**`files=` は表に含めない。** これは走査したファイル数であり、transcript ディレクトリへの追記で増える（記録時点で 109）。窓の中のレコードは変わらないため、表の値には影響しない。

### yowcow/dude#159 の訂正表と一致しない理由

[yowcow/dude#159 の訂正コメント](https://github.com/yowcow/dude/issues/159#issuecomment-5521143212)の訂正表とも、本スクリプトの出力は一致しない。**訂正表は `(file, requestId)` 対で集計されており、ファイル横断の重複除去を行っていないためである。**

| 集計単位 | 単位数 | cache_read | 換算合計 |
| --- | ---: | ---: | ---: |
| assistant レコード単位（測定報告） | 16,016 | 3,022,385,810 | $2,697.66 |
| `(file, requestId)` 対（#159 の訂正表） | 7,113 | 1,390,985,768 | $1,133.35 |
| **`requestId`（本スクリプト）** | **6,885** | **1,361,634,616** | **$1,104.72** |

差の 228 件は、セッションの resume / fork が先行レコードを別ファイルに複製したものである。同一の API リクエストであるから、[yowcow/dude#162](https://github.com/yowcow/dude/issues/162) の完了条件はこれを一度だけ数えることを要求しており、本スクリプトはそれに従う。

### 単価の前提

コスト換算は Claude Opus 5 の API 単価を `RATE` にハードコードしている — input $5.00 / output $25.00 per MTok、cache read は base input の 0.1×（$0.50）、cache write は 1 時間 TTL の 2×（$10.00）。実測では cache write の 100% が 1 時間 TTL であったため 2× を当てている。

単価が変わった場合、また別の model のセッションを測る場合は `RATE` の前提も変わる。**金額は API 単価での換算であり、実際の課金形態とは別である。** 比率と相対比較は課金形態に依存せず成立する。
