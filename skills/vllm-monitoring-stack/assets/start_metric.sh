#!/usr/bin/env bash
# 启动 LLM 监控容器栈（原 docker compose 项目 /data/ai/llm-monitor 的等价 docker run 命令）
# 容器: llm-prometheus / llm-grafana / llm-dcgm-exporter / llm-nvidia-smi-exporter
# 用法: bash start_metric.sh  （幂等：先清理同名旧容器，数据卷保留）
set -euo pipefail

MON_DIR="${MON_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/llm-monitor" && pwd)}"
NET=llm-monitor_default

# 1) 确保 compose 的默认网络存在
docker network inspect "$NET" >/dev/null 2>&1 || docker network create "$NET"

# 2) 清理同名旧容器（只删容器，保留 llm-monitor_* 数据卷）
for c in llm-prometheus llm-grafana llm-dcgm-exporter llm-nvidia-smi-exporter llm-comfyui-exporter llm-llama-slots-exporter; do
  docker rm -f "$c" >/dev/null 2>&1 || true
done

# 3) 按依赖顺序启动: prometheus -> grafana -> dcgm-exporter -> nvidia-smi-exporter

# ---- Prometheus (metrics 存储, 保留 15 天) ----
docker run -d \
  --name llm-prometheus \
  --restart unless-stopped \
  --network "$NET" \
  --network-alias prometheus \
  --add-host host.docker.internal:host-gateway \
  -p 9090:9090 \
  -v "$MON_DIR/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro" \
  -v llm-monitor_prometheus-data:/prometheus \
  prom/prometheus:latest \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.retention.time=15d

# ---- Grafana (仪表盘, 宿主机端口 3001) ----
docker run -d \
  --name llm-grafana \
  --restart unless-stopped \
  --network "$NET" \
  --network-alias grafana \
  -p 3001:3000 \
  -e GF_SECURITY_ADMIN_USER=admin \
  -e GF_SECURITY_ADMIN_PASSWORD=qwenmon2026 \
  -v "$MON_DIR/grafana/provisioning:/etc/grafana/provisioning:ro" \
  -v "$MON_DIR/grafana/dashboards:/var/lib/grafana/dashboards:ro" \
  -v llm-monitor_grafana-data:/var/lib/grafana \
  grafana/grafana:11.1.0

# ---- DCGM Exporter (NVIDIA GPU 指标, 端口 9400) ----
docker run -d \
  --name llm-dcgm-exporter \
  --restart unless-stopped \
  --network "$NET" \
  --network-alias dcgm-exporter \
  --gpus all \
  --pid host \
  --cap-add SYS_ADMIN \
  -p 9400:9400 \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  nvcr.io/nvidia/k8s/dcgm-exporter:4.6.0-4.8.3-distroless

# ---- nvidia-smi Exporter (补充 GPU 指标, 端口 9835, 本地构建镜像) ----
docker run -d \
  --name llm-nvidia-smi-exporter \
  --restart unless-stopped \
  --network "$NET" \
  --network-alias nvidia-gpu-exporter \
  --gpus all \
  --pid host \
  -e NVIDIA_DRIVER_CAPABILITIES=utility \
  -p 9835:9835 \
  llm-nvidia-smi-exporter:1.0

# ---- ComfyUI Exporter (应用层指标: 队列/VRAM/完成数, 端口 9464) ----
docker build -q -t comfyui-exporter:1.0 "$MON_DIR/comfyui-exporter" >/dev/null
docker run -d   --name llm-comfyui-exporter   --restart unless-stopped   --network "$NET"   --network-alias comfyui-exporter   --add-host host.docker.internal:host-gateway   -p 9464:9464   -e COMFYUI_URL=http://host.docker.internal:18188   comfyui-exporter:1.0

# ---- Llama Slots Exporter (每槽位上下文/缓存指标, 端口 9465) ----
docker build -q -t llama-slots-exporter:1.0 "$MON_DIR/llama-slots-exporter" >/dev/null
docker run -d \
  --name llm-llama-slots-exporter \
  --restart unless-stopped \
  --network "$NET" \
  --network-alias llama-slots-exporter \
  --add-host host.docker.internal:host-gateway \
  -p 9465:9465 \
  -e LLAMA_URL=http://host.docker.internal:8000 \
  llama-slots-exporter:1.0

# 4) 结果
docker ps --filter name=llm- --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
