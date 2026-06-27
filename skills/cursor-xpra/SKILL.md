---
name: cursor-xpra
description: Use when installing Cursor IDE on a headless Linux server/container and accessing it through xpra remote display. Covers download, extract (no FUSE), wrapper script (avoid AppRun recursion), /dev/shm crash fix, default browser config, fcitx5 Chinese input, and crash auto-restart guardian. Use on a fresh dev machine to set up Cursor remote access from scratch.
---

# Cursor on Headless Linux via Xpra

## Overview

One-shot guide to install Cursor IDE on a headless Linux server/container and access it
remotely through xpra (browser or native client). Covers every pitfall discovered: FUSE,
AppRun recursion, `/dev/shm` renderer crashes, default browser, Chinese input, and auto-restart.

**Prerequisites:** xpra already installed (see xpra-install skill). Ubuntu 24.04+ x86_64.

## Step 1: Install Cursor

### Download

Official download domain `downloader.cursor.sh` may fail DNS (NXDOMAIN) on private networks.
Use the CDN directly:

```bash
curl -fSL -o /tmp/cursor-latest.AppImage \
  "https://api2.cursor.sh/updates/download/golden/linux-x64/cursor/latest"
```

### Extract (Container / No FUSE)

Containers lack `/dev/fuse`. Must use `--appimage-extract`:

```bash
sudo mkdir -p /opt/cursor
sudo mv /tmp/cursor-latest.AppImage /opt/cursor/cursor.AppImage
sudo chmod +x /opt/cursor/cursor.AppImage
cd /opt/cursor && sudo ./cursor.AppImage --appimage-extract
# Creates squashfs-root/ directory
```

### Create Wrapper Script

**CRITICAL: Do NOT symlink to AppRun.** AppRun internally parses `.desktop` → `Exec=cursor`
→ re-invokes `/usr/local/bin/cursor` → infinite recursion. See Step 2 pitfall table.

Write `/usr/local/bin/cursor` (below). This is the real working version — copy verbatim:

```bash
sudo tee /usr/local/bin/cursor > /dev/null <<'WRAPPER'
#!/bin/bash
# Cursor wrapper — directly calls binary, avoids AppRun recursion
# Solves: no FUSE, no sandbox, no GPU, /dev/shm crash, default browser
export DISPLAY="${DISPLAY:-:100}"
CURSOR_ROOT="/opt/cursor/squashfs-root"
if [ ! -x "${CURSOR_ROOT}/usr/share/cursor/cursor" ]; then
  echo "Error: Cursor binary not found. Run: cd /opt/cursor && sudo ./cursor.AppImage --appimage-extract" >&2
  exit 1
fi
# Environment from AppRun
export PATH="${CURSOR_ROOT}/usr/bin:${CURSOR_ROOT}/usr/sbin:${CURSOR_ROOT}/bin:${CURSOR_ROOT}/sbin:${PATH}"
export LD_LIBRARY_PATH="${CURSOR_ROOT}/usr/lib:${CURSOR_ROOT}/usr/lib32:${CURSOR_ROOT}/usr/lib64:${CURSOR_ROOT}/lib:${CURSOR_ROOT}/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}"
export XDG_DATA_DIRS="${CURSOR_ROOT}/usr/share:/usr/local/share:/usr/share:${XDG_DATA_DIRS}"
export GSETTINGS_SCHEMA_DIR="${CURSOR_ROOT}/usr/share/glib-2.0/schemas:${GSETTINGS_SCHEMA_DIR}"
# Default browser for OAuth login flow
export BROWSER="${BROWSER:-/usr/bin/firefox}"
# Reduce shared memory usage
export ELECTRON_DISABLE_SHARED_MEMORY=1
exec "${CURSOR_ROOT}/usr/share/cursor/cursor" \
  --no-sandbox \                # container no namespace
  --disable-gpu \               # no GPU in container
  --disable-dev-shm-usage \     # KEY: use /tmp instead of 64MB /dev/shm
  --use-gl=swiftshader \        # software rendering (no GPU)
  "$@"
# ⚠️ Do NOT add --disable-software-rasterizer — it kills fcitx5 candidate window rendering
WRAPPER
sudo chmod +x /usr/local/bin/cursor
```

