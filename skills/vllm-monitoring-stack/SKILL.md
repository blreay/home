---
name: vllm-monitoring-stack
description: Deploy a Prometheus + Grafana monitoring stack for locally deployed LLM engines (vLLM container, llama.cpp bare process, ComfyUI) fronted by LiteLLM, with 5 ready-made dashboards (vLLM / llama.cpp / LiteLLM / GPU / ComfyUI), custom exporters, and GPU/engine alert rules. Use when the user wants monitoring, Grafana dashboards, per-slot context metrics, or alerts for a local LLM / image-gen deployment.
---

# LLM Monitoring Stack (vLLM + llama.cpp + LiteLLM + ComfyUI + GPU)

一套经过生产验证的本地大模型监控栈。`assets/` 内是全部现成素材（2026-09-19 与生产环境同步）。

## 架构总览

```
被监控对象                         采集                          展示/告警
─────────────                    ─────────                      ─────────
vLLM 容器 (:8000/metrics)   ─┐
llama-server (:8000/metrics) ─┼→ prometheus job [vllm-qwen]  ─┐
  └ llama-slots-exporter(:9465)→ job [llama-slots]            │
LiteLLM (:4000/metrics, bearer)→ job [litellm]                ├→ Prometheus(:9090) → Grafana(:3001)
ComfyUI (:18188 JSON API)    ─→ comfyui-exporter(:9464) → job [comfyui] ┤   5 面板 + 5 告警
GPU                          ─→ dcgm-exporter(:9400)  → job [dcgm]      │
                               nvidia-smi-exporter(:9835) → job [nvidia-smi] ┘
```

**关键设计**：vLLM 和 llama.cpp **共享 `:8000` 和同一个 job 名 `vllm-qwen`**（二者因显存/端口互斥，同一时刻只有一个在跑）。哪个引擎在跑，Prometheus 就收哪种指标（`vllm:*` 或 `llamacpp:*`），对应面板自动有数、另一个自动空——切引擎零配置改动。

## 六个容器

| 容器 | 端口 | 作用 |
|---|---|---|
| llm-prometheus | 9090 | 采集/存储(15天)，7 个 job |
| llm-grafana | 3001 | 面板+告警 (v11.1.0, admin/qwenmon2026) |
| llm-dcgm-exporter | 9400 | NVIDIA DCGM GPU 指标 |
| llm-nvidia-smi-exporter | 9835 | 自建 nvidia-smi exporter (python:3.11-slim 本地构建) |
| llm-comfyui-exporter | 9464 | ComfyUI 应用层指标(队列/VRAM/完成数)，抓 `:18188` 的 JSON API |
| llm-llama-slots-exporter | 9465 | llama.cpp **每槽位**上下文/缓存指标，抓 `:8000/slots` |

## 五个面板（grafana/dashboards/，文件夹 "LLM Monitoring"）

| 面板 | uid | 数据源 job | 要点 |
|---|---|---|---|
| Qwen vLLM Monitor | vllm-qwen-monitor | vllm-qwen | Overview/Latency(TTFT/ITL 分位数,直方图必须带 `_bucket`)/Requests/KV cache |
| llama.cpp · Qwen3.8-27B | llamacpp-qwen | vllm-qwen + llama-slots | 并发/排队(stat+曲线)/Decode·Prefill 速度(带坐标轴)/MTP 接受率(含分位置)/前缀缓存命中率/ms每token/**上下文峰值**(n_tokens_max, 带 262144 原生窗口红线)/**每槽位上下文大小历史**/每槽位缓存命中 |
| LiteLLM Proxy | (见文件) | litellm | 请求速率/时延/token 用量/按模型分组 |
| GPU Monitor | gpu-monitor | dcgm + nvidia-smi | GPU 专项 20 面板(温度/功耗/显存/利用率/时钟) |
| ComfyUI · MiniMax-H3 | comfyui-h3 | comfyui | 在线状态/执行中/排队/VRAM(动态加载视角)/完成速率(个/分钟)/最近任务耗时/系统内存 |

告警 5 条（30s 评估）：GPU 温度>85°C、显存>96%、remapped rows>0、vLLM KV cache OOM 压力、引擎掉线。

## 部署

**方式 A（推荐，docker run，幂等可重跑）**：
```bash
cp -r assets/llm-monitor /path/to/llm-monitor
cp assets/start_metric.sh /path/to/          # MON_DIR 自定位到脚本旁的 llm-monitor/
vi /path/to/llm-monitor/prometheus/prometheus.yml   # 改 CHANGE_ME_LITELLM_MASTER_KEY
bash /path/to/start_metric.sh
```
**方式 B（compose）**：`cd llm-monitor && docker compose up -d --build`

两种方式都要求目标机具备：docker + NVIDIA 容器运行时、引擎侧指标已开启（见下节）。

## 引擎侧接入清单

