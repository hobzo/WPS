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
1-2	1-2-1	1-2%20WPS%20%E6%96%87%E6%A1%A3%E6%A0%BC%E5%BC%8F%E7%9A%84%E7%BC%96%E8%BE%91/4.2.1/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.docx	4.2.1/中国共产党党史.docx	4c4fee7459a38014f4a1d1234648346c2d9f44d1c8eb62895b8f58dd3adb3d28
1-2	1-2-2	1-2%20WPS%20%E6%96%87%E6%A1%A3%E6%A0%BC%E5%BC%8F%E7%9A%84%E7%BC%96%E8%BE%91/4.2.2/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.docx	4.2.2/中国共产党党史.docx	5840b94828fe57dfcafb5e1062554ebee0f1e5c21b3a5008faae1d26d94b6752
1-2	1-2-3	1-2%20WPS%20%E6%96%87%E6%A1%A3%E6%A0%BC%E5%BC%8F%E7%9A%84%E7%BC%96%E8%BE%91/4.2.3/%E5%AD%A6%E6%9C%AF%E8%AE%BA%E6%96%87.docx	4.2.3/学术论文.docx	1943093554ed9d7cf13ebf869e2dac5cb9a70212c3bbad026df2157af9459dff
1-2	1-2-4	1-2%20WPS%20%E6%96%87%E6%A1%A3%E6%A0%BC%E5%BC%8F%E7%9A%84%E7%BC%96%E8%BE%91/4.2.4/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.docx	4.2.4/中国共产党党史.docx	e3cc7146c2074ad4115d6429d78657c75f82ace47b7cdc8ed203801b07bf6c39
1-2	1-2-5	1-2%20WPS%20%E6%96%87%E6%A1%A3%E6%A0%BC%E5%BC%8F%E7%9A%84%E7%BC%96%E8%BE%91/4.2.5/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.docx	4.2.5/中国共产党党史.docx	c44adcef57d77a6c4f9e5177a1a004c470078c1c6b8fb1aba924dc8522849ca7
1-2	1-2-6	1-2%20WPS%20%E6%96%87%E6%A1%A3%E6%A0%BC%E5%BC%8F%E7%9A%84%E7%BC%96%E8%BE%91/4.2.6/%E7%94%B5%E8%A7%86%E5%89%A7%E8%B1%86%E7%93%A3%E8%AF%84%E5%88%86%E6%8E%92%E8%A1%8C%E6%A6%9C.docx	4.2.6/电视剧豆瓣评分排行榜.docx	c49255370c38e2bcb4a59d51e08aff7178c726ee31ab3c1098b602a09f4b381b
1-2	1-2-7	1-2%20WPS%20%E6%96%87%E6%A1%A3%E6%A0%BC%E5%BC%8F%E7%9A%84%E7%BC%96%E8%BE%91/4.2.7/%E6%9C%8D%E5%8A%A1%E5%99%A8%E5%80%9F%E7%94%A8%E5%90%88%E5%90%8C.docx	4.2.7/服务器借用合同.docx	750a21dc63d7b6cf2c5e86aff9735d477562f7326790f46d8aea78089f958c3a
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
