# 指标速查表（实测验证）

## vLLM（vLLM 服务 /metrics 自带，job=vllm-qwen）

直方图（查询必须加 `_bucket` 后缀，配合 `histogram_quantile` + `sum by (le) (rate(...[15m]))`）：
- `vllm:time_to_first_token_seconds` — TTFT 首 token 延迟
- `vllm:e2e_request_latency_seconds` — 端到端请求延迟
- `vllm:request_queue_time_seconds` — 排队等待
- `vllm:request_prefill_time_seconds` — prefill 时间
- `vllm:request_decode_time_seconds` — decode 时间
- `vllm:request_time_per_output_token_seconds` — 每输出 token 耗时
- `vllm:inter_token_latency_seconds` / `vllm:request_inference_time_seconds` — 备选

Gauge / Counter：
- `vllm:num_requests_running` / `vllm:num_requests_waiting` — 当前运行/排队请求数
- `vllm:num_requests_waiting_by_reason{reason}` — 按原因排队（`capacity`=KV cache 不足）
- `vllm:kv_cache_usage_perc` — KV cache 使用率（0-1）
- `vllm:generation_tokens_total` / `vllm:prompt_tokens_total` — token 吞吐（counter，配 rate）
- `vllm:request_success_total{finished_reason}` — 成功请求（按结束原因）
- `vllm:num_preemptions_total` — 抢占次数（OOM 压力信号）
- `vllm:prefix_cache_hits_total` / `vllm:prefix_cache_queries_total` — 前缀缓存命中
- `vllm:prompt_tokens_by_source_total{source}` — 按来源的 prompt tokens

⚠️ vLLM 不同版本指标名不同（如 `time_per_output_token_seconds` → `request_time_per_output_token_seconds`）。定制面板前先核实：
```bash
curl -s 'localhost:9090/api/v1/series?match[]={__name__=~"vllm:.*"}' | python3 -c "
import json,sys
print('\n'.join(sorted({m['__name__'] for m in json.load(sys.stdin)['data']})))"
```

## DCGM（dcgm-exporter，job=dcgm，指标名 `DCGM_FI_DEV_*`，label `gpu=`）
- `DCGM_FI_DEV_GPU_TEMP` — 温度（°C）
- `DCGM_FI_DEV_GPU_UTIL` — 利用率（%）
- `DCGM_FI_DEV_FB_USED` / `FB_FREE` / `FB_RESERVED` — **单位 MiB（不是 bytes！）**
- `DCGM_FI_DEV_POWER_USAGE` — 功耗（W）
- `DCGM_FI_DEV_TOTAL_ENERGY_CONSUMPTION` — 累计能耗（mJ；÷3.6e9 → kWh）
- `DCGM_FI_DEV_CLOCK_SM` / `DCGM_FI_DEV_CLOCK_MEM` — 频率（MHz）
- `DCGM_FI_DEV_CORRECTABLE_REMAPPED_ROWS` / `DCGM_FI_DEV_UNCORRECTABLE_REMAPPED_ROWS` / `DCGM_FI_DEV_ROW_REMAP_FAILURE` — 显存行重映射，正常应为 0，非零=显存硬件退化
- `DCGM_FI_DEV_XID_ERRORS` — XID 错误，非零值得单独加告警

## nvidia-smi exporter（job=nvidia-smi，自建 python 脚本，label `gpu=, name=, uuid=`）
- `nvidia_smi_up` — 1 表示 scrape 成功（可配 target-down 类告警）
- `nvidia_smi_gpu_utilization` / `nvidia_smi_gpu_memory_utilization` — 利用率（%）
- `nvidia_smi_gpu_memory_used_bytes` / `..._total_bytes` / `..._free_bytes` — 显存（bytes）
- `nvidia_smi_gpu_temperature_celsius` / `nvidia_smi_gpu_memory_temperature_celsius` — 温度
- `nvidia_smi_gpu_power_watts` / `..._power_limit_watts` — 功耗
- `nvidia_smi_gpu_sm_clock_mhz` / `..._max_sm_clock_mhz` / `..._mem_clock_mhz` — 频率
- `nvidia_smi_gpu_fan_speed_percent` / `nvidia_smi_gpu_pstate` — 风扇/性能状态
- `nvidia_smi_gpu_throttled_<reason>` — 降频原因 1/0（gpu_idle、sw_power_cap、hw_thermal_slowdown、sw_thermal_slowdown、sync_boost 等）
- `nvidia_smi_gpu_ecc_corrected_volatile_total` / `..._uncorrected...` — ECC 错误（counter，仅 ECC 开启时导出）
- `nvidia_smi_process_memory_used_bytes{pid, process_name, gpu_uuid}` — 每进程显存占用（nvidia-smi compute-apps，需 `pid: host` 才能看到宿主进程）

⚠️ nvidia-smi 字段名随驱动版本变化（如 580 驱动用 `clocks.current.sm` 而非 `clocks.sm`）；exporter 的 `GPU_FIELDS` 列表按需调整，字段不存在时 nvidia-smi 返回空值，脚本会跳过（不影响其他指标）。
