#!/bin/bash
# Cursor wrapper for container/xpra environment
# 解决：AppRun 递归、无 FUSE、无沙箱、无 GPU、renderer crash
export DISPLAY="${DISPLAY:-:101}"
CURSOR_ROOT="/opt/cursor/squashfs-root"
export PATH="${CURSOR_ROOT}/usr/bin:${CURSOR_ROOT}/usr/sbin:${CURSOR_ROOT}/bin:${CURSOR_ROOT}/sbin:${PATH}"
export LD_LIBRARY_PATH="${CURSOR_ROOT}/usr/lib:${CURSOR_ROOT}/usr/lib32:${CURSOR_ROOT}/usr/lib64:${CURSOR_ROOT}/lib:${CURSOR_ROOT}/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}"
export XDG_DATA_DIRS="${CURSOR_ROOT}/usr/share:/usr/local/share:/usr/share:${XDG_DATA_DIRS}"
export GSETTINGS_SCHEMA_DIR="${CURSOR_ROOT}/usr/share/glib-2.0/schemas:${GSETTINGS_SCHEMA_DIR}"
# 默认浏览器
export BROWSER="/usr/bin/firefox"
export XDG_SESSION_DESKTOP="${XDG_SESSION_DESKTOP:-xpra}"
# 禁用共享内存（减少 renderer OOM 崩溃）
export ELECTRON_DISABLE_SHARED_MEMORY=1
exec "${CURSOR_ROOT}/usr/share/cursor/cursor" \
  --no-sandbox \
  --disable-gpu \
  --disable-dev-shm-usage \
  --use-gl=swiftshader \
  "$@"
