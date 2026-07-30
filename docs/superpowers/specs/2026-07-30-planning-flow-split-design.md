# 計画フェーズの二段分割 + 自作スキルの薄型化 — 設計

## 背景

issue yowcow/dotfiles#18 は「`review-plan` skill が重すぎるかもしれない。質を落とさずにエコ化できるならやりたい」という指摘。調査の結果、原因は2つあった。

- **原因1: レビュー対象が実装前の時点で詳細すぎる。** `ai/GUIDELINES.md` と `ai/skills/plan-work/SKILL.md`（Output contract）が、実装前の plan に「別セッション単体で実装できる自己完結性」を要求している。そのため設計合意の直後に exact paths・タスクごとの検証コマンド・エッジケース列挙まで書き切ることになり、その巨大な成果物に `review-plan` が 7レンズ × 3リビュアー × 最大5ラウンドで回る。
- **原因2: 自作スキルが superpowers の機能を再実装している。** `implement-work` の Execution method / Guardrails / Isolation の大半は superpowers の `subagent-driven-development`（以下 SDD）と `writing-plans` が既に所有していた。同じ diff が SDD のブランチ全体レビューと `review-code` で二度レビューされる重複もあった。

意図した成果は3つ。

1. 計画フェーズを「PR単位のTODOリスト（粗い・publish する）」と「1PR分の詳細plan（実装直前・スクラッチ）」の二段に分ける。
2. 自作スキルを配線だけに痩せさせ、各フェーズの手順は superpowers に委ねる。
3. `review-plan` は対象ごとにレンズと fan-out を絞り、自前で持つのは superpowers に存在しない「plan レビューのレンズ体系」だけにする。

スキルは現行の4つのまま（`plan-work` / `implement-work` / `review-plan` / `pr-to-ready`）。名前も増減もない。

## 設計

### 二段分割

計画フェーズを次の二段に分ける。

- **PR単位のTODOリスト** — `plan-work` が作り、tracking issue のコメントとして publish する。設計・分割方針・番号付きTODOリスト（各項目は目的・スコープ境界・完了条件のみ）を含む。exact paths、行番号、タスクごとの検証コマンド、エッジケース列挙は含まない。
- **1PR分の詳細plan** — `implement-work` の先頭で `superpowers:writing-plans` を使って起草する。実行方法（SDD 等）に渡すための作業ファイルであり、隔離された作業ツリーの中の git-ignore された場所に置く。publish せず、コミットもしない。

これにより、`review-plan` が重い詳細plan 全体に対して回ることがなくなり、代わりに粗いTODOリストと詳細plan それぞれに適したレンズ・fan-out で回る。

### スキルの薄型化

`implement-work` の Execution method / Guardrails / Isolation は、手順そのものを自前で書かず、superpowers のスキル名を委譲先として示すだけにする。具体的には isolation を `superpowers:using-git-worktrees`、実行を既定で `superpowers:subagent-driven-development`（別セッションなら `superpowers:executing-plans`）、TDD を `superpowers:test-driven-development`、並列は独立した事実収集のみ `superpowers:dispatching-parallel-agents` に委ねる。自前で残すのは、委譲コストを回収できる粒度かどうかの判断や、無関係なリファクタをしないといった配線レベルの判断のみ。

### `review-plan` の縮小

`review-plan` は1スキルのまま、対象を2つに分ける。

- **TODO list**（`plan-work` から）: レンズは Necessity / Completeness / Consistency / Reality / Risk。Assumptions と Executability はスキップ（タスク粒度の詳細がまだ存在せず適用不能）。
- **Implementation plan**（`implement-work` から）: レンズは Completeness / Consistency / Reality / Assumptions / Executability / Risk。Necessity はスキップ（TODO list 段階で決着済み）。

Dispatch は既定 **1リビュアーがそのターゲットの全レンズを担当**し、大きい・リスキー・複数サブシステムに跨る場合のみ最大 **2リビュアー**まで増やす。「1レンズ1リビュアー」の段は削除する。ラウンド上限は3（従来5から縮小）。finding contract・判定手順・report は1カ所のまま維持する。

### 新しいフロー契約

