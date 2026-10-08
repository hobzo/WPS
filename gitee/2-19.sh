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
2-19	2-19-1	2-19%20%E5%AE%9E%E9%AA%8C%E5%85%AB%20WPS%20%E8%A1%A8%E6%A0%BC%20%E8%AE%A4%E8%AF%86%E5%87%BD%E6%95%B0/step1/%E5%87%BD%E6%95%B0%E7%9A%84%E8%BE%93%E5%85%A5%E6%96%B9%E6%B3%95.xlsx	step1/函数的输入方法.xlsx	a050821d5a81f360217ccd90bfeab904b3240691cf89356b92180c8ad526c42a
2-19	2-19-2	2-19%20%E5%AE%9E%E9%AA%8C%E5%85%AB%20WPS%20%E8%A1%A8%E6%A0%BC%20%E8%AE%A4%E8%AF%86%E5%87%BD%E6%95%B0/step2/%E8%87%AA%E5%8A%A8%E8%AE%A1%E7%AE%97.xlsx	step2/自动计算.xlsx	0aa741b846c672e5be3f540d27cff894c92d440b41dc3c269c988122c7bb5c6b
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
