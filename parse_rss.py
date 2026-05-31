#!/usr/bin/env python3
"""
Parse Google News RSS files into a compact, deduped Markdown list.

Usage:  python3 parse_rss.py <raw_dir> [seen.json]

- Reads every *.xml in <raw_dir> (one file per company, filename = company).
- Skips any URL already recorded in seen.json, then records the new ones.
- Prints a Markdown item list to stdout (this is what gets fed to claude -p).

Stdlib only — no pip installs.
Note: seen URLs are committed as soon as they're parsed. To re-pull everything,
just delete seen.json.
"""
import sys, os, json, glob
import xml.etree.ElementTree as ET
from html import unescape

PER_COMPANY_CAP = 25  # bound tokens; raise if you want more breadth

raw_dir = sys.argv[1] if len(sys.argv) > 1 else "raw"
seen_path = sys.argv[2] if len(sys.argv) > 2 else "seen.json"

try:
    seen = set(json.load(open(seen_path)))
except Exception:
    seen = set()

new_seen = set(seen)
out = []

for path in sorted(glob.glob(os.path.join(raw_dir, "*.xml"))):
    company = os.path.splitext(os.path.basename(path))[0].replace("_", " ")
    try:
        root = ET.parse(path).getroot()
    except Exception:
        continue  # skip empty / failed fetches
    rows = []
    for it in root.findall(".//item"):
        title = (it.findtext("title") or "").strip()
        link = (it.findtext("link") or "").strip()
        date = (it.findtext("pubDate") or "").strip()
        src_el = it.find("source")
        source = (src_el.text or "").strip() if src_el is not None else ""
        if not link or link in new_seen:
            continue
        new_seen.add(link)
        rows.append(f"- {unescape(title)}  [{source} \u00b7 {date}]  {link}")
        if len(rows) >= PER_COMPANY_CAP:
            break
    if rows:
        out.append(f"\n### {company}")
        out.extend(rows)

# Commit the newly seen URLs
try:
    json.dump(sorted(new_seen), open(seen_path, "w"), indent=0)
except Exception as e:
    print(f"warn: could not write {seen_path}: {e}", file=sys.stderr)

sys.stdout.write("\n".join(out))
