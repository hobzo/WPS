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
WO-2-3	-	WO/2-3%20%E5%88%B6%E4%BD%9C%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E%E5%B7%A5%E4%BD%9C%E8%A1%A8/mytest.xlsx	mytest.xlsx	e4ab6ec3a4bb8c08a3d977fa1b5884ae6778d5c8197271b3d432bc4eb6866494
WO-2-3	WO-2-3-1	WO/2-3%20%E5%88%B6%E4%BD%9C%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E%E5%B7%A5%E4%BD%9C%E8%A1%A8/step1/my.xlsx	step1/my.xlsx	e3339d4b8c7ceb0a657f164589bbb2d6693f064b0d296de0bae40964db68ae89
WO-2-3	WO-2-3-2	WO/2-3%20%E5%88%B6%E4%BD%9C%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E%E5%B7%A5%E4%BD%9C%E8%A1%A8/step3/my.xlsx	step3/my.xlsx	aff18fd4c132f296e6e75d18310acde297bf97f4c8669f3ab0239a541b4b537b
WO-2-3	WO-2-3-3	WO/2-3%20%E5%88%B6%E4%BD%9C%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E%E5%B7%A5%E4%BD%9C%E8%A1%A8/step4/my.xlsx	step4/my.xlsx	a1080140ea407b2b438f15d2d93659d8abf2e7051898e9a105707d5030a38ccc
WO-2-3	WO-2-3-4	WO/2-3%20%E5%88%B6%E4%BD%9C%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E%E5%B7%A5%E4%BD%9C%E8%A1%A8/step5/my.xlsx	step5/my.xlsx	d7f7ca8571f983761745b5e8df21ec8bc04375db730a9a326538349be19f6a87
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