Also create desktop entry:

```bash
sudo tee /usr/share/applications/cursor.desktop > /dev/null <<'DESKTOP'
[Desktop Entry]
Name=Cursor
Comment=AI Code Editor
Exec=/opt/cursor/squashfs-root/AppRun --no-sandbox %F
Icon=/opt/cursor/squashfs-root/co.anysphere.cursor.png
Type=Application
Categories=Development;IDE;
StartupNotify=true
StartupWMClass=Cursor
DESKTOP
```

### Dependencies

```bash
sudo apt install -y libfuse2t64 xdg-utils firefox
```

Set Firefox as default browser for OAuth login:

```bash
DISPLAY=:100 xdg-settings set default-web-browser firefox.desktop
DISPLAY=:100 xdg-mime default firefox.desktop x-scheme-handler/http
DISPLAY=:100 xdg-mime default firefox.desktop x-scheme-handler/https
# Verify
DISPLAY=:100 xdg-settings get default-web-browser   # firefox.desktop
```

## Step 2: Startup Pitfalls & Fixes

**Every one of these was encountered and debugged. Check the symptom → apply the fix.**

| Symptom | Cause | Fix |
|---|---|---|
| `dlopen(): error loading libfuse.so.2` | Missing libfuse2 | `sudo apt install -y libfuse2t64` |
| `fuse: device not found` | Container no FUSE device | `--appimage-extract` (Step 1) |
| `Failed to move to new namespace: Operation not permitted` | Container no namespace | `--no-sandbox` (in wrapper) |
| **Process explosion: hundreds of `--no-sandbox` repeating** | AppRun recursion (`cursor → AppRun → exec cursor → ...`) | Wrapper calls binary directly, NOT AppRun |
| `Missing X server or $DISPLAY` | No DISPLAY set | `export DISPLAY=:100` (in wrapper) |
| `Failed to connect to the bus` (DBus errors) | No systemd dbus in container | **Harmless, ignore** |
| `Exiting GPU process during init` | No GPU in container | `--disable-gpu` (in wrapper) |
| **Window randomly closes, `renderer process gone (reason: crashed, code: 133)`** | Container `/dev/shm` only 64MB, Chromium needs 200-500MB | `--disable-dev-shm-usage` (in wrapper) or `mount -o remount,size=4G /dev/shm` |
| Click Login opens transfer/download dialog instead of Firefox | No default browser configured | Step 1 "Dependencies": `xdg-settings` + `export BROWSER` in wrapper |
| Chinese input dead in Cursor after adding `--disable-software-rasterizer` | That flag kills fcitx5 candidate window rendering | Remove it — wrapper above does NOT include it |
| Chinese input dead with `--input-method=fcitx5` in xpra | xpra sets `GTK_IM_MODULE=xim` | xpra must use `--env=GTK_IM_MODULE=fcitx5 --input-method=keep` |

### The /dev/shm Crash (Most Critical Container Bug)

**How it works:** Chromium renderer processes communicate via shared memory (`/dev/shm`).
Container default is 64MB. One Cursor window needs 200-500MB. `shmget()` fails → SIGSEGV → exit code 133.

```bash
# Verify
df -h /dev/shm   # 64M → problem

# Fix A (in wrapper above, no root needed): --disable-dev-shm-usage → use /tmp instead
# Fix B (needs root): sudo mount -o remount,size=4G /dev/shm
```

**Warning sign:** Multiple `renderer process gone (reason: crashed, code: 133)` lines in log.
Check: `grep "renderer process gone" ~/.config/Cursor/logs/*/main.log`

## Step 3: Launch with Xpra

All-in-one xpra launch command with Chinese input:

