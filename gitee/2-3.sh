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
2-3	2-3-1	2-3%20%E5%AE%9E%E9%AA%8C%E5%85%AD%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%BD%95%E5%85%A5%E6%95%B0%E6%8D%AE/src/%E5%A1%AB%E5%85%85%E6%95%B0%E6%8D%AE.xlsx	src/填充数据.xlsx	89d652f8e5a852976c384a638394e094e2c3ae0c696449dd177d76a0ec2ecb56
2-3	2-3-1	2-3%20%E5%AE%9E%E9%AA%8C%E5%85%AD%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%BD%95%E5%85%A5%E6%95%B0%E6%8D%AE/src/%E5%BD%95%E5%85%A5%E6%95%B0%E5%80%BC%E5%9E%8B%E6%95%B0%E6%8D%AE.xlsx	src/录入数值型数据.xlsx	588266b1419e36da4877f10c58de3db9b94a780420018cb26c2f3c465073d575
2-3	2-3-1	2-3%20%E5%AE%9E%E9%AA%8C%E5%85%AD%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%BD%95%E5%85%A5%E6%95%B0%E6%8D%AE/src/%E5%BD%95%E5%85%A5%E6%96%87%E6%9C%AC%E5%9E%8B%E6%95%B0%E6%8D%AE.xlsx	src/录入文本型数据.xlsx	6cf9ec2406a3742b7d4f71a5f5703717cc4a2cd06c5a3c497443df0b4f3aeed3
2-3	2-3-1	2-3%20%E5%AE%9E%E9%AA%8C%E5%85%AD%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%BD%95%E5%85%A5%E6%95%B0%E6%8D%AE/src/%E5%BD%95%E5%85%A5%E6%97%A5%E6%9C%9F%E5%9E%8B%E6%95%B0%E6%8D%AE.xlsx	src/录入日期型数据.xlsx	72668fe4fd626ed08285f42624f018b00092a0d5825afa74f49ed2e202eb6d43
2-3	2-3-1	2-3%20%E5%AE%9E%E9%AA%8C%E5%85%AD%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%BD%95%E5%85%A5%E6%95%B0%E6%8D%AE/src/%E9%99%90%E5%88%B6%E6%95%B0%E6%8D%AE%E5%BD%95%E5%85%A5%E8%8C%83%E5%9B%B4.xlsx	src/限制数据录入范围.xlsx	eb155f8d9c46fa7f3b884dfcfc79ebcc264f52ef490b2138c40ac8a1b5e62384
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
