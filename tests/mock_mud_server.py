#!/usr/bin/env python3
"""Mock MUD Server - 监听端口，发送样本数据，支持就绪信号"""

import socket
import sys
import time
import os


def run_server(port, lines_file, ready_file):
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(("127.0.0.1", port))
    server.listen(1)
    server.settimeout(15)

    with open(ready_file, "w") as f:
        f.write("READY")

    try:
        conn, addr = server.accept()
        time.sleep(0.5)
        with open(lines_file, "r") as f:
            for line in f:
                stripped = line.strip()
                if stripped:
                    conn.sendall((stripped + "\r\n").encode("utf-8"))
                    time.sleep(0.1)
        time.sleep(1)
        conn.close()
    except socket.timeout:
        pass
    finally:
        server.close()


if __name__ == "__main__":
    port = int(sys.argv[1])
    lines_file = sys.argv[2]
    ready_file = sys.argv[3] if len(sys.argv) > 3 else "/tmp/mock_server_ready.txt"
    run_server(port, lines_file, ready_file)
