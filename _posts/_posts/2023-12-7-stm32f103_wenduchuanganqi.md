---
title: STM32F103——DHT11温度传感器
date: 2023-12-7 20:24:00 +0800
categories: [STM32]
tags: [STM32]
pin: false
author: 
    name: hejiahua007
    link: https://space.bilibili.com/507838758
toc: true
comments: true
math: false
mermaid: true

---

## DHT11驱动原理

转自：https://blog.csdn.net/weixin_45631738/article/details/106367121

步骤一

DHT11上电后（DHT11上电后要等待 1S 以越过不稳定状态在此期间不能发送任何指令），测试环境 温湿度数据，并记录数据，同时 DHT11的 DATA 数据线由上拉电阻拉高一直保持高电平；此时 DHT11的 DATA 引脚处于输入状态，时刻检测外部信号。

步骤二

微处理器的 I/O设置为输出同时输出低电平，且低电平保持时间不能小于 18ms（最大不得超过 30ms）， 然后微处理器的 I/O设置为输入状态，由于上拉电阻，微处理器的 I/O即 DHT11的 DATA 数据线也随之变 高，等待 DHT11作出回答信号，发送信号如图所示：

![image](/assets/blog_res/2023-12-7-stm32f103_wenduchuanganqi/image.png)

步骤三

DHT11 的 DATA引脚检测到外部信号有低电平时，等待外部信号低电平结束，延迟后 DHT11 的 DATA 引脚处于输出状态，输出 83微秒的低电平作为应答信号，紧接着输出 87 微秒的高电平通知外设准备接 收数据，微处理器的 I/O 此时处于输入状态，检测到 I/O 有低电平（DHT11回应信号）后，等待 87微秒 的高电平后的数据接收，发送信号如图所示：

![image-1](/assets/blog_res/2023-12-7-stm32f103_wenduchuanganqi/image-1.png)

步骤四

由 DHT11 的 DATA引脚输出 40 位数据，微处理器根据 I/O电平的变化接收 40 位数据，位数据“0” 的格式为： 54 微秒的低电平和 23-27 微秒的高电平，位数据“1”的格式为： 54 微秒的低电平加 68-74 微秒的高电平。位数据“0”、“1”格式信号如图所

# 代码

```c
#include "stm32f10x.h"
#include "dht11.h"
#include "delay.h"
#include "stdio.h"

/************************/
uint8_t Temp = 0;		//温度
uint8_t Hmd = 0;		//湿度
/************************/


// THTB_Data - PA8

/**
 * 功能：  初始化温湿度计
 * 参数：  无
 * 返回值：无
 **/
void dht11_init(void)
{
	GPIO_InitTypeDef GPIO_InitStruct;
	
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);
	
	GPIO_InitStruct.GPIO_Mode = GPIO_Mode_Out_PP;
	GPIO_InitStruct.GPIO_Pin = GPIO_Pin_8;
	GPIO_InitStruct.GPIO_Speed = GPIO_Speed_50MHz;
	GPIO_Init(GPIOA, &GPIO_InitStruct);
	
	DHT11_SET_HIGH();
}

/**
 * 功能：  主机复位信号
 * 参数：  无
 * 返回值：无
 **/
void dht11_reset(void)
{
	DHT11_OUT();
	DHT11_SET_LOW();
	delay_ms(18);
	DHT11_SET_HIGH();
	delay_us(40);
}

/**
 * 功能：  温湿度计应答
 * 参数：  无
 * 返回值： 应答返回 1，非应答返回 0
 **/
int dht11_ack(void)
{
	int timeout = 0;
	
	// 方向：输入
	DHT11_IN();
	// 等待低电平到来
	while (DHT11_IS_HIGH());
	// 低电平计时
	while (DHT11_IS_LOW() && (timeout < 60)) {
		timeout++;
		delay_us(1);
	}
	// 超时
	if (timeout > 50) {
		return 0;
	}
	timeout = 0;
	// 高电平计时
	while (DHT11_IS_HIGH() && (timeout < 60)) {
		timeout++;
		delay_us(1);
	}
	// 超时
	if (timeout > 50) {
		return 0;
	}
	
	// 应答OK
	return 1;
}

/**
 * 功能：  读取温湿度的一个位
 * 参数：  无
 * 返回值：0 或 1
 **/
uint8_t dht11_read_bit(void)
{
	int timeout = 0;
	
	// 等待低电平到来
	while (DHT11_IS_HIGH());
	// 低电平延时
	while (DHT11_IS_LOW() && (timeout < 15)) {
		timeout++;
		delay_us(1);
	}
	timeout = 0;
	// 等待高电平到来
	while (DHT11_IS_LOW());
	// 高电平计时
	while (DHT11_IS_HIGH() && (timeout < 30)) {
		timeout++;
		delay_us(1);
	}
	// 等待高电平结束
	while (DHT11_IS_HIGH());
	
	// 返回这个位：0/1
	return (timeout <= 28) ? 0 : 1;
}

/**
 * 功能：  读取温湿度的一个字节
 * 参数：  无
 * 返回值：无
 **/
uint8_t dht11_read_byte(void)
{
	uint8_t byte = 0, i;
	
	for (i = 0; i < 8; i++) {
		byte <<= 1;   // 高位在前
		byte |= dht11_read_bit();
	}
	
	return byte;
}

/**
 * 功能：  读取温湿度数据
 * 参数：  dht 保存温湿度的数组
 * 返回值：成功返回 0，失败返回 -1
 **/
int dht11_read_data(uint8_t *humi, uint8_t *temp)
{

	int i = 0;
	uint8_t dht[5];
		
	dht11_reset();     // 主机复位


	if (dht11_ack()) {  // 温湿度计应答
		for (i = 4; i >= 0; i--) { // 读取数据
			dht[i] = dht11_read_byte();
		}
		// 校验
		if (dht[0] == dht[1] + dht[2] + dht[3] + dht[4]) {
			
			Hmd = dht[4];
			
			Temp = dht[2] - TEMPDIF;
			
			*humi = Hmd;
			*temp = Temp;
			
			return 0;
		}
		//printf("Check error\n");
	}
	else {
		//printf("NACK\n");
	}
	
	// 拉高电平为下次读取作准备
	DHT11_OUT();
	DHT11_SET_HIGH();
	
	return -1;
	
}

```


