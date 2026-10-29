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
WO-1-1	-	WO/1-1%20WPS%E6%96%87%E6%A1%A3%E5%9F%BA%E6%9C%AC%E6%93%8D%E4%BD%9C/%E4%B8%AA%E4%BA%BA%E7%AE%80%E5%8E%86.docx	个人简历.docx	399db672b6630fc365361f37c2712404a0c2376e927513751c03c8ca038c8238
WO-1-1	-	WO/1-1%20WPS%E6%96%87%E6%A1%A3%E5%9F%BA%E6%9C%AC%E6%93%8D%E4%BD%9C/%E6%88%91%E7%9A%84%E7%AC%AC%E4%B8%80%E4%B8%AAWPS%E6%96%87%E6%A1%A3.docx	我的第一个WPS文档.docx	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
WO-1-1	-	WO/1-1%20WPS%E6%96%87%E6%A1%A3%E5%9F%BA%E6%9C%AC%E6%93%8D%E4%BD%9C/%E8%87%AA%E8%8D%90%E4%BF%A1.docx	自荐信.docx	1fa4aab36330fc3b35fd6c88197a77fa89d9f70e32b6e6209183ffd8f0b7f2b2
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
