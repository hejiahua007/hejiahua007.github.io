---
title: STM32F103——光照
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


## 代码
```c
#include "delay.h"
#include "bh1750.h"

typedef   unsigned char BYTE;

void Single_Write_BH1750(uchar REG_Address)
{
   IIC_Start();                  //起始信号
   IIC_Send_Byte(BHAddWrite);   //发送设备地址+写信号
   IIC_Send_Byte(REG_Address);    //内部寄存器地址，
   IIC_Stop();                   //发送停止信号
}

void BH1750_GPIO_Init(void)       //BH1750 GPIO的初始化
{
    GPIO_InitTypeDef  GPIO_InitStructure;

    RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOB, ENABLE);     //使能端口时钟
    GPIO_InitStructure.GPIO_Pin = GPIO_Pin_6|GPIO_Pin_7;     
     GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;          //推挽输出
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;//速度50MHz
     GPIO_Init(GPIOB, &GPIO_InitStructure);      
     GPIO_SetBits(GPIOB,GPIO_Pin_6|GPIO_Pin_7);    
}

void BH1750_Config_Init(void)              //BH1750配置初始化
{
    BH1750_GPIO_Init();            //GPIO引脚配置
    Single_Write_BH1750(0x01);    //是一个信号，打开设备的信号 我的理解，，没看原理
}

void bh_data_send(u8 command)           
{
    do{
    IIC_Start();                      //iic起始信号
    IIC_Send_Byte(BHAddWrite);       //发送器件地址
    }while(IIC_Wait_Ack());           //等待从机应答
    IIC_Send_Byte(command);          //发送指令
    IIC_Wait_Ack();                   //等待从机应答
    IIC_Stop();                       //iic停止信号
}

u16 bh_data_read(void)
{
    u16 buf;
    IIC_Start();                       //iic起始信号
    IIC_Send_Byte(BHAddRead);         //发送器件地址+读标志位
    IIC_Wait_Ack();                     //等待从机应答
    buf=IIC_Read_Byte(1);              //读取数据
    buf=buf<<8;                        //读取并保存高八位数据
    buf+=0x00ff&IIC_Read_Byte(0);      //读取并保存低八位数据
    IIC_Stop();                        //发送停止信号 
    return buf; 
}


/*******************************
下面的都是 IIC 的一些操作  1113lc
***********************************/
//产生IIC起始信号
void IIC_Start(void)
{
    SDA_OUT();     //sda线输出
    IIC_SDA=1;            
    IIC_SCL=1;
    delay_us(4);
     IIC_SDA=0;//START:when CLK is high,DATA change form high to low 
    delay_us(4);
    IIC_SCL=0;//钳住I2C总线，准备发送或接收数据 
}      
//产生IIC停止信号
void IIC_Stop(void)
{
    SDA_OUT();//sda线输出
    IIC_SCL=0;
    IIC_SDA=0;//STOP:when CLK is high DATA change form low to high
     delay_us(4);
    IIC_SCL=1; 
    IIC_SDA=1;//发送I2C总线结束信号
    delay_us(4);                                   
}
//等待应答信号到来
//返回值：1，接收应答失败
//        0，接收应答成功
u8 IIC_Wait_Ack(void)
{
    u8 ucErrTime=0;
    SDA_IN();      //SDA设置为输入  
    IIC_SDA=1;delay_us(1);       
    IIC_SCL=1;delay_us(1);     
    while(READ_SDA)
    {
        ucErrTime++;
        if(ucErrTime>250)
        {
            IIC_Stop();
            return 1;
        }
    }
    IIC_SCL=0;//时钟输出0        
    return 0;  
} 
//产生ACK应答
void IIC_Ack(void)
{
    IIC_SCL=0;
    SDA_OUT();
    IIC_SDA=0;
    delay_us(2);
    IIC_SCL=1;
    delay_us(2);
    IIC_SCL=0;
}
//不产生ACK应答            
void IIC_NAck(void)
{
    IIC_SCL=0;
    SDA_OUT();
    IIC_SDA=1;
    delay_us(2);
    IIC_SCL=1;
    delay_us(2);
    IIC_SCL=0;
}                                          
//IIC发送一个字节
//返回从机有无应答
//1，有应答
//0，无应答              
void IIC_Send_Byte(u8 txd)
{                        
    u8 t;   
    SDA_OUT();         
    IIC_SCL=0;//拉低时钟开始数据传输
    for(t=0;t<8;t++)
    {              
        //IIC_SDA=(txd&0x80)>>7;
        if((txd&0x80)>>7)
            IIC_SDA=1;
        else
            IIC_SDA=0;
        txd<<=1;       
        delay_us(2);   //对TEA5767这三个延时都是必须的
        IIC_SCL=1;
        delay_us(2); 
        IIC_SCL=0;    
        delay_us(2);
    }     
}         
//读1个字节，ack=1时，发送ACK，ack=0，发送nACK   
u8 IIC_Read_Byte(unsigned char ack)
{
    unsigned char i,receive=0;
    SDA_IN();//SDA设置为输入
    for(i=0;i<8;i++ )
    {
        IIC_SCL=0; 
        delay_us(2);
        IIC_SCL=1;
        receive<<=1;
        if(READ_SDA)receive++;   
        delay_us(1); 
    }                     
    if (!ack)
        IIC_NAck();//发送nACK
    else
        IIC_Ack(); //发送ACK   
    return receive;
}



```


```h
#ifndef __BH1750_H
#define __BH1750_H
#include "sys.h"


//IO方向设置
#define SDA_IN()  {GPIOB->CRL&=0X0FFFFFFF;GPIOB->CRL|=(u32)8<<28;}       
#define SDA_OUT() {GPIOB->CRL&=0X0FFFFFFF;GPIOB->CRL|=(u32)3<<28;}

#define IIC_SCL    PBout(6) //SCL
#define IIC_SDA    PBout(7) //SDA     
#define READ_SDA   PBin(7)  //输入SDA 
#define ADDR 0x23//0100011
#define uchar unsigned char 

#define BHAddWrite     0x46      //从机地址+最后写方向位
#define BHAddRead      0x47      //从机地址+最后读方向位
#define BHPowDown      0x00      //关闭模块
#define BHPowOn        0x01      //打开模块等待测量指令
#define BHReset        0x07      //重置数据寄存器值在PowerOn模式下有效
#define BHModeH1       0x10      //高分辨率 单位1lx 测量时间120ms
#define BHModeH2       0x11      //高分辨率模式2 单位0.5lx 测量时间120ms
#define BHModeL        0x13      //低分辨率 单位4lx 测量时间16ms
#define BHSigModeH     0x20      //一次高分辨率 测量 测量后模块转到 PowerDown模式
#define BHSigModeH2    0x21      //同上类似
#define BHSigModeL     0x23      // 上类似

//BH1750 功能函数
void BH1750_Config_Init(void);
void bh_data_send(u8 command);
u16 bh_data_read(void);

//IIC所有操作函数    这些是必须要声明的，因为在c文件内部实现，顺序问题，在使用之前，必须对IIC函数声明，，           
void IIC_Start(void);                //发送IIC开始信号
void IIC_Stop(void);                  //发送IIC停止信号
void IIC_Send_Byte(u8 txd);            //IIC发送一个字节
u8 IIC_Read_Byte(unsigned char ack);//IIC读取一个字节
u8 IIC_Wait_Ack(void);                 //IIC等待ACK信号
void IIC_Ack(void);                    //IIC发送ACK信号
void IIC_NAck(void);                //IIC不发送ACK信号
#endif



 

```









































































































