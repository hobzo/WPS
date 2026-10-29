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
WO-1-3	-	WO/1-3%20WPS%E6%8F%92%E5%85%A5%E6%93%8D%E4%BD%9C/%E6%8F%92%E5%85%A5%E6%B5%81%E7%A8%8B%E5%9B%BE%E5%92%8CSmartArt%E5%9B%BE%E5%BD%A2.docx	插入流程图和SmartArt图形.docx	1cb711de35edb29f1fe979f2bfe2b0b27f88302c52f5297fec979dae706ef1cc
WO-1-3	-	WO/1-3%20WPS%E6%8F%92%E5%85%A5%E6%93%8D%E4%BD%9C/%E6%AF%95%E4%B8%9A%E8%AE%BA%E6%96%87.docx	毕业论文.docx	381c48806342f244e600ed735afbdcf5c18b67e6ebe81d541e132c7d72d3c510
WO-1-3	-	WO/1-3%20WPS%E6%8F%92%E5%85%A5%E6%93%8D%E4%BD%9C/%E6%AF%95%E4%B8%9A%E8%AE%BA%E6%96%87%E5%B0%81%E9%9D%A2.docx	毕业论文封面.docx	2f5beeb0f1aab7dd17d1a441697f748da14f4611103e8b2b60c95985b13a0620
WO-1-3	-	WO/1-3%20WPS%E6%8F%92%E5%85%A5%E6%93%8D%E4%BD%9C/%E6%AF%95%E4%B8%9A%E8%AE%BA%E6%96%87%E6%8E%92%E7%89%88.docx	毕业论文排版.docx	10af0016c20b76fa390dc309ecd246dac4d007fecb5d8756dd4218c14370df4b
WO-1-3	-	WO/1-3%20WPS%E6%8F%92%E5%85%A5%E6%93%8D%E4%BD%9C/%E7%9B%AE%E5%BD%95.docx	目录.docx	9692f960653e2c49495b3b307d5cd4ecd05c175cecea9f2ba3ef2c218006b9bb
WO-1-3	-	WO/1-3%20WPS%E6%8F%92%E5%85%A5%E6%93%8D%E4%BD%9C/%E8%AE%BA%E6%96%87.docx	论文.docx	d6b9023d9a2be19259afdaff2f9559d32d412a84e2eb78c5c35e483ac02af4c8
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
