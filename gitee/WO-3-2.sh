#!/usr/bin/env bash
set -euo pipefail

key=${1:-}
if [[ $# -ne 1 || ! $key =~ ^(WO-)?[0-9]+-[0-9]+(-[0-9]+)?$ ]]; then
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
WO-3-2	-	WO/3-2%20WPS%E6%BC%94%E7%A4%BA%E6%96%87%E7%A8%BF%E5%B9%BB%E7%81%AF%E7%89%87%E7%9A%84%E8%AE%BE%E8%AE%A1/%E4%BC%81%E4%B8%9A%E6%A6%82%E5%86%B5.pptx	企业概况.pptx	b17480f9c70ca304aaff81c47e80af6a177e4cc73836862e1d802afec14bddd5
WO-3-2	-	WO/3-2%20WPS%E6%BC%94%E7%A4%BA%E6%96%87%E7%A8%BF%E5%B9%BB%E7%81%AF%E7%89%87%E7%9A%84%E8%AE%BE%E8%AE%A1/%E8%87%AA%E5%AE%9A%E4%B9%89%E8%AE%BE%E8%AE%A1%E6%96%B9%E6%A1%88%E5%B9%BB%E7%81%AF%E7%89%87%E6%AF%8D%E7%89%88.pptx	自定义设计方案幻灯片母版.pptx	048b2b89ff3fed0e6d7f0907fbbb4d8a64423e7a20163548f2b27a8e7e4efb22
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
