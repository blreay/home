# Grafana 11.1 告警 Provisioning 详解（对照源码验证的踩坑清单）

基于 grafana/grafana v11.1.0 源码（pkg/services/provisioning/alerting、pkg/services/ngalert、pkg/expr）逐条验证，不是猜测。

## 规则结构：查询 A + 经典条件 B

每条规则 = 数据项 A（数据源查询）+ 数据项 B（经典条件），`condition: B` 指向条件项。**把 conditions 塞进 Prometheus 查询的 model 里是 10.2 之前的旧格式，11.1 引擎会忽略它**——引擎直接拿 A 的原始值判定（非零→报警、零→正常、空→NoData），表现为"任何非零值都误报"。

完整示例（GPU 温度）：

```yaml
apiVersion: 1
groups:
  - orgId: 1
    folder: LLM-Alerts          # 自动创建
    name: llm-gpu-alerts        # 组名
    interval: 30s               # 评估间隔
    contact_point_names: [default]
    rules:
      - uid: llm-gpu-temp-high  # 必须唯一，provisioner 按 uid upsert
        title: "GPU 温度过高 (>85°C)"
        condition: B
        data:
          - refId: A
            queryType: ''
            relativeTimeRange: {from: 60, to: 0}
            datasourceUid: vllm-prom          # 数据源 uid
            model:
              refId: A
              datasource: {type: prometheus, uid: vllm-prom}
              editorMode: code
              expr: max(DCGM_FI_DEV_GPU_TEMP)
              instant: true
              intervalMs: 1000
              maxDataPoints: 43200
              queryType: instant              # 必须，否则 prometheus 插件当 range 查询返回时间序列→评估报错
          - refId: B
            queryType: ''
            relativeTimeRange: {from: 0, to: 0}
            datasourceUid: "__expr__"         # 表达式节点伪数据源
            model:
              conditions:
                - evaluator: {params: [85], type: gt}
                  operator: {type: and}
                  query: {params: [A]}
                  reducer: {params: [], type: last}
                  type: query
              datasource: {type: __expr__, uid: __expr__}
              intervalMs: 1000
              maxDataPoints: 43200
              refId: B
              type: classic_conditions        # 引擎按 model.type 分发
        for: 2m
        noDataState: OK
        execErrState: Alerting
        isPaused: false
        labels: {severity: warning, category: gpu}
        annotations:
          summary: "GPU 温度高于 85°C"
          description: 'RTX 4090 温度 {{ printf "%.0f" $values.B0.Value }}°C，请检查散热或降负载。'
```

## 关键要点

1. **YAML 键名**（11.1 的 AlertRuleV1 DTO）：
   - `execErrState`——不是 `executionErrorState`（后者被静默忽略，默认值恰好是 Alerting，极易误判）
   - `noDataState`：OK / NoData / Alerting
   - 其余：`for`、`isPaused`、`labels`、`annotations`、`condition`、`data`、`uid`、`title`

2. **evaluator 类型只支持 5 种**：`gt`、`lt`、`within_range`（2 参数）、`outside_range`（2 参数）、`no_value`。
   - **`eq`、`ne`、`ge`、`le`、`qeq` 全部非法**（引擎报 `invalid evaluator type`，规则卡死在报警状态）。
   - 要表达"等于 0"：把表达式改写成 `1 - up{...}` 配 `gt 0`；"指标缺失"用 `absent(...)` 配 `gt 0`。

3. **引擎判定语义**：classic_conditions 输出的 frame 值 `0→Normal、非零→Alerting、nil→NoData`（按 noDataState 处理）；执行错误按 execErrState 处理。条件应输出布尔结果（PromQL 布尔表达式 `x > 0` 返回 1/0 或空）。

4. **注解取值**：`{{ $values.B0.Value }}`（B0 = 条件项 refId + 条件序号）是**原始输入值**（如真实温度 52），不是 0/1。模板支持 Go template 的 `printf`，但**没有 sprig**（没有 mul/add 等数学函数）。

5. **NoData 语义**：条件输入全为空 → NoData。布尔 PromQL（如 `increase(x[5m]) > 0 or (y) > 0`）无压力时返回空 → NoData，配 `noDataState: OK` 即不报警。

6. **target-down 标准写法**：`expr: 1 - up{job="X"}` + `gt 0` + `noDataState: Alerting`（up=1→0 不报；up=0→1 报警；指标整体消失→NoData 报警）。

7. **Provisioning 行为**：
   - **只在启动时加载，无热重载**——改完必须 `docker compose restart grafana`
   - 按 uid upsert：同 uid 更新、不产生重复
   - 删规则文件**不会**清理孤儿规则；需停 grafana 后手动删 grafana.db（`alert_rule`、`alert_rule_version`、`alert_instance` 表）对应行
   - API 不能删 provisioned 资源（报 "request affects resources created via provisioning API"）

8. **Grafana 11.1 API 端点**（旧版路径 /api/v1/alert/rules 等全 404）：
   - 规则：`GET /api/ruler/grafana/api/v1/rules`
   - 活动告警：`GET /api/alertmanager/grafana/api/v2/alerts`
   - 面板：`GET /api/dashboards/uid/<uid>`
   - 健康：`GET /api/health`

9. **调试手段**：compose 里给 grafana 临时加 `GF_LOG_FILTERS: "ngalert:debug"`，`docker logs` 可看到每次评估的具体错误（如 invalid evaluator type、查询失败等）；排查完删掉。

## 内置 5 条规则速查（assets/llm-monitor/grafana/provisioning/alerting/llm-alerts.yaml）

| uid | 表达式（A） | 条件（B） | for | noData | severity |
|---|---|---|---|---|---|
| llm-gpu-temp-high | `max(DCGM_FI_DEV_GPU_TEMP)` | `gt 85` | 2m | OK | warning |
| llm-gpu-memory-high | `sum(nvidia_smi_gpu_memory_used_bytes)/sum(nvidia_smi_gpu_memory_total_bytes)` | `gt 0.96` | 5m | OK | warning |
| llm-gpu-remapped-rows | `max(...CORRECTABLE_REMAPPED_ROWS)+max(...UNCORRECTABLE_REMAPPED_ROWS)+max(DCGM_FI_DEV_ROW_REMAP_FAILURE)` | `gt 0` | 1m | OK | critical |
| llm-vllm-oom-pressure | `increase(vllm:num_preemptions_total[5m]) > 0 or (vllm:num_requests_waiting_by_reason{reason="capacity"} > 0)` | `gt 0` | 1m | OK | critical |
| llm-vllm-target-down | `1 - up{job="vllm-qwen"}` | `gt 0` | 1m | Alerting | critical |