| フロー | entry | 成果物 |
|---|---|---|
| `plan-work` | issue 番号 / 計画依頼 | 設計 + PR単位TODOリスト（2 PR以上なら sub-issues）。1回だけ publish |
| `implement-work` | sub-issue 番号 / 1PRで収まる issue / 同規模の依頼 | 検証済みコミットのブランチ（PRなし） |
| `pr-to-ready` | 検証済みブランチ | ready な PR（変更なし） |

`implement-work` はゲートを2つ持つ: **Isolation → Plan gate**（`review-plan` が blocking finding なしで返る）→ **Execution** → **完了ゲート**（I4 の形）→ **Hand off**。

## 記述の原則

この書き換え全体を貫く原則は次の4つ。

- **依存はスキル名までに留める。** superpowers の行番号・セクション名・チェックリスト番号を引用しない。自作スキル同士も名前と契約で参照し、行番号を使わない。参照先はバージョン付きキャッシュ（`.../superpowers/6.2.0/skills/...`）で、上流更新のたびに全部ズレるため。
- **他スキルの挙動を上書きするときは、相手の該当箇所を指すのではなく、こちら側の不変条件を宣言してそれに反する動きを止める形で書く。** 1つの不変条件が複数の個別上書きを置き換えるので、記述量も減る。
- **サブスキルを呼ぶ箇所には必ず I0 の一文を添える。** 不変条件を GUIDELINES に置くだけでは足りない — サブスキル側の終端指示は呼び出し地点で読まれるので、そこで対抗されないと負ける。省略してよい呼び出し地点は無い（レビューで、最も強い終端指示を持つ箇所こそ補強を省いていた、という逆転が見つかった）。
- **機械的に担保できるなら文章より優先する。** 例: 詳細plan の非コミットは `.gitignore` への追加で機械的に防ぎ、散文の注意書きに頼らない。

superpowers の挙動についての事実（下記「検証済みの制約」）は、2026-07-30 時点 / superpowers 6.2.0 での観測として日付付きで記録し、スキル本文には持ち込まない。`plan-work` が 65536 文字上限を「contract ではなく observation」として扱っているのと同じ流儀。

## 不変条件

個別の override 文の代わりに、これだけを置く。

- **I0（制御フローの所有）** — サブスキルが自分の手順の最後に次のスキルへ進もうとしても従わない。フローの進行を決めるのは呼び出した側。GUIDELINES 冒頭の「The orchestrator owns the workflow's progression」の具体化であり、C3・C4・C5 をまとめて塞ぐ。個別のスキル名も手順名も出さないので上流更新に強い。ただし GUIDELINES に置くだけでは足りず、各呼び出し地点での局所補強が必須。

  切るのは「次のスキルへの遷移」だけ。サブスキルが自分の成果物に対して行う自己レビューとユーザー確認、および遷移前の内部の後片付けは走らせる — 呼び出しの目的成果物は「生ファイル」ではなく「自己レビューとユーザー確認を通った成果物」である。この線引きを誤ると3つ同時に壊れる（C15・C16・C17）。
- **I1（記録先と作業ツリー）** — `plan-work` は作業ツリーに触らない。設計と TODO の正式記録は tracking issue のコメント（issue が無ければチャット）。呼び出したサブスキルがファイル書き出しや commit を前提にしていても行わず、その対象を issue コメントに読み替える。サブスキルが成果物への自己レビューやユーザー確認を求める場合、その対象も同じく issue コメント（またはチャットの下書き）と読み替える。
- **I2（詳細plan はスクラッチ）** — `implement-work` における詳細plan は実行方法に渡すための作業ファイルであり、publish する成果物ではない。隔離された作業ツリーの中の git-ignore された場所に置く（決定4・決定9で機械的に担保）。
- **I3a（統合の所有）** — `implement-work` におけるブランチ統合の提示は Hand off が完了ゲート通過後に一度だけ行う。実行方法はそこへ進まない（I0 の帰結だが、統合は不可逆なので個別に明示する）。
- **I3b（PR 作成の所有）** — `implement-work` の Hand off で PR を作る選択肢が提示されたら push までで止める。PR の作成は `pr-to-ready` が owns する。
- **I3c（統合経路の限定）** — `implement-work` におけるこのワークフローの統合は PR 経由に限る。ブランチをベースに直接マージしてフローを終わらせる選択肢は取らない（`pr-to-ready` と CI と PR レビューを丸ごと飛ばすことになる — C18）。ユーザーが明示的にそれを望む場合のみ、PR を経ないことを確認した上で従う。
- **I4（レビューの重複回避）** — `implement-work` の完了ゲートで足すのは、その実行方法が済ませていないものだけ。ブランチ全体のレビューがクリーンで返っている場合に限り再実行しない。次はいずれも「クリーンでない」として扱い `review-code` を通す: 未解決または保留された finding が残っている（C6）、そもそもブランチ全体レビューが一度も走っていない（C13）、ゲート内の簡素化やレビュー修正で誰もレビューしていない差分が生じた。
- **I5（severity）** — `review-plan` における Critical / Important / Minor の3段を1行で自前定義する。他スキルの語彙を参照する方が脆い。

