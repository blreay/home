#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
comfyui_exporter.py — ComfyUI 应用层指标的 Prometheus exporter (仅标准库)

抓取 ComfyUI 内置 JSON API 并转为 Prometheus 指标:
  /system_stats  -> 在线状态/版本/系统内存/各设备 VRAM
  /queue         -> 正在执行/排队中的任务数
  /history       -> 累计完成任务数(计数)、最近一次执行耗时

环境变量:
  COMFYUI_URL    ComfyUI 地址 (默认 http://localhost:18188)
  EXPORTER_PORT  本 exporter 监听端口 (默认 9464)

注意: comfyui_prompts_completed_total 在 exporter 重启后从零重新计数
(启动时以当时已有历史为基线), rate() 可自动处理计数器重置。
"""
import json
import os
import threading
import time
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

COMFY = os.environ.get("COMFYUI_URL", "http://localhost:18188").rstrip("/")
PORT = int(os.environ.get("EXPORTER_PORT", "9464"))

HISTORY_ITEMS = 10          # 每次拉取的历史条数
HISTORY_INTERVAL = 30       # 历史轮询间隔(秒), 避免频繁拉大对象

_lock = threading.Lock()
_seen_ids = set()
_completed_total = 0
_last_exec_ms = 0
_history_cache = (0.0, [])  # (ts, lines)


def _get(path, timeout=5):
    try:
        with urllib.request.urlopen(COMFY + path, timeout=timeout) as r:
            return json.loads(r.read().decode("utf-8", "ignore"))
    except Exception:
        return None


def _history_lines():
    """带缓存的历史采集: 完成计数 + 最近执行耗时。"""
    global _completed_total, _last_exec_ms, _history_cache
    now = time.time()
    with _lock:
        ts, cached = _history_cache
        if now - ts < HISTORY_INTERVAL:
            return cached
    h = _get("/history?max_items=%d" % HISTORY_ITEMS, timeout=10)
    lines = []
    if isinstance(h, dict) and h:
        with _lock:
            first_run = not _seen_ids
            newest_ms = 0
            for pid, item in h.items():
                st = item.get("status") or {}
                if not st.get("completed"):
                    continue
                stamps = []
                for m in st.get("messages") or []:
                    if isinstance(m, list) and len(m) >= 2 and isinstance(m[1], dict):
                        t = m[1].get("timestamp")
                        if isinstance(t, (int, float)) and t > 0:
                            stamps.append(t)
                if pid not in _seen_ids:
                    _seen_ids.add(pid)
                    if not first_run:
                        _completed_total += 1
                if stamps:
                    newest_ms = max(newest_ms, max(stamps) - min(stamps))
            if len(_seen_ids) > 4096:
                _seen_ids = set(list(_seen_ids)[-2048:])
            if newest_ms and _last_exec_ms == 0:
                _last_exec_ms = newest_ms  # 启动基线
            elif newest_ms:
                _last_exec_ms = newest_ms
            lines.append("comfyui_prompts_completed_total %d" % _completed_total)
            if _last_exec_ms:
                lines.append("comfyui_last_execution_ms %d" % int(_last_exec_ms))
            _history_cache = (now, lines)
        return lines
    with _lock:
        _history_cache = (now, [])
    return []


def collect():
    out = []
    ss = _get("/system_stats")
    up = 1 if isinstance(ss, dict) else 0
    out.append("# HELP comfyui_up ComfyUI reachable (1/0)")
    out.append("# TYPE comfyui_up gauge")
    out.append("comfyui_up %d" % up)
    if up:
        sysm = ss.get("system") or {}
        ver = str(sysm.get("comfyui_version") or "unknown")
        out.append("# TYPE comfyui_info gauge")
        out.append('comfyui_info{version="%s"} 1' % ver)
        out.append("# TYPE comfyui_system_ram_total_bytes gauge")
        out.append("comfyui_system_ram_total_bytes %d" % int(sysm.get("ram_total") or 0))
        out.append("# TYPE comfyui_system_ram_free_bytes gauge")
        out.append("comfyui_system_ram_free_bytes %d" % int(sysm.get("ram_free") or 0))
        devs = ss.get("devices") or []
        out.append("# TYPE comfyui_vram_total_bytes gauge")
        out.append("# TYPE comfyui_vram_free_bytes gauge")
        out.append("# TYPE comfyui_torch_vram_total_bytes gauge")
        out.append("# TYPE comfyui_torch_vram_free_bytes gauge")
        for i, d in enumerate(devs):
            name = str(d.get("name") or ("cuda:%d" % i)).replace('"', "'")
            lbl = '{device="%d",name="%s"}' % (d.get("index", i), name)
            out.append("comfyui_vram_total_bytes%s %d" % (lbl, int(d.get("vram_total") or 0)))
            out.append("comfyui_vram_free_bytes%s %d" % (lbl, int(d.get("vram_free") or 0)))
            out.append("comfyui_torch_vram_total_bytes%s %d" % (lbl, int(d.get("torch_vram_total") or 0)))
            out.append("comfyui_torch_vram_free_bytes%s %d" % (lbl, int(d.get("torch_vram_free") or 0)))
    q = _get("/queue")
    if isinstance(q, dict):
        out.append("# TYPE comfyui_queue_running gauge")
        out.append("comfyui_queue_running %d" % len(q.get("queue_running") or []))
        out.append("# TYPE comfyui_queue_pending gauge")
        out.append("comfyui_queue_pending %d" % len(q.get("queue_pending") or []))
    try:
        out.extend(_history_lines())
    except Exception:
        pass
    return "\n".join(out) + "\n"


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.split("?")[0] in ("/metrics", "/"):
            t0 = time.time()
            body = collect().encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; version=0.0.4")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            if self.path.split("?")[0] == "/":
                pass
            _ = t0
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, fmt, *args):
        pass


if __name__ == "__main__":
    print("comfyui_exporter: %s -> :%d/metrics" % (COMFY, PORT), flush=True)
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