```bash
xpra start :100 \
  --bind-tcp=0.0.0.0:6001 \
  --start=xterm \
  --start="fcitx5 -d --replace" \
  --start=cursor \
  --env=GTK_IM_MODULE=fcitx5 \
  --env=QT_IM_MODULE=fcitx5 \
  --env=XMODIFIERS=@im=fcitx \
  --daemon=yes --tcp-auth=none --html=on \
  --dpi=96 \
  --input-method=keep
```

Connect:
- Browser: `http://<host>:6001/`
- Native client: `xpra attach tcp://<host>:6001/`

Toggle Chinese: `Ctrl+Space` (in xpra HTML5 client, enable ⚙️ → Grab keyboard).

Manual control:
```bash
xpra list                    # check sessions
xpra stop :100               # stop session
xpra control :100 start cursor  # re-launch cursor in existing session
```

## Step 4: Auto-Restart Guardian

Xvfb (X server) can crash after hours of use (`xterm: fatal IO error 11` →
`X connection error received`), taking down cursor + fcitx5 + xpra.

Create guardian script at `/usr/local/bin/xpra-guardian.sh`:

```bash
sudo tee /usr/local/bin/xpra-guardian.sh > /dev/null <<'GUARDIAN'
#!/bin/bash
set -o pipefail
DISPLAY_NUM=100; PORT=6001; DPI=96; CHECK_INTERVAL=30; STARTUP_GRACE=20
LOG_FILE="/usr/local/var/xpra-guardian.log"; PID_FILE="/usr/local/var/.xpra-guardian.pid"
mkdir -p "$(dirname "$LOG_FILE")"

log() { echo "$(date +'%Y-%m-%d %H:%M:%S') [guardian] $1"; }

start_session() {
    log "Starting xpra session on :${DISPLAY_NUM}..."
    /usr/bin/xpra start ":${DISPLAY_NUM}" \
        --bind-tcp="0.0.0.0:${PORT}" --start=xterm \
        --start="fcitx5 -d --replace" --start=cursor \
        --env=GTK_IM_MODULE=fcitx5 --env=QT_IM_MODULE=fcitx5 \
        --env=XMODIFIERS=@im=fcitx --daemon=yes --tcp-auth=none --html=on \
        --dpi="${DPI}" --input-method=keep >> "${LOG_FILE}" 2>&1
}

cleanup_stale() {
    log "Cleaning stale state..."
    pkill -9 -f "pulseaudio.*display=:${DISPLAY_NUM}" 2>/dev/null
    pkill -9 -f "fcitx5" 2>/dev/null
    /usr/bin/xpra list >/dev/null 2>&1
    rm -f /tmp/.X${DISPLAY_NUM}-lock /tmp/.X11-unix/X${DISPLAY_NUM} 2>/dev/null
    rm -rf /tmp/xpra/${DISPLAY_NUM} 2>/dev/null
    sleep 1
}

is_healthy() {
    timeout 3 bash -c "echo > /dev/tcp/127.0.0.1/${PORT}" 2>/dev/null || { log "UNHEALTHY: port not connectable"; return 1; }
    pgrep -f "xpra start :${DISPLAY_NUM}" >/dev/null 2>&1 || { log "UNHEALTHY: xpra main process not found"; return 1; }
    return 0
}

restart_session() {
    log "===== Restarting session ====="
    /usr/bin/xpra stop ":${DISPLAY_NUM}" >/dev/null 2>&1
    sleep 2
    pkill -9 -f "xpra start :${DISPLAY_NUM}" 2>/dev/null
    sleep 1
    cleanup_stale
    start_session
    sleep "${STARTUP_GRACE}"
    is_healthy && log "===== Session restarted =====" || log "===== Restart FAILED, retrying next cycle ====="
}

# Commands
case "${1:-}" in
    start)
        if [[ -f "${PID_FILE}" ]]; then
            old_pid=$(cat "${PID_FILE}")
            if kill -0 "${old_pid}" 2>/dev/null && ps -p "${old_pid}" -o args= 2>/dev/null | grep -q "xpra-guardian.sh foreground"; then
                echo "Guardian already running (pid=${old_pid})."; exit 1
            fi
        fi
        echo "Starting guardian in background..."
        nohup "$0" foreground >> "${LOG_FILE}" 2>&1 &
        echo $! > "${PID_FILE}"
        echo "Guardian started (pid=$!). Log: ${LOG_FILE}"
        ;;
    stop)
        if [[ -f "${PID_FILE}" ]]; then
            kill $(cat "${PID_FILE}") 2>/dev/null; sleep 1
            kill -9 $(cat "${PID_FILE}") 2>/dev/null
            rm -f "${PID_FILE}"
        fi
        echo "Guardian stopped."
        ;;
    status)
        [[ -f "${PID_FILE}" ]] && kill -0 $(cat "${PID_FILE}") 2>/dev/null && echo "Guardian: RUNNING" || echo "Guardian: NOT RUNNING"
        timeout 3 bash -c "echo > /dev/tcp/127.0.0.1/${PORT}" 2>/dev/null && echo "Session: HEALTHY" || echo "Session: DOWN"
        ;;
    check) is_healthy && echo "HEALTHY" || echo "UNHEALTHY" ;;
    restart-session) restart_session ;;
    foreground)   # internal: main loop
        log "########## Guardian started (display=:${DISPLAY_NUM}, port=${PORT}, interval=${CHECK_INTERVAL}s) ##########"
        is_healthy || restart_session
        while true; do
            sleep "${CHECK_INTERVAL}"
            is_healthy || { log "Health check FAILED, restarting..."; restart_session; }
        done
        ;;
    *) echo "Usage: $0 {start|stop|status|check|restart-session}"; exit 1 ;;
esac
GUARDIAN
sudo chmod +x /usr/local/bin/xpra-guardian.sh
```

