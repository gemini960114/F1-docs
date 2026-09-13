#!/usr/bin/env bash
# ==============================================================================
# test_connection.sh - 測試各大常用服務連線能力
# ==============================================================================
set -euo pipefail

echo "========================================================"
echo "🌐 開始測試外部網路連線狀態..."
echo "========================================================"

targets=(
    "https://huggingface.co"
    "https://pypi.org"
    "https://github.com"
)

for url in "${targets[@]}"; do
    printf "測試連線至 %-30s ... " "${url}"
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 -I "${url}" || echo "FAILED")
    if [[ "${STATUS}" =~ ^(200|301|302|304|307|308)$ ]]; then
        echo "✅ 成功 (HTTP ${STATUS})"
    else
        echo "❌ 失敗 (狀態碼: ${STATUS})"
    fi
done

echo "========================================================"
