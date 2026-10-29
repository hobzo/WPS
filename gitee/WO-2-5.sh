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
WO-2-5	WO-2-5-1	WO/2-5%20%E5%88%B6%E4%BD%9C%E5%AD%A6%E7%94%9F%E6%A1%A3%E6%A1%88%E8%A1%A8/step1/my.xlsx	step1/my.xlsx	f7e5ecd5c14b37a12bfdea3cf9ca88a2d47e75476b0fdf3f24f79ef5129f0139
WO-2-5	WO-2-5-2	WO/2-5%20%E5%88%B6%E4%BD%9C%E5%AD%A6%E7%94%9F%E6%A1%A3%E6%A1%88%E8%A1%A8/step2/my.xlsx	step2/my.xlsx	21db83abbfe5761659b9bbeac6a074b712615fc5b79cc047696f86ff7c484469
WO-2-5	WO-2-5-2	WO/2-5%20%E5%88%B6%E4%BD%9C%E5%AD%A6%E7%94%9F%E6%A1%A3%E6%A1%88%E8%A1%A8/step2/my1.xlsx	step2/my1.xlsx	a62283fb903af2a9bb0c9be2f2fa9c35c05937bf12dd51951fe36f2472350ab0
WO-2-5	WO-2-5-3	WO/2-5%20%E5%88%B6%E4%BD%9C%E5%AD%A6%E7%94%9F%E6%A1%A3%E6%A1%88%E8%A1%A8/step3/my.xlsx	step3/my.xlsx	84a06cf8bb48c01a7420871e57c3f093b173743ba74fc8d6182428fce355e802
WO-2-5	WO-2-5-4	WO/2-5%20%E5%88%B6%E4%BD%9C%E5%AD%A6%E7%94%9F%E6%A1%A3%E6%A1%88%E8%A1%A8/step4/my1.xlsx	step4/my1.xlsx	54f017cce52bee98ec3c4b2ea608196d902bcc8de7e83419b9154cf9e13579b0
WO-2-5	WO-2-5-4	WO/2-5%20%E5%88%B6%E4%BD%9C%E5%AD%A6%E7%94%9F%E6%A1%A3%E6%A1%88%E8%A1%A8/step4/student.xlsx	step4/student.xlsx	e1c264d147fe2cd2f6a99366cbd63f83e0c52539450b6d86495bee717ffdda76
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
