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
1-6	1-6-1	1-6%20%E5%88%B6%E4%BD%9C%E6%89%B9%E9%87%8F%E5%A4%84%E7%90%86%E6%96%87%E6%A1%A3/4.5.1/%E7%B4%A0%E6%9D%90/%E6%95%B0%E6%8D%AE%E6%BA%90.docx	4.5.1/素材/数据源.docx	7a7db868cda61ba02cd2ea2bd0f80a960f6f3c5a4fe66407ae48a1d37a9989de
1-6	1-6-1	1-6%20%E5%88%B6%E4%BD%9C%E6%89%B9%E9%87%8F%E5%A4%84%E7%90%86%E6%96%87%E6%A1%A3/4.5.1/%E7%B4%A0%E6%9D%90/%E9%82%80%E8%AF%B7%E5%87%BD.docx	4.5.1/素材/邀请函.docx	3a3389e20c63d2c77476ace9599f5d8e22ba1027e3ab3377a7dad0e933076a9c
1-6	1-6-1	1-6%20%E5%88%B6%E4%BD%9C%E6%89%B9%E9%87%8F%E5%A4%84%E7%90%86%E6%96%87%E6%A1%A3/4.5.1/%E7%B4%A0%E6%9D%90/%E9%82%80%E8%AF%B7%E5%87%BD%E5%90%88%E5%B9%B6.docx	4.5.1/素材/邀请函合并.docx	25fc8d8aa0dc7087aed6266d9bdf4abf16d74aa1c7a97a5a45717097b598c9da
1-6	1-6-2	1-6%20%E5%88%B6%E4%BD%9C%E6%89%B9%E9%87%8F%E5%A4%84%E7%90%86%E6%96%87%E6%A1%A3/4.5.2/%E7%B4%A0%E6%9D%90/%E5%87%86%E8%80%83%E8%AF%81.docx	4.5.2/素材/准考证.docx	7fee15db34fee18a8659d99249424023a2e471cc523d194037719e0ce2f695b9
1-6	1-6-2	1-6%20%E5%88%B6%E4%BD%9C%E6%89%B9%E9%87%8F%E5%A4%84%E7%90%86%E6%96%87%E6%A1%A3/4.5.2/%E7%B4%A0%E6%9D%90/%E6%95%B0%E5%AD%A6%E7%AB%9E%E8%B5%9B%E5%87%86%E8%80%83%E8%AF%81%E5%90%88%E5%B9%B6.docx	4.5.2/素材/数学竞赛准考证合并.docx	bb131d94cfbd0607bd82f6de7b002bd47f14dd5378c5d867f1e1518f720d12b0
1-6	1-6-3	1-6%20%E5%88%B6%E4%BD%9C%E6%89%B9%E9%87%8F%E5%A4%84%E7%90%86%E6%96%87%E6%A1%A3/4.5.3/%E6%88%90%E7%BB%A9%E5%8D%95%E5%90%88%E5%B9%B6.docx	4.5.3/成绩单合并.docx	1b83b8c5b0a86c27dce720e975a21d162c9bd4ce49d2c28f328522735877bc03
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
