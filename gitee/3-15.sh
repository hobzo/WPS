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
3-15	3-15-1	3-15%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E5%9B%9B%20WPS%20%E6%BC%94%E7%A4%BA%20%E8%BE%93%E5%87%BA/test/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.pdf	test/中国共产党党史.pdf	adda412674697cbab37017e4b98232b990047b647844ebe8081c74927338f9d6
3-15	3-15-1	3-15%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E5%9B%9B%20WPS%20%E6%BC%94%E7%A4%BA%20%E8%BE%93%E5%87%BA/test/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.ppt	test/中国共产党党史.ppt	b5f731ae2f83190c3f8369787fc0d8ed8fd31a7c8a7931084342796ce457cee9
3-15	3-15-1	3-15%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E5%9B%9B%20WPS%20%E6%BC%94%E7%A4%BA%20%E8%BE%93%E5%87%BA/test/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.pptx	test/中国共产党党史.pptx	183e26be0f6adde1de4e526575fc9c0e2f17083475d1d18bd4e7a0451267814c
3-15	3-15-2	3-15%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E5%9B%9B%20WPS%20%E6%BC%94%E7%A4%BA%20%E8%BE%93%E5%87%BA/test2/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.pdf	test2/中国共产党党史.pdf	994a226a5ff1ecc1702f3640403a0c6af61d82c6426e20253f2f3fe14103f172
3-15	3-15-2	3-15%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E5%9B%9B%20WPS%20%E6%BC%94%E7%A4%BA%20%E8%BE%93%E5%87%BA/test2/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.pptx	test2/中国共产党党史.pptx	183e26be0f6adde1de4e526575fc9c0e2f17083475d1d18bd4e7a0451267814c
3-15	3-15-3	3-15%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E5%9B%9B%20WPS%20%E6%BC%94%E7%A4%BA%20%E8%BE%93%E5%87%BA/test3/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.pdf	test3/中国共产党党史.pdf	efc3dc36346e34092539aebaedfbff160acb5da68819e8cec57cdec702a4c59c
3-15	3-15-3	3-15%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E5%9B%9B%20WPS%20%E6%BC%94%E7%A4%BA%20%E8%BE%93%E5%87%BA/test3/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.pptx	test3/中国共产党党史.pptx	183e26be0f6adde1de4e526575fc9c0e2f17083475d1d18bd4e7a0451267814c
3-15	3-15-4	3-15%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E5%9B%9B%20WPS%20%E6%BC%94%E7%A4%BA%20%E8%BE%93%E5%87%BA/test4/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.pptx	test4/中国共产党党史.pptx	183e26be0f6adde1de4e526575fc9c0e2f17083475d1d18bd4e7a0451267814c
3-15	3-15-4	3-15%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E5%9B%9B%20WPS%20%E6%BC%94%E7%A4%BA%20%E8%BE%93%E5%87%BA/test4/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B21.pdf	test4/中国共产党党史1.pdf	5ea6916d63ccb59e113f595d8808a1a43e5fd77d2ed3241687f222cb20d2d22c
3-15	3-15-4	3-15%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E5%9B%9B%20WPS%20%E6%BC%94%E7%A4%BA%20%E8%BE%93%E5%87%BA/test4/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B22.pdf	test4/中国共产党党史2.pdf	a00af0631677227bdac7142819bb1df6dad5059d52eb8af4d004b1917775ccb4
3-15	3-15-4	3-15%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E5%9B%9B%20WPS%20%E6%BC%94%E7%A4%BA%20%E8%BE%93%E5%87%BA/test4/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B23.pdf	test4/中国共产党党史3.pdf	e7c2f8f8f2e06f479800597b4206e51b78ad9a78f2855a99cbcd4123a1fa299d
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
