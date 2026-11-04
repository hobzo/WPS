#!/usr/bin/env bash
set -euo pipefail
key=${1:-}
if [[ $# -ne 1 || ! $key =~ ^((WO-)?[0-9]+-[0-9]+)(-[0-9]+)?$ ]]; then
    echo '请输入编号，例如：1-1 或 1-1-1' >&2
    exit 2
fi
major=${BASH_REMATCH[1]}
base=${WPS_SOURCE:-https://gitee.com/obzo/www/raw/main}
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if command -v wget >/dev/null; then
    if ! wget -nv --timeout=20 --tries=4 -O "$tmp/stage.sh" "$base/gitee/$major.sh" 2> "$tmp/download.log"; then
        cat "$tmp/download.log" >&2
        echo "关卡脚本下载失败：$major，尚未下载或替换目标文件。" >&2
        exit 1
    fi
elif command -v curl >/dev/null; then
    if ! curl --fail --location --silent --show-error --retry 3 --connect-timeout 20 --max-time 90 "$base/gitee/$major.sh" -o "$tmp/stage.sh"; then
        echo "关卡脚本下载失败：$major，尚未下载或替换目标文件。" >&2
        exit 1
    fi
else
    echo '缺少 wget 或 curl' >&2
    exit 1
fi
WPS_SOURCE="$base" bash "$tmp/stage.sh" "$key"
