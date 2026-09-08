---
name: xpra-install
description: Use when installing or upgrading xpra on Linux (Ubuntu 24.04+), needing Chinese pinyin input method through fcitx5, encountering input method failures where Ctrl+Space doesn't switch languages, OR configuring xterm font/size/colors (xterm font is tiny, Latin letters look stretched/spaced out, or background color needs changing) via ~/.Xresources. Covers the full stack: install, fcitx5 config, IM env var pitfalls, xterm font/size/colors via Xresources + auto-load on xpra start, DPI, and auto-restart guardian.
---

# Xpra Install & Configure (Linux)

## Overview

One-shot guide to install xpra 6.x on Ubuntu with fcitx5 Chinese input method.
All pitfalls discovered through real debugging are documented inline.

**What xpra is**: Remote X11 session multiplexer — like `screen`/`tmux` for GUI apps.
Connect via native client (`xpra attach`) or browser (`http://host:6001/`).

## Quick Install (Ubuntu 24.04 Noble)

```bash
# GPG key + apt repo
sudo curl -fsSL https://xpra.org/xpra.asc -o /usr/share/keyrings/xpra.asc
sudo tee /etc/apt/sources.list.d/xpra.sources <<'EOF'
Types: deb
URIs: https://xpra.org
Suites: noble
Components: main
Signed-By: /usr/share/keyrings/xpra.asc
Architectures: amd64 arm64
EOF
sudo apt update && sudo apt install -y xpra xdg-utils xvfb
```

> Other releases: replace `noble` with `jammy`/`bookworm`/`focal`. CentOS: use `https://xpra.org/repos/CentOS/`.
> If `downloader.cursor.sh` DNS fails (NXDOMAIN in private networks), use `api2.cursor.sh` directly.

## Fcitx5 Chinese Input Method

### Why fcitx5 (not fcitx4 / ibus)

fcitx5 is actively maintained, supports GTK4/Qt6, and works reliably with xpra.
fcitx4 is dead; ibus needs DBus which is often broken in containers.

### Install

```bash
sudo apt install -y \
  fcitx5 fcitx5-chinese-addons \
  fcitx5-frontend-gtk3 fcitx5-frontend-gtk4 fcitx5-frontend-qt5 \
  fcitx5-configtool
```

### Configure Pinyin

```bash
mkdir -p ~/.config/fcitx5
cat > ~/.config/fcitx5/profile <<'EOF'
[Groups/0]
Name=Default
Default Layout=us
DefaultIM=pinyin

[Groups/0/Items/0]
Name=pinyin
Layout=

[Groups/0/Items/1]
Name=keyboard-us
Layout=

[GroupOrder]
0=Default
EOF
```

Or use GUI: `DISPLAY=:100 fcitx5-configtool`

### THE CRITICAL PITFALL: IM Environment Variables

**90% of "input method doesn't work" bugs are here.**

xpra's `--input-method=fcitx5` sets `GTK_IM_MODULE=xim` — WRONG for fcitx5.
Firefox/Electron (GTK apps) only read `GTK_IM_MODULE`, so they fall back to XIM
protocol which fcitx5 ignores. Result: Ctrl+Space does nothing.

**Correct fix: Use `--env` to inject the right values + `--input-method=keep` to stop xpra overriding them:**

```bash
xpra start :100 \
  --bind-tcp=0.0.0.0:6001 \
  --start="xrdb -merge $HOME/.Xresources" \   # auto-load xterm font/colors (see below)
  --start=xterm \
  --start="fcitx5 -d --replace" \
  --env=GTK_IM_MODULE=fcitx5 \
  --env=QT_IM_MODULE=fcitx5 \
  --env=XMODIFIERS=@im=fcitx \
  --daemon=yes --tcp-auth=none --html=on \
  --dpi=96 \
  --input-method=keep
```

