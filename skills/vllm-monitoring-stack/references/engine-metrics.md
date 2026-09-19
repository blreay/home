# 引擎侧指标语义参考 (llama.cpp / ComfyUI / 槽位)

vLLM 指标见 `metrics.md`。本文覆盖其余三个来源，全部经生产实测校准 (2026-09)。

## 1. llama-server 原生指标 (需 `--metrics`, job=vllm-qwen, 前缀 `llamacpp:`)

| 指标 | 类型 | 语义 |
|---|---|---|
| requests_processing | gauge | 正在处理的请求数 |
| requests_deferred | gauge | 排队等待的请求数（槽位满时>0） |
| predicted_tokens_seconds | gauge | 当前 decode 速度 (tok/s) |
| prompt_tokens_seconds | gauge | 当前 prefill 速度 (tok/s) |
| tokens_predicted_total | counter | 累计生成 token |
| prompt_seconds_total | counter | 累计 prefill 耗时(秒) |
| prompt_tokens_total | counter | **累计 prompt 处理量**（"所有请求上下文总和"看这个） |
| prompt_tokens_cached_total | counter | 累计命中前缀缓存的 prompt token（命中率=cached/total 的 rate 比） |
| tokens_predicted_seconds_total | counter | 累计 decode 耗时 → ms/token = rate(seconds)/rate(tokens)×1000 |
| n_decode_total | counter | 累计 decode 次数 |
| **n_tokens_max** | counter | **自启动以来最长单次请求长度(prompt+生成)的水位**。单调不减、重启归零。不是容量/不是总和/不是当前值！超过模型原生窗口(如262144)即进入外推区 |
| n_busy_slots_per_decode | gauge | 每次 decode 平均忙碌槽位数 |
| spec_decode_num_drafts_total | counter | MTP/投机解码发起次数 |
| spec_decode_num_draft_tokens_total | counter | 草稿 token 总数 |
| spec_decode_num_accepted_tokens_total | counter | 被接受的草稿 token → **接受率=accepted/draft** |
| spec_decode_num_accepted_tokens_per_pos_total{position} | counter | 分位置接受数 → 位置N接受率=per_pos{N}/drafts，用于决定 draft 深度 |

调度特性备忘：单批预算 n_batch(默认2048)会被大 prefill 占满——220K 冷 prompt 期间，同跑的小请求 decode 会从 ~60 t/s 掉到 ~3 t/s（搭便车效应），属 llama.cpp 设计使然；缓解=调小 `-b` 或错峰。

## 2. llama-slots-exporter (:9465, 抓 `GET /slots`, 前缀 `llamaslot_`)

| 指标 | 语义 |
|---|---|
| llamaslot_up | llama-server /slots 可达(1/0)。引擎没跑时=0，面板断线属正常 |
| llamaslot_n_ctx{slot} | 槽位上下文容量(tokens) |
| llamaslot_processing{slot} | 槽位是否正在处理(0/1) |
| llamaslot_n_prompt_tokens{slot} | 该槽**当前/最近一个任务**的上下文大小。空闲后保留残留水位（阶梯线），非当前占用 |
| llamaslot_n_prompt_tokens_cache{slot} | 上述 prompt 中命中前缀缓存的部分（对照看缓存效率） |
| llamaslot_id_task{slot} | 任务号 |

## 3. comfyui-exporter (:9464, 抓 18188 的 /system_stats /queue /history, 前缀 `comfyui_`)

**注意**：ComfyUI 无原生 /metrics；8188 端口若为带登录门户的前置层会 302，exporter 必须直连本体端口(默认18188)。

| 指标 | 语义 |
|---|---|
| comfyui_up | 可达(1/0) |
| comfyui_info{version} | 版本 |
| comfyui_queue_running / queue_pending | 执行中/排队任务数（/queue 的两个数组长度） |
| comfyui_vram_total_bytes / vram_free_bytes{device,name} | ComfyUI 视角的设备显存（--lowvram 动态加载时 free 随模型换入换出波动） |
| comfyui_torch_vram_total_bytes / torch_vram_free_bytes | torch 已分配部分 |
| comfyui_system_ram_total_bytes / ram_free_bytes | 系统内存 |
| comfyui_prompts_completed_total | 累计完成任务数（经 /history?max_items=10, 30s轮询；exporter 重启以当时历史为基线归零） |
| comfyui_last_execution_ms | 最近一次任务耗时（history 里 execution_start→最后时间戳差值） |

## 4. LiteLLM (job=litellm, 需 bearer_token=master_key)

`litellm_settings.success_callback: [prometheus]` 开启，指标前缀 `litellm_`：请求计数/时延直方图/token 用量/按 api_key·model·user 维度。面板 LiteLLM Proxy 已引用。
应用层补充（非 Prometheus）：思考电表 thinking_meter.py 回调输出 JSONL（档位/思考token/缓存命中/来源），报表用 thinking_report.py。

## 5. 排查速查

```bash
# 目标健康总览
curl -s localhost:9090/api/v1/targets?state=active | python3 -c "import json,sys; [print(t['labels']['job'],t['health'],t.get('lastError','')[:60]) for t in json.load(sys.stdin)['data']['activeTargets']]"
# 某指标是否存在/语义
curl -s localhost:8000/metrics | grep -B2 "指标名"     # 看 # HELP 原文, 别猜
curl -s localhost:9465/metrics | grep llamaslot
# 面板无数据三步: 目标up? → 指标存在? → 面板expr的job/前缀对?
```
