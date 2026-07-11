---
title: 树莓派——闹钟（定时器）
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

## 闹钟
逻辑：创建一个线程，不断的获取时间，判断是否到达设定的时间节点，到达就往通信队列里面放入这个时间节点相对于的序号，然后通过get_ready_id获取序号，执行相对于的操作

```c
import time
import threading
import queue

class AlarmThread(threading.Thread):
    def __init__(self, alarm_queue):
        super().__init__()
        self.alarms = {}  # 存储闹钟的字典，键为时间点，值为闹钟的标识符
        self.alarm_queue = alarm_queue

    def add_alarm(self, alarm_time, alarm_id):
        self.alarms[alarm_time] = alarm_id

    def remove_alarm(self, alarm_time, alarm_id):
        if alarm_time in self.alarms and self.alarms[alarm_time] == alarm_id:
            del self.alarms[alarm_time]

    def run(self):
        while True:
            current_time = time.strftime("%H:%M:%S")
            if current_time in self.alarms:
                alarm_id = self.alarms[current_time]
                print(f"Alarm {alarm_id} triggered at {current_time}")
                self.alarm_queue.put(alarm_id)  # 将alarm_id放入队列
                self.remove_alarm(current_time, alarm_id)
            time.sleep(1)

# 创建线程安全的队列和闹钟线程
alarm_queue = queue.Queue()
alarm_thread = AlarmThread(alarm_queue)

def Alarm_init():
    alarm_thread.start()

def Alarm_add(time, id):
    # 设置闹钟
    alarm_thread.add_alarm(time, id)

def Alarm_del(time, id):
    # 删除闹钟
    alarm_thread.remove_alarm(time, id)

def get_ready_id():
    try:
        # 从队列中获取alarm_id
        alarm_id = alarm_queue.get_nowait()
        # 这里你可以根据alarm_id执行主进程的相应操作
        print(f"Received alarm_id in the main process: {alarm_id}")
        return alarm_id
    except queue.Empty:
        # 队列为空时会抛出异常，可以忽略
        return 0
```

如：

    def open_play_music():
 	#播报语音“每日音乐播放已开启”
    #开启定时器（早上、晚上）
    Alarm_add("10:40:00", 2)
    #Alarm_add("21:35:00", 3)

添加了一个10点40分的定时器，序号为2，当那个时间到达是，取出队列的存储的2，然后执行播放音乐的操作






























































































