| Variable | Correct | Wrong (common) |
|---|---|---|
| `GTK_IM_MODULE` | `fcitx5` | `xim` (xpra default) |
| `QT_IM_MODULE` | `fcitx5` | `ibus` / `xim` |
| `XMODIFIERS` | `@im=fcitx` | unset → fcitx5 XIM server uses `fcitx` |

### Verify Input Method

```bash
# Check fcitx5 running
ps -ef | grep fcitx5 | grep -v grep

# Check app inherited correct env (replace PID)
cat /proc/<PID>/environ | tr '\0' '\n' | grep IM_MODULE

# Full diagnostic
DISPLAY=:100 fcitx5-diagnose 2>&1 | less
```

### Usage

| Action | Shortcut |
|---|---|
| Toggle Chinese/English | `Ctrl+Space` |
| Switch between methods | `Ctrl+Shift` |
| Temp English (in Chinese mode) | `Shift` (left or right) |
| Candidate page up/down | `-` / `=` |
| Select candidate | `1`-`9`, `0` |

In HTML5 browser client: upper-right ⚙️ → Keyboard → enable "Grab keyboard" (browser may intercept Ctrl+Space).

## xterm Font, Size & Colors (via `~/.Xresources`)

xterm started by xpra has **no settings menu** — font, size and colors are configured
through X resources. Two pitfalls unique to xterm + xpra:

1. **Tiny font / no default font config** — xterm under a fresh xpra X server falls back
   to a tiny bitmap font. You must set `faceName` + `faceSize` explicitly.
2. **Latin letters look stretched, as if spaces were inserted between every character** —
   caused by setting a CJK font (e.g. `Noto Sans Mono CJK SC`) as the main `faceName`.
   xterm is not a modern terminal with font fallback: a CJK font's Latin glyphs get
   widened into full cells with large side-bearings. **Fix: Latin monospace as
   `faceName`, CJK only via `faceNameDoublesize`.** Verified — advance-width ratios:
   DejaVu Sans Mono = identical width for every glyph (true monospace); Noto Sans Mono
   CJK = wildly varying widths (A≠M≠space), so it must NOT be the main font.

### Pick the fonts

```bash
# Latin monospace (for faceName)
fc-list : family | grep -iE "mono|liberation" | sort -u   # DejaVu Sans Mono, Liberation Mono, ...
# CJK-capable monospace (for faceNameDoublesize) — pick the SC (Simplified) variant
fc-list :lang=zh family | grep -i mono | sort -u           # Noto Sans Mono CJK SC, ...
```

### Write `~/.Xresources`

```bash
cat > ~/.Xresources <<'EOF'
! TrueType rendering (not bitmap X fonts) — crisp + scalable
XTerm*renderFont: true

! Main font: pure Latin monospace (compact, strictly equal-width, no stretching)
XTerm*faceName: DejaVu Sans Mono
! CJK / double-width chars via a separate CJK font (never set CJK as faceName)
XTerm*faceNameDoublesize: Noto Sans Mono CJK SC

! Font size — change this number to scale (e.g. 16 / 18)
XTerm*faceSize: 14
XTerm*faceSizeDPI: 96

! UTF-8 / locale (Chinese renders correctly)
XTerm*locale: true
XTerm*utf8: 2
XTerm*utf8Title: true

! Word selection: treat - . / : ~ _ as word chars (joint selection)
XTerm*charClass: 33:48,35:48,37:48,43:48,45-47:48,58:48,61:48,63:48,95:48,126:48

! Colors: pure black background, white foreground + cursor
XTerm*background: #000000
XTerm*foreground: #FFFFFF
XTerm*cursorColor: #FFFFFF
EOF
```

### Apply to the running session

```bash
# Load into the running xpra display — applies to NEW xterm windows only
DISPLAY=:100 xrdb -merge ~/.Xresources
# Verify
DISPLAY=:100 xrdb -query | grep -iE "xterm\*(faceName|faceSize|background)"
# Open a new window to see the effect (already-open windows won't change)
DISPLAY=:100 xterm &
```

