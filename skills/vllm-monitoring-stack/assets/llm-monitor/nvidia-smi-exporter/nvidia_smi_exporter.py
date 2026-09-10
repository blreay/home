#!/usr/bin/env python3
"""Lightweight nvidia-smi Prometheus exporter (stdlib only).

Runs nvidia-smi on each scrape and exposes GPU + per-process metrics.
"""
import csv
import io
import os
import re
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.environ.get("PORT", "9835"))

EVENT_REASONS = [
    "gpu_idle",
    "sw_power_cap",
    "hw_power_brake_slowdown",
    "hw_thermal_slowdown",
    "sw_thermal_slowdown",
    "sync_boost",
    "applications_clocks_setting",
]

GPU_FIELDS = [
    "index", "name", "uuid", "driver_version",
    "utilization.gpu", "utilization.memory",
    "memory.total", "memory.used", "memory.free",
    "temperature.gpu", "temperature.memory",
    "power.draw", "power.limit", "power.default_limit",
    "clocks.current.sm", "clocks.current.memory", "clocks.max.sm",
    "fan.speed", "pstate",
] + ["clocks_event_reasons." + r for r in EVENT_REASONS] + [
    "ecc.mode.current",
    "ecc.errors.corrected.volatile.total",
    "ecc.errors.uncorrected.volatile.total",
]


def fnum(value):
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def run_nvidia_smi(fields, query="gpu"):
    cmd = ["nvidia-smi", "--format=csv,noheader,nounits",
           "--query-" + query + "=" + ",".join(fields)]
    out = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
    if out.returncode != 0:
        raise RuntimeError(out.stderr.strip() or "nvidia-smi failed")
    return [[cell.strip() for cell in row] for row in csv.reader(io.StringIO(out.stdout)) if row]


def collect():
    lines = []
    gpus = run_nvidia_smi(GPU_FIELDS)
    for row in gpus:
        data = dict(zip(GPU_FIELDS, row))
        idx = data["index"]
        labels = f'gpu="{idx}", name="{data["name"]}", uuid="{data["uuid"]}"'

        def emit(metric, help_text, value, mtype="gauge"):
            v = fnum(value)
            if v is None:
                return
            lines.append(f"# HELP {metric} {help_text}")
            lines.append(f"# TYPE {metric} {mtype}")
            lines.append(f"{metric}{{{labels}}} {v}")

        emit("nvidia_smi_gpu_info", "GPU info (1 if present).", 1)
        emit("nvidia_smi_gpu_utilization", "GPU utilization, percent.", data["utilization.gpu"])
        emit("nvidia_smi_gpu_memory_utilization", "GPU memory utilization, percent.", data["utilization.memory"])
        used = fnum(data["memory.used"])
        total = fnum(data["memory.total"])
        free = fnum(data["memory.free"])
        if used is not None:
            emit("nvidia_smi_gpu_memory_used_bytes", "GPU memory used, bytes.", used * 1048576)
        if total is not None:
            emit("nvidia_smi_gpu_memory_total_bytes", "GPU memory total, bytes.", total * 1048576)
        if free is not None:
            emit("nvidia_smi_gpu_memory_free_bytes", "GPU memory free, bytes.", free * 1048576)
        emit("nvidia_smi_gpu_temperature_celsius", "GPU temperature, celsius.", data["temperature.gpu"])
        emit("nvidia_smi_gpu_memory_temperature_celsius", "GPU memory temperature, celsius.", data["temperature.memory"])
        emit("nvidia_smi_gpu_power_watts", "GPU power draw, watts.", data["power.draw"])
        emit("nvidia_smi_gpu_power_limit_watts", "GPU power limit, watts.", data["power.limit"])
        emit("nvidia_smi_gpu_power_default_limit_watts", "GPU default power limit, watts.", data["power.default_limit"])
        emit("nvidia_smi_gpu_sm_clock_mhz", "SM clock, MHz.", data["clocks.current.sm"])
        emit("nvidia_smi_gpu_mem_clock_mhz", "Memory clock, MHz.", data["clocks.current.memory"])
        emit("nvidia_smi_gpu_max_sm_clock_mhz", "Max SM clock, MHz.", data["clocks.max.sm"])
        emit("nvidia_smi_gpu_fan_speed_percent", "Fan speed, percent.", data["fan.speed"])
        m = re.fullmatch(r"P(\d+)", data["pstate"].strip())
        if m:
            emit("nvidia_smi_gpu_pstate", "Current performance state (0 is highest).", int(m.group(1)))

        for reason in EVENT_REASONS:
            lines.append(f"# HELP nvidia_smi_gpu_throttled_{reason} GPU clocks throttled due to {reason} (1/0).")
            lines.append(f"# TYPE nvidia_smi_gpu_throttled_{reason} gauge")
            lines.append(f"nvidia_smi_gpu_throttled_{reason}{{{labels}}} {1 if (data.get('clocks_event_reasons.' + reason) or '0').strip() in ('1', 'True', 'true') else 0}")

        if data["ecc.mode.current"].strip().lower() == "enabled":
            emit("nvidia_smi_gpu_ecc_corrected_volatile_total", "ECC corrected volatile errors, total.", data["ecc.errors.corrected.volatile.total"], mtype="counter")
            emit("nvidia_smi_gpu_ecc_uncorrected_volatile_total", "ECC uncorrected volatile errors, total.", data["ecc.errors.uncorrected.volatile.total"], mtype="counter")

    apps = run_nvidia_smi(["pid", "process_name", "used_memory", "gpu_uuid"], query="compute-apps")
    if apps:
        lines.append("# HELP nvidia_smi_process_memory_used_bytes GPU memory used by process, bytes.")
        lines.append("# TYPE nvidia_smi_process_memory_used_bytes gauge")
        for row in apps:
            if len(row) < 4:
                continue
            pid, name, mem, uuid = row[0], row[1], row[2], row[3]
            v = fnum(mem)
            if v is None:
                continue
            safe_name = name.replace('"', "'")
            lines.append(f'nvidia_smi_process_memory_used_bytes{{gpu_uuid="{uuid}", pid="{pid}", process_name="{safe_name}"}} {v * 1048576}')

    lines.append("# HELP nvidia_smi_up 1 if nvidia-smi query succeeded.")
    lines.append("# TYPE nvidia_smi_up gauge")
    lines.append("nvidia_smi_up 1")
    return "\n".join(lines) + "\n"


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/metrics":
            try:
                body = collect().encode()
                code = 200
            except Exception as exc:
                body = f"# nvidia-smi exporter error: {exc}\n".encode()
                code = 500
            self.send_response(code)
            self.send_header("Content-Type", "text/plain; version=0.0.4")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        elif self.path == "/health":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok")
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, fmt, *args):
        pass


if __name__ == "__main__":
    print(f"nvidia-smi exporter listening on :{PORT}")
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
