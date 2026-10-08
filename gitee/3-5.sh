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
3-5	3-5-1	3-5%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E4%BA%8C%20WPS%20%E6%BC%94%E7%A4%BA%20%E5%BD%A2%E7%8A%B6/test1/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.pptx	test1/中国共产党党史.pptx	7a892003f0090d7f743ef1ca250c4604add840510eb150318c60a76878c39416
3-5	3-5-2	3-5%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E4%BA%8C%20WPS%20%E6%BC%94%E7%A4%BA%20%E5%BD%A2%E7%8A%B6/test2/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.pptx	test2/中国共产党党史.pptx	775e601d88d2dabc89cc281cc725e1cb9765fe15cb341a0fc6e1a59bacf888bc
3-5	3-5-3	3-5%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E4%BA%8C%20WPS%20%E6%BC%94%E7%A4%BA%20%E5%BD%A2%E7%8A%B6/test3/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.pptx	test3/中国共产党党史.pptx	8e3c2afd462617e320194f8d8f057044d02522b20c7bd7b6b909c320519ca8ac
3-5	3-5-4	3-5%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E4%BA%8C%20WPS%20%E6%BC%94%E7%A4%BA%20%E5%BD%A2%E7%8A%B6/test4/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.pptx	test4/中国共产党党史.pptx	3da6a24b35610866c6b775e752245bc17ace8bbfc9b6cce7c458550258f5e31e
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
