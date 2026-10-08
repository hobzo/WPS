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
2-23	2-23-1	2-23%20%E5%AE%9E%E9%AA%8C%E4%B9%9D%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%85%AC%E5%BC%8F%E4%B8%8E%E5%87%BD%E6%95%B0%E7%BB%BC%E5%90%88%E5%AE%9E%E8%B7%B5-2/step1/%E6%A1%88%E4%BE%8B1%EF%BC%9A%E5%88%B6%E4%BD%9C%E6%B7%98%E5%AE%9D%E5%BA%97%E9%93%BA%E9%94%80%E5%94%AE%E6%8A%A5%E8%A1%A8.xlsx	step1/案例1：制作淘宝店铺销售报表.xlsx	ac5b5efb9d53a0162f25f11e62dbc20bcd79fa770601d34dd2efd3c8125ad908
2-23	2-23-2	2-23%20%E5%AE%9E%E9%AA%8C%E4%B9%9D%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%85%AC%E5%BC%8F%E4%B8%8E%E5%87%BD%E6%95%B0%E7%BB%BC%E5%90%88%E5%AE%9E%E8%B7%B5-2/step2/%E6%A1%88%E4%BE%8B2%EF%BC%9A%E5%88%B6%E4%BD%9C%E5%91%98%E5%B7%A5%E5%B7%A5%E8%B5%84%E8%A1%A8.xlsx	step2/案例2：制作员工工资表.xlsx	63611f85918070a0951897a0e0ce1f70c9bd1e1f7c37407a4430a5391de73a6e
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
