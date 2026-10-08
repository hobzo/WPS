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
1-4	1-4-1	1-4%20WPS%20%E6%96%87%E6%A1%A3%E6%8E%92%E7%89%88/4.4.2/%E6%96%87%E6%A1%A31.docx	4.4.2/文档1.docx	da4940ec0f0c456a511fe9eac31636222e4451e7367266c1c6bb3588907aa740
1-4	1-4-2	1-4%20WPS%20%E6%96%87%E6%A1%A3%E6%8E%92%E7%89%88/4.4.3/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2%E7%B4%A0%E6%9D%90.docx	4.4.3/中国共产党党史素材.docx	d1077118481a9575abc7990e07150f915504e235b393bdd4ba1b4c92a79215b2
1-4	1-4-3	1-4%20WPS%20%E6%96%87%E6%A1%A3%E6%8E%92%E7%89%88/4.4.4/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.docx	4.4.4/中国共产党党史.docx	81f52212d3f002fcded638a4f842a4c0fdd4f3264f5dbc80510a43014d27a346
1-4	1-4-4	1-4%20WPS%20%E6%96%87%E6%A1%A3%E6%8E%92%E7%89%88/step4_SetType/%E5%A4%9A%E5%AA%92%E4%BD%93%E4%BF%A1%E6%81%AF%E5%A4%84%E7%90%86%E5%B7%A5%E5%85%B7%E4%BB%8B%E7%BB%8D.docx	step4_SetType/多媒体信息处理工具介绍.docx	df22d1887e3ecb779aeb0a68fbcef80da8e83e5916a5e45479cb2fccfb40aff1
1-4	1-4-5	1-4%20WPS%20%E6%96%87%E6%A1%A3%E6%8E%92%E7%89%88/step6_InsertFoot/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.docx	step6_InsertFoot/中国共产党党史.docx	a67442c29ced210910e3fec8009c88d8c2d5a9cc0839c25d3bc367695a3d5549
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
