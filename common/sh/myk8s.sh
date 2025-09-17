#!/bin/bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/mycommon.sh"
typeset g_mandatory_utilities=(awk sed jq kubectl)

function my_show_usage {
    cat - <<EOF
Usage[Advanced]: ${g_appname_short} [-x] [command]
         get_resource : get all CPU and MEMORY resource for all k8s cluster
EOF
}

function k8s_get_resource {
  # 获取所有节点的 JSON 信息
  kubectl get nodes -o json > nodes.json

  # 使用 jq 提取 CPU 和内存信息并进行汇总
  total_cpu=0
  total_memory=0

  while IFS= read -r node; do
    name=$(echo "$node" | jq -r '.metadata.name')
    cpu=$(echo "$node" | jq -r '.status.capacity.cpu')
    memory=$(echo "$node" | jq -r '.status.capacity.memory')
    echo "name=$name      cpu=$cpu memory=$memory"

    # 将内存从 KiB 转换为 MiB
    memory_mib=$((${memory%Ki} / 1024))

    total_cpu=$((total_cpu + cpu))
    total_memory=$((total_memory + memory_mib))
  #done < <(jq -c '.items[]' nodes.json)
  done <<<$(jq -c '.items[]' nodes.json)

  echo "Total CPU: $total_cpu"
  echo "Total Memory (MiB): $total_memory"
}

function my_entry {
    typeset act="${1:-NOVAL}"
    case $act in
      get_resource) k8s_get_resource $@;;
      NOVAL) my_show_usage_entry $@;;
    esac
}

main ${@}
