---
title: python_线程间的通信4
date: 2023-10-24 10:30:00 +0800
categories: [python,线程通信]
tags: [python,线程通信]
pin: false
author: 
    name: hejiahua007
    link: https://space.bilibili.com/507838758
toc: true
comments: true
math: false
mermaid: true

---
# Python并发编程之线程消息通信机制任务协调（四）

# 本文目录

- 前言
- Event事件
- Condition
- Queue队列
- 总结

## 前言

今天，我们就来探讨一下如何控制线程的触发执行。

要实现对多个线程进行控制，其实本质上就是消息通信机制在起作用，利用这个机制发送指令，告诉线程，什么时候可以执行，什么时候不可以执行，执行什么内容。
经过我的总结，线程中通信方法大致有如下三种：

- threading.Event
- threading.Condition
- queue.Queue

先抛出结论，接下来我们来一一探讨下。

## Event事件

Python提供了非常简单的通信机制 Threading.Event，通用的条件变量。多个线程可以等待某个事件的发生，在事件发生后，所有的线程都会被激活。

关于Event的使用也超级简单，就三个函数

``` cpp
event = threading.Event()

# 重置event，使得所有该event事件都处于待命状态
event.clear()

# 等待接收event的指令，决定是否阻塞程序执行
event.wait()

# 发送event指令，使所有设置该event事件的线程执行
event.set()

```
举个例子来看下。

``` cpp
import time
import threading


class MyThread(threading.Thread):
    def __init__(self, name, event):
        super().__init__()
        self.name = name
        self.event = event

    def run(self):
        print('Thread: {} start at {}'.format(self.name, time.ctime(time.time())))
        # 等待event.set()后，才能往下执行
        self.event.wait()
        print('Thread: {} finish at {}'.format(self.name, time.ctime(time.time())))


threads = []
event = threading.Event()

# 定义五个线程
[threads.append(MyThread(str(i), event)) for i in range(1,5)]

# 重置event，使得event.wait()起到阻塞作用
event.clear()

# 启动所有线程
[t.start() for t in threads]

print('等待5s...')
time.sleep(5)

print('唤醒所有线程...')
event.set()
```
执行一下，看看结果

    Thread: 1 start at Sun May 13 20:38:08 2018
    Thread: 2 start at Sun May 13 20:38:08 2018
    Thread: 3 start at Sun May 13 20:38:08 2018
    Thread: 4 start at Sun May 13 20:38:08 2018

    等待5s...

    唤醒所有线程...
    Thread: 1 finish at Sun May 13 20:38:13 2018
    Thread: 4 finish at Sun May 13 20:38:13 2018
    Thread: 2 finish at Sun May 13 20:38:13 2018
    Thread: 3 finish at Sun May 13 20:38:13 2018

可见在所有线程都启动（start()）后，并不会执行完，而是都在self.event.wait()止住了，需要我们通过event.set()来给所有线程发送执行指令才能往下执行。

## Condition

Condition和Event 是类似的，并没有多大区别。

同样，Condition也只需要掌握几个函数即可。

``` cpp
cond = threading.Condition()

# 类似lock.acquire()
cond.acquire()

# 类似lock.release()
cond.release()

# 等待指定触发，同时会释放对锁的获取,直到被notify才重新占有琐。
cond.wait()

# 发送指定，触发执行
cond.notify()

```
举个网上一个比较趣的捉迷藏的例子来看看

```cpp 
import threading, time

class Hider(threading.Thread):
    def __init__(self, cond, name):
        super(Hider, self).__init__()
        self.cond = cond
        self.name = name

    def run(self):
        time.sleep(1)  #确保先运行Seeker中的方法
        self.cond.acquire()

        print(self.name + ': 我已经把眼睛蒙上了')
        self.cond.notify()
        self.cond.wait()
        print(self.name + ': 我找到你了哦 ~_~')
        self.cond.notify() 

        self.cond.release()
        print(self.name + ': 我赢了')

class Seeker(threading.Thread):
    def __init__(self, cond, name):
        super(Seeker, self).__init__()
        self.cond = cond
        self.name = name

    def run(self):
        self.cond.acquire()
        self.cond.wait()
        print(self.name + ': 我已经藏好了，你快来找我吧')
        self.cond.notify()
        self.cond.wait()
        self.cond.release()
        print(self.name + ': 被你找到了，哎~~~')

cond = threading.Condition()
seeker = Seeker(cond, 'seeker')
hider = Hider(cond, 'hider')
seeker.start()
hider.start()

```
通过cond来通信，阻塞自己，并使对方执行。从而，达到有顺序的执行。

看下结果

    hider:   我已经把眼睛蒙上了
    seeker:  我已经藏好了，你快来找我吧
    hider:   我找到你了 ~_~
    hider:   我赢了
    seeker:  被你找到了，哎~~~


## Queue队列

终于到了我们今天的主角了。
从一个线程向另一个线程发送数据最安全的方式可能就是使用 queue 库中的队列了。创建一个被多个线程共享的 Queue 对象，这些线程通过使用put() 和 get() 操作来向队列中添加或者删除元素。 
同样，对于Queue，我们也只需要掌握几个函数即可。
复制代码