`finishing-a-development-branch` が冒頭で全テストを再実行する重複は明示的に受容する — テスト再実行はレビューパスと違って安価で、統合直前の最終セーフティネットとして値段に見合う。

## 検証済みの制約（2026-07-30 時点 / superpowers 6.2.0 での観測）

以下は **契約ではなく観測**である。2026-07-30 時点の事実に過ぎない。大半は `review-plan` のリビュアーが superpowers 6.2.0 の実ファイルとスクリプトを読んで確認したもので、C10 はこのリポジトリの `Makefile`、C12 と C19 は git の実挙動を実測したもの。`plan-work` が 65536 文字のコメント上限を「contract ではなく observation」として扱っているのと同じ流儀で、上流の superpowers が更新されればここに記録した挙動は古くなり得る。だからこそスキル本文にはこれらの制約そのものを持ち込まず、この spec にだけ日付付きで記録する。

- **C1** SDD と `executing-plans` は plan をファイルとして受け取る。SDD の作業ディレクトリ解決・タスク抽出・レビューパッケージ生成の3スクリプトはいずれも plan ファイルパスを引数に取り、先頭で存在チェックして無ければ異常終了する。進捗 ledger も plan ファイルパスで自身を識別する。→ 詳細plan を「セッション内のみ」にすると実行方法に渡せない。
- **C2** `git worktree add` は追跡されていないファイルを新しい作業ツリーにコピーしない。よって gitignore した plan ファイルを worktree の外で書くと、worktree 内に存在せず C1 の存在チェックで即死する。加えて `writing-plans` 自身が「isolated worktree なら実行時までに作られているべき」という前提を明記している。→ isolation を plan の起草より前に置く。
- **C3** `writing-plans` は plan を保存した直後に実行方法（SDD / `executing-plans`）の選択をユーザーに問い、選ばれたスキルを自分で呼ぶ。放置すると Plan gate の `review-plan` ループが丸ごと飛ばされる。逆に I0 でここを止めると、その選択手順にも到達しなくなるので、実行方法の選択は `implement-work` が持たねばならない。
- **C4** `brainstorming` は自身の終端状態を「`writing-plans` を呼ぶこと。他のスキルは呼ぶな」と明言している。`plan-work` が `writing-plans` を呼ばない設計にすると、この終端遷移に引きずられる。
- **C5** SDD と `executing-plans` は、それぞれ自分の最後に `finishing-a-development-branch` を呼んで終わる。同スキルはローカルマージも選択肢として提示するので、放置すると完了ゲートの簡素化より前に統合が起きうる。
- **C6** SDD は per-task レビュー + 修正ループ + ブランチ全体レビュー + 修正波 + スコープ付き再レビューまで持つ。ただし最後は未解決の finding を「park」して終わることがあり、クリーンで終わるとは限らない。
- **C7** `writing-plans` は spec カバレッジ・プレースホルダ・型整合の自己レビューを自前で持つ。`review-plan` の plan ターゲットはこれを再実行してはいけない。
- **C8** SDD の作業ディレクトリは自分で `*` を書いた `.gitignore` を置くので、リポジトリ側の `/.superpowers/` エントリは冗長（防御の二重化として害はない）。load-bearing なのは `/docs/superpowers/plans/` の方だけ。
- **C9** SDD は Task 1 の前に plan 内の矛盾を走査してユーザーに一括提示する。plan gate の Consistency レンズと重なるが、gate を通った plan なら空振りするだけで害はない。
- **C10 ★実装時の事故要因★** `Makefile:150` は `ln -sfn $(AI_GUIDELINES_ABS) $@`、`AI_GUIDELINES_ABS := $(abspath ai/GUIDELINES.md)` で CWD 相対に解決される。worktree の中で `make` を走らせると `~/.claude/CLAUDE.md` と全スキル symlink が worktree を指し、worktree 削除後に dangling symlink となってこのマシンの全 AI CLI セッションが壊れる。この変更自体を worktree で作業する前提なので踏みやすい（本変更が持ち込んだ欠陥ではなく既存の踏み穴。恒久対策は別 issue 候補）。
- **C11** `brainstorming` の終端指示は `<HARD-GATE>` ブロック・プロセス図の唯一の終端ノード・「唯一呼ぶスキルは `writing-plans`」の断言、の三重で強調されている。しかも同スキルは spec を書いて commit する手順を含む。`plan-work` には worktree が無い（決定9の Isolation は `implement-work` 側）ので、ここで負けると master への直接コミットが起き、`plan-work` の Boundary と GUIDELINES の「master に直接コミットするな」を同時に破る。→ 最も強い対抗指示を持つ箇所なので、I0 の局所補強を最優先で置く。
- **C12** `using-git-worktrees` は既存の隔離を現在の CWD からしか検出しない（`GIT_DIR` と `GIT_COMMON_DIR` の比較）。ブランチ名や機能名で既存の worktree を探す仕組みは無く、作成手順は `git worktree add <path> -b <branch>` を無条件に打つので、同名ブランチが既にあると fatal で失敗する。→ 別セッションからの再開時に効く。
- **C13** `executing-plans` はブランチ全体レビューを一切持たない（タスク実行から統合工程へ直行する）。→ I4 は「レビューが一度も走っていない」を「クリーンでない」として扱わないと、`executing-plans` のブランチが無レビューで Hand off に到達する。
- **C14** 既存の隔離が検出された場合、`using-git-worktrees` は作成だけを飛ばし、プロジェクト設定とベースライン検証の手順はそのまま走る。決定9で Isolation を前倒しすると、実行方法が同スキルを呼び直した時にこの2手順が二度走る。C6・C8 と違って実時間のコストがあるが、正しさには影響しない。
- **C15** `brainstorming` は設計のユーザー承認の後に、成果物への自己レビューとユーザー確認の手順を持つ。現行の `plan-work` はこれを issue コメントへ読み替えて保存している。I0 を「成果物ができた時点で切る」と読むとこれが落ち、publish される成果物の内容に人間の承認が一度も入らないまま決定6で sub-issue が自動生成される。
- **C16** `writing-plans` の自己レビュー（spec カバレッジ / プレースホルダ / 型整合）は、plan の保存後・実行方法の提示前にある。I0 をファイル保存時点で切ると、決定8「品質バーは plan を書くスキルが所有する」の土台が消える。
- **C17** SDD は作業ディレクトリの削除（`rm -rf`）を統合工程の呼び出し直前に置いている。I0 が遷移だけを切るなら削除は走るが、成果物完成時点で切ると宙に浮く。
- **C18** `finishing-a-development-branch` の選択肢にはローカルマージがある（ベースブランチへ `git merge` して feature ブランチを削除する）。これを選ぶと `pr-to-ready` も CI も PR レビューも丸ごと飛ぶ。I3b は PR 作成の選択肢しか塞いでいないので、別途塞ぐ必要がある。
- **C19** `git worktree remove` は、gitignore されたファイルやディレクトリが作業ツリー内に残っていても `--force` なしで成功する。詳細plan ファイル（`/docs/superpowers/plans/` 配下）と SDD の作業ディレクトリ（`/.superpowers/sdd/` 配下）の両方を置いた状態で実測した。よって決定4の置き場所は後片付けを妨げず、回避策も不要。

