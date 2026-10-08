#!/usr/bin/env bash
set -euo pipefail

key=${1:-}
if [[ $# -ne 1 || ! $key =~ ^[0-9]+-[0-9]+(-[0-9]+)?$ ]]; then
    echo '请输入编号，例如：1-1 或 1-1-1' >&2
    exit 2
fi
base=${WPS_SOURCE:-https://gitee.com/obzo/www/raw/main}
dest=${WPS_DEST:-/data/workspace/myshixun}
for tool in sha256sum mktemp; do
    command -v "$tool" >/dev/null || { echo "缺少命令：$tool" >&2; exit 1; }
done
if ! command -v wget >/dev/null && ! command -v curl >/dev/null; then
    echo '缺少 wget 或 curl' >&2
    exit 1
fi
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
fetch_file() {
    if command -v wget >/dev/null; then
        wget -q --show-progress --timeout=20 --tries=4 -O "$2" "$1"
    else
        curl --fail --location --progress-bar --show-error --retry 3 --connect-timeout 20 --speed-time 30 --speed-limit 1 "$1" -o "$2"
    fi
}
cat > "$tmp/index.tsv" <<'WPS_FILES'
2-16	2-16-1	2-16%20%E5%AE%9E%E9%AA%8C%E4%B8%83%20WPS%20%E8%A1%A8%E6%A0%BC%20%E6%95%B0%E6%8D%AE%E7%9A%84%E5%88%86%E7%B1%BB%E6%B1%87%E6%80%BB/project1/%E5%8D%95%E9%A1%B9%E5%88%86%E7%B1%BB%E6%B1%87%E6%80%BB.xlsx	project1/单项分类汇总.xlsx	7a9bac8cffc094ae6b3a6d18d4dcbb6691afc937964daef4fe2a2c2065665efe
2-16	2-16-2	2-16%20%E5%AE%9E%E9%AA%8C%E4%B8%83%20WPS%20%E8%A1%A8%E6%A0%BC%20%E6%95%B0%E6%8D%AE%E7%9A%84%E5%88%86%E7%B1%BB%E6%B1%87%E6%80%BB/project2/%E5%B5%8C%E5%A5%97%E5%88%86%E7%B1%BB%E6%B1%87%E6%80%BB.xlsx	project2/嵌套分类汇总.xlsx	16b0569314c4de07af5fceda8423a2a9afb4ec7b7825f55d6e93bb3b3e172e40
WPS_FILES
count=0
while IFS=$'\t' read -r major minor source target digest; do
    if [[ $key != "$major" && $key != "$minor" ]]; then
        continue
    fi
    case "/$target/" in
        *'/../'*|*'/./'*|*'//'*) echo '无效目标路径' >&2; exit 1 ;;
    esac
    count=$((count + 1))
    fetch_file "$base/$source" "$tmp/$count"
    actual=$(sha256sum "$tmp/$count")
    [[ ${actual%% *} == "$digest" ]] || { echo "校验失败：$target" >&2; exit 1; }
    printf '%s\n' "${target##*/}"
    printf '%s\t%s\n' "$count" "$target" >> "$tmp/selected.tsv"
done < "$tmp/index.tsv"
if [[ $count -eq 0 ]]; then
    echo "编号不存在：$key" >&2
    exit 2
fi
while IFS=$'\t' read -r number target; do
    output="$dest/$target"
    mkdir -p -- "$(dirname -- "$output")"
    mv -f -- "$tmp/$number" "$output"
done < "$tmp/selected.tsv"
