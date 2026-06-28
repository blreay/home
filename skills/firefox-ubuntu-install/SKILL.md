---
name: firefox-ubuntu-install
description: Use when installing Firefox browser on Ubuntu 24.04+ (Noble) in a container or headless environment where snap packages don't work. Also use when Firefox shows "requires the firefox snap to be installed" error, or when xdg-open/x-www-browser needs a working Firefox for OAuth login flows in Electron apps.
---

# Firefox Ubuntu Install (Container / Headless)

## Overview

**Ubuntu 24.04's default `firefox` package is a snap transition package — it does NOT install a working browser.**
This is by design in Ubuntu's packaging policy. In containers (no snapd) or headless servers,
the snap-based package is dead on arrival. The fix: Mozilla Team PPA, which provides a real deb package.

## The Problem

```bash
sudo apt install -y firefox   # seems to work...

which firefox                  # /usr/bin/firefox — looks fine!
firefox --version              # "requires the firefox snap to be installed"
```

The apt package `1:1snap1-0ubuntu5` is just a stub that delegates to snap. In containers:
- No snapd daemon
- Snaps require systemd + squashfs + apparmor (all missing/fragile in containers)
- Result: Firefox completely unusable despite "successful" apt install

## The Fix: Mozilla Team PPA

### Step 1: Add Mozilla Team PPA

```bash
# Add the PPA repo
sudo add-apt-repository -y ppa:mozillateam/ppa

# Or manual method (if add-apt-repository not available):
sudo tee /etc/apt/sources.list.d/mozillateam-ubuntu-ppa-noble.sources <<'EOF'
Types: deb
URIs: https://ppa.launchpadcontent.net/mozillateam/ppa/ubuntu/
Suites: noble
Components: main
Signed-By: /usr/share/keyrings/mozillateam-archive-keyring.gpg
EOF

# Get the signing key
sudo curl -fsSL https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x9BDB4DBF4F8C5F38E1BD8A3BBAFD4816A6E21867 \
  | sudo gpg --dearmor -o /usr/share/keyrings/mozillateam-archive-keyring.gpg
```

### Step 2: Pin the PPA (force use of Mozilla's real deb over Ubuntu's snap stub)

```bash
sudo tee /etc/apt/preferences.d/mozillateam-firefox <<'EOF'
Package: firefox*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001

# Block the snap transition package
Package: firefox*
Pin: release o=Ubuntu
Pin-Priority: -1
EOF
```

This ensures:
1. Mozilla's Firefox from the PPA gets priority 1001 (always preferred)
2. Ubuntu's snap stub gets priority -1 (never installed)

### Step 3: Install

```bash
sudo apt update
sudo apt install -y firefox
```

Verify:
```bash
firefox --version          # "Mozilla Firefox 151.0.2" (not a snap error)
dpkg -l firefox | tail -1  # Version should contain "~mt1" (Mozilla Team build)
apt-cache policy firefox   # Should show PPA version installed
```

## Setup as Default Browser (for xdg-open / Electron OAuth)

```bash
# Install xdg-utils if not present
sudo apt install -y xdg-utils

# Set Firefox as default for the current DISPLAY
DISPLAY=:100 xdg-settings set default-web-browser firefox.desktop
DISPLAY=:100 xdg-mime default firefox.desktop x-scheme-handler/http
DISPLAY=:100 xdg-mime default firefox.desktop x-scheme-handler/https

# Verify
DISPLAY=:100 xdg-settings get default-web-browser    # → firefox.desktop
DISPLAY=:100 xdg-mime query default x-scheme-handler/https  # → firefox.desktop

# Environment variable (Electron apps read this)
export BROWSER="/usr/bin/firefox"
```

## One-Liner Install

```bash
sudo add-apt-repository -y ppa:mozillateam/ppa \
  && printf 'Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n\nPackage: firefox*\nPin: release o=Ubuntu\nPin-Priority: -1\n' \
     | sudo tee /etc/apt/preferences.d/mozillateam-firefox \
  && sudo apt update && sudo apt install -y firefox xdg-utils
```

## Verification Checklist

```bash
# 1. Firefox binary is real (not snap stub)
file $(which firefox)               # → symlink to ../lib/firefox/firefox.sh

# 2. Actually launches (in X session)
DISPLAY=:100 firefox --version      # → "Mozilla Firefox 151.0.2"

# 3. Package confirms PPA source
apt-cache policy firefox | grep 'LP-PPA-mozillateam'

# 4. Default browser set
DISPLAY=:100 xdg-settings get default-web-browser  # → firefox.desktop

# 5. xdg-open works
DISPLAY=:100 xdg-open https://example.com &
# Should see Firefox launch in xpra session
```

## Common Mistakes

| Mistake | Result | Prevention |
|---|---|---|
| `apt install firefox` without PPA | Snap stub installed, "requires snap" error | Always add PPA first |
| PPA added but no pinning | Ubuntu's snap stub still preferred (same package name) | Add `/etc/apt/preferences.d/mozillateam-firefox` |
| No `xdg-utils` installed | `xdg-settings: command not found` | `apt install xdg-utils` |
| `xdg-settings` without DISPLAY | Writes to wrong session config | Always set `DISPLAY=:100` |
| No `BROWSER` env var | Electron apps (Cursor) show download dialog instead of opening URL | `export BROWSER=/usr/bin/firefox` |

## Uninstall

```bash
sudo apt remove -y firefox
sudo rm /etc/apt/sources.list.d/mozillateam-ubuntu-ppa-noble.sources
sudo rm /etc/apt/preferences.d/mozillateam-firefox
sudo apt update
```

## Reference Notes

- Mozilla Team PPA: https://launchpad.net/~mozillateam/+archive/ubuntu/ppa
- Ubuntu's snap transition policy: https://discourse.ubuntu.com/t/ubuntu-desktop-24-04-lts-release-notes
- For other Ubuntu versions: replace `noble` with `jammy` (22.04) / `focal` (20.04)