C11〜C18 は特に load-bearing — I0 の切断線（どこで遷移だけを切り、自己レビュー等は走らせるか）、`brainstorming` 呼び出し地点の補強を最優先とする根拠、`implement-work` の worktree 再利用チェック手順、I3c の必要性は、いずれもこの8件の観測抜きには導けない。

## 決定事項

1. 詳細plan（`superpowers:writing-plans` + 穴レビュー ループ）は `implement-work` の先頭に内包する。新スキルは作らない。
2. issue の起票はスコープ外（人間が先に起票する前提）。
3. `review-plan` は1スキルに2ターゲット。finding contract・判定手順・report は1カ所のまま。
4. 詳細plan はファイルとして書き、コミットしない（C1）。パスはサブスキルのデフォルトに任せ、`.gitignore` に `/docs/superpowers/plans/` を追加してコミットを機械的に防ぐ。`/.superpowers/` も併せて追加するが、これは防御の二重化（C8）。
5. 各 sub-issue の中身は目的・スコープ境界・完了条件 + 親 issue の設計コメント URL。exact paths と検証コマンドは書かない。
6. 2 PR 以上に分かれる場合、sub-issue 作成は必須（確認しない）。当初の要望は「作るか確認する」だったが、確認して No になった場合に `implement-work` の entry も `pr-to-ready` の親 issue クローズ判定も成立しないことがレビューで判明したため、ユーザーが明示的に必須化を選択した。
7. 完了ゲートは、その実行方法がまだやっていないことだけを足す（I4）。
8. 詳細plan の品質バー（exact paths、プレースホルダ禁止、タスクごとの検証手順）は自前で書かない — plan を書くスキルが所有し、`review-plan` のレンズが実際に穴を見る。
9. isolation は plan の起草より前（C2）。`implement-work` が `superpowers:using-git-worktrees` を名前で呼ぶ。実行方法が同スキルを呼び直しても作成は二重にならない（設定とベースラインは二度走る — C14、正しさには影響しない）。plan gate でエスカレーションした場合、worktree は片付けずに残してよい。ただし再開時は新規作成の前に既存の worktree とブランチの有無を確認して再利用する（`git worktree list` と `git branch --list <branch>`）— C12 により、確認せず作成すると同名ブランチで失敗する。

