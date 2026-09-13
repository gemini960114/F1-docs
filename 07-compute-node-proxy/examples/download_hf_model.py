#!/usr/bin/env python3
# ==============================================================================
# download_hf_model.py - 測試透過 Proxy 下載 Hugging Face 模型設定檔
# ==============================================================================
import os
import urllib.request
import json

print("==> 檢查當前 Python 環境 Proxy 變數:")
print(f"    http_proxy  : {os.environ.get('http_proxy')}")
print(f"    https_proxy : {os.environ.get('https_proxy')}")
print()

# 測試以標準 urllib 讀取 Hugging Face API
MODEL_ID = "bert-base-uncased"
API_URL = f"https://huggingface.co/api/models/{MODEL_ID}"

print(f"==> 嘗試透過 Proxy 存取 Hugging Face API: {API_URL}")
try:
    req = urllib.request.Request(API_URL, headers={"User-Agent": "HPC-Proxy-Test/1.0"})
    with urllib.request.urlopen(req, timeout=10) as response:
        data = json.loads(response.read().decode())
        print(f"✅ 存取成功！模型 ID: {data.get('id')}")
        print(f"   模型架構: {data.get('config', {}).get('architectures', ['N/A'])}")
except Exception as e:
    print(f"❌ 存取失敗: {e}")
    exit(1)
