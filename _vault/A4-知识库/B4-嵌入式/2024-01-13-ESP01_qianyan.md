---
title: ESP01————前言
date: 2024-1-13 19:48:00 +0800
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

1. 完成智能开关，（烧录代码、远程点灯）
2. 远程操控制雾器，灯，舵机等

## 要求掌握

1. ESP01的烧录，以及基本的例程
2. ESP01的客户端的搭建以及连接
3. 使用TCP进行通信
4. 实现智能开关的远程点灯
5. ...
6. ..
7. .

## 相关知识

1.什么是ESP-01S、ESP-01，两者有什么区别

![image](/assets/blog_res/2024-1-13-ESP01_qianyan/image.png)

ESP-01和ESP-01S

左边的是ESP-01S，右边的是ESP-01

ESP-01S天线区域右下角只有一个指示灯，ESP-01天线区域右下角有两个指示灯。

![image-1](/assets/blog_res/2024-1-13-ESP01_qianyan/image-1.png)

ESP-01S属于新版，相较与ESP-01模块它底部有引脚名标记，且去掉了电源指示灯，所以ESP-01S上电后只有蓝灯会闪烁一下，不会有其他现象发生。并且ESP-01S在串口通信时不需要接使能脚，而ESP-01需要拉高使能脚。

2.如何烧录

一：配置arduino IDE，使其支持ESP8266编程开发

https://zhuanlan.zhihu.com/p/475982456

错误补充：https://zhuanlan.zhihu.com/p/84766034

![image-6](/assets/blog_res/2024-1-13-ESP01_qianyan/image-6.png)

参考离线安装，在线安装不行

3. 烧录简单的代码，实现led灯以及wifi
```c
#include <ESP8266WiFi.h>​
const char ssid[] = "000";      //WiFi名
const char pass[] = "000";       //WiFi密码
WiFiClient client;
//初始化
void setup()
{
  Serial.begin(115200);
  Serial.println("esp8266 test");
  //initWiFi();
  pinMode(0, OUTPUT);
  pinMode(2, OUTPUT);
  digitalWrite(0, 1);
  digitalWrite(2, 1);
}
//主循环
void loop()
{
  Serial.println("hello esp8266");
  delay(1000);
  delay(1000);
  digitalWrite(0, 0);
  digitalWrite(2, 0);
  delay(1000);
  delay(1000);
  digitalWrite(0, 1);
  digitalWrite(2, 1);
}
//初始化WIFI
void initWiFi()
{
  Serial.print("Connecting WiFi...");
  WiFi.mode(WIFI_STA); //配置WIFI为Station模式
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
很气，2个小时，都搞不定，有那么难吗
遇到各种问题，内心浮躁起来了，所以没有理性思考，看来学习还是得配上做笔记记录思路来配合食用才行

问题一：esp32-01和esp32-01s的使用方法和接线方法都不同，我忽视了，导致反反复复不行
问题二：esp32-01s烧录了代码后，接上线，没有一个灯是亮的，都不知道到底启动了没
问题三：esp32-01烧录了代码后，接线，灯不亮，使用没烧录的接线，灯也不良，说明我完全没有弄懂工作模式的接线
问题四：不知道电源模块提供的电是否合适，（小问题）

思考：网上很多的资料，难找，也很杂，特别是因为01和01s这两个版本，导致情况更复杂，我应该首先找官方的资料，而不是零零散散的网上的资料，其次找找课程资料。

这两个半小时反映的问题很大很多，

最大的问题当属侥幸心理，浮躁，没有脚踏实地，然后更没有做笔记，一心想找个快车道三下五除二，一下子搞定他。但很显然这不是一个简单的问题

其次，思路和方法不对，找资料没有固定的优先级，找错资料，接着”侥幸“地一个个地试网上那些零零散散的方法，结果浪费了大量的时间，还搞得心情不好，我应当将写下某段时间某些计划，记录遇到的问题，分析解决方法，然后再行动，而不是无头苍蝇般到处找资料

总结：慢就是快，做好记录和计划。

1.找官方文档，数据手册。

2.学习esp3201s

资料一言难尽

# esp3201s

下载模式

![image-2](/assets/blog_res/2024-1-13-ESP01_qianyan/image-2.png)

工作模式

![image-3](/assets/blog_res/2024-1-13-ESP01_qianyan/image-3.png)

失败：
烧录上面的代码后（之运行io2的闪烁），安装工作模式接线，但运行时io2一直为高电平，我都怀疑有没有烧成。

尝试：烧一下官方的固件库

结果:烧录很顺利，发现买回来的电源模块不对劲，3.3v供电不足，导致串口无法收发东西，事实上似乎不足以启动的样子。然后接到5v那里，就可以用了。使用5v转3.3v的结果和直接街道3.3v那里的结果一样，可能是买回来的这个模块的问题，和网上说的不太一样。结论：直接用5v就好了

md，一开始就不该听接电脑的5v不行的话
![image-4](/assets/blog_res/2024-1-13-ESP01_qianyan/image-4.png)

烧录代码

```c
/*
  Note that this sketch uses LED_BUILTIN to find the pin with the internal LED
  GPIO2   LED
*/

void setup() {
   Serial.begin(115200);
   Serial.println("9999999999999999999999");
  pinMode(LED_BUILTIN, OUTPUT);     // Initialize the LED_BUILTIN pin as an output
}

