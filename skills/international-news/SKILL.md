---
name: international-news
description: Fetch today's international news summary. Use when the user asks for "today's international news", "world news", "what's happening in the world today", "latest international headlines", etc. Supports topic filtering (politics, finance, tech).
compatibility: Requires a workspace with curl (curl fetches Google News RSS feeds).
---

# International News Fetcher

Fetch today's international news and present it to the user as a grouped, topic-based summary.

## When to use

Use this skill when the user asks for international news, world news, or today's headlines, e.g.:
- "today's international news"
- "world news today"
- "what's happening in the world"
- "latest international headlines"

## How it works

A bash script fetches Google News RSS feeds and extracts article titles. It needs `curl` and standard text tools (`grep`, `sed`). The assistant then organizes the headlines into a user-facing summary grouped by topic.

The script creates its temporary file robustly: it tries `$TMPDIR`, then `/tmp`, then the script's own directory, so it works even on systems where `/tmp` is missing or unwritable (e.g. some Termux/Android setups).

## Steps

### 1. Fetch the headlines

Run the fetch script:
`scripts/fetch_news.sh`

Optional arguments:
- `--topic TOPIC`: fetch a specific topic feed. Available topics: `world`, `nation`/`us`, `politics`, `business`/`finance`/`economy`, `tech`/`technology`, `science`, `health`, `sports`, `entertainment`/`culture`.
- `--world`: use the world news topic feed (broader geopolitical coverage). Equivalent to `--topic world`.
- `--count N`: show the first N headlines (default 25).
- Without arguments, it fetches the top stories feed.

Examples:
`scripts/fetch_news.sh --count 20`
`scripts/fetch_news.sh --topic tech --count 15`
`scripts/fetch_news.sh --topic politics`

The script prints a numbered list of headlines in the form `N. <Headline> - <Source>`. If the network is unavailable or the feed is empty, it prints an error message and exits non-zero.

### 2. Organize and present the summary

Group the headlines into topics and present them to the user in Chinese. Follow this structure:

- Open with a title line: `## 🌍 今日国际新闻速览` (or an equivalent in the user's language), plus the date.
- Group headlines by topic, each with an emoji marker and a bold topic label, e.g. `### 🗳️ 美国政治 · 中期选举`.
- Under each topic, list the stories as bullet points: `- **<short Chinese summary>**：<key detail>（<source>）`.
- Keep each entry concise: a short summary of the headline plus the source.
- If a story is significant, give it slightly more detail. Do not pad the list.

Suggested topic groups and emoji markers:
- `🗳️` Politics / elections
- `🌍` Geopolitics / international relations
- `🕌` Middle East
- `🇪🇺` Europe
- `🌏` Asia-Pacific
- `🇺🇦` Conflicts / Russia-Ukraine
- `💹` Economy / finance
- `🔬` Technology / science
- `🎭` Culture / society
- `📉` Markets

Fall back to a generic `🌐` marker for any topic not listed above. Only show a topic group if it has at least one story.

### 3. Close with an offer

End the summary by offering to drill into a specific topic or to fetch a different feed (e.g. world mode) if the user wants more detail.

## Notes

- The feed is English-language Google News top stories. Headlines come as-is; the assistant translates and summarizes them for the user.
- If a headline seems stale (older than ~2 days), mention it is likely an older story and offer to fetch a different feed.
- Do not use a memory file for the headlines; this is live data, fetch it fresh each time.
- The presentation step is part of the skill: always produce the grouped summary above, not just the raw headline list.
