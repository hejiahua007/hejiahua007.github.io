---
title: 树莓派——tcp_server
date: 2023-11-28 21:40:00 +0800
categories: [树莓派]
tags: [树莓派]
pin: false
author: 
    name: hejiahua007
    link: https://space.bilibili.com/507838758
toc: true
comments: true
math: false
mermaid: true

---

## tcp服务器
想法：主进程中fock一个子进程用来搭建tcp的服务器端，不断的连接tcp客户端，接收和转发处理存储数据，子进程与主进程间使用管道进行通信。

```c
import socket
import threading
from multiprocessing import Pipe
import sqlite1
import select
HOST = '192.168.**.**'
PORT = 8888
commands = {
    'kaimen': lambda: send_to_client("kaimen", "192.168.**.**"),
    'guanmen': lambda: send_to_client("guanmen", "192.168.**.**"),
    'kaichuang': lambda: send_to_client("kaichuang", "192.168.**.**"),
    'guanchuang': lambda: send_to_client("guanchuang", "192.168.**.**"),
    'kaidneg': lambda: send_to_client("kaidneg", "192.168.**.**"),
    'guandeng': lambda: send_to_client("guandeng", "192.168.**.**"),
    'kaichuanglian': lambda: send_to_client("kaichuanglian", "192.168.**.**"),
    'guanchuanglian': lambda: send_to_client("guanchuanglian", "192.168.**.**"),
    'kaixiangxun': lambda: send_to_client("kaixiangxun", "192.168.**.**"),
    'guanxiangxun': lambda: send_to_client("guanxiangxun", "192.168.**.**"),
    'kaizhiwuqi': lambda: send_to_client("kaizhiwuqi", "192.168.**.**"),
    'guanzhiwuqi': lambda: send_to_client("guanzhiwuqi", "192.168.**.**"),
    'kaifengshan': lambda: send_to_client("kaifengshan", "192.168.**.**"),
    'guanfengshan': lambda: send_to_client("guanfengshan", "192.168.**.**"),
}
lock = threading.Lock()
client_sockets = {}

def broadcast_message(message, sender_ip):
    with lock:
        for ip, socket_item in client_sockets.items():
            if ip != sender_ip:
                try:
                    socket_item.send(message.encode())
                except socket.error as e:
                    print(f"Error sending message to {ip}: {e}")

def send_to_client(message, target_ip):
    with lock:
        if target_ip in client_sockets:
            try:
                client_sockets[target_ip].send(message.encode())
            except socket.error as e:
                print(f"Error sending message to {target_ip}: {e}")
        else:
            print(f"Client with IP {target_ip} not found.")

def handle_client(client_socket, client_address):
    with lock:
        client_sockets[client_address[0]] = client_socket
    data_batch = []  # 初始化空列表

    while True:
        request = client_socket.recv(1024)
        if not request:
            break

        message = request.decode()
        print(f"Received from {client_address[0]}:{client_address[1]}: {message}")

        if message.lower().strip() == "quit":
            print(f"Client {client_address[0]}:{client_address[1]} requested to quit")
            break

        if message.startswith("send_to"):
            parts = message.split(":")
            # 格式: send_to:192.168.:fengsan=1
            if len(parts) == 3:
                target_ip = parts[1].strip()
                send_to_client(parts[2], target_ip)
                continue
        if message.startswith("wendu"):
            parts = message.split("&")
            if len(parts) == 6:
                wendu = float(parts[0].strip().split("=")[1])
                shidu = float(parts[1].strip().split("=")[1])
                guangzhao = float(parts[2].strip().split("=")[1])
                co2 = float(parts[3].strip().split("=")[1])
                shengxiang = float(parts[4].strip().split("=")[1])
                fengli = float(parts[5].strip().split("=")[1])
                data_batch.append((wendu, shidu, guangzhao, co2, shengxiang, fengli))  # 将元组添加到列表中

        if len(data_batch) == 2:  # 检查列表中的元组数量是否达到20
            db_path = sqlite1.get_db_path()
            table_name = sqlite1.get_table_name()
            sqlite1.insert_batch_data(db_path, table_name, data_batch)
            data_batch = []  # 清空 data_batch 列表
        # 处理接收到的其他消息
        handle_custom_commands(message, client_address[0])

    with lock:
        del client_sockets[client_address[0]]

    client_socket.close()

def handle_custom_commands(message, sender_ip):
    custom_commands = ["kongtiao", "jiashi", "chuanglian", "jingshi", "fengshan"]

    for command in custom_commands:
        if command in message:
            # 根据需要修改目标 IP
            target_ip = "192.168.**.**"
            send_to_client(message, target_ip)
            return

    # 在这里添加其他处理接收到的消息的逻辑，0例如广播给所有客户端
    broadcast_message(message, sender_ip)


def run_server(pipe):
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server_socket.bind((HOST, PORT))
    server_socket.listen(5)
    print(f"Server listening on {HOST}:{PORT}")
    server_socket.settimeout(5)  # 设置超时时间为5秒
    while True:
        try:
            client_socket, client_address = server_socket.accept()
            print(f"Accepted connection from {client_address[0]}:{client_address[1]}")
            
            client_thread = threading.Thread(target=handle_client, args=(client_socket, client_address))
            client_thread.start()
        except socket.timeout:
            # 如果在超时时间内没有新连接尝试，执行下面的逻辑
            print("\n")
        
        # 继续执行其他逻辑
        ready_sockets, _, _ = select.select([pipe], [], [], 5)  # 等待5秒钟来检查管道是否可读
        if pipe in ready_sockets:  # 如果管道可读
            command = pipe.recv()
            if command in commands:
                commands[command]()
```

    2024-04-27 15:38:53.804 25399-25399 AndroidRuntime          com.example.myapplication            E  FATAL EXCEPTION: main
                                                                                                        Process: com.example.myapplication, PID: 25399
                                                                                                        android.os.NetworkOnMainThreadException
                                                                                                            at android.os.StrictMode$AndroidBlockGuardPolicy.onNetwork(StrictMode.java:1565)
                                                                                                            at java.net.SocketOutputStream.socketWrite(SocketOutputStream.java:116)
                                                                                                            at java.net.SocketOutputStream.write(SocketOutputStream.java:149)
                                                                                                            at com.example.myapplication.JiajuActivity.onItemClick(JiajuActivity.java:291)
                                                                                                            at com.example.myapplication.JiajuListAdapter$MyHolder.onClick(JiajuListAdapter.java:69)
                                                                                                            at android.view.View.performClick(View.java:7322)
                                                                                                            at android.view.View.performClickInternal(View.java:7296)
                                                                                                            at android.view.View.access$3600(View.java:839)
                                                                                                            at android.view.View$PerformClick.run(View.java:28319)
                                                                                                            at android.os.Handler.handleCallback(Handler.java:900)
                                                                                                            at android.os.Handler.dispatchMessage(Handler.java:103)
                                                                                                            at android.os.Looper.loop(Looper.java:219)
                                                                                                            at android.app.ActivityThread.main(ActivityThread.java:8673)
                                                                                                            at java.lang.reflect.Method.invoke(Native Method)
                                                                                                            at com.android.internal.os.RuntimeInit$MethodAndArgsCaller.run(RuntimeInit.java:513)
                                                                                                            at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:1109)

几乎都是主线程不能执行网络的命令这类的错误，需要把它弄到线程上执行。































































































































