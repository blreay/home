---
name: vllm-monitoring-stack
description: Deploy a Prometheus + Grafana + DCGM + nvidia-smi monitoring stack (docker compose) for a locally deployed vLLM inference container, with ready-made vLLM/GPU dashboards and GPU/vLLM alert rules. Use when the user wants monitoring, Grafana dashboards, or alerts for a vLLM / LLM docker deployment.
---

# vLLM Monitoring Stack

用 docker compose 一键部署 LLM 推理服务的完整监控栈（assets/llm-monitor/ 为全部现成配置，验证过可运行）：

| 服务 | 端口 | 作用 |
|---|---|---|
| prometheus | 9090 | 指标采集/存储 |
| grafana | 3001 | 面板 + 告警（v11.1.0） |
| dcgm-exporter | 9400 | NVIDIA DCGM GPU 指标 |
| nvidia-gpu-exporter | 9835 | 自建 nvidia-smi exporter（python:3.11-slim 本地构建，无第三方镜像依赖） |

内置内容：
- 面板 2 个：`vllm-qwen.json`（uid `vllm-qwen-monitor`，vLLM Overview/Latency/Requests/Cache + GPU 概况）、`gpu-monitor.json`（uid `gpu-monitor`，GPU 专项 20 面板）
- 告警 5 条（30s 评估）：GPU 温度>85°C、显存>96%、remapped rows>0（硬件坏块）、vLLM KV cache OOM 压力（抢占/capacity 排队）、vLLM 服务掉线（疑似 CUDA OOM 崩溃）

## 前置条件
- Docker + NVIDIA 容器运行时：`docker run --rm --gpus all nvidia/cuda:12.4.1-base nvidia-smi` 能跑通
- vLLM 服务容器运行中且暴露 `/metrics`（默认目标 `host.docker.internal:8000`）
- 端口 9090、3001、9400、9835 空闲（刻意用 3001 避开常见占用）

## 部署步骤
1. 把 `assets/llm-monitor/` 整目录复制到目标位置（如 `/data/ai/llm-monitor`）
2. 检查 `prometheus/prometheus.yml` 里 vLLM 目标的 host:port（不是 `host.docker.internal:8000` 就改）。
   **job 名保持 `vllm-qwen` 不要改**——dashboard 的 vLLM 面板和 target-down 告警都引用这个标签；确需改名时，对 `grafana/dashboards/vllm-qwen.json` 与 `grafana/provisioning/alerting/llm-alerts.yaml` 全局替换 `job="vllm-qwen"`
3. `cd llm-monitor && docker compose up -d --build`（nvidia-smi exporter 需本地构建；dcgm-exporter 拉 nvcr.io 镜像）
4. 等 Grafana 就绪（约 30-40s），按下一节验证

## 验证（全部应通过）
```bash
cd /path/to/llm-monitor
docker compose ps                                    # 4 个容器全部 Up
curl -s localhost:9090/api/v1/targets | python3 -c "import json,sys; [print(t['labels']['job'], t['health']) for t in json.load(sys.stdin)['data']['activeTargets']]"   # 4 个 job 全 up
curl -s -u admin:qwenmon2026 localhost:3001/api/health          # database: ok
curl -s 'localhost:9090/api/v1/series?match[]={__name__=~"vllm:.*"}' | python3 -c "import json,sys; print(len(json.load(sys.stdin)['data']), 'vllm metrics')"   # 90+
curl -s 'localhost:9090/api/v1/query?query=DCGM_FI_DEV_GPU_TEMP' | python3 -m json.tool   # 有温度值
curl -s 'localhost:9090/api/v1/query?query=nvidia_smi_up' | python3 -m json.tool          # 值为 1
curl -s -u admin:qwenmon2026 localhost:3001/api/dashboards/uid/vllm-qwen-monitor | python3 -c "import json,sys; print(json.load(sys.stdin)['dashboard']['title'])"
curl -s -u admin:qwenmon2026 localhost:3001/api/ruler/grafana/api/v1/rules | python3 -c "import json,sys; print(sum(len(g['rules']) for v in json.load(sys.stdin).values() for g in v), 'rules')"   # 5
curl -s -u admin:qwenmon2026 localhost:3001/api/alertmanager/grafana/api/v2/alerts | python3 -c "import json,sys; print(len(json.load(sys.stdin)), 'active alerts')"   # 健康时应为 0
```
浏览器打开 `http://<host>:3001`（admin / qwenmon2026）："LLM Monitoring" 文件夹下两个面板，"LLM-Alerts" 文件夹下 5 条告警。

## 关键约束（改告警/面板前必读）
- **告警规则只在 Grafana 启动时加载，无热重载**：改 `llm-alerts.yaml` 后必须 `docker compose restart grafana`。dashboard JSON 则 30s 内自动热加载，无需重启。
- **Grafana 11.1 告警 YAML 格式非常特殊**：condition 必须是独立的 `classic_conditions` 数据项、键名是 `execErrState`/`noDataState`、evaluator 只支持 gt/lt/within_range/outside_range/no_value（没有 eq/qeq）。改告警前读 `references/grafana11-alerting.md`，这是最容易踩的坑。
- **Prometheus 直方图查询必须带 `_bucket` 后缀**：`histogram_quantile(0.5, sum by (le) (rate(vllm:time_to_first_token_seconds_bucket[15m])))`，漏了面板就是空白。
- **vLLM 指标名随版本变化**：定制面板前先用 `count by (__name__)({__name__=~"vllm:.*"})` 核实实际暴露的指标名（见 `references/metrics.md`）。
- stat/gauge 面板只显示当前值、没有时间轴；要看趋势用 timeseries 类型。
- 面板 15m 窗口内无请求则无数据点，属正常现象。

## 定制
- 密码/端口：`docker-compose.yml` 的 `GF_SECURITY_ADMIN_PASSWORD`（默认 qwenmon2026）、`ports`
- GPU 数量：两个 GPU exporter 默认 `count: all`，单卡可改 `count: 1`
- 告警阈值/持续时间：`llm-alerts.yaml` 各规则的 evaluator `params` 和 `for`
- 采集频率：`prometheus.yml` 的 `scrape_interval`（默认 10s）
- 通知渠道：Grafana → Alerting → Contact points（默认 default 未配 SMTP/webhook，告警只在 UI 展示）
