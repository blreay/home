---
name: litellm-monitoring
description: 把 LiteLLM proxy 的 Prometheus 指标（请求/延迟/TTFT/tokens/花费/部署状态）接入已有的 Grafana+Prometheus 栈，含现成 dashboard。用于用户想监控 LiteLLM（litellm proxy，端口 4000）时；前提是有可写的 litellm config.yaml 和一个运行中的 Prometheus+Grafana（如 vllm-monitoring-stack 部署的）。
---

# LiteLLM Monitoring

给 LiteLLM proxy 开 Prometheus 指标并接入已有 Grafana+Prometheus 栈（本 skill 假设监控栈已在运行，例如用 vllm-monitoring-stack 部署的 llm-monitor：prometheus:9090 + grafana:3001）。

内置资源：
- `assets/litellm-proxy.json` — 现成 dashboard（uid `litellm-proxy`，5 区域 25 面板：Overview/Traffic/Tokens/Cost/Deployments，v1.97.0 指标实测可用）
- `assets/litellm-prometheus-job.yml` — Prometheus 抓取 job 片段
- `references/metrics.md` — 指标名/类型/label 完整参考（定制面板前必读）

## 前置条件
- Prometheus（9090）+ Grafana（3001）运行中；Grafana 有 dashboard 文件 provision（`grafana/dashboards/` 目录）
- LiteLLM proxy 在运行（宿主机进程或容器，默认 4000 端口），能编辑其 `config.yaml` 并重启
- 知道 master_key（或任意有效 API key），配置在 `general_settings.master_key`

## 部署步骤

### 1. 启用 metrics（改 config + 重启）
在 `config.yaml` 的 `litellm_settings:` 下加：

```yaml
litellm_settings:
  success_callback:
    - prometheus
```

**改完必须重启 LiteLLM**——该配置只在启动时加载，没有运行时 reload 端点（`/config/update` 需要 DB，裸 YAML 部署不可用）。如果机器上有等待推理空闲窗口的重启脚本（避免打断在途请求）优先用它；否则直接 kill 后按原启动方式拉起。

验证端点（注意 `/metrics` 会 307 重定向到 `/metrics/`，要带 `-L`；未带 key 返回 401，未启用返回 404，可据此区分问题）：

```bash
curl -sL -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer <master_key>" http://<litellm-host>:4000/metrics   # 200
```

### 2. 加 Prometheus 抓取 job
把 `assets/litellm-prometheus-job.yml` 追加到 prometheus.yml 的 `scrape_configs` 下（如 `llm-monitor/prometheus/prometheus.yml`），改两处：
- target：宿主机部署用 `host.docker.internal:4000`（compose 需 `extra_hosts: host-gateway`，vllm-monitoring-stack 已带）；LiteLLM 本身是容器就用 `<容器名>:4000`
- `bearer_token` 填 master_key（`/metrics` 默认要鉴权；不想鉴权可改 `litellm_settings.require_auth_for_metrics_endpoint: false`，但默认保持鉴权）

重载 Prometheus：`curl -X POST localhost:9090/-/reload` 在 prom/prometheus:latest（3.x）上可能返回 403，改用 SIGHUP：

```bash
docker exec <prometheus容器> kill -HUP 1
```

### 3. 装 dashboard
```bash
cp assets/litellm-proxy.json <监控栈>/grafana/dashboards/
```
Grafana 文件 provider 30s 内自动加载，**无需重启 Grafana**。dashboard 用 `${datasource}` 模板变量选 Prometheus 数据源，与 vllm-monitoring-stack 的面板一致，可直接进同一个 "LLM Monitoring" 文件夹。

### 4. 验证
```bash
# 抓取目标 up（无 lastError）
curl -s localhost:9090/api/v1/targets | python3 -c "import json,sys; [print(t['labels']['job'], t['health'], t.get('lastError')) for t in json.load(sys.stdin)['data']['activeTargets'] if t['labels'].get('job')=='litellm']"

# 有数据
curl -s -G localhost:9090/api/v1/query --data-urlencode 'query=sum(rate(litellm_proxy_total_requests_metric_total[5m]))' | python3 -m json.tool
curl -s -G localhost:9090/api/v1/query --data-urlencode 'query=count(litellm_deployment_state == 0)' | python3 -m json.tool   # 健康部署数 >= 1

# 面板已注册
curl -s -u admin:<密码> localhost:3001/api/dashboards/uid/litellm-proxy | python3 -c "import json,sys; d=json.load(sys.stdin)['dashboard']; print(d['title'], len(d['panels']), 'panels')"
```
浏览器 `http://<host>:3001/d/litellm-proxy` 确认 5 个区域各自有面板（若全部挤进一个 row，是 row 的 gridPos.y 丢了，参考本 skill dashboard 里每行显式 y 值）。

## 关键约束（踩过的坑）
- **指标名带 `_total` 后缀**：代码常量叫 `litellm_spend_metric`，实际暴露 `litellm_spend_metric_total`；histogram 查询必须带 `_bucket`（`litellm_llm_api_latency_metric_bucket`）。写查询前先按 references/metrics.md 里的实际名，或用 `curl -sL .../metrics | grep '^# TYPE'` 核实。
- **model label 不统一**：请求/token/花费/延迟类用 `model`，`deployment_*` 类用 `litellm_model_name`，proxy 级没有 model。
- **`litellm_deployment_state`：0=healthy、1=partial outage、2=complete outage**（不是 1=active）。
- `/metrics` 默认要求有效 API key（master_key 可用）；未启用时是 404、未鉴权是 401；且会 307 到 `/metrics/`。
- Prometheus 3.x 的 `/-/reload` 可能 403，用 `kill -HUP 1`。
- litellm 重启后 counter 归零，重启后几分钟内 rate 类面板数据不完整属正常；cache 相关面板在未配置缓存时永远空（No data）。
- 面板 15m 窗口内无请求则无数据点，属正常。
