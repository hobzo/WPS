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
2-13	2-13-1	2-13%20WPS%20%E8%A1%A8%E6%A0%BC%20%E6%95%B0%E6%8D%AE%E7%9A%84%E6%8E%92%E5%BA%8F/project1/%E7%AE%80%E5%8D%95%E6%8E%92%E5%BA%8F.xlsx	project1/简单排序.xlsx	180d255a30b77bee0666f962a78a9c9c614a1f6fb827df926b51bbb37ae71269
2-13	2-13-2	2-13%20WPS%20%E8%A1%A8%E6%A0%BC%20%E6%95%B0%E6%8D%AE%E7%9A%84%E6%8E%92%E5%BA%8F/project2/%E5%A4%8D%E6%9D%82%E6%8E%92%E5%BA%8F.xlsx	project2/复杂排序.xlsx	78184c0d6393750bacf65d77929b60428cd47365bb812866f1e13ec241283380
2-13	2-13-3	2-13%20WPS%20%E8%A1%A8%E6%A0%BC%20%E6%95%B0%E6%8D%AE%E7%9A%84%E6%8E%92%E5%BA%8F/project3/%E6%8C%89%E7%AC%94%E7%94%BB%E6%8E%92%E5%BA%8F.xlsx	project3/按笔画排序.xlsx	e589f63b1d8fd995227f3a4107652200b84902d3889880a65ddb642be4ad0648
2-13	2-13-4	2-13%20WPS%20%E8%A1%A8%E6%A0%BC%20%E6%95%B0%E6%8D%AE%E7%9A%84%E6%8E%92%E5%BA%8F/project4/%E6%8C%89%E9%A2%9C%E8%89%B2%E6%8E%92%E5%BA%8F.xlsx	project4/按颜色排序.xlsx	b457479f60f0994f31596b5b3ab0d302c9c520fca140f75c1ffcf8f8953a10b6
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