> Edit a value → re-run `xrdb -merge` → open a new window. Changed value not showing?
> Use `xrdb -load` (replaces, clears stale keys) instead of `-merge`.

### Make xpra auto-load it on every start (CRITICAL)

xpra does **not** automatically read `~/.Xresources` when starting a new X server
(unlike a full Xorg/display-manager session). Each `xpra start` yields a fresh resource
DB, so font/colors reset on every restart. Add an `xrdb -merge` `--start` entry
**before** `--start=xterm` so every new window picks it up:

```bash
xpra start :100 \
  --bind-tcp=0.0.0.0:6001 \
  --start="xrdb -merge $HOME/.Xresources" \   # <-- add BEFORE --start=xterm
  --start=xterm \
  --start="fcitx5 -d --replace" \
  --env=GTK_IM_MODULE=fcitx5 \
  --env=QT_IM_MODULE=fcitx5 \
  --env=XMODIFIERS=@im=fcitx \
  --daemon=yes --tcp-auth=none --html=on \
  --dpi=96 \
  --input-method=keep
```

> Global small-everything (all GUI apps, not just xterm) → raise `--dpi=96` to `--dpi=144`.
> For only xterm, the `faceSize` change above is more precise.

## Post-Install Checklist

```bash
xpra list                     # show sessions
xpra info :100                # session details
DISPLAY=:100 xdpyinfo | grep resolution  # check DPI
tail -f /tmp/xpra/100/server.log         # watch logs
```

## Common Pitfalls

| Symptom | Cause | Fix |
|---|---|---|
| Ctrl+Space dead in Firefox/Electron | `GTK_IM_MODULE=xim` | `--env=GTK_IM_MODULE=fcitx5 --input-method=keep` |
| **xterm font tiny in xpra** | no default font config under fresh xpra X server | set `faceName`+`faceSize` in `~/.Xresources` (see "xterm Font, Size & Colors") |
| **Latin letters stretched as if spaced out** | CJK font set as xterm `faceName` | use Latin mono as `faceName`, CJK only via `faceNameDoublesize` |
| **xterm font/colors reset after xpra restart** | xpra doesn't auto-read `~/.Xresources` | add `--start="xrdb -merge $HOME/.Xresources"` before `--start=xterm` |
| Font too small (all GUI apps) | Default 96 DPI | `--dpi=144` on start |
| `XError: BadAtom` / `XIO fatal error` | X server corrupted | `xpra stop :N` → `rm -rf /tmp/xpra/N /tmp/.XN-lock /tmp/.X11-unix/XN` → restart on different display |
| Session dead but port still in use | Zombie xpra proc | `pkill -9 -f "xpra start :N"` → restart |
| PulseAudio errors in log | No real audio device (container) | Harmless, ignore or `--speaker=off` |
| `ss -ltn` shows nothing but port works | `ss` broken in this container env | Use `netstat -ltnp` or `/dev/tcp` to test |
| fcitx5 crashes with "All display connections gone" | X server crashed (fatal IO error 11) | See xpra-crash-guardian skill |

## Auto-Restart Guardian

Long-running X servers in containers can crash (Xvfb `fatal IO error 11`).
Install the guardian to auto-detect and restart:

```bash
curl -fsSL https://raw.githubusercontent.com/... -o /usr/local/bin/xpra-guardian.sh
chmod +x /usr/local/bin/xpra-guardian.sh
xpra-guardian.sh start   # runs in background, checks every 30s
```

The guardian script is at [/home/admin/tools/xpra-guardian.sh](../tools/xpra-guardian.sh).

## Reference

The full comprehensive guide at `/home/admin/tools/xpra-best-practices.md` covers SSL, auth, performance tuning, `--start` vs `--start-child`, desktop mode, shadow mode, clipboard, printing, audio, and more.
