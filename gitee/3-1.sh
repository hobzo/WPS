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
3-1	3-1-1	3-1%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E4%B8%80%20WPS%20%E6%BC%94%E7%A4%BA%20%E5%88%9D%E5%AD%A6%E8%80%85%E5%88%B6%E4%BD%9C%E6%BC%94%E7%A4%BA%E6%96%87%E7%A8%BF/res/.gitkeep	res/.gitkeep	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
3-1	3-1-1	3-1%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E4%B8%80%20WPS%20%E6%BC%94%E7%A4%BA%20%E5%88%9D%E5%AD%A6%E8%80%85%E5%88%B6%E4%BD%9C%E6%BC%94%E7%A4%BA%E6%96%87%E7%A8%BF/res/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.pptx	res/中国共产党党史.pptx	532f4c792f3864c043bfd9f647cbd38b6a7541746d0b4777152a48c63262ea31
3-1	3-1-2	3-1%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E4%B8%80%20WPS%20%E6%BC%94%E7%A4%BA%20%E5%88%9D%E5%AD%A6%E8%80%85%E5%88%B6%E4%BD%9C%E6%BC%94%E7%A4%BA%E6%96%87%E7%A8%BF/test3/.gitkeep	test3/.gitkeep	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
3-1	3-1-2	3-1%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E4%B8%80%20WPS%20%E6%BC%94%E7%A4%BA%20%E5%88%9D%E5%AD%A6%E8%80%85%E5%88%B6%E4%BD%9C%E6%BC%94%E7%A4%BA%E6%96%87%E7%A8%BF/test3/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.pptx	test3/中国共产党党史.pptx	1a6925a0ecb708245a4ba7a47c1c223f70f19b8480e310daddd22c6db16a5805
3-1	3-1-3	3-1%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E4%B8%80%20WPS%20%E6%BC%94%E7%A4%BA%20%E5%88%9D%E5%AD%A6%E8%80%85%E5%88%B6%E4%BD%9C%E6%BC%94%E7%A4%BA%E6%96%87%E7%A8%BF/test4/.gitkeep	test4/.gitkeep	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
3-1	3-1-3	3-1%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E4%B8%80%20WPS%20%E6%BC%94%E7%A4%BA%20%E5%88%9D%E5%AD%A6%E8%80%85%E5%88%B6%E4%BD%9C%E6%BC%94%E7%A4%BA%E6%96%87%E7%A8%BF/test4/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.pptx	test4/中国共产党党史.pptx	e9686466a2f0c01886e762dbff450e2dfd713d53ba799c55b86ba380136adf52
3-1	3-1-4	3-1%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E4%B8%80%20WPS%20%E6%BC%94%E7%A4%BA%20%E5%88%9D%E5%AD%A6%E8%80%85%E5%88%B6%E4%BD%9C%E6%BC%94%E7%A4%BA%E6%96%87%E7%A8%BF/test5/.gitkeep	test5/.gitkeep	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
3-1	3-1-4	3-1%20%E5%AE%9E%E9%AA%8C%E5%8D%81%E4%B8%80%20WPS%20%E6%BC%94%E7%A4%BA%20%E5%88%9D%E5%AD%A6%E8%80%85%E5%88%B6%E4%BD%9C%E6%BC%94%E7%A4%BA%E6%96%87%E7%A8%BF/test5/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.pptx	test5/中国共产党党史.pptx	dfc9a718ccd6bb93b0fca231e72381f391c337c7625f59b94fc6bd97d27a6294
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
