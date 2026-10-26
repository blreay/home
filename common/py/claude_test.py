#!/usr/bin/env python3
"""claude-failfast: api 重试达到 N 次后终止进程"""
import json, os, signal, subprocess, sys

MAX_RETRY = 5
proc = subprocess.Popen(["claude"] + sys.argv[1:],
                        stdout=subprocess.PIPE, text=True,
                        start_new_session=True)  # 独立进程组,便于杀干净
for line in proc.stdout:
    sys.stdout.write(line); sys.stdout.flush()
    try:
        e = json.loads(line)
    except ValueError:
        continue
    if (e.get("type") == "system" and e.get("subtype") == "api_retry"
            and e.get("attempt", 0) >= MAX_RETRY):
        os.killpg(proc.pid, signal.SIGKILL)
        print(f"[wrapper] 重试达 {MAX_RETRY} 次,放弃", file=sys.stderr)
        sys.exit(124)
sys.exit(proc.wait())
