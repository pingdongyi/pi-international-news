#!/usr/bin/env bash
# Fetch today's international news headlines from Google News RSS.
# Usage: fetch_news.sh [--world] [--count N]

set -euo pipefail

COUNT=25
FEED="https://news.google.com/rss?hl=en-US&gl=US&ceid=US:en"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --world)
      FEED="https://news.google.com/rss/headlines/section/topic/WORLD?hl=en-US&gl=US&ceid=US:en"
      shift
      ;;
    --count)
      COUNT="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: fetch_news.sh [--world] [--count N]" >&2
      exit 2
      ;;
  esac
done

TMPFILE="$(mktemp)"
trap 'rm -f "$TMPFILE"' EXIT

if ! curl -sL --max-time 20 "$FEED" -o "$TMPFILE"; then
  echo "ERROR: failed to fetch news feed (network issue?)" >&2
  exit 1
fi

if [[ ! -s "$TMPFILE" ]]; then
  echo "ERROR: news feed is empty" >&2
  exit 1
fi

# Extract <title> tags, skip the first two (feed title and "Google News" label).
grep -oP '(?<=<title>).*?(?=</title>)' "$TMPFILE" \
  | sed 's/&amp;/\&/g; s/&quot;/"/g; s/&#39;/'"'"'/g; s/&lt;/</g; s/&gt;/>/g' \
  | tail -n +3 \
  | head -n "$COUNT" \
  | nl -w2 -s'. '
