---
title: python_async
date: 2023-10-24 8:20:00 +0800
categories: [python]
tags: [python_异步]
pin: false
author: 
    name: hejiahua007
    link: https://space.bilibili.com/507838758
toc: true
comments: true
math: false
mermaid: true

---
https://blog.csdn.net/brucewong0516/article/details/82697935

## 在学习asyncio之前，先理清楚同步/异步的概念：

- 同步是指完成事务的逻辑，先执行第一个事务，如果阻塞了，会一直等待，直到这个事务完成，再执行第二个事务，顺序执行
- 异步是和同步相对的，异步是指在处理调用这个事务的之后，不会等待这个事务的处理结果，直接处理第二个事务去了，通过状态、通知、回调来通知调用者处理结果

## asyncio函数：

异步IO采用消息循环的模式，重复“读取消息—处理消息”的过程，**也就是说异步IO模型”需要一个消息循环，在消息循环中，主线程不断地重复“读取消息-处理消息”这一过程。**

- event_loop 事件循环：程序开启一个无限的循环，程序员会把一些函数注册到事件循环上。当满足事件发生的时候，调用相应的协程函数。
- coroutine 协程：协程对象，指一个使用async关键字定义的函数，它的调用不会立即执行函数，而是会返回一个协程对象。协程对象需要注册到事件循环，由事件循环调用。
- task 任务：一个协程对象就是一个原生可以挂起的函数，任务则是对协程进一步封装，其中包含任务的各种状态。
- async/await 关键字： 用于定义协程的关键字，async定义一个协程，await用于挂起阻塞的异步调用接口。

## 一、asyncio

下面通过举例来对比同步代码和异步代码编写方面的差异，其次看下两者性能上的差距，使用asyncio.sleep(1)模拟耗时1秒的io操作。

同步代码：

``` cpp
import time

def hello():
    time.sleep(1)

def run():
    for i in range(5):
        hello()
        print('Hello World:%s' % time.time())  
if __name__ == '__main__':
    run()

Hello World:1536842494.2786784
Hello World:1536842495.2796268
Hello World:1536842496.2802596
Hello World:1536842497.2804587
Hello World:1536842498.2812462
```

异步代码：

``` cpp
import time
import asyncio

# 定义异步函数
async def hello():
    print('Hello World:%s' % time.time())
    #必须使用await，不能使用yield from；如果是使用yield from ，需要采用@asyncio.coroutine相对应
    await asyncio.sleep(1)   
    print('Hello wow World:%s' % time.time())

def run():
    tasks = []
    for i in range(5):
        tasks.append(hello())
    loop.run_until_complete(asyncio.wait(tasks))

loop = asyncio.get_event_loop()
if __name__ =='__main__':
    run()

Hello World:1536855050.1950748
Hello World:1536855050.1950748
Hello World:1536855050.1950748
Hello World:1536855050.1960726
Hello World:1536855050.1960726
(暂停约1秒)
Hello wow World:1536855051.1993241
Hello wow World:1536855051.1993241
Hello wow World:1536855051.1993241
Hello wow World:1536855051.1993241
Hello wow World:1536855051.1993241

```
async def 用来定义异步函数，其内部有异步操作。

每个线程有一个事件循环，主线程调用asyncio.get_event_loop()时会创建事件循环，把异步的任务丢给这个循环的run_until_complete()方法，事件循环会安排协同程序的执行。












