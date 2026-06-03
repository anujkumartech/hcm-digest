#!/usr/bin/env bash
#
# Fetch + parse ONLY. Prints this week's news items (Markdown) to stdout.
#
# Used by the cloud Routine: analysis and email happen inside the routine
# session (see ROUTINE.md), not here. No claude -p, no SMTP, no dedup store —
# the weekly when:7d window is the dedup.
#
# Requires: curl + python3 (both standard in the cloud environment).
# Note: news.google.com must be on the environment's allowed-domains list,
# or the curl calls return 403 host_not_allowed under "Trusted" network access.

set -euo pipefail
cd "$(dirname "$0")"

RAW_DIR="raw"
# Cloud routines re-clone the repo each run, so raw/ starts empty and needs no
# cleanup. curl -o overwrites any same-named file, so re-runs stay correct too.
mkdir -p "$RAW_DIR"

KW='(AI OR "artificial intelligence" OR "machine learning" OR "generative AI" OR copilot OR agent OR LLM)'

while IFS= read -r company || [ -n "$company" ]; do
  [[ -z "${company// /}" ]] && continue
  [[ "$company" =~ ^[[:space:]]*# ]] && continue

  safe="$(echo "$company" | tr ' /' '__')"
  query="\"$company\" $KW when:7d"
  enc="$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$query")"
  url="https://news.google.com/rss/search?q=${enc}&hl=en-US&gl=US&ceid=US:en"

  curl -sL --max-time 30 -A "Mozilla/5.0" "$url" -o "$RAW_DIR/$safe.xml" || true
  sleep 1
done < companies.txt

# /dev/null as the seen-store = no dedup (intended for the weekly cloud run).
python3 parse_rss.py "$RAW_DIR" /dev/null
