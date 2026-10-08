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
2-14	2-14-1	2-14%20WPS%20%E8%A1%A8%E6%A0%BC%20%E6%95%B0%E6%8D%AE%E7%9A%84%E7%AD%9B%E9%80%89/project1/%E6%95%B0%E5%80%BC%E7%AD%9B%E9%80%89.xlsx	project1/数值筛选.xlsx	338eee7d5d05c1b55fc82657d858cc94f96a08c6d7f43d93a455d00a1b463670
2-14	2-14-2	2-14%20WPS%20%E8%A1%A8%E6%A0%BC%20%E6%95%B0%E6%8D%AE%E7%9A%84%E7%AD%9B%E9%80%89/project2/%E7%AD%9B%E9%80%89%E6%96%87%E6%9C%AC.xlsx	project2/筛选文本.xlsx	e1033b81202c3e943cc94b61344267e92100ab7cb04b02c30ff281876d2bd92e
2-14	2-14-3	2-14%20WPS%20%E8%A1%A8%E6%A0%BC%20%E6%95%B0%E6%8D%AE%E7%9A%84%E7%AD%9B%E9%80%89/project3/%E6%97%A5%E6%9C%9F%E7%AD%9B%E9%80%89.xlsx	project3/日期筛选.xlsx	f7f19f1d32c64b1d375c2c8518702115f92dbf02097bc15608c946ae5dc1508e
2-14	2-14-4	2-14%20WPS%20%E8%A1%A8%E6%A0%BC%20%E6%95%B0%E6%8D%AE%E7%9A%84%E7%AD%9B%E9%80%89/project4/%E9%AB%98%E7%BA%A7%E7%AD%9B%E9%80%89.xlsx	project4/高级筛选.xlsx	516ddd1b1edaf67d3ea98edf36a109ef065c1556a5d6af6b0415bd7f341ee16b
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
