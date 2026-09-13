import streamlit as st
import socket

st.set_page_config(page_title="HPC Streamlit Demo", layout="centered")

hostname = socket.gethostname().split('.')[0]

st.title("🚀 HPC 反向代理 Streamlit 範例")
st.success(f"目前執行主機節點: **{hostname}**")

st.markdown("""
### 關於本應用
在國網中心 Open OnDemand (OOD) 的子路徑反向代理下，Streamlit 必須設定 `--server.baseUrlPath`，
以確保內部 WebSockets 與靜態腳本能正確與 `/rnode/<hostname>/<port>/` 溝通。
""")

name = st.text_input("請輸入您的名字：", "研究員")
if st.button("打招呼"):
    st.write(f"你好，{name}！歡迎使用 HPC 互動儀表板。")
