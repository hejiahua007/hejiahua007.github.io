---
title: 毕设测试1
date: 2024-3-21 9:00:00 +0800
categories: [毕设测试]
tags: [毕设测试]
pin: false
author: 
    name: hejiahua007
    link: https://space.bilibili.com/507838758
toc: true
comments: true
math: false
mermaid: true

---

## 前言

先前就已经尝试过将各个模块结合在一起，出现了很多的bug，但拖延之下，转而投入了目标检测的怀抱，导致接下来疑难重重。

## 过程1

先是尝试着将stm32和树莓派连接在一起，但由于那时候似乎是用草稿本做的记录，后面内存不够，就不见了，现在再次尝试的时候，发现出现了3个bug，一个是光敏传感器的，一个是串口问题，一个是wifi的连接问题，还有一个资料有点乱的问题，这些都是之前遇到过的，现在居然要重新做一遍，真的令人烦躁，记录还是得好好的做好才行。

光敏的问题其实并不大，最主要的是wifi的连接问题。

```c
void esp_init(void)
{
//	Send_Data("+++\r\n");
//	// 测试 AT 启动
//	Send_Cmd_Wait_Cmd("AT\r\n","OK");
//    //
//	Send_Cmd_Wait_Cmd("ATE0\r\n","OK");
//    //重启模块
//	Send_Cmd_Wait_Cmd("AT+RST\r\n","ready");
//    //设置Wi-Fi模式并保存到flash
//  Send_Cmd_Wait_Cmd("AT+CWMODE_DEF=1\r\n","OK");
	//连接ap	
	delay_ms(1000);
	if(isWifiConnected()){
			printf("WIFI连接成功\r\n");
	}else{
			Send_Cmd_Wait_Cmd("AT+CWJAP=\"USER_509\",\"3643731ZSC\"\r\n","OK");
			printf("WIFI连接成功\r\n");
	}
    // 检查TCP连接状态
    if (isTcpConnected()) {
        printf("TCP连接成功\r\n");
    } else {
        // 尝试建立TCP连接
        Send_Cmd_Wait_Cmd("AT+CIPSTART=\"TCP\",\"192.168.43.94\",8888\r\n","OK");
        printf("尝试连接TCP服务器\r\n");
    }
	printf("配置完成");
	delay_ms(2000);
}

```
Send_Cmd_Wait_Cmd使用这个函数接收到的不一定准确，若是没有接收到等待的指令，就会进入无线等待，就此卡主。
而且，当esp3201若已经连接上了wifi，或者是已经建立了tcp连接，那么再次使用命令叫它连接或是建立tcp连接时，就会出现问题。
像是wifi连接，若是已经连接上了，你还用Send_Cmd_Wait_Cmd("AT+CWJAP=\"USER_509\",\"3643731ZSC\"\r\n"，那就会出现问题：先是断开wifi，然后再连接wifi（不成功）
还有wifi连接成功后的tcp，再次建立tcp的话，会出现：error的报错，然后卡主。
ps:若是已经连接成功过wifi，tcp，esp一开机就会自动连接上

所以要先判断一下，然后再进行连接。

2024年3月21日17:07:54
D:\git_cangku\毕设\stm32_sleep\USER，这个是可以用的

---
![image](/assets/blog_res/2024-3-21-bisheceshi1/image.png)



