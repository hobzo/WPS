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
2-1	2-1-1	2-1%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B7%A5%E4%BD%9C%E7%B0%BF%E4%B8%8E%E5%B7%A5%E4%BD%9C%E8%A1%A8%E7%9A%84%E5%9F%BA%E6%9C%AC%E6%93%8D%E4%BD%9C/step1/.gitkeep	step1/.gitkeep	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
2-1	2-1-1	2-1%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B7%A5%E4%BD%9C%E7%B0%BF%E4%B8%8E%E5%B7%A5%E4%BD%9C%E8%A1%A8%E7%9A%84%E5%9F%BA%E6%9C%AC%E6%93%8D%E4%BD%9C/step1/%E5%B7%A5%E4%BD%9C%E7%B0%BF1.xlsx	step1/工作簿1.xlsx	fa55db4ae49912d55cab9bb2bc2eeffecc923c97743c8a8c070919c1ca8ebb5a
2-1	2-1-2	2-1%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B7%A5%E4%BD%9C%E7%B0%BF%E4%B8%8E%E5%B7%A5%E4%BD%9C%E8%A1%A8%E7%9A%84%E5%9F%BA%E6%9C%AC%E6%93%8D%E4%BD%9C/step2/.gitkeep	step2/.gitkeep	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
2-1	2-1-2	2-1%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B7%A5%E4%BD%9C%E7%B0%BF%E4%B8%8E%E5%B7%A5%E4%BD%9C%E8%A1%A8%E7%9A%84%E5%9F%BA%E6%9C%AC%E6%93%8D%E4%BD%9C/step2/%E6%8F%92%E5%85%A5%E5%8F%8A%E5%88%A0%E9%99%A4%E5%B7%A5%E4%BD%9C%E8%A1%A8.xlsx	step2/插入及删除工作表.xlsx	ce2a32cc578c5f9dee4ce9000dcb43010a01595b6fdddeffaa53909513d00500
2-1	2-1-3	2-1%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B7%A5%E4%BD%9C%E7%B0%BF%E4%B8%8E%E5%B7%A5%E4%BD%9C%E8%A1%A8%E7%9A%84%E5%9F%BA%E6%9C%AC%E6%93%8D%E4%BD%9C/step5/.gitkeep	step5/.gitkeep	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
2-1	2-1-3	2-1%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B7%A5%E4%BD%9C%E7%B0%BF%E4%B8%8E%E5%B7%A5%E4%BD%9C%E8%A1%A8%E7%9A%84%E5%9F%BA%E6%9C%AC%E6%93%8D%E4%BD%9C/step5/%E7%A7%BB%E5%8A%A8%E4%B8%8E%E5%A4%8D%E5%88%B6%E5%B7%A5%E4%BD%9C%E8%A1%A8.xlsx	step5/移动与复制工作表.xlsx	06183ac8b7b87f74b36159fc2425a56b293c6320f77ef2ecf363b8f9c5753ffd
2-1	2-1-4	2-1%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B7%A5%E4%BD%9C%E7%B0%BF%E4%B8%8E%E5%B7%A5%E4%BD%9C%E8%A1%A8%E7%9A%84%E5%9F%BA%E6%9C%AC%E6%93%8D%E4%BD%9C/step6/.gitkeep	step6/.gitkeep	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
2-1	2-1-4	2-1%20WPS%20%E8%A1%A8%E6%A0%BC%20%E5%B7%A5%E4%BD%9C%E7%B0%BF%E4%B8%8E%E5%B7%A5%E4%BD%9C%E8%A1%A8%E7%9A%84%E5%9F%BA%E6%9C%AC%E6%93%8D%E4%BD%9C/step6/%E5%B7%A5%E4%BD%9C%E8%A1%A8%E6%A0%87%E7%AD%BE%E8%AE%BE%E7%BD%AE.xlsx	step6/工作表标签设置.xlsx	b6cfd7e8b4941e594bbefe9d9efeedcdeafea35f37e40afa5ad184b2341bbb95
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
