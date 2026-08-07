---
title: 树莓派——每日一言
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

## 每日一言


```c
import requests
import speaking
from clock import Alarm_add,Alarm_del

url = "https://v1.hitokoto.cn/?c=a&c=c&c=e&c=f&c=h&c=i&c=k"

def yiyan():
	response = requests.get(url)
	data = response.json()

	# 检查响应状态码
	if response.status_code == 200:
		hitokoto = data["hitokoto"]
		from_who = data["from_who"]
		print("Hitokoto:", hitokoto)
	else:
		print("请求失败:", data["message"])
	#speaking.speak(hitokoto,0)
	return hitokoto
	
def open_yiyan():
    #格言已开启
    #speaking.play_audio("../file/aphorism/kaiqi.wav")
    #开启定时器
	Alarm_add("21:50:00", 4)
    
    
def close_yiyan():

    #格言已开启
    #speaking.play_audio("../file/aphorism/close.wav")
    #开启定时器
    Alarm_del("21:46:00", 4)


#yiyan()

```































































































































