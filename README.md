# pi-international-news

A [Pi](https://pi.dev) **skill** that fetches today's international news summary.

Use it when the user asks for "today's international news", "world news", "what's
happening in the world today", or "latest international headlines". Supports topic
filtering (politics, finance, tech). Requires `curl`.

## Install

```bash
pi install git:https://github.com/pingdongyi/pi-international-news.git@v1
```

## Usage

Ask the model for today's international news; the skill fetches grouped,
topic-based headlines via Google News RSS feeds.
