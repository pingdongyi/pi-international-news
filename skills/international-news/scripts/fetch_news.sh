#!/usr/bin/env bash
# Fetch today's international news headlines from Google News RSS.
# Usage: fetch_news.sh [--topic TOPIC] [--world] [--count N] [--attempts N] [--retry-delay S]

set -euo pipefail

COUNT=25
FEED="https://news.google.com/rss?hl=en-US&gl=US&ceid=US:en"
ATTEMPTS=3
RETRY_DELAY=5

# Map friendly topic names to Google News topic-section IDs.
declare -A TOPICS=(
  [world]=WORLD
  [nation]=NATION
  [us]=NATION
  [politics]=POLITICS
  [business]=BUSINESS
  [finance]=BUSINESS
  [economy]=BUSINESS
  [tech]=TECHNOLOGY
  [technology]=TECHNOLOGY
  [science]=SCIENCE
  [health]=HEALTH
  [sports]=SPORTS
  [entertainment]=ENTERTAINMENT
  [culture]=ENTERTAINMENT
)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --world)
      FEED="https://news.google.com/rss/headlines/section/topic/WORLD?hl=en-US&gl=US&ceid=US:en"
      shift
      ;;
    --topic)
      [[ $# -ge 2 ]] || { echo "ERROR: --topic requires a value" >&2; exit 2; }
      KEY="$(echo "$2" | tr '[:upper:]' '[:lower:]')"
      if [[ -z "${TOPICS[$KEY]:-}" ]]; then
        echo "ERROR: unknown topic '$2'" >&2
        echo "Available topics: ${!TOPICS[*]}" >&2
        exit 2
      fi
      FEED="https://news.google.com/rss/headlines/section/topic/${TOPICS[$KEY]}?hl=en-US&gl=US&ceid=US:en"
      shift 2
      ;;
    --count)
      COUNT="$2"
      shift 2
      ;;
    --attempts)
      ATTEMPTS="$2"
      shift 2
      ;;
    --retry-delay)
      RETRY_DELAY="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: fetch_news.sh [--topic TOPIC] [--world] [--count N] [--attempts N] [--retry-delay S]" >&2
      exit 2
      ;;
  esac
done

# Create a temp file robustly. Some environments (e.g. Termux/Android) have no
# /tmp directory, or it may not be writable, so try several candidate dirs and
# fall back to the script's own directory or the current working directory.
TMPFILE=""
make_temp() {
  local d f
  for d in "${TMPDIR:-/tmp}" "$(cd "$(dirname "$0")" && pwd)" "$PWD"; do
    [[ -d "$d" && -w "$d" ]] || continue
    if f="$(mktemp "$d/news.XXXXXX" 2>/dev/null)"; then
      TMPFILE="$f"
      return 0
    fi
  done
  return 1
}

if ! make_temp; then
  echo "ERROR: could not create a temporary file" >&2
  exit 1
fi
trap 'rm -f "$TMPFILE"' EXIT

# --- Fetch with retries: a single transient network blip must not kill the summary ---
ok=0
for ((i = 1; i <= ATTEMPTS; i++)); do
  if curl -sL --max-time 20 "$FEED" -o "$TMPFILE" \
     && [[ -s "$TMPFILE" ]] \
     && grep -q '<title>' "$TMPFILE"; then
    ok=1
    break
  fi
  rm -f "$TMPFILE"
  if [[ $i -lt $ATTEMPTS ]]; then
    sleep "$RETRY_DELAY"
  fi
done

if [[ $ok -eq 0 ]]; then
  echo "ERROR: failed to fetch news feed (network issue?)" >&2
  exit 1
fi

# Extract <title> tags, skipping the feed title and the "Google News" label.
# 'head' may close the pipe early, triggering SIGPIPE upstream; guard the
# pipeline so that does not surface as a false failure under 'set -o pipefail'.
TITLES="$(grep -oP '(?<=<title>).*?(?=</title>)' "$TMPFILE" \
  | sed 's/&amp;/\&/g; s/&quot;/"/g; s/&#39;/'"'"'/g; s/&lt;/</g; s/&gt;/>/g' \
  | tail -n +3 \
  | head -n "$COUNT" \
  || true)"

if [[ -z "$TITLES" ]]; then
  echo "ERROR: no headlines found in feed" >&2
  exit 1
fi

printf '%s\n' "$TITLES" | nl -w2 -s'. '
