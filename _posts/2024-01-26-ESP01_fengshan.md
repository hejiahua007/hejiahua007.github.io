---
title: ESP01————风扇
date: 2024-1-26 9:18:00 +0800
categories: [ESP01]
tags: [ESP01]
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

#include <ESP8266WiFi.h>​
const char ssid[] = "";      //WiFi名
const char pass[] = "";       //WiFi密码
WiFiClient client; //创建一个WiFiClient对象
const char* server = "192.168.1.7"; //服务器的IP地址
const int port = 8888; //服务器的端口号
const int ledPin2 = 2; //继电器的引脚
const int ledPin0 = 0; //LED的引脚
//初始化
void setup()
{
  Serial.begin(115200);
  Serial.println("esp8266 test");
  initWiFi();
  pinMode(ledPin0, OUTPUT);
  digitalWrite(ledPin0, HIGH);
  pinMode(ledPin2, OUTPUT);
  digitalWrite(ledPin2, HIGH);
}
//主循环
void loop()
{
  Serial.println("hello esp8266");
  delay(1000);
  //如果WiFi连接正常，尝试连接服务器
  if (WiFi.status() == WL_CONNECTED) {
    Serial.print("Connecting to ");
    Serial.println(server);
    //如果连接成功，发送HTTP请求
    if (client.connect(server, port)) {
      Serial.println("Connected to server");
      //发送GET请求，请求服务器发送LED的状态
      client.println("GET_STATE_LED&led_ready");
      //等待服务器的响应
      while (client.connected() || client.available()) {
        //如果有数据可读，读取并处理
        if (client.available()) {
          String line = client.readStringUntil('\n');
          Serial.println(line);
          //如果读到了LED的状态，根据状态控制LED灯，并向服务器发送反馈
          if (line.startsWith("LED:")) {
            int ledState = line.substring(4).toInt();
            Serial.print("LED state: ");
            Serial.println(ledState);
            if (ledState == 1) {
              digitalWrite(ledPin0, LOW);
              digitalWrite(ledPin2, LOW);
              //client.println("led_ready");
            }
            else if (ledState == 2) {
              digitalWrite(ledPin0, LOW);
              digitalWrite(ledPin2, LOW);
              //client.println("led_on");
            }
            else if (ledState == 0) {
              digitalWrite(ledPin0, HIGH);
              digitalWrite(ledPin2, HIGH);
              //client.println("led_off");
            }
          }
        }
      }
      //断开连接
      client.stop();
      Serial.println("Disconnected from server");
    }
    else {
      //如果连接失败，打印错误信息
      Serial.println("Connection failed");
    }
  }
  else {
    //如果WiFi连接断开，打印错误信息
    Serial.println("WiFi disconnected");
  }
}
//初始化WIFI
void initWiFi()
{
  Serial.print("Connecting WiFi...");
  WiFi.mode(WIFI_STA); //配置WIFI为Station模式
  //设置静态IP地址，网关，子网掩码，DNS
  IPAddress local_IP(192, 168, 1, 20);
  IPAddress gateway(192, 168, 1, 1);
  IPAddress subnet(255, 255, 255, 0);
  IPAddress primaryDNS(8, 8, 8, 8);
  IPAddress secondaryDNS(8, 8, 4, 4);
  if (!WiFi.config(local_IP, gateway, subnet, primaryDNS, secondaryDNS)) {
    Serial.println("STA Failed to configure");
  }
  WiFi.begin(ssid, pass); //传入WIFI热点的ssid和密码
  while (WiFi.status() != WL_CONNECTED) //等待连接成功
  {
    delay(500);
    Serial.print(".");
  }
  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP()); //打印自己的IP地址
}
```

直接放继电器上用不了，貌似电源模块供不起电。得了解一下相关的信息才行

## 资料

我手头准备用的是51单片机送的电机

电机属于大功率负载，如果直接接在i/o口，会损坏单片机硬件。因此需要在单片机和电机之间加入驱动电路，常见的是直接驱动和h桥驱动。

![image](/assets/blog_res/2024-1-13-ESP01_fengshan/image.png)

![image-1](/assets/blog_res/2024-1-13-ESP01_fengshan/image-1.png)

51单片机使用的是开发板自带的资源ULN2002D进行驱动

ULN2003D 是一种高电流可溶性继电器驱动芯片，它通常用于驱动直流电机。ULN2003D 的主要作用是将较低电压的控制信号转换为较高电压的驱动信号，从而可以通过驱动直流电机。ULN2003D 具有高电流输出能力，使用它可以减少控制系统的电路复杂度和功率损耗，并且可以额外提供驱动电流。ULN2003D 在驱动直流电机时主要用于将低电压的控制信号转换为高电压的驱动信号，从而提高驱动能力，减少电路复杂度和功率损耗。

https://blog.csdn.net/qq_44419932/article/details/115905686?ops_request_misc=%257B%2522request%255Fid%2522%253A%2522170623577816777224448889%2522%252C%2522scm%2522%253A%252220140713.130102334.pc%255Fall.%2522%257D&request_id=170623577816777224448889&biz_id=0&utm_medium=distribute.pc_search_result.none-task-blog-2~all~first_rank_ecpm_v1~rank_v31_ecpm-17-115905686-null-null.142^v99^pc_search_result_base6&utm_term=%E7%9B%B4%E6%B5%81%E7%94%B5%E6%9C%BAesp8266&spm=1018.2226.3001.4187

https://blog.csdn.net/qq_52307281/article/details/128343690?ops_request_misc=%257B%2522request%255Fid%2522%253A%2522170623577816777224448889%2522%252C%2522scm%2522%253A%252220140713.130102334.pc%255Fall.%2522%257D&request_id=170623577816777224448889&biz_id=0&utm_medium=distribute.pc_search_result.none-task-blog-2~all~first_rank_ecpm_v1~rank_v31_ecpm-19-128343690-null-null.142^v99^pc_search_result_base6&utm_term=%E7%9B%B4%E6%B5%81%E7%94%B5%E6%9C%BAesp8266&spm=1018.2226.3001.4187

https://blog.csdn.net/qq_41262681/article/details/95319321

https://blog.csdn.net/dingxiang1987824/article/details/113420892?ops_request_misc=%257B%2522request%255Fid%2522%253A%2522170623745316800192217921%2522%252C%2522scm%2522%253A%252220140713.130102334..%2522%257D&request_id=170623745316800192217921&biz_id=0&utm_medium=distribute.pc_search_result.none-task-blog-2~all~top_positive~default-1-113420892-null-null.142^v99^pc_search_result_base6&utm_term=L298n&spm=1018.2226.3001.4187

直流电机可以用l298n来驱动，

![image-2](/assets/blog_res/2024-1-13-ESP01_fengshan/image-2.png)

可以通过控制IN1和IN2来进行正反转以及pwn控制，所以需要用到两个引脚。我又esp3201和esp8266node板，看来得用8266node板来控制电机和舵机了

所以接下来的任务就是，购买l298n，学习esp8266的烧录，先学习电亮一个led，然后在学习控制舵机

反思：查阅资料近乎用了2个小时的时间，按道理来说，可能一个半小时就可以了，但我第一个小时里，直接尝试将点击连到继电器上面，然后使用esp3201s_led的代码来进行控制，结果出现了奇奇怪怪的反应，最后得出一个结论，就是电可能不够，然后又进一步的尝试，更确认了这个结论，然后才上网找资料，了解这个电机，使用它需要的驱动。我应该直接寻找这个电机的型号，找它的相关资料，然后找它的使用方法，而不是自己去探索。

结论：理性计划节省时间，先了解情况，再然后才可以开始动手。

## 实验步骤

![image](/assets/blog_res/2024-1-26-ESP01_fengshan/image.png)

![image-1](/assets/blog_res/2024-1-26-ESP01_fengshan/image-1.png)

![image-9](/assets/blog_res/2024-1-26-ESP01_duoji/image-9.png)

![image-8](/assets/blog_res/2024-1-26-ESP01_duoji/image-8.png)

实物接线图：
![7c6694311e35d0a48c121e10ecbade9](/assets/blog_res/2024-1-26-ESP01_fengshan/7c6694311e35d0a48c121e10ecbade9.jpg)

![fef7c9d1ac2bf10730dd6281133ffd1](/assets/blog_res/2024-1-26-ESP01_fengshan/fef7c9d1ac2bf10730dd6281133ffd1.jpg)
使用方法就是两个控制线的高低以及占空比

```c
#include <ESP8266WiFi.h>
#include <Servo.h>

