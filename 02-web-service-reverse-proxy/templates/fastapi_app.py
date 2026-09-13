import os
import socket
from fastapi import FastAPI

hostname = socket.gethostname().split('.')[0]
port = int(os.environ.get("PORT", "8000"))

# 核心關鍵: 指定 root_path 確保 Swagger UI (/docs) 與 OpenAPI schema 正常解析
root_path = f"/rnode/{hostname}/{port}"
app = FastAPI(
    title="HPC FastAPI Demo",
    root_path=root_path,
    description="在反向代理子路徑下運作的 FastAPI 範例"
)

@app.get("/")
def read_root():
    return {
        "status": "online",
        "hostname": hostname,
        "message": f"歡迎存取 FastAPI！請前往 {root_path}/docs 查看 API 介面"
    }

@app.get("/items/{item_id}")
def read_item(item_id: int, q: str = None):
    return {"item_id": item_id, "q": q}
