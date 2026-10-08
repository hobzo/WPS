#!/usr/bin/env bash
set -euo pipefail
key=${1:-}
if [[ $# -ne 1 || ! $key =~ ^([0-9]+-[0-9]+)(-[0-9]+)?$ ]]; then
    echo '请输入编号，例如：1-1 或 1-1-1' >&2
    exit 2
fi
major=${BASH_REMATCH[1]}
base=${WPS_SOURCE:-https://gitee.com/obzo/www/raw/main}
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if command -v wget >/dev/null; then
    wget -q --timeout=20 --tries=4 -O "$tmp/stage.sh" "$base/gitee/$major.sh"
elif command -v curl >/dev/null; then
    curl --fail --location --silent --show-error --retry 3 --connect-timeout 20 --max-time 90 "$base/gitee/$major.sh" -o "$tmp/stage.sh"
else
    echo '缺少 wget 或 curl' >&2
    exit 1
fi
WPS_SOURCE="$base" bash "$tmp/stage.sh" "$key"
