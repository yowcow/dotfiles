#!/usr/bin/env python3
"""dude セッションの token 消費と subagent dispatch を集計する。
使い方: python3 measure-claude-code.py [transcript-dir ...] [--since ISO8601] [--until ISO8601]

usage は **API リクエスト単位**で合算する。Claude Code は 1 レスポンスを content
ブロックごとに別レコードとして書き、各レコードに同一の usage の複製を持たせるため、
レコード単位で足すと 1 リクエストが複数回数えられる。requestId の初出だけを数え、
セッションの resume / fork がファイルを跨いで先行レコードを複製した場合も一度だけ
数える。したがって `per request` 系の指標は、いずれも重複除去後の値である。
（`per session` 系の分母は窓内に assistant レコードを持つ transcript ファイル数であり、
走査ファイル数 `files=` とは別の量である。複製ファイルを別セッションと数えるため目安に留まる。）

--since / --until で [since, until) の半開区間に絞る。transcript は追記式で、
測定しているセッション自身も含まれるため、前後比較では必ず両端を指定すること。
--until だけでは [集計開始, until) という入れ子区間になり、変更前のデータに
支配されて差が出ない。"""
import json, sys, glob, os, re
from collections import Counter, defaultdict

args = [a for a in sys.argv[1:]]
until = since = None
for flag in ("--until", "--since"):
    if flag in args:
        i = args.index(flag)
        if i + 1 >= len(args) or args[i+1].startswith("--"):
            sys.exit(f"error: {flag} に値がありません")
        if flag == "--until": until = args[i+1]
        else: since = args[i+1]
        del args[i:i+2]
# transcript-dir は複数取れる。Claude Code は worktree のセッションを作業ディレクトリ由来の
# 別ディレクトリに書くため、1 つの窓が複数のディレクトリに散る。
DIRS = args or [os.path.expanduser("~/.claude/projects/-home-yowcow-repos-dude")]
# 存在しないディレクトリは走査 0 件として黙って通ると、窓が空であることと区別が付かない。
for d in DIRS:
    if not os.path.isdir(d):
        sys.exit(f"error: transcript-dir がありません: {d}")

# 役割分類。description を主、prompt 冒頭 300 字を補助に、上から順に最初に当たったものを採る。
ROLES = [
    ("review-plan",   r"review[- ]?plan|plan re-?review|TODO ?(list|リスト)|implementation plan|計画.*(レビュー|review)|lens"),
    ("review-code",   r"review[- ]?code|code review|whole-?branch review|re-?review|diff.*review|findings"),
    ("simplify-code", r"simplif|簡約|cleanup|clean up|tidy"),
    ("pr-to-ready",   r"\bPR\b|pull request|copilot|CI |thread|comment"),
    ("implement",     r"implement|実装|\bTDD\b|write tests?|task \d"),
    ("investigate",   r"investigat|調査|measure|測定|diagnos|profil"),
    ("explore",       r"explore|search|grep|inventory|locate|find "),
]
def classify(desc, prompt):
    hay = f"{desc or ''}\n{(prompt or '')[:300]}"
    for name, pat in ROLES:
        if re.search(pat, hay, re.I):
            return name
    return "unknown"

dispatch = Counter(); sidechain = Counter()
roles = defaultdict(Counter)
lo = hi = None
files = sorted({os.path.realpath(f)
                for d in DIRS for f in glob.glob(os.path.join(d, "*.jsonl"))})
# subagent のターンは親の transcript に来ない。glob を再帰にせず別立てで走査するのは、
# top-level 側の files / sessions / per request の母数を動かさないためである。
sub_files = sorted({os.path.realpath(f) for d in DIRS
                    for f in glob.glob(os.path.join(d, "*", "subagents", "*.jsonl"))})

