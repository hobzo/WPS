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
3-2	3-2-1	3-2%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E4%B8%80%20WPS%20%E6%BC%94%E7%A4%BA%20%E4%BD%BF%E7%94%A8%E6%AF%8D%E7%89%88%E5%88%9B%E5%BB%BA%E8%87%AA%E5%B7%B1%E7%9A%84%E6%BC%94%E7%A4%BA%E6%96%87%E7%A8%BF/test1/%E6%B5%8B%E8%AF%95.pptx	test1/测试.pptx	5e60aeb4f1fc73e92061393e4c57adc588a48dcf427bf441ce7dd2759b69a2b5
3-2	3-2-2	3-2%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E4%B8%80%20WPS%20%E6%BC%94%E7%A4%BA%20%E4%BD%BF%E7%94%A8%E6%AF%8D%E7%89%88%E5%88%9B%E5%BB%BA%E8%87%AA%E5%B7%B1%E7%9A%84%E6%BC%94%E7%A4%BA%E6%96%87%E7%A8%BF/test2/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.pptx	test2/中国共产党党史.pptx	b4b7c30966f32e9bd23d7d73a6406260e3759be5073b5103d8b7bc66e0525970
3-2	3-2-3	3-2%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E4%B8%80%20WPS%20%E6%BC%94%E7%A4%BA%20%E4%BD%BF%E7%94%A8%E6%AF%8D%E7%89%88%E5%88%9B%E5%BB%BA%E8%87%AA%E5%B7%B1%E7%9A%84%E6%BC%94%E7%A4%BA%E6%96%87%E7%A8%BF/test3/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.pptx	test3/中国共产党党史.pptx	813532310d85295c9f591caee1de8e854597a6265f4a3a5e3a6b8ec70cb06aab
3-2	3-2-3	3-2%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E4%B8%80%20WPS%20%E6%BC%94%E7%A4%BA%20%E4%BD%BF%E7%94%A8%E6%AF%8D%E7%89%88%E5%88%9B%E5%BB%BA%E8%87%AA%E5%B7%B1%E7%9A%84%E6%BC%94%E7%A4%BA%E6%96%87%E7%A8%BF/test3/%E6%B5%8B%E8%AF%95.pptx	test3/测试.pptx	239e120d447dbbfbbac8f3b370b4b1f7d540074128d0089e771848cf753762b1
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