## レビュー経緯

この設計は `review-plan` を5ラウンド回して収束させた。43件の finding が accept され、1件が reject された。fan-out はラウンドを追うごとに 3 → 2 → 2 → 2 → 1 と絞られていった。

正直に記録しておくと、**最終（第5）ラウンドでも Critical finding が1件出ており、5ラウンド上限内でクリーンな合格には到達していない。** ラウンド3〜5で繰り返し出た欠陥クラスは「同一ファイルの別の節が旧契約を述べたまま残る」というもの（`plan-work` の Roles / Pass / Output contract 導入文 / Escalation の round cap / Splitting large work、`implement-work` と `review-plan` の `description` と冒頭、など）。節を数え上げる方式ではこの欠陥クラスが閉じないため、実装では各ファイルを節ごとの列挙に頼らず全文読み直しで新契約に照らして直す方針を採る。

## 未検証の前提

- ★最も load-bearing かつ文面では検証不能★ I0 の呼び出し側の停止指示が、サブスキル自身の強い終端指示に実際に勝つかどうか。C11 の通り `brainstorming` の終端指示は三重に強調されており、これに勝てるかは経験的にしか分からない。実装時のエンドツーエンドのスモークテストがこの前提を検証する唯一の手段であり、そこで負けるようであれば I0 + 局所補強という設計自体を見直す（次善手はサブスキルを呼ばず該当手順を自前で持つことだが、それは薄型化の目的と逆行するので、その時点でユーザーに判断を仰ぐ）。
- SDD 以外に `.superpowers/` へ書き込む superpowers スキルがあるか（あれば `/.superpowers/` エントリは冗長でなくなる）。C8 の判定に影響するだけで、追加自体は無害。

なお「`git worktree remove` が gitignore されたファイルの存在で失敗しないか」は当初この一覧にあったが、実装時に実測して解決した（C19）。