```bash
# Start guardian (survives terminal close)
xpra-guardian.sh start
# Check health
xpra-guardian.sh status
# Auto-start on login: add to ~/.bashrc
echo '/usr/local/bin/xpra-guardian.sh start >/dev/null 2>&1 || true' >> ~/.bashrc
```

**Recovery time:** ~55 seconds from crash to full recovery. Logs at `/usr/local/var/xpra-guardian.log`.

## Step 5: Verify Everything

```bash
# 1. Cursor binary works
cursor --version

# 2. Xpra session alive
xpra list | grep "LIVE session"

# 3. Port listening
netstat -ltnp | grep 6001

# 4. Fcitx5 running
ps -ef | grep fcitx5 | grep -v grep

# 5. Cursor has correct IM env vars
PID=$(pgrep -f "cursor --no-sandbox" | head -1)
cat /proc/$PID/environ | tr '\0' '\n' | grep IM_MODULE
# Expect: GTK_IM_MODULE=fcitx5

# 6. Default browser set
xdg-settings get default-web-browser  # firefox.desktop

# 7. Guardian running
xpra-guardian.sh status

# 8. Browser access
echo "Open http://$(hostname -I | awk '{print $1}'):6001/"
```

## Troubleshooting Checklist

| Check | Command |
|---|---|
| Cursor installed? | `which cursor && cursor --version` |
| Xpra session alive? | `xpra list` |
| Port binding? | `netstat -ltnp \| grep 6001` |
| `/dev/shm` size? | `df -h /dev/shm` (must be >64M or using `--disable-dev-shm-usage`) |
| IM env vars in cursor? | `cat /proc/$(pgrep cursor \| head -1)/environ \| tr '\0' '\n' \| grep IM_MODULE` |
| Cursor crash log? | `grep "renderer process gone" ~/.config/Cursor/logs/*/main.log` |
| Xpra server log? | `tail -f /tmp/xpra/100/server.log` |
| Fcitx5 running? | `ps -ef \| grep fcitx5` |
| Fcitx5 diagnostics? | `DISPLAY=:100 fcitx5-diagnose 2>&1 \| less` |

## Reference

Full guides with additional detail:
- Xpra: `/home/admin/tools/xpra-best-practices.md` (SSL, auth, perf, desktop/shadow modes)
- Cursor: `/home/admin/tools/cursor-linux-install-guide.md` (all 9 crash scenarios, detailed `/dev/shm` analysis)
