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
2-21	2-21-1	2-21%20%E5%AE%9E%E9%AA%8C%E4%B9%9D%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B8%B8%E7%94%A8%E5%87%BD%E6%95%B02%EF%BC%88%E6%9F%A5%E6%89%BE%E4%B8%8E%E5%BA%94%E7%94%A8%E3%80%81%E9%80%BB%E8%BE%91%E3%80%81%E6%97%A5%E6%9C%9F%E5%92%8C%E6%97%B6%E9%97%B4%E5%87%BD%E6%95%B0%EF%BC%89/step1/VLOOKUP%20%E5%87%BD%E6%95%B0.xlsx	step1/VLOOKUP 函数.xlsx	1c6f782fb189950da6d5b687448970490462e65b4e81af09d9e171e5f90f7b8f
2-21	2-21-2	2-21%20%E5%AE%9E%E9%AA%8C%E4%B9%9D%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B8%B8%E7%94%A8%E5%87%BD%E6%95%B02%EF%BC%88%E6%9F%A5%E6%89%BE%E4%B8%8E%E5%BA%94%E7%94%A8%E3%80%81%E9%80%BB%E8%BE%91%E3%80%81%E6%97%A5%E6%9C%9F%E5%92%8C%E6%97%B6%E9%97%B4%E5%87%BD%E6%95%B0%EF%BC%89/step2/MATCH%E5%87%BD%E6%95%B0.xlsx	step2/MATCH函数.xlsx	3c045b044a91f5dfc6d195f307b0c6c3c43c05923ee5d91593009d57be2feffe
2-21	2-21-3	2-21%20%E5%AE%9E%E9%AA%8C%E4%B9%9D%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B8%B8%E7%94%A8%E5%87%BD%E6%95%B02%EF%BC%88%E6%9F%A5%E6%89%BE%E4%B8%8E%E5%BA%94%E7%94%A8%E3%80%81%E9%80%BB%E8%BE%91%E3%80%81%E6%97%A5%E6%9C%9F%E5%92%8C%E6%97%B6%E9%97%B4%E5%87%BD%E6%95%B0%EF%BC%89/step3/IF%E5%87%BD%E6%95%B0.xlsx	step3/IF函数.xlsx	85112dff8408b77f929c5dd4d288503d539ff666cfdeace33f78b0aa6852e432
2-21	2-21-4	2-21%20%E5%AE%9E%E9%AA%8C%E4%B9%9D%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B8%B8%E7%94%A8%E5%87%BD%E6%95%B02%EF%BC%88%E6%9F%A5%E6%89%BE%E4%B8%8E%E5%BA%94%E7%94%A8%E3%80%81%E9%80%BB%E8%BE%91%E3%80%81%E6%97%A5%E6%9C%9F%E5%92%8C%E6%97%B6%E9%97%B4%E5%87%BD%E6%95%B0%EF%BC%89/step4/AND%E5%87%BD%E6%95%B0.xlsx	step4/AND函数.xlsx	cdd61414b35809c131d8dcc4068f1226c1e73318f4bf2790b80cb4d1850ca297
2-21	2-21-5	2-21%20%E5%AE%9E%E9%AA%8C%E4%B9%9D%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B8%B8%E7%94%A8%E5%87%BD%E6%95%B02%EF%BC%88%E6%9F%A5%E6%89%BE%E4%B8%8E%E5%BA%94%E7%94%A8%E3%80%81%E9%80%BB%E8%BE%91%E3%80%81%E6%97%A5%E6%9C%9F%E5%92%8C%E6%97%B6%E9%97%B4%E5%87%BD%E6%95%B0%EF%BC%89/step5/OR%E5%87%BD%E6%95%B0.xlsx	step5/OR函数.xlsx	da01624dbe4261356c07446042d0ef644d3cb105974b19c693feb821a5b8e9c6
2-21	2-21-6	2-21%20%E5%AE%9E%E9%AA%8C%E4%B9%9D%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B8%B8%E7%94%A8%E5%87%BD%E6%95%B02%EF%BC%88%E6%9F%A5%E6%89%BE%E4%B8%8E%E5%BA%94%E7%94%A8%E3%80%81%E9%80%BB%E8%BE%91%E3%80%81%E6%97%A5%E6%9C%9F%E5%92%8C%E6%97%B6%E9%97%B4%E5%87%BD%E6%95%B0%EF%BC%89/step6/TODAY%E5%92%8CNOW%E5%87%BD%E6%95%B0.xlsx	step6/TODAY和NOW函数.xlsx	d9c99108890beee5f93cacdf3629537bc151ff9dc398cbcad0f7eb4b38413ee9
2-21	2-21-7	2-21%20%E5%AE%9E%E9%AA%8C%E4%B9%9D%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B8%B8%E7%94%A8%E5%87%BD%E6%95%B02%EF%BC%88%E6%9F%A5%E6%89%BE%E4%B8%8E%E5%BA%94%E7%94%A8%E3%80%81%E9%80%BB%E8%BE%91%E3%80%81%E6%97%A5%E6%9C%9F%E5%92%8C%E6%97%B6%E9%97%B4%E5%87%BD%E6%95%B0%EF%BC%89/step7/YEAR%E5%87%BD%E6%95%B0.xlsx	step7/YEAR函数.xlsx	436d7821b87d689b5f452e70d12c9146f187da9b9843e5129e3a84ef988d7d20
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
