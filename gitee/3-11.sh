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
3-11	3-11-1	3-11%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E5%9B%9B%20WPS%20%E6%BC%94%E7%A4%BA%20%E8%87%AA%E5%AE%9A%E4%B9%89%E5%8A%A8%E7%94%BB/test/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.pptx	test/中国共产党党史.pptx	2674b84039483f88626d27f877a6781fd972d5cc93df2c8dee23445c3b4e8848
3-11	3-11-2	3-11%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E5%9B%9B%20WPS%20%E6%BC%94%E7%A4%BA%20%E8%87%AA%E5%AE%9A%E4%B9%89%E5%8A%A8%E7%94%BB/test2/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.pptx	test2/中国共产党党史.pptx	163ec6ca59e73d2404d781ec8617ec05baaf3016619ddaf1bef303ec66095390
3-11	3-11-3	3-11%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E5%9B%9B%20WPS%20%E6%BC%94%E7%A4%BA%20%E8%87%AA%E5%AE%9A%E4%B9%89%E5%8A%A8%E7%94%BB/test3/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.pptx	test3/中国共产党党史.pptx	d73c531b8588159c2549aceb803a57131cb371792bc71adadbc06c2692c970e1
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
