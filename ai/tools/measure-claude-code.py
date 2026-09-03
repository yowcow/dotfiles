#!/usr/bin/env python3
"""dude セッションの token 消費と subagent dispatch を集計する。
使い方: python3 measure-claude-code.py [transcript-dir] [--since ISO8601] [--until ISO8601]

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
        if flag == "--until": until = args[i+1]
        else: since = args[i+1]
        del args[i:i+2]
DIR = args[0] if args else os.path.expanduser(
    "~/.claude/projects/-home-yowcow-repos-dude")

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

usage = defaultdict(Counter); turns = Counter()
dispatch = Counter(); sidechain = Counter()
roles = defaultdict(Counter)
sessions = set()
lo = hi = None
files = sorted(glob.glob(os.path.join(DIR, "*.jsonl")))

for fp in files:
    with open(fp, encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line: continue
            try: rec = json.loads(line)
            except ValueError: continue
            ts = rec.get("timestamp")
            if until and ts and ts >= until: continue
            if since and ts and ts < since: continue
            if ts:
                lo = ts if lo is None or ts < lo else lo
                hi = ts if hi is None or ts > hi else hi
            if rec.get("type") != "assistant": continue
            sessions.add(fp)
            sidechain[rec.get("isSidechain")] += 1
            msg = rec.get("message") or {}
            model = msg.get("model", "UNKNOWN"); u = msg.get("usage") or {}
            turns[model] += 1
            for k in ("input_tokens", "output_tokens",
                      "cache_read_input_tokens", "cache_creation_input_tokens"):
                usage[model][k] += u.get(k) or 0
            cc = u.get("cache_creation")
            if isinstance(cc, dict):
                usage[model]["ttl_5m"] += cc.get("ephemeral_5m_input_tokens") or 0
                usage[model]["ttl_1h"] += cc.get("ephemeral_1h_input_tokens") or 0
            for blk in (msg.get("content") or []):
                if isinstance(blk, dict) and blk.get("type") == "tool_use" \
                        and blk.get("name") in ("Agent", "Task"):
                    inp = blk.get("input") or {}
                    m = inp.get("model") or "(omitted)"
                    dispatch[m] += 1
                    roles[classify(inp.get("description"), inp.get("prompt"))][m] += 1

print(f"files={len(files)}  since={since}  until={until}  observed={lo} .. {hi}")
print(f"sessions with assistant turns in window: {len(sessions)}")
print(f"isSidechain: {dict(sidechain)}")
for model, c in usage.items():
    print(f"\n{model}  turns={turns[model]}")
    for k in ("input_tokens","output_tokens","cache_read_input_tokens",
              "cache_creation_input_tokens","ttl_5m","ttl_1h"):
        print(f"  {k:32} {c[k]:>15,}")
# コスト換算。単価は Claude Opus 5（input $5.00 / output $25.00 per MTok、
# cache read = 0.1x input、cache write = 1h TTL で 2x input）。
RATE = {"input_tokens": 5.00, "output_tokens": 25.00,
        "cache_read_input_tokens": 0.50, "cache_creation_input_tokens": 10.00}
c = usage.get("claude-opus-5", Counter())
total = sum(c[k] / 1e6 * r for k, r in RATE.items())
print("\nclaude-opus-5 のコスト換算（1h TTL の cache write を仮定）")
for k, r in RATE.items():
    amt = c[k] / 1e6 * r
    pct = amt / total * 100 if total else 0
    print(f"  {k:32} ${amt:>10,.2f}  {pct:>5.1f}%")
print(f"  {'TOTAL':32} ${total:>10,.2f}")
if sessions:
    print(f"  per session                      ${total/len(sessions):>10,.2f}"
          f"   turns/session {turns['claude-opus-5']/len(sessions):>8.1f}")
if turns["claude-opus-5"]:
    t = turns["claude-opus-5"]
    print(f"  cache_read/turn {c['cache_read_input_tokens']/t:>12,.0f}"
          f"   cache_creation/turn {c['cache_creation_input_tokens']/t:>10,.0f}"
          f"   output/turn {c['output_tokens']/t:>8,.0f}")

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
