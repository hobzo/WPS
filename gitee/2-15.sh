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
2-15	2-15-1	2-15%20%E5%AE%9E%E9%AA%8C%E4%B8%83%20WPS%20%E8%A1%A8%E6%A0%BC%20%E7%94%A8%E9%A2%9C%E8%89%B2%E6%88%96%E5%9B%BE%E6%A0%87%E7%9B%B4%E8%A7%82%E5%B1%95%E7%A4%BA%E6%95%B0%E6%8D%AE/project1/%E7%AA%81%E5%87%BA%E6%98%BE%E7%A4%BA%E9%87%8D%E8%A6%81%E5%80%BC.xlsx	project1/突出显示重要值.xlsx	64855547eb9a418fe2acb136929175314728ea582e7ae5240cdd01f7bf03e8fd
2-15	2-15-2	2-15%20%E5%AE%9E%E9%AA%8C%E4%B8%83%20WPS%20%E8%A1%A8%E6%A0%BC%20%E7%94%A8%E9%A2%9C%E8%89%B2%E6%88%96%E5%9B%BE%E6%A0%87%E7%9B%B4%E8%A7%82%E5%B1%95%E7%A4%BA%E6%95%B0%E6%8D%AE/project2/%E6%95%B0%E6%8D%AE%E6%9D%A1%E7%9A%84%E5%BA%94%E7%94%A8.xlsx	project2/数据条的应用.xlsx	e7d997d377e87d2a44af7524f19c1dcecb0a5d8ebf7eb4e2a026a11ea539a171
2-15	2-15-3	2-15%20%E5%AE%9E%E9%AA%8C%E4%B8%83%20WPS%20%E8%A1%A8%E6%A0%BC%20%E7%94%A8%E9%A2%9C%E8%89%B2%E6%88%96%E5%9B%BE%E6%A0%87%E7%9B%B4%E8%A7%82%E5%B1%95%E7%A4%BA%E6%95%B0%E6%8D%AE/project3/%E8%89%B2%E9%98%B6%E5%92%8C%E5%9B%BE%E6%A0%87%E9%9B%86%E7%9A%84%E5%BA%94%E7%94%A8.xlsx	project3/色阶和图标集的应用.xlsx	e1c3b7fb50dce3514c823444af4276c1e919e05061c99d565941bc397653c8d5
2-15	2-15-4	2-15%20%E5%AE%9E%E9%AA%8C%E4%B8%83%20WPS%20%E8%A1%A8%E6%A0%BC%20%E7%94%A8%E9%A2%9C%E8%89%B2%E6%88%96%E5%9B%BE%E6%A0%87%E7%9B%B4%E8%A7%82%E5%B1%95%E7%A4%BA%E6%95%B0%E6%8D%AE/project4/%E7%AE%A1%E7%90%86%E6%9D%A1%E4%BB%B6%E6%A0%BC%E5%BC%8F%E8%A7%84%E5%88%99.xlsx	project4/管理条件格式规则.xlsx	b4e3f8df16ae38220df46621017d6acc5fc591444bebe6998fb8f6cc868b5e96
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
