---
title: python_线程池6
date: 2023-10-24 8:30:00 +0800
categories: [python,线程池]
tags: [python,线程池]
pin: false
author: 
    name: hejiahua007
    link: https://space.bilibili.com/507838758
toc: true
comments: true
math: false
mermaid: true

---

# Python并发编程之消息队列补充及如何创建线程池（六）

## 创建多线程的两种方式

在使用多线程处理任务时也不是线程越多越好，**由于在切换线程的时候，需要切换上下文环境，依然会造成cpu的大量开销**。为解决这个问题，线程池的概念被提出来了。预先创建好一个较为优化的数量的线程，让过来的任务立刻能够使用，就形成了线程池。

在Python3中，创建线程池是通过concurrent.futures函数库中的ThreadPoolExecutor类来实现的。

```c
import time
import threading
from concurrent.futures import ThreadPoolExecutor


def target():
    for i in range(5):
        print('running thread-{}:{}'.format(threading.get_ident(), i))
        time.sleep(1)

#: 生成线程池最大线程为5个
pool = ThreadPoolExecutor(5) 

for i in range(100):
    pool.submit(target) # 往线程中提交，并运行 

```
从结果来看，前面设置线程池最大线程数5个，有生效。

    running thread-11308:0
    running thread-12504:0
    running thread-5656:0
    running thread-12640:0
    running thread-7948:0

    running thread-11308:1
    running thread-5656:1
    running thread-7948:1
    running thread-12640:1
    running thread-12504:1

    ...
    ...

除了使用上述第三方模块的方法之外，我们还可以自己结合前面所学的消息队列来自定义线程池。

这里我们就使用queue来实现一个上面同样效果的例子，大家感受一下。

```c
import time
import threading
from queue import Queue

def target(q):
    while True:
        msg = q.get()
        for i in range(5):
            print('running thread-{}:{}'.format(threading.get_ident(), i))
            time.sleep(1)

def pool(workers,queue):
    for n in range(workers):
        t = threading.Thread(target=target, args=(queue,))
        t.daemon = True
        t.start()

queue = Queue()
# 创建一个线程池：并设置线程数为5
pool(5, queue)

for i in range(100):
    queue.put("start")

# 消息都被消费才能结束
queue.join()

```

    输出是和上面是完全一样的效果

    running thread-11308:0
    running thread-12504:0
    running thread-5656:0
    running thread-12640:0
    running thread-7948:0

    running thread-11308:1
    running thread-5656:1
    running thread-7948:1
    running thread-12640:1
    running thread-12504:1

    ...
    ...



