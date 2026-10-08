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
2-18	2-18-1	2-18%20%E5%AE%9E%E9%AA%8C%E5%85%AB%20WPS%20%E8%A1%A8%E6%A0%BC%20%E7%86%9F%E6%82%89%E5%85%AC%E5%BC%8F/step1/%E8%BE%93%E5%85%A5%E5%92%8C%E7%BC%96%E8%BE%91%E5%85%AC%E5%BC%8F.xlsx	step1/输入和编辑公式.xlsx	1e7ece7ca560b12378219b115613e3b6acfdc3e2a273e78074f7d8e5c10e1608
2-18	2-18-2	2-18%20%E5%AE%9E%E9%AA%8C%E5%85%AB%20WPS%20%E8%A1%A8%E6%A0%BC%20%E7%86%9F%E6%82%89%E5%85%AC%E5%BC%8F/step2/%E5%8D%95%E5%85%83%E6%A0%BC%E7%9A%84%E5%BC%95%E7%94%A8%E5%BD%A2%E5%BC%8F.xlsx	step2/单元格的引用形式.xlsx	09d3cc5b8c3271a691d61364c2860069588a3173f889c5a3be548c00aa7e65fc
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
