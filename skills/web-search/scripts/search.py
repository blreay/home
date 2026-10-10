#!/usr/bin/env python3
"""Free web search: 360 Search primary, Bing fallback. No API key required."""
import html
import re
import sys
import urllib.parse
import urllib.request

UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"


def fetch(url: str, timeout: int = 15) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read().decode("utf-8", errors="ignore")


def _clean(title: str) -> str:
    return html.unescape(re.sub(r"<[^>]+>", "", title)).strip()


def search_so(query: str, count: int):
    s = fetch("https://www.so.com/s?q=" + urllib.parse.quote(query))
    res = re.findall(
        r'<h3[^>]*class="res-title[^"]*"[^>]*>\s*<a[^>]+href="([^"]+)"[^>]*>(.*?)</a>',
        s, re.S)
    out = []
    for url, title in res:
        t = _clean(title)
        if t:
            out.append((t, url))
        if len(out) >= count:
            break
    return out


def search_bing(query: str, count: int):
    s = fetch("https://cn.bing.com/search?q=" + urllib.parse.quote(query) + f"&count={count}")
    res = re.findall(r'<h2[^>]*>\s*<a[^>]+href="([^"]+)"[^>]*>(.*?)</a>', s, re.S)
    out = []
    for url, title in res:
        t = _clean(title)
        if t:
            out.append((t, url))
        if len(out) >= count:
            break
    return out


def main():
    if len(sys.argv) < 2:
        print("usage: search.py <query> [count] [--resolve]", file=sys.stderr)
        sys.exit(2)
    query = sys.argv[1]
    count = 10
    resolve = "--resolve" in sys.argv
    for a in sys.argv[2:]:
        if a.isdigit():
            count = int(a)
    results, engine = search_so(query, count), "360"
    if not results:
        results, engine = search_bing(query, count), "bing"
    print(f"engine={engine} query={query!r} results={len(results)}")
    for i, (t, u) in enumerate(results, 1):
        print(f"\n{i}. {t}\n   {u}")
    if resolve:
        for i, (t, u) in enumerate(results, 1):
            if "so.com/link" in u:
                try:
                    req = urllib.request.Request(u, headers={"User-Agent": UA})
                    with urllib.request.urlopen(req, timeout=10) as r:
                        print(f"   [{i}] -> {r.geturl()}")
                except Exception as e:
                    print(f"   [{i}] -> (resolve failed: {e})")


if __name__ == "__main__":
    main()
