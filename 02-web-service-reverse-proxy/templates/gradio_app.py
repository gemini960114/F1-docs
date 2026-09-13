#!/usr/bin/env python3
import socket
import gradio as gr

hostname = socket.gethostname().split('.')[0]
port = 7860

def greet(name, intensity):
    return "哈囉 " + name + "!" * int(intensity)

demo = gr.Interface(
    fn=greet,
    inputs=["text", gr.Slider(value=2, minimum=1, maximum=10, step=1)],
    outputs=["text"],
    title="HPC Gradio 反向代理範例",
    description="展示如何在國網中心子路徑反向代理下運行 Gradio"
)

if __name__ == "__main__":
    # 核心關鍵: 指定 root_path 為 /rnode/<hostname>/<port>
    demo.launch(
        server_name="0.0.0.0",
        server_port=port,
        root_path=f"/rnode/{hostname}/{port}",
        share=False
    )
