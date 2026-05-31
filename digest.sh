#!/usr/bin/env bash
#
# Weekly HCM/HR AI competitive-intelligence digest.
#   fetch (Google News RSS, last 7 days) -> parse+dedup -> claude -p -> email
#
# Run manually:  ./digest.sh
# (Scheduling instructions are in README.md.)

set -euo pipefail
cd "$(dirname "$0")"

# --- config ---------------------------------------------------------------
if [ -f .env ]; then set -a; source .env; set +a; fi

DATE="$(date +%Y-%m-%d)"
RAW_DIR="raw"
mkdir -p "$RAW_DIR"
rm -f "$RAW_DIR"/*.xml 2>/dev/null || true

# AI keyword cluster used to narrow each company's news to AI-relevant items.
KW='(AI OR "artificial intelligence" OR "machine learning" OR "generative AI" OR copilot OR agent OR LLM)'

# --- 1. fetch -------------------------------------------------------------
while IFS= read -r company || [ -n "$company" ]; do
  # skip blanks and comments
  [[ -z "${company// /}" ]] && continue
  [[ "$company" =~ ^[[:space:]]*# ]] && continue

  safe="$(echo "$company" | tr ' /' '__')"
  query="\"$company\" $KW when:7d"
  enc="$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$query")"
  url="https://news.google.com/rss/search?q=${enc}&hl=en-US&gl=US&ceid=US:en"

  echo "fetch: $company"
  curl -sL --max-time 30 -A "Mozilla/5.0" "$url" -o "$RAW_DIR/$safe.xml" \
    || echo "  (fetch failed for $company, skipping)"
  sleep 1   # be polite to the endpoint
done < companies.txt

# --- 2. parse + dedup -----------------------------------------------------
ITEMS="$(python3 parse_rss.py "$RAW_DIR" seen.json)"

if [ -z "${ITEMS// /}" ]; then
  echo "No new items this week. Nothing to send."
  exit 0
fi

# --- 3. analyze with claude -p (headless) ---------------------------------
echo "analyzing with claude -p ..."
PROMPT="$(cat prompt.md)

## This week's news items (raw, from Google News RSS)
$ITEMS"

# --allowedTools WebFetch lets claude read the top articles for detail.
# For fully unattended runs (e.g. cron with no one at the keyboard), add:
#   --dangerously-skip-permissions
DIGEST="$(claude -p "$PROMPT" --allowedTools "WebFetch" --output-format text)"

OUT="digest-$DATE.md"
printf '%s\n' "$DIGEST" > "$OUT"
echo "digest written: $OUT"

# --- 4. deliver -----------------------------------------------------------
if python3 send_email.py "$OUT" "$DATE"; then
  echo "done."
else
  echo "email step failed (digest is still saved at $OUT)."
fi