// the loop function runs over and over again forever
void loop() {
  Serial.println("00000000000000");
  digitalWrite(LED_BUILTIN, LOW);   // Turn the LED on (Note that LOW is the voltage level
  // but actually the LED is on; this is because
  // it is active low on the ESP-01)
  delay(1000);                      // Wait for a second
  Serial.println("11111111111111");
  digitalWrite(LED_BUILTIN, HIGH);  // Turn the LED off by making the voltage HIGH
  delay(1000);                      // Wait for two seconds (to demonstrate the active low LED)
}
```

![image-5](/assets/blog_res/2024-1-13-ESP01_qianyan/image-5.png)

结果如此，也不知道成没，感觉没有

寻找其他的烧录方式。

呼，终于成了一点，原来要改这里

![image-7](/assets/blog_res/2024-1-13-ESP01_qianyan/image-7.png)

![image-8](/assets/blog_res/2024-1-13-ESP01_qianyan/image-8.png)

但还是才有一个问题，就是io2的引脚似乎并没有这样循环的输出高低电平，io2连接的led灯只有一点点微弱的光，似乎与代码设置的没关系，但板子的某个led灯反复蓝光闪烁，可能就是代码的原因。好歹前进了一大步

**总结：网上搜寻的零碎的方法途径要进行多方比对，挑选通用的方法**

![image-9](/assets/blog_res/2024-1-13-ESP01_qianyan/image-9.png)

很奇怪，板子上的io2有微弱的正电流，使得外接的led能亮一点点，当板子将io2拉低的时候，电流从VDD3V3那里流经R4电阻，再然后电量LED1，再回到板子。我将板子的io2接地，LED1没有亮，接外置的led2，led2很暗，可能这个板子上拉出的io2脚是在R4电阻与LED1之间拉出来的，使得板子上的io2一直都为3v3，但因为经过电阻电流很弱。所以不论板子将io0还是io2拉低还是拉高，板子上的io2和io0脚都是3v3。

若是要用这个板子控制，或许可以将GPIO3,GPIO1的TX\RX改一下

尝试：
发现外界的led灯接到任何东西身上，包括触碰我的手指都会有微弱的光，

https://zhuanlan.zhihu.com/p/413606409

https://blog.csdn.net/weixin_53992961/article/details/113469717

分析：看了很多的例程，应该是可以的，使用io0控制继电器，然后就可以使用了。但又出现一个新的问题，就是继电器不亮，樊。

终于破案了，原来是电源问题，

![ac3eeb10256b8b152d43fb0f03ab3a8](/assets/blog_res/2024-1-13-ESP01_qianyan/ac3eeb10256b8b152d43fb0f03ab3a8.jpg)


![0280438b53364c026af4849e6e14e04](/assets/blog_res/2024-1-13-ESP01_qianyan/0280438b53364c026af4849e6e14e04.jpg)

无论是电脑串口供电，还是继电器插上去供电，还是电源模块供电（还没试过，应该也是了），直接按原来的方法来接线的话，似乎会供电不足，表现的话为，继电器：esp3201sled不亮不运作io0也不运作，串口：esp3201sled亮能运作io0不运作，这两个我再其底部又外接了一条5v的来自电源模块的线后，就通通恢复正常了。

这天收获很大，哈哈

代码：
1.连接上wifi，并且设置ip=192.，端口什么的
2.写收到信息时的反馈代码，受到led=1,就向服务器发送led_ready，收到led=2，就打开led灯(digitalWrite(0, 0);digitalWrite(2, 0);),并向服务器发送led_on,收到led=0，就关闭led灯（digitalWrite(0, 1);digitalWrite(2, 1);），并且向服务器发送led_off；

搞定了

代码：

```c
//增加如下功能：
//1.连接上wifi，并且设置ip=192.168.1.20，端口什么的
//2.写收到信息时的反馈代码，受到led=1,就向服务器发送led_ready，收到led=2，就打开led灯(digitalWrite(0, 0);digitalWrite(2, 0);),并向服务器发送led_on,收到led=0，就关闭led灯（digitalWrite(0, 1);digitalWrite(2, 1);），并且向服务器发送led_off；

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

结果：树莓派先开启服务器，接着esp3201s开启，连接wifi，接入指定ip的服务器，并发送获取现在设备状态的请求，并根据状态开启或关闭。接着安卓端开启，连接服务器，接着刷新，获取服务器当前所以设备状态，更新recyclerview，然后我点击模块led，这时led发送app:ledon或者ledoff到服务器，然后服务器又根据接收到的发送给esp3201s终端。整体表现为，可以通过单击开关远处的led灯

![image-10](/assets/blog_res/2024-1-13-ESP01_qianyan/image-10.png)

![410bfbd80aaeefbb105c483290b72d1](/assets/blog_res/2024-1-13-ESP01_qianyan/410bfbd80aaeefbb105c483290b72d1.jpg)

安排：
1.尝试烧录进esp3201试试（可以使用）
2.计划

kongtiao=0&zhiwuqi=0&chuanglian=0&chuanghu=0&tishi=0&fengshan=1&led=1\n

计划

1. esp32+制雾器
2. esp32+舵机
3. esp32+风扇

制雾器需要弄原理图，将按键开机改为上电开机，舵机需要学习烧录esp8266，获取相应的代码，风扇也需要寻找资料。这三个中较为麻烦的是制雾器。

弄完这三个之后，需要将ui，代码，树莓派啥的都优化一下，减少代码的量，减少一些显而易见的bug，，在然后将采集数据的stm32那里优化一下，再拍个视频记录记录。