``` cpp
from queue import Queue
# maxsize默认为0，不受限
# 一旦>0，而消息数又达到限制，q.put()也将阻塞
q = Queue(maxsize=0)

# 阻塞程序，等待队列消息。
q.get()

# 获取消息，设置超时时间
q.get(timeout=5.0)

# 发送消息
q.put()

# 等待所有的消息都被消费完
q.join()

# 以下三个方法，知道就好，代码中不要使用

# 查询当前队列的消息个数
q.qsize()

# 队列消息是否都被消费完，True/False
q.empty()

# 检测队列里消息是否已满
q.full()

```

函数会比之前的多一些，同时也从另一方面说明了其功能更加丰富。

举个老师点名的例子。

``` cpp
from queue import Queue
from threading import Thread
import time

class Student(Thread):
    def __init__(self, name, queue):
        super().__init__()
        self.name = name
        self.queue = queue

    def run(self):
        while True:
            # 阻塞程序，时刻监听老师，接收消息
            msg = self.queue.get()
            # 一旦发现点到自己名字，就赶紧答到
            if msg == self.name:
                print("{}：到！".format(self.name))


class Teacher:
    def __init__(self, queue):
        self.queue=queue

    def call(self, student_name):
        print("老师：{}来了没？".format(student_name))
        # 发送消息，要点谁的名
        self.queue.put(student_name)


queue = Queue()
teacher = Teacher(queue=queue)
s1 = Student(name="小明", queue=queue)
s2 = Student(name="小亮", queue=queue)
s1.start()
s2.start()

print('开始点名~')
teacher.call('小明')
time.sleep(1)
teacher.call('小亮')

```
运行结果如下

    开始点名~
    老师：小明来了没？
    小明：到！
    老师：小亮来了没？
    小亮：到！

## 总结

学习了以上三种通信方法，我们很容易就能发现Event 和 Condition 是threading模块原生提供的模块，原理简单，功能单一，它能发送 True 和 False 的指令，所以只能适用于某些简单的场景中。

而Queue则是比较高级的模块，它可能发送任何类型的消息，包括字符串、字典等。其内部实现其实也引用了Condition模块（譬如put和get函数的阻塞），正是其对Condition进行了功能扩展，所以功能更加丰富，更能满足实际应用。

**补充**

## 消息队列的先进先出

首先，要告诉大家的事，消息队列可不是只有queue.Queue这一个类，除它之外，还有queue.LifoQueue和queue.PriorityQueue这两个类。

从名字上，对于他们之间的区别，你大概也能猜到一二吧。

    queue.Queue：先进先出队列
    queue.LifoQueue：后进先出队列
    queue.PriorityQueue：优先级队列

先来看看，我们的老朋友，queue.Queue。

所谓的先进先出（FIFO，First in First Out），就是先进入队列的消息，将优先被消费。

这和我们日常排队买菜是一样的，先排队的人肯定是先买到菜。

用代码来说明一下

```c
import queue

q = queue.Queue()

for i in range(5):
    q.put(i)

while not q.empty():
    print q.get()
```
看看输出，符合我们先进先出的预期。存入队列的顺序是01234，被消费的顺序也是01234。

    0
    1
    2
    3
    4

再来看看Queue.LifoQueue，后进先出，就是后进入消息队列的，将优先被消费。

这和我们羽毛球筒是一样的，最后放进羽毛球筒的球，会被第一个取出使用。

用代码来看下

```c
import queue

q = queue.LifoQueue()

for i in range(5):
    q.put(i)

while not q.empty():
    print q.get()
```
来看看输出，符合我们后进后出的预期。存入队列的顺序是01234，被消费的顺序也是43210。

    4
    3
    2
    1
    0

最后来看看Queue.PriorityQueue，优先级队列。
这和我们日常生活中的会员机制有些类似，办了金卡的人比银卡的服务优先，办了银卡的人比不办卡的人服务优先。

来用代码看一下
```c
from queue import PriorityQueue

# 重新定义一个类，继承自PriorityQueue
class MyPriorityQueue(PriorityQueue):
    def __init__(self):
        PriorityQueue.__init__(self)
        self.counter = 0

    def put(self, item, priority):
        PriorityQueue.put(self, (priority, self.counter, item))
        self.counter += 1

    def get(self, *args, **kwargs):
        _, _, item = PriorityQueue.get(self, *args, **kwargs)
        return item


queue = MyPriorityQueue()
queue.put('item2', 2)
queue.put('item5', 5)
queue.put('item3', 3)
queue.put('item4', 4)
queue.put('item1', 1)

while True:
    print(queue.get())

```
来看看输出，符合我们的预期。我们存入入队列的顺序是25341，对应的优先级也是25341，可是被消费的顺序丝毫不受传入顺序的影响，而是根据指定的优先级来消费。

    item1
    item2
    item3
    item4
    item5
