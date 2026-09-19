#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
llama_slots_exporter.py — llama-server /slots → Prometheus (仅标准库)

暴露每个槽位的任务上下文指标:
  llamaslot_up                          llama-server /slots 是否可达
  llamaslot_n_ctx{slot}                 槽位上下文容量
  llamaslot_processing{slot}            槽位是否正在处理 (0/1)
  llamaslot_n_prompt_tokens{slot}       当前/最近任务的上下文大小 (prompt tokens)
  llamaslot_n_prompt_tokens_cache{slot} 其中命中前缀缓存的部分
  llamaslot_id_task{slot}               任务号 (空闲时可能为上次任务号/-1)

环境变量:
  LLAMA_URL      llama-server 地址 (默认 http://localhost:8000)
  EXPORTER_PORT  监听端口 (默认 9465)

注意: llama-server 未运行时 llamaslot_up=0, 其余序列消失(面板显示断线属正常)。
"""
import json
import os
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

LLAMA = os.environ.get("LLAMA_URL", "http://localhost:8000").rstrip("/")
PORT = int(os.environ.get("EXPORTER_PORT", "9465"))


def collect():
    out = []
    slots = None
    try:
        with urllib.request.urlopen(LLAMA + "/slots", timeout=5) as r:
            data = json.loads(r.read().decode("utf-8", "ignore"))
            if isinstance(data, list):
                slots = data
    except Exception:
        slots = None
    up = 1 if slots is not None else 0
    out.append("# HELP llamaslot_up llama-server /slots reachable (1/0)")
    out.append("# TYPE llamaslot_up gauge")
    out.append("llamaslot_up %d" % up)
    if up:
        out.append("# HELP llamaslot_n_ctx context capacity per slot (tokens)")
        out.append("# TYPE llamaslot_n_ctx gauge")
        out.append("# HELP llamaslot_processing slot busy (1/0)")
        out.append("# TYPE llamaslot_processing gauge")
        out.append("# HELP llamaslot_n_prompt_tokens context size of current/last task per slot")
        out.append("# TYPE llamaslot_n_prompt_tokens gauge")
        out.append("# HELP llamaslot_n_prompt_tokens_cache cached prompt tokens of current/last task per slot")
        out.append("# TYPE llamaslot_n_prompt_tokens_cache gauge")
        out.append("# TYPE llamaslot_id_task gauge")
        for s in slots:
            try:
                lbl = '{slot="%s"}' % s.get("id", 0)
                out.append("llamaslot_n_ctx%s %d" % (lbl, int(s.get("n_ctx") or 0)))
                out.append("llamaslot_processing%s %d" % (lbl, 1 if s.get("is_processing") else 0))
                out.append("llamaslot_n_prompt_tokens%s %d" % (lbl, int(s.get("n_prompt_tokens") or 0)))
                out.append("llamaslot_n_prompt_tokens_cache%s %d" % (lbl, int(s.get("n_prompt_tokens_cache") or 0)))
                out.append("llamaslot_id_task%s %d" % (lbl, int(s.get("id_task") if s.get("id_task") is not None else -1)))
            except Exception:
                continue
    return "\n".join(out) + "\n"


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.split("?")[0] in ("/metrics", "/"):
            body = collect().encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; version=0.0.4")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, fmt, *args):
        pass


if __name__ == "__main__":
    print("llama_slots_exporter: %s/slots -> :%d/metrics" % (LLAMA, PORT), flush=True)
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
