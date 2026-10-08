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
2-11	2-11-1	2-11%20%E5%AE%9E%E9%AA%8C%E5%8D%81%20WPS%20%E8%A1%A8%E6%A0%BC%20%E7%94%A8%E6%95%B0%E6%8D%AE%E9%80%8F%E8%A7%86%E8%A1%A8%E5%8A%A8%E6%80%81%E5%88%86%E6%9E%90%E6%95%B0%E6%8D%AE/step1/%E5%88%9B%E5%BB%BA%E6%95%B0%E6%8D%AE%E9%80%8F%E8%A7%86%E8%A1%A8.xlsx	step1/创建数据透视表.xlsx	75d719b479e9cabf0f2d14c8eb469acccfe32cab146fd1934707e081c33d68e4
2-11	2-11-2	2-11%20%E5%AE%9E%E9%AA%8C%E5%8D%81%20WPS%20%E8%A1%A8%E6%A0%BC%20%E7%94%A8%E6%95%B0%E6%8D%AE%E9%80%8F%E8%A7%86%E8%A1%A8%E5%8A%A8%E6%80%81%E5%88%86%E6%9E%90%E6%95%B0%E6%8D%AE/step2/%E8%AE%BE%E7%BD%AE%E6%95%B0%E6%8D%AE%E9%80%8F%E8%A7%86%E8%A1%A8%E5%AD%97%E6%AE%B5.xlsx	step2/设置数据透视表字段.xlsx	85cad98d661a0b3bc7507ea17225b66679ddfba786977ff0cc57726a7de3be7c
2-11	2-11-3	2-11%20%E5%AE%9E%E9%AA%8C%E5%8D%81%20WPS%20%E8%A1%A8%E6%A0%BC%20%E7%94%A8%E6%95%B0%E6%8D%AE%E9%80%8F%E8%A7%86%E8%A1%A8%E5%8A%A8%E6%80%81%E5%88%86%E6%9E%90%E6%95%B0%E6%8D%AE/step3/%E7%BE%8E%E5%8C%96%E6%95%B0%E6%8D%AE%E9%80%8F%E8%A7%86%E8%A1%A8.xlsx	step3/美化数据透视表.xlsx	898905d8da127de64a781c5cd04b9d29bea6563326cd9fa5cf47eff05f0aedba
2-11	2-11-4	2-11%20%E5%AE%9E%E9%AA%8C%E5%8D%81%20WPS%20%E8%A1%A8%E6%A0%BC%20%E7%94%A8%E6%95%B0%E6%8D%AE%E9%80%8F%E8%A7%86%E8%A1%A8%E5%8A%A8%E6%80%81%E5%88%86%E6%9E%90%E6%95%B0%E6%8D%AE/step4/%E5%9C%A8%E6%95%B0%E6%8D%AE%E9%80%8F%E8%A7%86%E8%A1%A8%E4%B8%AD%E6%89%A7%E8%A1%8C%E7%AD%9B%E9%80%89.xlsx	step4/在数据透视表中执行筛选.xlsx	627a844ce991e8060d283158db36d2e619f44e8f8af2217638f0ca9dd9aafa29
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