const char ssid[] = "";      // WiFi名
const char pass[] = "";    // WiFi密码
WiFiClient client;                   // 创建一个WiFiClient对象
const char* server = "192.168.";   // 服务器的IP地址
const int port = 8888;                // 服务器的端口号



int pos = 0;                          // 角度存储变量

// 初始化
void setup()
{
  Serial.begin(115200);
  Serial.println("esp8266 test");
  initWiFi();
  pinMode(D1, OUTPUT);
  pinMode(D2, OUTPUT);
  digitalWrite(D1, LOW);
  digitalWrite(D2, LOW);

}

// 主循环
void loop()
{
  Serial.println("hello esp8266");
  delay(1000);
  // 如果WiFi连接正常，尝试连接服务器
  if (WiFi.status() == WL_CONNECTED) {
    Serial.print("Connecting to ");
    Serial.println(server);
    // 如果连接成功，发送HTTP请求
    if (client.connect(server, port)) {
      Serial.println("Connected to server");
      // 发送GET请求，请求服务器发送FENSHAN的状态
      client.println("GET_STATE_FENSHAN&fengshan_ready");
      // 等待服务器的响应
      while (client.connected() || client.available()) {
        // 如果有数据可读，读取并处理
        if (client.available()) {
          String line = client.readStringUntil('\n');
          Serial.println(line);
          // 如果读到了FENSHAN的状态，根据状态控制FENSHAN灯，并向服务器发送反馈
          if (line.startsWith("FENSHAN:")) {
            int fengshanState = line.substring(8).toInt();
            Serial.print("FENGSHAN state: ");
            Serial.println(fengshanState);
            if (fengshanState == 2) {
              // Full speed forward
              analogWrite(D1, 255); // 设置PWM占空比为最大值
              analogWrite(D2, 0);   // 停止GPIO4的PWM输出
            }
            else if (fengshanState == 1) {
              // Half speed forward
              analogWrite(D1, 128); // 设置PWM占空比为一半
              analogWrite(D2, 0);   // 停止GPIO4的PWM输出
            }
            else if (fengshanState == 0) {
              // Stop
              analogWrite(D1, 0); // 停止GPIO5的PWM输出
              analogWrite(D2, 0); // 停止GPIO4的PWM输出
            }
          }
        }
      }
      // 断开连接
      client.stop();
      Serial.println("Disconnected from server");
    }
    else {
      // 如果连接失败，打印错误信息
      Serial.println("Connection failed");
    }
  }
  else {
    // 如果WiFi连接断开，打印错误信息
    Serial.println("WiFi disconnected");
  }
}

