---
title: ESP01————制雾器
date: 2024-1-24 16:02:00 +0800
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
## 目标

1. 将制雾器改为上电开启
2. 写相应的esp3201的代码
3. 实现远程开启制雾器
.
## 制雾器资料

https://blog.csdn.net/weixin_43278295/article/details/113849759?ops_request_misc=%257B%2522request%255Fid%2522%253A%2522170140082316777224415397%2522%252C%2522scm%2522%253A%252220140713.130102334..%2522%257D&request_id=170140082316777224415397&biz_id=0&utm_medium=distribute.pc_search_result.none-task-blog-2~all~sobaiduend~default-4-113849759-null-null.142^v96^pc_search_result_base6&utm_term=%E5%8A%A0%E6%B9%BF%E5%99%A8%E6%A8%A1%E5%9D%97%E4%BD%BF%E7%94%A8&spm=1018.2226.3001.4187

![df980e62fca3940e8b94590f6159c35](/assets/blog_res/2024-1-13-ESP01_zhiwuqi/df980e62fca3940e8b94590f6159c35.jpg)

分析：购买回雾化片，使用发现，开关是由一个按钮开关来控制的，根据资料说的可能由某一个引脚控制的，拉低-延时-拉高即可开启，于是尝试着拿led灯测试

![1706088822550](/assets/blog_res/2024-1-13-ESP01_zhiwuqi/1706088822550.png)

当按下按钮开启制雾器的时候，led灯亮了一下，然后又灭了，说明这个引脚拉低了一下。
当再次按下按钮两次，led灯亮了两次，然后制雾器关闭，说明制雾器开启后，这个引脚拉低两次为关闭

因此可以通过这个引脚来控制制雾器的开启关闭

![e6f9b0ec051720b7284532fa9a55730](/assets/blog_res/2024-1-13-ESP01_zhiwuqi/e6f9b0ec051720b7284532fa9a55730.jpg)
![image](/assets/blog_res/2024-1-13-ESP01_zhiwuqi/image.png)

当esp3201s收到信号时，开启：io2先拉低，延时一秒，然后拉高，此时制雾器被开启（制雾器那根先被拉低，1s后，拉高），关闭：io2先拉低，1s后，拉高，1s后，拉低，1s后，拉高，也就是重复前面的那个两次，此时制雾器关闭。

```C

#include <ESP8266WiFi.h>​
const char ssid[] = "";      //WiFi名
const char pass[] = "";       //WiFi密码
WiFiClient client; //创建一个WiFiClient对象
const char* server = ""; //服务器的IP地址
const int port = 8888; //服务器的端口号
const int zhiwuqiPin2 = 2; //继电器的引脚
const int ledPin0 = 0; //LED的引脚
//初始化
void setup()
{
  Serial.begin(115200);
  Serial.println("esp8266 test");
  initWiFi();
  pinMode(ledPin0, OUTPUT);
  digitalWrite(ledPin0, HIGH);
  pinMode(zhiwuqiPin2, OUTPUT);
  digitalWrite(zhiwuqiPin2, HIGH);
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
      //发送GET请求，请求服务器发送zhiwuqi的状态
      client.println("GET_STATE_ZHIWUQI&zhiwuqi_ready");
      //等待服务器的响应
      while (client.connected() || client.available()) {
        //如果有数据可读，读取并处理
        if (client.available()) {
          String line = client.readStringUntil('\n');
          Serial.println(line);
          //如果读到了zhiwuqi的状态，根据状态控制zhiwuqi灯，并向服务器发送反馈
          if (line.startsWith("ZHIWUQI:")) {
            int zhiwuqiState = line.substring(8).toInt();
            Serial.print("ZHIWUQI state: ");
            Serial.println(zhiwuqiState);
            if (zhiwuqiState == 2) {
              digitalWrite(ledPin0, LOW);
              digitalWrite(zhiwuqiPin2, LOW);
              delay(1000);
              digitalWrite(ledPin0, HIGH);
              digitalWrite(zhiwuqiPin2, HIGH);
            }
            else if (zhiwuqiState == 0) {
              digitalWrite(ledPin0, LOW);
              digitalWrite(zhiwuqiPin2, LOW);
              delay(1000);
              digitalWrite(ledPin0, HIGH);
              digitalWrite(zhiwuqiPin2, HIGH);
              delay(1000);
              digitalWrite(ledPin0, LOW);
              digitalWrite(zhiwuqiPin2, LOW);
              delay(1000);
              digitalWrite(ledPin0, HIGH);
              digitalWrite(zhiwuqiPin2, HIGH);
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
}```