```h
#ifndef _DHT11_H_
#define _DHT11_H_

//#include "bitband.h"
#include "sys.h"

/************************/
extern uint8_t Temp;		//温度
extern uint8_t Hmd;		//湿度

#define TEMPDIF 0		//实际温差

/************************/

#if 1

#define DHT11_SET_HIGH()   do { PAout(8) = 1; } while (0)
#define DHT11_SET_LOW()    do { PAout(8) = 0; } while (0)

#define DHT11_IS_LOW()     !PAin(8)
#define DHT11_IS_HIGH()    PAin(8)

#else

#define DHT11_SET_HIGH()   do { GPIO_SetBits(GPIOA, GPIO_Pin_8); } while (0)
#define DHT11_SET_LOW()    do { GPIO_ResetBits(GPIOA, GPIO_Pin_8); } while (0)

#define DHT11_IS_LOW()     (!GPIO_ReadInputDataBit(GPIOA, GPIO_Pin_8))
#define DHT11_IS_HIGH()    GPIO_ReadInputDataBit(GPIOA, GPIO_Pin_8)

#endif

#define DHT11_IN()         do { GPIOA->CRH &= ~0xF; GPIOA->CRH |= 0x4; } while (0)
#define DHT11_OUT()        do { GPIOA->CRH &= ~0xF; GPIOA->CRH |= 0x3; } while (0)

/**
 * 功能：  初始化温湿度计
 * 参数：  无
 * 返回值：无
 **/
void dht11_init(void);

/**
 * 功能：  主机复位信号
 * 参数：  无
 * 返回值：无
 **/
void dht11_reset(void);

/**
 * 功能：  温湿度计应答
 * 参数：  无
 * 返回值： 应答返回 1，非应答返回 0
 **/
int dht11_ack(void);

/**
 * 功能：  读取温湿度的一个位
 * 参数：  无
 * 返回值：0 或 1
 **/
uint8_t dht11_read_bit(void);

/**
 * 功能：  读取温湿度的一个字节
 * 参数：  无
 * 返回值：无
 **/
uint8_t dht11_read_byte(void);

/**
 * 功能：  读取温湿度数据
 * 参数：  dht 保存温湿度的数组
 * 返回值：成功返回 0，失败返回 -1
 **/
int dht11_read_data(uint8_t *humi, uint8_t *temp);

#endif
```








































































