// 初始化WIFI
void initWiFi()
{
  Serial.print("Connecting WiFi...");
  WiFi.mode(WIFI_STA); // 配置WIFI为Station模式
  // 设置静态IP地址，网关，子网掩码，DNS
  IPAddress local_IP(192, 168, 1, 21);
  IPAddress gateway(192, 168, 1, 1);
  IPAddress subnet(255, 255, 255, 0);
  IPAddress primaryDNS(8, 8, 8, 8);
  IPAddress secondaryDNS(8, 8, 4, 4);
  if (!WiFi.config(local_IP, gateway, subnet, primaryDNS, secondaryDNS)) {
    Serial.println("STA Failed to configure");
  }
  WiFi.begin(ssid, pass); // 传入WIFI热点的ssid和密码
  while (WiFi.status() != WL_CONNECTED) // 等待连接成功
  {
    delay(500);
    Serial.print(".");
  }
  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP()); // 打印自己的IP地址
}
```

综合舵机的esp8266的代码：
```c
#include <ESP8266WiFi.h>
#include <Servo.h>

const char ssid[] = "";      // WiFi名
const char pass[] = "";    // WiFi密码
WiFiClient client;                   // 创建一个WiFiClient对象
const char* server = "192.168.1.";   // 服务器的IP地址
const int port = 8888;                // 服务器的端口号
Servo myServo;  // 定义Servo对象来控制
int pos = 0;    // 角度存储变量