def scan(paths, top_level, already=frozenset()):
    """paths を走査し、(usage, requests, seen, active_files, shared 件数) を返す。

    already に含まれる key は数えない。`model: "inherit"` で出した agent の
    リクエストは親の transcript と agent 自身の transcript の両方に記録されるため、
    corpus ごとに独立して数えると同じ API リクエストを 2 回計上する。

    重複除去は module の docstring の述べる理由による。seen をファイルループの外で
    持つのは、resume / fork がファイルを跨いで複製した requestId も一度だけ数える
    ためである。

    top_level は top-level の corpus のときだけ真にする。dispatch と役割別の内訳、
    isSidechain の診断、および観測範囲 lo / hi は、いずれも top-level について述べる
    量であり、subagent 側の走査で動かすと同じ行の files= と対象が食い違う。"""
    global lo, hi
    usage = defaultdict(Counter); requests = Counter()
    seen = set(); active_files = set(); shared = set()
    for fp in paths:
        with open(fp, encoding="utf-8", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line: continue
                try: rec = json.loads(line)
                except ValueError: continue
                ts = rec.get("timestamp")
                if until and ts and ts >= until: continue
                if since and ts and ts < since: continue
                if ts and top_level:
                    lo = ts if lo is None or ts < lo else lo
                    hi = ts if hi is None or ts > hi else hi
                if rec.get("type") != "assistant": continue
                active_files.add(fp)
                msg = rec.get("message") or {}
                model = msg.get("model", "UNKNOWN"); u = msg.get("usage") or {}
                rid = rec.get("requestId")
                # requestId を持たないレコード（`<synthetic>` など）は uuid で一意化する。
                key = rid if rid is not None else ("uuid", rec.get("uuid"))
                if key in already:
                    shared.add(key)
                elif key not in seen:
                    seen.add(key)
                    requests[model] += 1
                    for k in ("input_tokens", "output_tokens",
                              "cache_read_input_tokens", "cache_creation_input_tokens"):
                        usage[model][k] += u.get(k) or 0
                    cc = u.get("cache_creation")
                    if isinstance(cc, dict):
                        usage[model]["ttl_5m"] += cc.get("ephemeral_5m_input_tokens") or 0
                        usage[model]["ttl_1h"] += cc.get("ephemeral_1h_input_tokens") or 0
                if not top_level: continue
                sidechain[rec.get("isSidechain")] += 1
                # dispatch は全レコードを走査する。重複レコードもそれぞれ別の content ブロックを
                # 運ぶため、読み飛ばすと tool_use を取りこぼす。
                for blk in (msg.get("content") or []):
                    if isinstance(blk, dict) and blk.get("type") == "tool_use" \
                            and blk.get("name") in ("Agent", "Task"):
                        inp = blk.get("input") or {}
                        m = inp.get("model") or "(omitted)"
                        dispatch[m] += 1
                        roles[classify(inp.get("description"), inp.get("prompt"))][m] += 1
    return usage, requests, seen, active_files, len(shared)

usage, requests, seen_requests, sessions, _ = scan(files, top_level=True)
# top-level を先に数え、そこで数えた key は subagent 側から除く。top-level の値は
# yowcow/dude#161 の判定指標の基礎なので、重なりはそちらに残して subagent 側を削る。
sub_usage, sub_requests, sub_seen, sub_agents, shared = scan(
    sub_files, top_level=False, already=seen_requests)

print(f"files={len(files)}  since={since}  until={until}  observed={lo} .. {hi}")
print(f"sessions with assistant turns in window: {len(sessions)}")
print(f"isSidechain（assistant レコード単位）: {dict(sidechain)}")
for model, c in usage.items():
    print(f"\n{model}  requests={requests[model]}")
    for k in ("input_tokens","output_tokens","cache_read_input_tokens",
              "cache_creation_input_tokens","ttl_5m","ttl_1h"):
        print(f"  {k:32} {c[k]:>15,}")
# コスト換算。単価は Claude API の公表値（USD / MTok）で、列は
# base input / 5m cache write / 1h cache write / cache read / output。
# https://platform.claude.com/docs/en/about-claude/pricing （2026-09-04 参照）
RATES = {
    "claude-fable-5-1": (10.00, 12.50, 20.00, 0.25, 50.00),
    "claude-opus-5":     (5.00,  6.25, 10.00, 0.50, 25.00),
    "claude-sonnet-5":   (2.00,  2.50,  4.00, 0.20, 10.00),
    "claude-haiku-4-5":  (1.00,  1.25,  2.00, 0.10,  5.00),
}
def rate_for(model):
    # transcript は日付付きの ID（claude-haiku-4-5-20251001）も書くため、日付の接尾辞だけを許す。
    # 単なる前方一致にすると、将来の枝番（claude-opus-5-1 のような ID）に隣の単価が黙って当たる。
    for name, r in RATES.items():
        if model == name or re.fullmatch(re.escape(name) + r"-\d{8}", model):
            return r
    return None

def cost_of(c, rate):
    inp, w5m, w1h, rd, out = rate
    # cache_creation の TTL 内訳を持たないレコードの残差。従来どおり 1h 単価で当てる。
    unsplit = max(c["cache_creation_input_tokens"] - c["ttl_5m"] - c["ttl_1h"], 0)
    return {"input_tokens":            c["input_tokens"] / 1e6 * inp,
            "output_tokens":           c["output_tokens"] / 1e6 * out,
            "cache_read_input_tokens": c["cache_read_input_tokens"] / 1e6 * rd,
            "cache_write_5m":          c["ttl_5m"] / 1e6 * w5m,
            "cache_write_1h":          c["ttl_1h"] / 1e6 * w1h,
            "cache_write_unsplit":     unsplit / 1e6 * w1h}

def report_cost(usage, requests):
    """model ごとのコスト換算を出し、(合算, priced requests) を返す。"""
    priced = {m: cost_of(c, r) for m, c in usage.items() if (r := rate_for(m))}
    # 金額の出どころを 1 つにする。model ごとの小計は以降ここからだけ引く。
    subtotal = {m: sum(d.values()) for m, d in priced.items()}
    for model in sorted(priced, key=lambda m: -subtotal[m]):
        d = priced[model]; sub = subtotal[model]; c = usage[model]; t = requests[model]
        print(f"\n{model} のコスト換算  requests={t}")
        for k, amt in d.items():
            pct = amt / sub * 100 if sub else 0
            print(f"  {k:32} ${amt:>10,.2f}  {pct:>5.1f}%")
        print(f"  {'SUBTOTAL':32} ${sub:>10,.2f}")
        print(f"  {'per request':32} ${sub/t:>10,.4f}")
        print(f"  cache_read/request {c['cache_read_input_tokens']/t:>9,.0f}"
              f"   cache_creation/request {c['cache_creation_input_tokens']/t:>7,.0f}"
              f"   output/request {c['output_tokens']/t:>5,.0f}")
    # 単価表に無い model は $0 として黙って混ぜず、token だけを別立てで示す。
    for model in sorted(m for m in usage if m not in priced):
        c = usage[model]
        print(f"\n{model}  requests={requests[model]}  単価未登録のため未計上"
              f"（input {c['input_tokens']:,} / output {c['output_tokens']:,}"
              f" / cache_read {c['cache_read_input_tokens']:,}"
              f" / cache_creation {c['cache_creation_input_tokens']:,}）")
    return sum(subtotal.values()), sum(requests[m] for m in priced)

grand, priced_requests = report_cost(usage, requests)
print(f"\n全 model 合算  TOTAL ${grand:>10,.2f}   priced requests={priced_requests}")
if sessions:
    print(f"  per session                      ${grand/len(sessions):>10,.2f}"
          f"   priced requests/session {priced_requests/len(sessions):>8.1f}")
if priced_requests:
    # model ごとのブロックの `per request` とは別の量である。ラベルを分けるのは、
    # model が混ざる窓では両者が乖離し、出力だけを見て取り違えられるためである。
    print(f"  per priced request               ${grand/priced_requests:>10,.4f}")

# subagent は別立てで出す。上の合算には含めない — top-level 側の母数を動かさないためで、
# 動かすと per session の定義と、yowcow/dude#161 の判定指標の母数が両方変わる。
print(f"\n=== subagent（上の合算には含まない）  files={len(sub_files)}"
      f"  窓内に assistant を持つ agent={len(sub_agents)} ===")
if sub_files:
    sub_grand, sub_priced_requests = report_cost(sub_usage, sub_requests)
    print(f"\nsubagent 合算  TOTAL ${sub_grand:>10,.2f}   priced requests={sub_priced_requests}")
    if sub_priced_requests:
        print(f"  per priced request               ${sub_grand/sub_priced_requests:>10,.4f}")
    if grand + sub_grand:
        print(f"  subagent が占める割合            {sub_grand/(grand+sub_grand)*100:>10,.1f}%"
              f"   （main loop と合わせた総額 ${grand+sub_grand:,.2f}）")
    # 除いた件数は黙って消さずに示す。`model: "inherit"` の agent がここに現れる。
    if shared:
        print(f"  うち {shared} 件は top-level で既に数えたため subagent 側では計上していない")
elif sum(dispatch.values()):
    # dispatch があるのに agent の transcript が 1 件も無い窓は、走査が空振りした形と
    # 区別が付かない。DIRS に存在ガードを置いたのと同じ理由で、黙って 0 を返さない。
    print("  警告: dispatch のある窓で subagent の transcript が 1 件も見つからない。"
          "走査するレイアウト（<project-dir>/<session-uuid>/subagents/*.jsonl）を確かめること。")

print(f"\ndispatch total={sum(dispatch.values())}")
for k, v in dispatch.most_common(): print(f"  {k:12} {v:>4}")

cols = ["(omitted)", "haiku", "opus", "sonnet"]
print(f"\n{'role':14}" + "".join(f"{c:>11}" for c in cols) + f"{'total':>8}")
MARKED = {"review-plan", "review-code", "pr-to-ready"}
unmarked_opus = 0
for r in [n for n, _ in ROLES] + ["unknown"]:
    c = roles.get(r)
    if not c: continue
    tot = sum(c.values())
    print(f"{r:14}" + "".join(f"{c[x]:>11}" for x in cols) + f"{tot:>8}")
    if r not in MARKED: unmarked_opus += c["opus"]
print(f"\n印なし役割への opus 明示: {unmarked_opus} 件")
