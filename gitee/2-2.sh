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
2-2	2-2-1	2-2%20%E5%AE%9E%E9%AA%8C%E5%85%AD%20WPS%20%E8%A1%A8%E6%A0%BC%20%E8%AE%BE%E7%BD%AE%E8%A1%8C%E5%88%97%E5%92%8C%E5%8D%95%E5%85%83%E6%A0%BC/%E7%B4%A0%E6%9D%90/%E5%90%88%E5%B9%B6%E4%B8%8E%E6%8B%86%E5%88%86%E5%8D%95%E5%85%83%E6%A0%BC.xlsx	素材/合并与拆分单元格.xlsx	4141e4cc8db24a8ca03e0869c1c6672e5369978661007d7faf122cab5516364e
2-2	2-2-1	2-2%20%E5%AE%9E%E9%AA%8C%E5%85%AD%20WPS%20%E8%A1%A8%E6%A0%BC%20%E8%AE%BE%E7%BD%AE%E8%A1%8C%E5%88%97%E5%92%8C%E5%8D%95%E5%85%83%E6%A0%BC/%E7%B4%A0%E6%9D%90/%E6%8F%92%E5%85%A5%E6%88%96%E5%88%A0%E9%99%A4%E8%A1%8C%E5%88%97.xlsx	素材/插入或删除行列.xlsx	d2301072be68ad969ef8b82a1ea4e3199f759c2d37bacc4ec6242c490d3530ac
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
