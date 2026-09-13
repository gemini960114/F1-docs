#!/usr/bin/env python3
"""
get_free_port.py - 隨機綁定 0 號埠，取得由作業系統配發的閒置 Port
用法:
  python3 get_free_port.py
或在 Bash 腳本中使用:
  PORT=$(python3 get_free_port.py)
"""
import socket

def get_free_port():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('', 0))
        return s.getsockname()[1]

if __name__ == '__main__':
    print(get_free_port())
