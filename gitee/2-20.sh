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
2-20	2-20-1	2-20%20%E5%AE%9E%E9%AA%8C%E5%85%AB%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B8%B8%E7%94%A8%E5%87%BD%E6%95%B01%EF%BC%88%E6%B1%82%E5%92%8C%E3%80%81%E7%BB%9F%E8%AE%A1%E5%87%BD%E6%95%B0%EF%BC%89/step1/%E6%B1%82%E5%92%8C%E5%87%BD%E6%95%B0.xlsx	step1/求和函数.xlsx	51aa96103481d860e6f2d6b35498f53e3591a05f84d32e28033de6cd94b72333
2-20	2-20-2	2-20%20%E5%AE%9E%E9%AA%8C%E5%85%AB%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B8%B8%E7%94%A8%E5%87%BD%E6%95%B01%EF%BC%88%E6%B1%82%E5%92%8C%E3%80%81%E7%BB%9F%E8%AE%A1%E5%87%BD%E6%95%B0%EF%BC%89/step2/AVERAGE%E5%87%BD%E6%95%B0.xlsx	step2/AVERAGE函数.xlsx	bab6d28dd45336b737e84708345e0d0e20d98bc6912e349288743a8f4d7beecd
2-20	2-20-3	2-20%20%E5%AE%9E%E9%AA%8C%E5%85%AB%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B8%B8%E7%94%A8%E5%87%BD%E6%95%B01%EF%BC%88%E6%B1%82%E5%92%8C%E3%80%81%E7%BB%9F%E8%AE%A1%E5%87%BD%E6%95%B0%EF%BC%89/step3/AVERAGEIF%E5%87%BD%E6%95%B0.xlsx	step3/AVERAGEIF函数.xlsx	d9651b217b07495645403f9b4b5f10febfab4ef8b1ed8a7e3899f910d23cb59e
2-20	2-20-4	2-20%20%E5%AE%9E%E9%AA%8C%E5%85%AB%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B8%B8%E7%94%A8%E5%87%BD%E6%95%B01%EF%BC%88%E6%B1%82%E5%92%8C%E3%80%81%E7%BB%9F%E8%AE%A1%E5%87%BD%E6%95%B0%EF%BC%89/step4/COUNT%E5%87%BD%E6%95%B0.xlsx	step4/COUNT函数.xlsx	3fe5d7f4173ce3618b3dcb7cc5f09440a6c21703663a398fb6a11e0934491055
2-20	2-20-5	2-20%20%E5%AE%9E%E9%AA%8C%E5%85%AB%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B8%B8%E7%94%A8%E5%87%BD%E6%95%B01%EF%BC%88%E6%B1%82%E5%92%8C%E3%80%81%E7%BB%9F%E8%AE%A1%E5%87%BD%E6%95%B0%EF%BC%89/step5/COUNTIF%E5%87%BD%E6%95%B0.xlsx	step5/COUNTIF函数.xlsx	03b126916d4712f592ccc53f07763f9607f7bfeb4f5ac6ebb26e12cb7c4fde57
2-20	2-20-6	2-20%20%E5%AE%9E%E9%AA%8C%E5%85%AB%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B8%B8%E7%94%A8%E5%87%BD%E6%95%B01%EF%BC%88%E6%B1%82%E5%92%8C%E3%80%81%E7%BB%9F%E8%AE%A1%E5%87%BD%E6%95%B0%EF%BC%89/step6/MAX%E5%92%8CMIN%E5%87%BD%E6%95%B0.xlsx	step6/MAX和MIN函数.xlsx	6fc8146fd390b486b30d66c757edbfde02cc296eea2acebf2fde0b8009396292
2-20	2-20-7	2-20%20%E5%AE%9E%E9%AA%8C%E5%85%AB%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B8%B8%E7%94%A8%E5%87%BD%E6%95%B01%EF%BC%88%E6%B1%82%E5%92%8C%E3%80%81%E7%BB%9F%E8%AE%A1%E5%87%BD%E6%95%B0%EF%BC%89/step7/RANK%E5%87%BD%E6%95%B0.xlsx	step7/RANK函数.xlsx	59cee5048c7222c63e7f1cf8f6d53265574405d5f5cfeb546e0839a838ea54f4
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
