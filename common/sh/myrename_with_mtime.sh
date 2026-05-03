#!/bin/bash

# 检查参数
if [ $# -ne 1 ]; then
  echo "Usage: $0 <file_path>"
  exit 1
fi

file="$1"

# 检查文件是否存在
if [ ! -e "$file" ]; then
  echo "Error: File '$file' does not exist."
  exit 1
fi

# 检查是否为普通文件
if [[ ! -f "$file" && ! -d "$file" ]]; then
  echo "Error: '$file' is not a regular file."
  exit 1
fi

# 获取修改时间 (跨平台兼容)
if command -v gdate >/dev/null 2>&1; then
  # 适用于安装了 coreutils 的 macOS
  mtime=$(gdate -r "$file" +%Y%m%d_%H%M%S)
elif command -v date >/dev/null 2>&1; then
  # Linux 或 macOS 原生 date
  if [[ "$(uname)" == "Darwin" ]]; then
    mtime=$(date -r "$file" +%Y%m%d_%H%M%S)
  else
    mtime=$(date -r "$file" +%Y%m%d_%H%M%S 2>/dev/null || 
           stat -c %y "$file" | cut -d'.' -f1 | tr -d '-' | tr : '_')
  fi
else
  echo "Error: date command not found"
  exit 1
fi

# 分离文件名和扩展名
dirname=$(dirname "$file")
basename=$(basename "$file")

# 处理无扩展名情况
if [[ "$basename" == *.* ]]; then
  filename="${basename%.*}"
  ext=".${basename##*.}"
else
  filename="$basename"
  ext=""
fi

# 构建新文件名 (格式: 原名_YYYYMMDD_HHMMSS.扩展名)
new_filename="${filename}_${mtime}${ext}"

# 重命名文件
new_path="${dirname}/${new_filename}"

# 检查目标文件是否存在
if [ -e "$new_path" ]; then
  echo "Error: Target file '$new_path' already exists."
  exit 1
fi

# 执行重命名
mv -v "$file" "$new_path"
echo "Successfully renamed to: $new_path"
