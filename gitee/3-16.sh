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
3-16	3-16-1	3-16%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E5%9B%9B%20WPS%20%E6%BC%94%E7%A4%BA%E6%96%87%E7%A8%BF%E6%94%BE%E6%98%A0%E4%B8%8E%E8%BE%93%E5%87%BA%20%E7%BB%BC%E5%90%88%E5%AE%9E%E8%B7%B5/test/6.4.3.pdf	test/6.4.3.pdf	8fcbb432db42e64149f6cfc96688d00c7306ee2b08e6b20a20b43c3d09b667de
3-16	3-16-1	3-16%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E5%9B%9B%20WPS%20%E6%BC%94%E7%A4%BA%E6%96%87%E7%A8%BF%E6%94%BE%E6%98%A0%E4%B8%8E%E8%BE%93%E5%87%BA%20%E7%BB%BC%E5%90%88%E5%AE%9E%E8%B7%B5/test/6.4.3.pptx	test/6.4.3.pptx	54704e82d618f92bfc6917cc98ec006df0fda3e07d128a3ba2d0710dc30e11dc
3-16	3-16-1	3-16%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E5%9B%9B%20WPS%20%E6%BC%94%E7%A4%BA%E6%96%87%E7%A8%BF%E6%94%BE%E6%98%A0%E4%B8%8E%E8%BE%93%E5%87%BA%20%E7%BB%BC%E5%90%88%E5%AE%9E%E8%B7%B5/test/test.pdf	test/test.pdf	1412cbeaa3d0f9b3fbc9e888adf2afe5e23ffe4edbf2be20d41c601079b6eefc
3-16	3-16-1	3-16%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E5%9B%9B%20WPS%20%E6%BC%94%E7%A4%BA%E6%96%87%E7%A8%BF%E6%94%BE%E6%98%A0%E4%B8%8E%E8%BE%93%E5%87%BA%20%E7%BB%BC%E5%90%88%E5%AE%9E%E8%B7%B5/test/test.pptx	test/test.pptx	8bcfc9b628f6d7d280045e70c5478275d5e4f4ec3b981656799b1ddaf9a1966c
3-16	3-16-1	3-16%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E5%9B%9B%20WPS%20%E6%BC%94%E7%A4%BA%E6%96%87%E7%A8%BF%E6%94%BE%E6%98%A0%E4%B8%8E%E8%BE%93%E5%87%BA%20%E7%BB%BC%E5%90%88%E5%AE%9E%E8%B7%B5/test/%E6%89%93%E5%8D%B01.pdf	test/打印1.pdf	d5d723ba48699ce2acfd46df2b33cef8fa1f0d71f34e6eccc94388c75cb074e6
3-16	3-16-1	3-16%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E5%9B%9B%20WPS%20%E6%BC%94%E7%A4%BA%E6%96%87%E7%A8%BF%E6%94%BE%E6%98%A0%E4%B8%8E%E8%BE%93%E5%87%BA%20%E7%BB%BC%E5%90%88%E5%AE%9E%E8%B7%B5/test/%E6%89%93%E5%8D%B02.pdf	test/打印2.pdf	3b4b8cc5ed8cd3ae6dfaba1f0a49addca415786858354bd4445c8fde2bd9b594
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
