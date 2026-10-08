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
1-5	1-5-1	1-5%20WPS%20%E9%95%BF%E6%96%87%E6%A1%A3%E6%8E%92%E7%89%88/step1/.gitkeep	step1/.gitkeep	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
1-5	1-5-1	1-5%20WPS%20%E9%95%BF%E6%96%87%E6%A1%A3%E6%8E%92%E7%89%88/step1/%E7%B4%A0%E6%9D%90%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2-%E6%96%B0.docx	step1/素材中国共产党党史-新.docx	f7a1fc0195e94b4c66e4dc5a1b9fa8f0574a33b9e40412e21d0216631a93699f
1-5	1-5-2	1-5%20WPS%20%E9%95%BF%E6%96%87%E6%A1%A3%E6%8E%92%E7%89%88/step2/.gitkeep	step2/.gitkeep	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
1-5	1-5-2	1-5%20WPS%20%E9%95%BF%E6%96%87%E6%A1%A3%E6%8E%92%E7%89%88/step2/.%E7%B4%A0%E6%9D%90%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2-%E6%96%B0%E6%9C%80%E7%BB%88%E6%95%88%E6%9E%9C.docx	step2/.素材中国共产党党史-新最终效果.docx	a0af14ef2c5f1af079c740260af8a9fd7d3dcc311e2288824d70986b08b2fcd5
1-5	1-5-2	1-5%20WPS%20%E9%95%BF%E6%96%87%E6%A1%A3%E6%8E%92%E7%89%88/step2/%E7%B4%A0%E6%9D%90%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2-%E6%96%B0.docx	step2/素材中国共产党党史-新.docx	a0af14ef2c5f1af079c740260af8a9fd7d3dcc311e2288824d70986b08b2fcd5
1-5	1-5-3	1-5%20WPS%20%E9%95%BF%E6%96%87%E6%A1%A3%E6%8E%92%E7%89%88/step3/.gitkeep	step3/.gitkeep	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
1-5	1-5-3	1-5%20WPS%20%E9%95%BF%E6%96%87%E6%A1%A3%E6%8E%92%E7%89%88/step3/.%E7%B4%A0%E6%9D%90%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2-%E6%96%B0%E6%9C%80%E7%BB%88%E6%95%88%E6%9E%9C.docx	step3/.素材中国共产党党史-新最终效果.docx	5beca1b8220b31aba58c3f079e0284ad38216f417c2b43c6ba632e8ba157acbb
1-5	1-5-3	1-5%20WPS%20%E9%95%BF%E6%96%87%E6%A1%A3%E6%8E%92%E7%89%88/step3/%E7%B4%A0%E6%9D%90%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2-%E6%96%B0.docx	step3/素材中国共产党党史-新.docx	5beca1b8220b31aba58c3f079e0284ad38216f417c2b43c6ba632e8ba157acbb
1-5	1-5-4	1-5%20WPS%20%E9%95%BF%E6%96%87%E6%A1%A3%E6%8E%92%E7%89%88/step4/.gitkeep	step4/.gitkeep	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
1-5	1-5-4	1-5%20WPS%20%E9%95%BF%E6%96%87%E6%A1%A3%E6%8E%92%E7%89%88/step4/.%E7%B4%A0%E6%9D%90%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2-%E6%96%B0%E6%9C%80%E7%BB%88%E6%95%88%E6%9E%9C.docx	step4/.素材中国共产党党史-新最终效果.docx	d6bd7cbef307503081a6ab87f26690c52ca3debda9527772408d41ea56f71bca
1-5	1-5-4	1-5%20WPS%20%E9%95%BF%E6%96%87%E6%A1%A3%E6%8E%92%E7%89%88/step4/%E7%B4%A0%E6%9D%90%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2-%E6%96%B0.docx	step4/素材中国共产党党史-新.docx	d6bd7cbef307503081a6ab87f26690c52ca3debda9527772408d41ea56f71bca
1-5	1-5-5	1-5%20WPS%20%E9%95%BF%E6%96%87%E6%A1%A3%E6%8E%92%E7%89%88/step5/.gitkeep	step5/.gitkeep	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
1-5	1-5-5	1-5%20WPS%20%E9%95%BF%E6%96%87%E6%A1%A3%E6%8E%92%E7%89%88/step5/%E4%B8%AD%E5%9B%BD%E5%85%B1%E4%BA%A7%E5%85%9A%E5%85%9A%E5%8F%B2.docx	step5/中国共产党党史.docx	0703dc24631ce8c80583587d183337256c62380e9a05cdeeaca773c0305f1644
1-5	1-5-6	1-5%20WPS%20%E9%95%BF%E6%96%87%E6%A1%A3%E6%8E%92%E7%89%88/step6/.gitkeep	step6/.gitkeep	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
1-5	1-5-6	1-5%20WPS%20%E9%95%BF%E6%96%87%E6%A1%A3%E6%8E%92%E7%89%88/step6/.%E4%B9%A0%E8%BF%91%E5%B9%B3%E5%90%8C%E5%BF%97%E3%80%8A%E8%AE%BA%E5%85%9A%E7%9A%84%E9%9D%92%E5%B9%B4%E5%B7%A5%E4%BD%9C%E3%80%8B%E4%B8%BB%E8%A6%81%E7%AF%87%E7%9B%AE%E4%BB%8B%E7%BB%8D%E6%9C%80%E7%BB%88%E6%95%88%E6%9E%9C.docx	step6/.习近平同志《论党的青年工作》主要篇目介绍最终效果.docx	8880aaddcf17261e6ece2a23a2ff8b0e1035f83d0223941ec28dc2c149971b25
1-5	1-5-6	1-5%20WPS%20%E9%95%BF%E6%96%87%E6%A1%A3%E6%8E%92%E7%89%88/step6/%E7%B4%A0%E6%9D%90%E4%B9%A0%E8%BF%91%E5%B9%B3%E5%90%8C%E5%BF%97%E3%80%8A%E8%AE%BA%E5%85%9A%E7%9A%84%E9%9D%92%E5%B9%B4%E5%B7%A5%E4%BD%9C%E3%80%8B%E4%B8%BB%E8%A6%81%E7%AF%87%E7%9B%AE%E4%BB%8B%E7%BB%8D.docx	step6/素材习近平同志《论党的青年工作》主要篇目介绍.docx	8880aaddcf17261e6ece2a23a2ff8b0e1035f83d0223941ec28dc2c149971b25
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
