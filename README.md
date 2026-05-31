# HCM AI Digest

A weekly competitive-intelligence digest of what the major HCM / HR-tech companies
are doing **with** and **for** AI. It pulls the last 7 days of public news per
company, has `claude -p` filter and analyze it, and emails you a clean Markdown
brief.

```
fetch (Google News RSS, when:7d)  ->  parse + dedup  ->  claude -p  ->  email
```

## Files
| File | Role |
|------|------|
| `companies.txt`  | Your watchlist, one company per line. Edit freely. |
| `digest.sh`      | The orchestrator. This is what you run. |
| `parse_rss.py`   | Turns raw RSS into a compact, deduped item list (stdlib only). |
| `prompt.md`      | The analyst instructions given to `claude -p`. Tune this to change the output. |
| `send_email.py`  | Emails the finished digest (stdlib only). |
| `.env`           | Your email credentials (create from `.env.example`). |
| `seen.json`      | Auto-created. Remembers URLs already sent so weeks don't repeat. |

## Prerequisites
- **Claude Code** installed and signed in (`claude` on your PATH). Test with `claude -p "ping"`.
- **Python 3** (only the standard library is used — nothing to pip install).
- `curl` (preinstalled on macOS/Linux).

## Setup
```bash
cp .env.example .env      # then edit .env with your email + app password
chmod +x digest.sh
```

## Run it
```bash
./digest.sh
```
First run: review `digest-YYYY-MM-DD.md` and tweak `prompt.md` / `companies.txt`
until the output is what you want.

## Schedule it later (Monday 9am)
You picked "decide later," so this is just for reference.

**Linux / macOS (cron):**
```cron
0 9 * * 1  cd /full/path/to/hcm-ai-digest && ./digest.sh >> run.log 2>&1
```
Cron only fires if the machine is awake at 9am Monday. For an always-on host, your
RTX box is the natural home.

**macOS (laptop that sleeps):** use `launchd` with a `StartCalendarInterval` — it
runs the job at the next wake if the machine was asleep at the scheduled time.

**Windows:** Task Scheduler, trigger Weekly / Monday / 09:00, action `bash digest.sh`
(via WSL or Git Bash).

For unattended runs, add `--dangerously-skip-permissions` to the `claude -p` line in
`digest.sh` so it never pauses for a tool-permission prompt. Wrap in a timeout
(`timeout 15m ...`) so a stuck run can't hang forever.

## Known limitations (this is a v0)
- **Google News links redirect.** RSS links are Google redirect URLs, so `WebFetch`
  on them is hit-or-miss; the digest works off the headline/snippet when a fetch
  fails. Cleaner sourcing = add each company's official newsroom/blog RSS, which
  gives direct URLs.
- **Headline-level filtering.** Items are narrowed by AI keywords in the query, so a
  story whose AI angle isn't in the headline can be missed. Widen the keyword set in
  `digest.sh` or drop it to pull everything and let claude filter.
- **Dedup commits on parse.** A URL is marked "seen" as soon as it's parsed, even if
  the email later fails. To re-pull everything, delete `seen.json`.

## Upgrade paths when you outgrow v0
- Swap Google News RSS for per-company newsroom RSS (clean URLs, primary sources).
- Add a local-Llama first pass on your RTX box to pre-filter "is this AI-related?"
  before spending Claude tokens on synthesis.
- Switch the synthesis step from `claude -p` to a direct Anthropic API script for
  structured JSON output, retries, and tighter cost control.
- Render Markdown -> HTML email (`pip install markdown`) for nicer formatting.
