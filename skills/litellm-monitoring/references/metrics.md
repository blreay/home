# LiteLLM Prometheus 指标参考（v1.97.0 实测）

采集后先跑一次核实（不同版本可能变化）：

```bash
curl -sL -H "Authorization: Bearer <key>" http://<litellm>:4000/metrics | grep -E '^# TYPE' | awk '{print $3, $4}' | sort -u
```

## 命名规则（与文档/常量表不一致，以实际暴露为准）
- **counter 一律带 `_total` 后缀**：代码里叫 `litellm_spend_metric`，实际暴露 `litellm_spend_metric_total`
- **histogram 用基础名 + `_bucket`/`_sum`/`_count`**：如 `litellm_llm_api_latency_metric_bucket`
- 每个指标还有 `..._created` gauge（时间戳），忽略即可
- 除 litellm 指标外还有 `python_*` / `process_*` 运行时指标

## counter（全部以 `_total` 结尾）
| 指标 | 含义 | 常用 label |
|---|---|---|
| `litellm_proxy_total_requests_metric_total` | 代理总请求数 | `requested_model`, `model_id`（无 model） |
| `litellm_proxy_failed_requests_metric_total` | 代理失败请求数 | 同上 |
| `litellm_requests_metric_total` | 完成的 LLM 请求数 | `model`, `requested_model`, `model_id` |
| `litellm_llm_api_failed_requests_metric_total` | LLM API 调用失败数 | `end_user`, `hashed_api_key`, `user` 等（**无 model**） |
| `litellm_spend_metric_total` | 累计花费 (USD) | `model`, `requested_model` |
| `litellm_total_tokens_metric_total` | 累计 input+output tokens | `model` |
| `litellm_input_tokens_metric_total` | 累计 input tokens | `model` |
| `litellm_output_tokens_metric_total` | 累计 output tokens | `model` |
| `litellm_input_cached_tokens_metric_total` | 缓存命中的 input tokens | `model` |
| `litellm_input_cache_creation_tokens_metric_total` | 缓存创建的 tokens | `model` |
| `litellm_output_reasoning_tokens_metric_total` | reasoning tokens | `model` |
| `litellm_input_audio_tokens_metric_total` / `litellm_output_audio_tokens_metric_total` | 音频 tokens | `model` |
| `litellm_cache_hits_metric_total` / `litellm_cache_misses_metric_total` | 缓存命中/未命中（未配缓存则无数据） | `model` |
| `litellm_cached_tokens_metric_total` | 缓存命中 tokens | - |
| `litellm_deployment_total_requests_total` | 部署级总请求 | `litellm_model_name`, `requested_model` |
| `litellm_deployment_success_responses_total` / `litellm_deployment_failure_responses_total` | 部署级成功/失败 | `litellm_model_name` |
| `litellm_deployment_successful_fallbacks_total` / `litellm_deployment_failed_fallbacks_total` | fallback 成功/失败 | `litellm_model_name` |
| `litellm_deployment_cooled_down_total` | 部署进入冷却次数 | `requested_model`, `exception_status` |
| `litellm_provider_cache_read_input_tokens_metric_total` / `..._creation_...` | 提供商 prompt-cache tokens | `model` |
| `litellm_images_generated_metric_total` / `litellm_video_duration_seconds_metric_total` | 图像/视频生成 | - |
| `litellm_mcp_tool_calls_total` / `litellm_mcp_tool_call_spend_metric_total` | MCP 工具调用 | - |
| `litellm_callback_logging_failures_metric_total` | 回调日志失败 | - |

## histogram（基础名，查询用 `_bucket`）
| 指标 | 含义 | model label |
|---|---|---|
| `litellm_llm_api_latency_metric` | LLM API 调用端到端延迟 (s) | `model` |
| `litellm_llm_api_time_to_first_token_metric` | TTFT (s) | `model` |
| `litellm_request_total_latency_metric` | 请求总延迟 (s) | `model` |
| `litellm_overhead_latency_metric` | 代理自身开销 (s) | - |
| `litellm_overhead_with_guardrails_latency_metric` | 含 guardrail 开销 (s) | - |
| `litellm_request_queue_time_seconds` | 队列等待时间 (s) | `model` |
| `litellm_deployment_latency_per_output_token` | TPOT (s) | `litellm_model_name` |
| `litellm_guardrail_latency_seconds` | guardrail 延迟 (s) | - |
| `litellm_managed_batch_duration_seconds` | 批量任务时长 (s) | - |

## gauge
| 指标 | 含义 |
|---|---|
| `litellm_in_flight_requests` | 当前在途 HTTP 请求数 |
| `litellm_deployment_state` | 部署状态：**0=healthy, 1=partial outage, 2=complete outage**（注意不是 1=active） |
| `litellm_deployment_tpm_limit` / `litellm_deployment_rpm_limit` | 部署 TPM/RPM 限制（配置了才出现） |
| `litellm_remaining_requests_metric` / `litellm_remaining_tokens_metric` | 剩余请求/token 配额（配置了才出现） |
| `litellm_active_users` / `litellm_total_users` / `litellm_teams_count` / `litellm_team_members_metric` | 用户/团队计数 |
| `litellm_remaining_*_budget_metric` / `litellm_*_max_budget_metric` / `litellm_*_budget_remaining_hours_metric` | 预算相关（api_key/team/org/user 维度，配置了才出现） |
| `litellm_managed_file_size_bytes` | 批量文件大小 |

## label 速记
- 请求/token/花费/延迟类：`model`（v1 模型名）+ `requested_model` + `model_id`
- 部署类（deployment_*）：`litellm_model_name` + `model_id`（**没有 model**）
- 代理级（proxy_*）：只有 `requested_model` + `model_id`
- 其他常见 label：`hashed_api_key`, `api_key_alias`, `team`, `user`, `end_user`, `api_provider`, `client_ip`, `user_agent`, `status_code`

## 常用查询（dashboard 同款）
```promql
# 请求速率 / 成功率
sum(rate(litellm_proxy_total_requests_metric_total[5m]))
(1 - sum(rate(litellm_proxy_failed_requests_metric_total[5m]))
   / clamp_min(sum(rate(litellm_proxy_total_requests_metric_total[5m])), 1e-9)) * 100

# 延迟分位（histogram 必须带 _bucket）
histogram_quantile(0.95, sum by (le) (rate(litellm_llm_api_latency_metric_bucket[5m])))
histogram_quantile(0.95, sum by (le, model) (rate(litellm_llm_api_time_to_first_token_metric_bucket[5m])))

# 按模型
sum by (model) (rate(litellm_input_tokens_metric_total[5m])) * 60

# 花费
sum(litellm_spend_metric_total)                          # 累计
sum(rate(litellm_spend_metric_total[1h])) * 3600        # 每小时

# 部署
count(litellm_deployment_state == 0)                    # 健康部署数
sum(litellm_deployment_state > 0)                       # 故障中部署数
histogram_quantile(0.95, sum by (le) (rate(litellm_deployment_latency_per_output_token_bucket[5m])))  # TPOT p95
```

注意：litellm 重启后 counter 归零，重启后 5m 窗口内的 rate 数据不完整属正常。
