# ai/tools

AI アシスタントの運用を測るための道具を置く。`Makefile` の install 対象ではない — `$HOME` へ symlink して使う dotfile ではなく、このリポジトリ内から直接走らせる道具である。

## measure-claude-code.py

Claude Code のセッションコスト（token 消費と subagent dispatch）を集計する。

**Claude Code 専用である。** 走査対象は Claude Code の transcript（`~/.claude/projects/*/*.jsonl` と、subagent 側の `~/.claude/projects/*/*/subagents/*.jsonl`）で、レコード形（`type` / `message.usage` / `isSidechain`）と dispatch を数える tool 名（`Agent` / `Task`）を決め打ちしている。他のアシスタント（Gemini / Codex / Grok）の記録には当たらない。

### 出所

[yowcow/dude#159 の測定報告](https://github.com/yowcow/dude/issues/159#issuecomment-5518651417) に貼られたコードブロックに由来する。追跡 issue は [yowcow/dude#162](https://github.com/yowcow/dude/issues/162)。測定報告のコメントは唯一の記録であり、元のスクリプトはセッション破棄とともに消える一時ディレクトリにあったため、この場所を durable な置き場とした。

**もはや逐語コピーではない。** 設置時点では逐語コピーであり、測定報告の数値と一致することが検証機構であったが、その性質は[計上単位の訂正](https://github.com/yowcow/dude/issues/159#issuecomment-5521143212)によって意図的に手放した。測定報告の数値との一致は、もはや守るべき性質ではない。

測定報告のコードブロックからの差分は次の 5 点である。

1. ファイル名を `measure.py` から `measure-claude-code.py` へ改め、docstring の使い方の 1 行を合わせた。
2. [yowcow/dotfiles#253](https://github.com/yowcow/dotfiles/issues/253) で `--since` / `--until` の値欠落と「値が別のフラグである」ケースを弾くガードを引数解析に足した。値を書き忘れると `IndexError` の traceback が出るか、次のフラグが値として黙って採られるかのどちらかになっていたためで、経緯はリンク先の issue に記録がある。**ガードは異常な起動形を非ゼロ終了させるだけであり、集計ロジックと出力には影響しない。**
3. **usage の合算を assistant レコード単位から API リクエスト単位に改めた。** Claude Code は 1 レスポンスを content ブロックごとに別レコードとして書き、各レコードに同一の usage の複製を持たせるため、レコード単位の合算は絶対値を過大に計上する。`requestId` の初出だけを数え、ファイルを跨いだ複製も一度だけ数える。
4. **出力に計上単位を明示した。** ラベルを `turns` から `requests` に改め、`per request $`（1 リクエストあたりの換算後 $）の行を加え、`isSidechain` の行にはレコード単位の診断である旨の注記を付けた。

5. **コスト換算を model ごとの単価に改め、cache write を TTL の実測内訳で按分し、transcript-dir を複数受けるようにした。** 経緯は [yowcow/dude#169](https://github.com/yowcow/dude/issues/169) の pilot 測定である — 安い model の main loop を測る窓では、Claude Opus 5 決め打ちの換算は主たる消費を計上できず、`promptCacheTtl` を `5m` にした窓では 1h 単価を当てた換算が符号を誤らせ、`pr-to-ready` が自前で作る worktree のセッションは別ディレクトリに落ちて 1 ディレクトリの走査から漏れる。加えて、**subagent の消費が 1 件も走査されていなかった** — 印付き worker のコストは、まさに読まれていないファイルの側にある。**これら 4 点はいずれも測定そのものを成立させないため、機能追加ではなく前提の訂正として入れた。**

機能追加（測定項目の追加、可視化）は上記 issue のスコープ外である。**ただし 4 の `per request $` の 1 行だけは例外として追加した** — [訂正コメント](https://github.com/yowcow/dude/issues/159#issuecomment-5521143212)が判定をこの単位で行うべきと定め、[yowcow/dude#161](https://github.com/yowcow/dude/issues/161) の判定指標がこの値に依存するためである。この行を落としてはならない。

### 何を測るか

Claude Code の transcript（`~/.claude/projects/<作業ディレクトリ由来の名前>/*.jsonl` と、その配下の `<session-uuid>/subagents/*.jsonl`）を走査し、`type` が `assistant` のレコードから次を集計する。**usage は `requestId` の初出のみを数える**（ファイル横断で重複除去する）一方、**dispatch は全レコードを走査する** — 重複レコードもそれぞれ別の content ブロックを運ぶためである。

- model ごとの API リクエスト数と token（`input` / `output` / `cache_read` / `cache_creation`、および cache write の TTL 別内訳）
- model ごとの API 単価によるコスト換算（cache write は TTL の実測内訳で按分）と、全 model 合算・1 セッション・1 リクエストあたりの派生値
- subagent（`<project-dir>/<session-uuid>/subagents/` 直下の `*.jsonl`。Claude Code はこれを `agent-*.jsonl` の名前で書く）の消費を**別立てで**同じ換算にかけた値と、総額に占める割合
- `Agent` / `Task` の tool_use から、subagent dispatch の件数と `model` 指定の分布、および `description` と prompt 冒頭 300 字による役割別の内訳

既定の transcript ディレクトリは `~/.claude/projects/-home-yowcow-repos-dude`。位置引数で差し替える。**位置引数は複数取れる** — Claude Code は worktree のセッションを作業ディレクトリ由来の別ディレクトリ（`-home-yowcow-repos-dude--claude-worktrees-<branch>` 等）に書くため、1 つの窓が複数のディレクトリに散る。同じ実体のファイルは一度だけ走査する（`dir` と `dir/` のように書き方が違っても実体パスで畳む）。

**subagent の消費は別立てで走査し、別立てで示す。** Claude Code は subagent のターンを親の transcript にインラインで書かず、`<project-dir>/<session-uuid>/subagents/agent-*.jsonl` に書く。親側の assistant レコードは `isSidechain` がすべて false であり、消費がインラインで現れることはない。したがって `*.jsonl` の非再帰 glob だけでは、**`dispatch total` は表示されるのに、その dispatch が消費した token が 1 つも計上されない**という形になる。[yowcow/dude#159](https://github.com/yowcow/dude/issues/159) の測定報告が subagent 消費量を 8 標本からの外挿として別扱いしたのは、この穴の裏返しである。

**走査を再帰にするのではなく第 2 の走査として足したのは、top-level 側の母数を動かさないためである。** 再帰にすると `sessions` に agent のファイルが加わって `per session` の定義が変わり、[yowcow/dude#161](https://github.com/yowcow/dude/issues/161) の判定指標（per request $、帯 ±27.9%）は top-level のみの母数で測られているため、分子だけを増やすと比較可能性が崩れる。別立てなら、既存の帯をそのまま当てられる一方で、**「main loop のコスト」と「印付き worker のコスト」を分けて読める** — これは pilot が答えようとしている問いそのものである。

subagent 側は usage と requests だけを集計する。**したがって `dispatch 合計` と subagent のコストは母集団が違う** — 前者は top-level が発行した dispatch の数、後者は `subagents/` に落ちた全 agent の消費であり、subagent がさらに出した dispatch は前者に現れない（固定窓では 422 対 434）。**両者を割って「dispatch あたりのコスト」を出してはならない。**`dispatch` と役割別の内訳、および `isSidechain` の診断は誰が誰を出したかの記録であり、top-level 側でのみ数える。2 つの走査は順に行い、**top-level で数えた `requestId` は subagent 側で数えない**。`model: "inherit"` で出した agent のリクエストは親の transcript と agent 自身の transcript の両方に記録されるため、corpus ごとに独立して数えると同じ API リクエストを 2 回計上する（実測で観測済み）。重なりを top-level 側に残すのは、そちらが yowcow/dude#161 の判定指標の基礎だからである。除いた件数は黙って消さずに出力する。

### 起動形

```
python3 ai/tools/measure-claude-code.py [transcript-dir ...] [--since ISO8601] [--until ISO8601]
```

`--since` / `--until` は半開区間 `[since, until)` に絞る。標準ライブラリのみを使う。**存在しないディレクトリを渡した場合は非ゼロ終了する** — 走査 0 件として黙って通ると、窓が空であることと区別が付かず、`TOTAL $0.00` が正しい測定値のように見えるためである。

### 窓を固定する理由

transcript は追記式であり、測定しているセッション自身の transcript も同じディレクトリに含まれる。**窓を固定しないと数字は毎回増え、前後比較が成立しない。**

前後比較では `--since` と `--until` の**両方**を与える。`--until` だけを動かすと後者の窓が前者を含む入れ子区間になり、どちらも変更前のデータに支配されて差が出ない。

### 固定窓での再現

`python3 ai/tools/measure-claude-code.py --until 2026-09-02T00:00:00Z` の出力を 2026-09-03 に記録し、**model ごとの単価への変更後に 2026-09-04 へ再測定して同値であることを確認した**（観測範囲 2026-08-24T05:45:08Z 〜 2026-09-01T08:45:08Z）。この窓の cache write は 100% が 1h TTL であるため、TTL 按分は Claude Opus 5 決め打ちの旧換算と同じ金額に着地する。**表は既定の 1 ディレクトリだけを走査した値であり、worktree のセッションを含まない。** **再現の対象はこの表、すなわち本スクリプト自身の出力である。**

| 項目 | 値 |
| --- | ---: |
| sessions with assistant turns in window | 85 |
| `isSidechain` | 全 16,026 レコードが `false` |
| `claude-opus-5` requests | 6,885 |
| `input_tokens` | 13,748 |
| `output_tokens` | 6,039,592 |
| `cache_read_input_tokens` | 1,361,634,616 |
| `cache_creation_input_tokens` | 27,284,222（`ttl_1h` 27,284,222 / `ttl_5m` 0） |
| `<synthetic>` requests | 10（6 項目すべて 0。単価表に無いため未計上） |
| `claude-opus-5` SUBTOTAL | $1,104.72（input $0.07 / output $150.99 / cache_read $680.82 / cache_write_5m $0.00 / cache_write_1h $272.84 / cache_write_unsplit $0.00） |
| 比率 | 0.0% / 13.7% / 61.6% / 0.0% / 24.7% / 0.0% |
| 全 model 合算 TOTAL / priced requests | $1,104.72 / 6,885 |
| per session / requests per session | $13.00 / 81.0 |
| per request / per priced request | $0.1605（この窓は priced な model が `claude-opus-5` 1 つなので両者は同値） |
| cache_read/request / cache_creation/request / output/request | 197,768 / 3,963 / 877 |
| dispatch 合計 | 422（省略 284 / opus 68 / sonnet 65 / haiku 5） |
| 役割別 | review-plan 156 / review-code 130 / simplify-code 72 / pr-to-ready 19 / implement 15 / investigate 6 / explore 5 / unknown 19 |
| 印なし役割への opus 明示 | 5 件 |
| subagent: 窓内に assistant を持つ agent | 434 |
| subagent: `claude-sonnet-5` | requests 5,515 / SUBTOTAL $151.29 / per request $0.0274 |
| subagent: `claude-opus-5` | requests 376 / SUBTOTAL $23.02 / per request $0.0612 |
| subagent: `claude-haiku-4-5-20251001` | requests 24 / SUBTOTAL $0.56 / per request $0.0233 |
| subagent: `<synthetic>` | requests 7（単価未登録のため未計上） |
| subagent 合算 TOTAL / priced requests | $174.87 / 5,915 |
| subagent: per priced request | $0.0296 |
| subagent が占める割合 / 総額 | 13.7% / $1,279.59 |

**測定報告のうち subagent 消費量の数字は 8 標本からの外挿であってスクリプトの出力ではなく、再現の対象外である。**

**親 issue の測定報告の表は再現の対象ではない。むしろ再現してはならない** — あの表は assistant レコード単位で合算された過大計上値である（`claude-opus-5` 16,016 ターン、cache_read 3,022,385,810、換算合計 $2,697.66）。

`sessions with assistant turns in window` と `isSidechain` はレコード単位の診断であり、リクエスト単位への訂正の影響を受けない。dispatch と役割別も、全レコードを走査するため不変である。

**`per session` の分母は、窓内に assistant レコードを 1 件以上持つ transcript ファイルの数である**（この窓では 85、出力の `sessions with assistant turns in window`）。**走査ファイル数 `files=` とは別の量である。** リクエスト単位への訂正は分子にのみ及ぶため、resume / fork が生んだ複製ファイルはそのまま別セッションとして数えられる（この窓では、新規 `requestId` を 1 件も寄与しない純粋な複製ファイルが 3 件ある）。**セッションあたりの値は目安であり、判定に用いてはならない** — 判定は `per request` で行う。**なお `per request`（model ごとの小計 ÷ その model の requests）と `per priced request`（全 priced model の合算 ÷ priced requests の合計）は別の量であり、model が混ざる窓では乖離する** — どちらを判定に当てたかは測定報告の側で述べること。

**`files=` は表に含めない。** これは走査したファイル数であり、transcript ディレクトリへの追記で増える（記録時点で 109）。窓の中のレコードは変わらないため、表の値には影響しない。**subagent 側の `files=` も同じ理由で含めない** — 表に置いたのは「窓内に assistant を持つ agent」の数である。

**この窓では、main loop の cache write が 100% 1h TTL であるのに対し、subagent 側は 100% 5m TTL である。** `promptCacheTtl` の設定が及ぶ範囲（main conversation と、それとインラインで走る helper）と符合する。TTL の設定を動かして符号を読む測定は、main loop についてのみ成立する。

### yowcow/dude#159 の訂正表と一致しない理由

[yowcow/dude#159 の訂正コメント](https://github.com/yowcow/dude/issues/159#issuecomment-5521143212)の訂正表とも、本スクリプトの出力は一致しない。**訂正表は `(file, requestId)` 対で集計されており、ファイル横断の重複除去を行っていないためである。**

| 集計単位 | 単位数 | cache_read | 換算合計 |
| --- | ---: | ---: | ---: |
| assistant レコード単位（測定報告） | 16,016 | 3,022,385,810 | $2,697.66 |
| `(file, requestId)` 対（#159 の訂正表） | 7,113 | 1,390,985,768 | $1,133.35 |
| **`requestId`（本スクリプト）** | **6,885** | **1,361,634,616** | **$1,104.72** |

差の 228 件は、セッションの resume / fork が先行レコードを別ファイルに複製したものである。同一の API リクエストであるから、[yowcow/dude#162](https://github.com/yowcow/dude/issues/162) の完了条件はこれを一度だけ数えることを要求しており、本スクリプトはそれに従う。

### 単価の前提

コスト換算は model ごとの API 単価を `RATES` にハードコードしている。出典は [Pricing](https://platform.claude.com/docs/en/about-claude/pricing)（2026-09-04 参照）で、単位は USD / MTok である。

| model | base input | 5m cache write | 1h cache write | cache read | output |
| --- | ---: | ---: | ---: | ---: | ---: |
| `claude-fable-5-1` | $10.00 | $12.50 | $20.00 | $0.25 | $50.00 |
| `claude-opus-5` | $5.00 | $6.25 | $10.00 | $0.50 | $25.00 |
| `claude-sonnet-5` | $2.00 | $2.50 | $4.00 | $0.20 | $10.00 |
| `claude-haiku-4-5` | $1.00 | $1.25 | $2.00 | $0.10 | $5.00 |

cache read は base input の 0.1× であり、Claude Fable 5.1 だけが 0.025× という別扱いを受ける（出典同上）。model は完全一致か、8 桁の日付を接尾辞に持つ形（`claude-haiku-4-5-20251001`）でだけ引く。**単なる前方一致にしないのは、将来の枝番（`claude-opus-5-1` のような ID）に隣の行の単価が黙って当たるのを避けるためである** — `claude-fable-5-1` が既にこの命名を取っている以上、起こりうる形である。

cache write は `ttl_5m` / `ttl_1h` の実測内訳で按分する。**内訳を持たないレコードの残差は `cache_write_unsplit` として 1h 単価を当て、別行で示す** — 旧実装の仮定をそのまま残した形であり、金額が丸ごと消えるより、どれだけが仮定に依存しているかが見えるほうがよいためである。

**単価表に無い model は $0 として黙って合算に混ぜず、`単価未登録のため未計上` として token だけを示す。** 換算の TOTAL と `per priced request` の分母（`priced requests`）はいずれも単価の付いた model だけを数える（model ごとの `per request` の分母は、その model 自身の requests である）。

単価が変わった場合は `RATES` の前提も変わる。**金額は API 単価での換算であり、実際の課金形態とは別である。** 比率と相対比較は課金形態に依存せず成立する。
