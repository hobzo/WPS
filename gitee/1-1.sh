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
1-1	1-1-1	1-1%20WPS%20%E6%96%87%E5%AD%97%E5%9F%BA%E6%9C%AC%E6%93%8D%E4%BD%9C/03/%E6%96%87%E6%A1%A31.docx	03/文档1.docx	29903d81da2d46e32e27cda9995b3e7570eb910f795dc66565fae947a61b9d79
1-1	1-1-2	1-1%20WPS%20%E6%96%87%E5%AD%97%E5%9F%BA%E6%9C%AC%E6%93%8D%E4%BD%9C/04/%E4%B8%83%E4%B8%80%E8%AE%B2%E8%AF%9D%E8%8A%82%E9%80%89.docx	04/七一讲话节选.docx	a570f374e75ed53a95d2ac3e0d80a4ca4a1bc4499f65a0945176f715e655a2c1
1-1	1-1-2	1-1%20WPS%20%E6%96%87%E5%AD%97%E5%9F%BA%E6%9C%AC%E6%93%8D%E4%BD%9C/04/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.docx	04/中国共产党党史.docx	4b381e4df982b366970ef9d96ed104dcd5069badbaa2a27d28951ed649f8d0cd
1-1	1-1-3	1-1%20WPS%20%E6%96%87%E5%AD%97%E5%9F%BA%E6%9C%AC%E6%93%8D%E4%BD%9C/05/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.docx	05/中国共产党党史.docx	39079102f607273299021b18c0796925fac741f541bbbd56c31214562b2ae873
1-1	1-1-3	1-1%20WPS%20%E6%96%87%E5%AD%97%E5%9F%BA%E6%9C%AC%E6%93%8D%E4%BD%9C/05/%E5%A4%8D%E5%88%B6%E6%AE%B5%E8%90%BD.docx	05/复制段落.docx	dcc97b03587f700645372aad0a1e2abafc9b18475e4b282e8b7221705e808ba6
1-1	1-1-4	1-1%20WPS%20%E6%96%87%E5%AD%97%E5%9F%BA%E6%9C%AC%E6%93%8D%E4%BD%9C/06/%E5%9B%BE%E4%B9%A6%E7%AE%A1%E7%90%86%E5%88%B6%E5%BA%A6.docx	06/图书管理制度.docx	c12e7db235e3a101bd8e11958f5521a53ec79190ee61f33f21ac35f2adb35eb7
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
