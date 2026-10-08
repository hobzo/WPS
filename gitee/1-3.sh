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
1-3	1-3-1	1-3%20WPS%20%E7%9A%84%E5%9B%BE%E7%89%87%E5%92%8C%E8%A1%A8%E6%A0%BC%E7%9A%84%E5%A4%84%E7%90%86/4.3.1/%E6%B5%8B%E8%AF%95.docx	4.3.1/测试.docx	906b1f2a7eb8f986f9bbdc41fb738be745c264dae87415b19ca2ed85ebec3ebe
1-3	1-3-2	1-3%20WPS%20%E7%9A%84%E5%9B%BE%E7%89%87%E5%92%8C%E8%A1%A8%E6%A0%BC%E7%9A%84%E5%A4%84%E7%90%86/4.3.2/%E7%B4%A0%E6%9D%90%E5%86%AC%E5%A5%A5%E4%BC%9A.docx	4.3.2/素材冬奥会.docx	aa92f213dee9156b3dc4f12e6666e01d8e5be59f037f183f256686a420c98174
1-3	1-3-3	1-3%20WPS%20%E7%9A%84%E5%9B%BE%E7%89%87%E5%92%8C%E8%A1%A8%E6%A0%BC%E7%9A%84%E5%A4%84%E7%90%86/4.3.3/%E7%B4%A0%E6%9D%90%E5%86%AC%E5%A5%A5%E4%BC%9A-%E8%89%BA%E6%9C%AF%E5%AD%97.docx	4.3.3/素材冬奥会-艺术字.docx	420e992f77a21e8f6cf4854fd1fea68e7013235e272d6af409daa968ec227d7c
1-3	1-3-4	1-3%20WPS%20%E7%9A%84%E5%9B%BE%E7%89%87%E5%92%8C%E8%A1%A8%E6%A0%BC%E7%9A%84%E5%A4%84%E7%90%86/4.3.4/%E8%87%AA%E9%80%89%E5%9B%BE%E5%BD%A2%E5%BA%94%E7%94%A8.docx	4.3.4/自选图形应用.docx	dca156afded68bd0d46d468496e195f9e269571e78fba596f9e4b3e6a798ef24
1-3	1-3-5	1-3%20WPS%20%E7%9A%84%E5%9B%BE%E7%89%87%E5%92%8C%E8%A1%A8%E6%A0%BC%E7%9A%84%E5%A4%84%E7%90%86/4.3.5/%E7%B4%A0%E6%9D%90%E8%80%83%E7%94%9F%E5%9F%BA%E6%9C%AC%E4%BF%A1%E6%81%AF%E8%A1%A8.docx	4.3.5/素材考生基本信息表.docx	0cc8e5d575e7f451f87989565c2d546bf3f57ae8eac031835cc075b575f49d21
1-3	1-3-6	1-3%20WPS%20%E7%9A%84%E5%9B%BE%E7%89%87%E5%92%8C%E8%A1%A8%E6%A0%BC%E7%9A%84%E5%A4%84%E7%90%86/4.3.6/xx%E5%8D%95%E4%BD%8D%E5%B7%AE%E6%97%85%E6%8A%A5%E9%94%80%E5%8D%95.docx	4.3.6/xx单位差旅报销单.docx	d99d44e51ec522eb37b3456deace6dcad3cde6c797d07002088943b96d109599
1-3	1-3-7	1-3%20WPS%20%E7%9A%84%E5%9B%BE%E7%89%87%E5%92%8C%E8%A1%A8%E6%A0%BC%E7%9A%84%E5%A4%84%E7%90%86/4.3.7/%E7%94%B5%E5%AD%90%E5%B0%8F%E6%8A%A5.docx	4.3.7/电子小报.docx	ba7d9a7197061e07e659c8acf51b262f7e3f2562be7e2663544728817ba2b742
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
