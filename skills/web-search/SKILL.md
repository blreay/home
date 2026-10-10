---
name: web-search
description: Free local web search via scripts/search.py (360 Search primary, Bing fallback). No API key, no paid account, no cost. Use when asked to search the web, look up Chinese companies, news, or documentation, or verify facts online.
---

# Web Search (Free)

Deterministic search through `scripts/search.py`. Works with plain network access; nothing to install or pay for.

## Usage

```bash
python3 <skill_dir>/scripts/search.py "query" [count] [--resolve]
```

- Primary engine: 360 Search (so.com) — best for Chinese queries (company names, news, people).
- Fallback: Bing (cn.bing.com) when 360 returns no parseable results.
- `--resolve` follows 360 redirect links (`so.com/link?m=...`) and prints the final target URLs.

## Notes

- 360 result URLs are redirect links; they open fine in a browser. Use `--resolve` when you need the real target URL to fetch.
- To read a page, curl the URL with a browser User-Agent and parse the HTML yourself.
- Baidu and Sogou block plain curl with security-check pages; do not rely on them.
