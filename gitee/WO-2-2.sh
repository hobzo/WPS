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
WO-2-2	WO-2-2-1	WO/2-2%20%E5%88%B6%E4%BD%9C%E9%A6%96%E9%A1%B5%E5%B7%A5%E4%BD%9C%E8%A1%A8/step1/my.xlsx	step1/my.xlsx	975a32b6fb0e5e0df5e6c303f8611a93295737991a07ec31b96b276e76f1f5b5
WO-2-2	WO-2-2-2	WO/2-2%20%E5%88%B6%E4%BD%9C%E9%A6%96%E9%A1%B5%E5%B7%A5%E4%BD%9C%E8%A1%A8/step2/my.xlsx	step2/my.xlsx	6bb54702162bb9cfbaf6194cba8822fdfe31f5f0b8e8e50639675510a3bea353
WO-2-2	WO-2-2-3	WO/2-2%20%E5%88%B6%E4%BD%9C%E9%A6%96%E9%A1%B5%E5%B7%A5%E4%BD%9C%E8%A1%A8/step3/my.xlsx	step3/my.xlsx	6a00770aa4308adf44ec580fbc8f8d8dd60150cd396a44504d96a36eec5dc0de
WO-2-2	WO-2-2-4	WO/2-2%20%E5%88%B6%E4%BD%9C%E9%A6%96%E9%A1%B5%E5%B7%A5%E4%BD%9C%E8%A1%A8/step4/my.xlsx	step4/my.xlsx	32dc8d101188612032870f767628d4544aa5ff63ae9e56eec1cd0156ae83b4d7
WO-2-2	WO-2-2-5	WO/2-2%20%E5%88%B6%E4%BD%9C%E9%A6%96%E9%A1%B5%E5%B7%A5%E4%BD%9C%E8%A1%A8/step5/timg.jpg	step5/timg.jpg	1050ad4b97ad2292c13c25a70fa67fd087f6e0ea056f1914d7a2d62aa45e93e7
WO-2-2	WO-2-2-5	WO/2-2%20%E5%88%B6%E4%BD%9C%E9%A6%96%E9%A1%B5%E5%B7%A5%E4%BD%9C%E8%A1%A8/step5/%E9%A6%96%E9%A1%B5%E5%B7%A5%E4%BD%9C%E8%A1%A8.xlsx	step5/首页工作表.xlsx	a58e9a36d542b2a863fd2dfffa1e87ef6efb543132a8d0886d9fcd66dc5474c8
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