// 初始化
void setup()
{
  Serial.begin(115200);
  Serial.println("esp8266 test");
  initWiFi();
  pinMode(D1, OUTPUT);
  pinMode(D2, OUTPUT);
  digitalWrite(D1, LOW);
  digitalWrite(D2, LOW);
  myServo.attach(14); //D5   
}

// 主循环
void loop()
{
  Serial.println("hello esp8266");
  delay(1000);
  // 如果WiFi连接正常，尝试连接服务器
  if (WiFi.status() == WL_CONNECTED) {
    Serial.print("Connecting to ");
    Serial.println(server);
    // 如果连接成功，发送HTTP请求
    if (client.connect(server, port)) {
      Serial.println("Connected to server");
      // 发送GET请求，请求服务器发送FENSHAN的状态
      client.println("GET_STATE_FENSHAN&fengshan_ready");
      client.println("GET_STATE_DUOJI&duoji_ready");
      // 等待服务器的响应
      while (client.connected() || client.available()) {
        // 如果有数据可读，读取并处理
        if (client.available()) {
          String line = client.readStringUntil('\n');
          Serial.println(line);
          // 如果读到了FENSHAN的状态，根据状态控制FENSHAN灯，并向服务器发送反馈
          if (line.startsWith("FENSHAN:")) {
            int fengshanState = line.substring(8).toInt();
            Serial.print("FENGSHAN state: ");
            Serial.println(fengshanState);
            if (fengshanState == 2) {
              // Full speed forward
              analogWrite(D1, 255); // 设置PWM占空比为最大值
              analogWrite(D2, 0);   // 停止GPIO4的PWM输出
              client.println("FENGSHAN state:2");
            }
            else if (fengshanState == 1) {
              // Half speed forward
              analogWrite(D1, 128); // 设置PWM占空比为一半
              analogWrite(D2, 0);   // 停止GPIO4的PWM输出
              client.println("FENGSHAN state:1");
            }
            else if (fengshanState == 0) {
              // Stop
              analogWrite(D1, 0); // 停止GPIO5的PWM输出
              analogWrite(D2, 0); // 停止GPIO4的PWM输出
              client.println("FENGSHAN state:0");
            }
          }
          else if (line.startsWith("DUOJI:")) {
            int duojiState = line.substring(6).toInt();
            Serial.print("DUOJI state: ");
            Serial.println(duojiState);
            if (duojiState == 1) {
              // To 0°
              myServo.write(0);
              client.println("DUOJI state:1");
              delay(1000);
            }
            else if (duojiState == 2) {
              // To 90°
              myServo.write(90);
              client.println("DUOJI state:2");
              delay(1000);
            }
            else if (duojiState == 0) {
              // To 180°
              myServo.write(180);
              client.println("DUOJI state:0");
              delay(1000);
            }
          }
        }
      }
      // 断开连接
      client.stop();
      Serial.println("Disconnected from server");
    }
    else {
      // 如果连接失败，打印错误信息
      Serial.println("Connection failed");
    }
  }
  else {
    // 如果WiFi连接断开，打印错误信息
    Serial.println("WiFi disconnected");
  }
}

// 初始化WIFI
void initWiFi()
{
  Serial.print("Connecting WiFi...");
  WiFi.mode(WIFI_STA); // 配置WIFI为Station模式
  // 设置静态IP地址，网关，子网掩码，DNS
  IPAddress local_IP(192, 168, 1, 21);
  IPAddress gateway(192, 168, 1, 1);
  IPAddress subnet(255, 255, 255, 0);
  IPAddress primaryDNS(8, 8, 8, 8);
  IPAddress secondaryDNS(8, 8, 4, 4);
  if (!WiFi.config(local_IP, gateway, subnet, primaryDNS, secondaryDNS)) {
    Serial.println("STA Failed to configure");
  }
  WiFi.begin(ssid, pass); // 传入WIFI热点的ssid和密码
  while (WiFi.status() != WL_CONNECTED) // 等待连接成功
  {
    delay(500);
    Serial.print(".");
  }
  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP()); // 打印自己的IP地址
}

```

