| 引擎 | 要做什么 |
|---|---|
| vLLM | 无需任何参数，`/metrics` 常开 |
| llama.cpp (llama-server) | **必须加 `--metrics`**（默认关闭！）；建议同时 `--alias <模型名>`、`--slots`（默认开，供 slots exporter） |
| LiteLLM | config.yaml `litellm_settings: success_callback: [prometheus]`；其 `/metrics` 需鉴权 → prometheus.yml 的 litellm job 填 `bearer_token: <master_key>` |
| ComfyUI | 无原生 metrics。注意 **8188 常是带登录门户的前置层(302)，18188 才是本体 JSON API**（/system_stats /queue /history）——exporter 连 18188 |

## 验证

```bash
curl -s localhost:9090/api/v1/targets?state=active | python3 -c "import json,sys; [print(t['labels']['job'],t['health']) for t in json.load(sys.stdin)['data']['activeTargets']]"
# 期望: vllm-qwen/litellm/dcgm/nvidia-smi/comfyui/llama-slots/prometheus 全 up
# (对应引擎没跑时 vllm-qwen 或 llama-slots 或 comfyui 为 down 属正常)
curl -s -u admin:qwenmon2026 localhost:3001/api/search?type=dash-db | python3 -m json.tool  # 5 个面板
curl -s localhost:9465/metrics | grep llamaslot_up      # llama-server 在跑时=1
curl -s localhost:9464/metrics | grep comfyui_up        # ComfyUI 在跑时=1
```

## 踩坑清单（血泪，改任何东西前先读）

1. **compose 改写成 docker run 必须手工补 `--network-alias`**：compose 自动以服务名注册 DNS（`dcgm-exporter`/`nvidia-gpu-exporter`/`prometheus`），docker run 只有容器名（`llm-` 前缀）。丢了别名的症状：prometheus 里 dcgm/nvidia-smi 目标 down（`lookup dcgm-exporter: no such host`），**Grafana 数据源 `http://prometheus:9090` 也解析失败 → 全部面板无数据**。assets/start_metric.sh 已带全部别名。
2. **llama-server 的 /metrics 默认关闭**，不加 `--metrics` 时 job 显示 up 但零指标（404 页面被当空响应）。
3. **`llamacpp:n_tokens_max` 语义**：HELP 原文 "Largest observed sequence length (prompt + generation)" —— 是**自启动以来最长单次请求**的水位（单调不减，重启归零），不是容量、不是总和、不是当前值。总和看 `prompt_tokens_total`。
4. **Prometheus 容器 bind-mount 的是 inode**：把 prometheus.yml 所在目录搬家/重建后，运行中的容器还在读旧 inode；必须重建容器（start_metric.sh 幂等重跑即可）。
5. **Grafana 面板文件是唯一事实来源**：provisioned 面板 30s 热加载；UI 里的改动(allowUiUpdates)会在文件变更时被覆盖——改面板请改 JSON 文件。
6. **告警规则只在 Grafana 启动时加载**，改 llm-alerts.yaml 后必须重启 grafana 容器。Grafana 11.1 告警 YAML 格式特殊，见 `references/grafana11-alerting.md`。
7. **直方图查询必须带 `_bucket`**：`histogram_quantile(0.5, sum by (le) (rate(vllm:time_to_first_token_seconds_bucket[15m])))`。
8. **槽位指标是"残留值"语义**：`llamaslot_n_prompt_tokens{slot}` 在槽位空闲后保留上一个任务的水位，配合 `llamaslot_processing` 判断是否"正在进行时"。
9. **exporter 计数器重启归零**：`comfyui_prompts_completed_total` 以启动时历史为基线，rate() 自动处理重置。
10. **vLLM 指标名随版本变化**：定制前用 `count by (__name__)({__name__=~"vllm:.*"})` 核实，见 `references/metrics.md`；llama.cpp/ComfyUI 指标语义见 `references/engine-metrics.md`。
11. stat 面板只显示当前值；看趋势必须 timeseries。15m 窗口无请求则无数据点属正常。

## 定制

- 密码/端口：compose 或 start_metric.sh 里 `GF_SECURITY_ADMIN_PASSWORD`（默认 qwenmon2026，**公网机器务必改**）、各 `-p` 映射
- job 名 `vllm-qwen` 不要改（面板和告警都引用 `job="vllm-qwen"`；确需改则全局替换面板 JSON + llm-alerts.yaml）
- 数据源 uid `vllm-prom` 同理（所有面板 JSON 引用）
- 告警阈值：llm-alerts.yaml 各 evaluator params / for
- 采集频率：prometheus.yml `scrape_interval`（默认 10s）
- ComfyUI/llama.cpp 地址：两个 exporter 容器的 env `COMFYUI_URL` / `LLAMA_URL`

## 相关组件（不在本 skill 内，同机部署时配套）

- **litellm-monitoring skill**：LiteLLM 侧更多观测
- **思考电表** thinking_meter.py（litellm CustomLogger 回调）：每请求 JSONL 落盘（档位/思考量/缓存命中/来源IP）+ 控制台单行摘要 + 报表脚本，属 litellm 应用层观测，与 Prometheus 栈互补
- **op.sh**：三引擎统一启停切换（监控栈与引擎解耦的前提）
