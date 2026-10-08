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
2-5	2-5-1	2-5%20%E5%AE%9E%E9%AA%8C%E5%8D%81%20WPS%20%E8%A1%A8%E6%A0%BC%20%E7%94%A8%E5%9B%BE%E8%A1%A8%E7%9B%B4%E8%A7%82%E5%B1%95%E7%A4%BA%E6%95%B0%E6%8D%AE/step1/%E5%88%9B%E5%BB%BA%E5%9B%BE%E8%A1%A8.xlsx	step1/创建图表.xlsx	b455e6f3d07c20be6d6d66dcf23461d14fb1878b3fe18d63b4510d6bcbf77d47
2-5	2-5-2	2-5%20%E5%AE%9E%E9%AA%8C%E5%8D%81%20WPS%20%E8%A1%A8%E6%A0%BC%20%E7%94%A8%E5%9B%BE%E8%A1%A8%E7%9B%B4%E8%A7%82%E5%B1%95%E7%A4%BA%E6%95%B0%E6%8D%AE/step2/.gitkeep	step2/.gitkeep	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
2-5	2-5-2	2-5%20%E5%AE%9E%E9%AA%8C%E5%8D%81%20WPS%20%E8%A1%A8%E6%A0%BC%20%E7%94%A8%E5%9B%BE%E8%A1%A8%E7%9B%B4%E8%A7%82%E5%B1%95%E7%A4%BA%E6%95%B0%E6%8D%AE/step2/%E8%B0%83%E6%95%B4%E5%9B%BE%E8%A1%A8%E5%A4%A7%E5%B0%8F%E5%92%8C%E4%BD%8D%E7%BD%AE.xlsx	step2/调整图表大小和位置.xlsx	3d0e2b560f9a081c9da3c8dd56cb77363512b99153a7fd5835dada9aa9893212
2-5	2-5-3	2-5%20%E5%AE%9E%E9%AA%8C%E5%8D%81%20WPS%20%E8%A1%A8%E6%A0%BC%20%E7%94%A8%E5%9B%BE%E8%A1%A8%E7%9B%B4%E8%A7%82%E5%B1%95%E7%A4%BA%E6%95%B0%E6%8D%AE/step3/%E6%9B%B4%E6%94%B9%E5%9B%BE%E8%A1%A8%E7%B1%BB%E5%9E%8B.xlsx	step3/更改图表类型.xlsx	d934e72d1192b7ff019708580847aa974e1135a59eae769ceee8101eaba046c9
2-5	2-5-4	2-5%20%E5%AE%9E%E9%AA%8C%E5%8D%81%20WPS%20%E8%A1%A8%E6%A0%BC%20%E7%94%A8%E5%9B%BE%E8%A1%A8%E7%9B%B4%E8%A7%82%E5%B1%95%E7%A4%BA%E6%95%B0%E6%8D%AE/step4/%E6%B7%BB%E5%8A%A0%E6%88%96%E5%88%A0%E9%99%A4%E5%9B%BE%E8%A1%A8%E5%9B%BE%E8%A1%A8%E5%85%83%E7%B4%A0.xlsx	step4/添加或删除图表图表元素.xlsx	e5f7d06acf78042de6e159801539cb0caec380db5fc7f43625e557e3d1ad5730
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
