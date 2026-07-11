---
title: python_线程锁3
date: 2023-10-24 9:50:00 +0800
categories: [python,多线程]
tags: [python,多线程]
pin: false
author: 
    name: hejiahua007
    link: https://space.bilibili.com/507838758
toc: true
comments: true
math: false
mermaid: true

---
# Python并发编程之谈谈线程中的“锁机制”（三）

今天的内容会比较基础，主要是为了让新手也能无障碍地阅读，所以还是要再巩固下基础。学完了基础，你们也就能很顺畅地跟着我的思路理解以后的文章。

# 本文目录

- 何为Lock（ 锁 ）？
- 如何使用Lock（ 锁 ）？
- 为何要使用锁？
- 可重入锁（RLock）
- 防止死锁的加锁机制
- 饱受争议的GIL（全局锁）
  
## 何为Lock（ 锁 ）？

有一个奇葩的房东，他家里有两个房间想要出租。这个房东很抠门，家里有两个房间，但却只有一把锁，不想另外花钱是去买另一把锁，也不让租客自己加锁。这样租客只有，先租到的那个人才能分配到锁。X先生，率先租到了房子，并且拿到了锁。而后来者Y先生，由于锁已经已经被X取走了，自己拿不到锁，也不能自己加锁，Y就不愿意了。也就不租了，换作其他人也一样，没有人会租第二个房间，直到X先生退租，把锁还给房东，可以让其他房客来取。第二间房间才能租出去。

换句话说，就是房东同时只能出租一个房间，一但有人租了一个房间，拿走了唯一的锁，就没有人再在租另一间房了。

回到我们的线程中来，有两个线程A和B，A和B里的程序都加了同一个锁对象，当线程A率先执行到lock.acquire()(拿到全局唯一的锁后)，线程B只能等到线程A释放锁lock.release()后（归还锁）才能运行lock.acquire()（拿到全局唯一的锁）并执行后面的代码。

## 如何使用Lock（ 锁 ）？

来简单看下代码，学习如何加锁，获取钥匙，释放锁。
``` cpp
import threading

# 生成锁对象，全局唯一
lock = threading.Lock()

# 获取锁。未获取到会阻塞程序，直到获取到锁才会往下执行
lock.acquire()

# 释放锁，归回倘，其他人可以拿去用了
lock.release()

```
需要注意的是，lock.acquire() 和 lock.release()必须成对出现。否则就有可能造成死锁。

很多时候，我们虽然知道，他们必须成对出现，但是还是难免会有忘记的时候。
为了，规避这个问题。我推荐使用使用上下文管理器来加锁。

``` cpp
import threading

lock = threading.Lock()
with lock:
    # 这里写自己的代码
    pass
```

with 语句会在这个代码块执行前自动获取锁，在执行结束后自动释放锁。

## 为何要使用锁？

你现在肯定还是一脸懵逼，这么麻烦，我不用锁不行吗？有的时候还真不行。

那么为了说明锁存在的意义。我们分别来看下，不用锁的情形有怎样的问题。

定义两个函数，分别在两个线程中执行。这两个函数 共用 一个变量 n 。
``` cpp
def job1():
    global n
    for i in range(10):
        n+=1
        print('job1',n)

def job2():
    global n
    for i in range(10):
        n+=10
        print('job2',n)

n=0
t1=threading.Thread(target=job1)
t2=threading.Thread(target=job2)
t1.start()
t2.start()

```
看代码貌似没什么问题，执行下看看输出

    job1 1
    job1 2
    job1 job2 13
    job2 23
    job2 333
    job1 34
    job1 35
    job2
    job1 45 46
    job2 56
    job1 57
    job2
    job1 67
    job2 68 78
    job1 79
    job2
    job1 89
    job2 90 100
    job2 110

是不是很乱？完全不是我们预想的那样。

解释下这是为什么？因为两个线程共用一个全局变量，又由于两线程是交替执行的，当job1 执行三次 +1 操作时，job2就不管三七二十一 给n做了+10操作。两个线程之间，执行完全没有规矩，没有约束。所以会看到输出当然也很乱。

加了锁后，这个问题也就解决，来看看

``` cpp
def job1():
    global n, lock
    # 获取锁
    lock.acquire()
    for i in range(10):
        n += 1
        print('job1', n)
    lock.release()


def job2():
    global n, lock
    # 获取锁
    lock.acquire()
    for i in range(10):
        n += 10
        print('job2', n)
    lock.release()

n = 0
# 生成锁对象
lock = threading.Lock()

t1 = threading.Thread(target=job1)
t2 = threading.Thread(target=job2)
t1.start()
t2.start()

```
由于job1的线程，率先拿到了锁，所以在for循环中，没有人有权限对n进行操作。当job1执行完毕释放锁后，job2这才拿到了锁，开始自己的for循环。

看看执行结果，真如我们预想的那样。

    job1 1
    job1 2
    job1 3
    job1 4
    job1 5
    job1 6
    job1 7
    job1 8
    job1 9
    job1 10
    job2 20
    job2 30
    job2 40
    job2 50
    job2 60
    job2 70
    job2 80
    job2 90
    job2 100
    job2 110

## 可重入锁（RLock）

有时候在同一个线程中，我们可能会多次请求同一资源（就是，获取同一锁钥匙），俗称锁嵌套。

如果还是按照常规的做法，会造成死锁的。比如，下面这段代码，你可以试着运行一下。会发现并没有输出结果。

``` cpp
import threading

def main():
    n = 0
    lock = threading.Lock()
    with lock:
        for i in range(10):
            n += 1
            with lock:
                print(n)

t1 = threading.Thread(target=main)
t1.start()

```
是因为，第二次获取锁时，发现锁已经被同一线程的人拿走了。自己也就理所当然，拿不到锁，程序就卡住了。

那么如何解决这个问题呢。

threading模块除了提供Lock锁之外，还提供了一种可重入锁RLock，专门来处理这个问题。

threading模块除了提供Lock锁之外，还提供了一种可重入锁RLock，专门来处理这个问题。

``` cpp
import threading

def main():
    n = 0
    # 生成可重入锁对象
    lock = threading.RLock()
    with lock:
        for i in range(10):
            n += 1
            with lock:
                print(n)

t1 = threading.Thread(target=main)
t1.start()

```
执行一下，发现已经有输出了。

    1
    2
    3
    4
    5
    6
    7
    8
    9
    10

需要注意的是，可重入锁，只在同一线程里，放松对锁钥匙的获取，其他与Lock并无二致。

## 防止死锁的加锁机制

在编写多线程程序时，可能无意中就会写了一个死锁。可以说，死锁的形式有多种多样，但是**本质都是相同的，都是对资源不合理竞争的结果。**

以本人的经验总结，死锁通常以下几种

- 同一线程，嵌套获取同把锁，造成死锁。 
- 多个线程，不按顺序同时获取多个锁。造成死锁   

对于第一种，上面已经说过了，使用可重入锁。

主要是第二种。可能你还没明白，是如何死锁的。
举个例子。

    线程1，嵌套获取A,B两个锁，线程2，嵌套获取B,A两个锁。由于两个线程是交替执行的，是有机会遇到线程1获取到锁A，而未获取到锁B，在同一时刻，线程2获取到锁B，而未获取到锁A。由于锁B已经被线程2获取了，所以线程1就卡在了获取锁B处，由于是嵌套锁，线程1未获取并释放B，是不能释放锁A的，这是导致线程2也获取不到锁A，也卡住了。两个线程，各执一锁，各不让步。造成死锁。

经过数学证明，只要两个（或多个）线程获取嵌套锁时，按照固定顺序就能保证程序不会进入死锁状态。

那么问题就转化成如何保证这些锁是按顺序的？

有两个办法

人工自觉，人工识别。
写一个辅助函数来对锁进行排序。
第一种，就不说了。

第二种，可以参考如下代码

``` cpp
import threading
from contextlib import contextmanager

# Thread-local state to stored information on locks already acquired
_local = threading.local()

@contextmanager
def acquire(*locks):
    # Sort locks by object identifier
    locks = sorted(locks, key=lambda x: id(x))

    # Make sure lock order of previously acquired locks is not violated
    acquired = getattr(_local,'acquired',[])
    if acquired and max(id(lock) for lock in acquired) >= id(locks[0]):
        raise RuntimeError('Lock Order Violation')

    # Acquire all of the locks
    acquired.extend(locks)
    _local.acquired = acquired

    try:
        for lock in locks:
            lock.acquire()
        yield
    finally:
        # Release locks in reverse order of acquisition
        for lock in reversed(locks):
            lock.release()
        del acquired[-len(locks):]


```
如何使用呢？
``` cpp
import threading
x_lock = threading.Lock()
y_lock = threading.Lock()

def thread_1():

    while True:
        with acquire(x_lock):
            with acquire(y_lock):
                print('Thread-1')

def thread_2():
    while True:
        with acquire(y_lock):
            with acquire(x_lock):
                print('Thread-2')

t1 = threading.Thread(target=thread_1)
t1.daemon = True
t1.start()

t2 = threading.Thread(target=thread_2)
t2.daemon = True
t2.start()
```

看到没有，表面上thread_1的先获取锁x，再获取锁y，而thread_2是先获取锁y，再获取x。

但是实际上，acquire函数，已经对x，y两个锁进行了排序。所以thread_1，hread_2都是以同一顺序来获取锁的，是不是造成死锁的。

## 饱受争议的GIL（全局锁）

多进程是真正的并行，而多线程是伪并行，实际上他只是交替执行。

是什么导致多线程，只能交替执行呢？是一个叫GIL（Global Interpreter Lock，全局解释器锁）的东西。

什么是GIL呢？

任何Python线程执行前，必须先获得GIL锁，然后，每执行100条字节码，解释器就自动释放GIL锁，让别的线程有机会执行。这个GIL全局锁实际上把所有线程的执行代码都给上了锁，所以，多线程在Python中只能交替执行，即使100个线程跑在100核CPU上，也只能用到1个核。

需要注意的是，GIL并不是Python的特性，它是在实现Python解析器(CPython)时所引入的一个概念。而Python解释器，并不是只有CPython，除它之外，还有PyPy，Psyco，JPython，IronPython等。

在绝大多数情况下，我们通常都认为 Python == CPython，所以也就默许了Python具有GIL锁这个事。

都知道GIL影响性能，那么如何避免受到GIL的影响？

使用多进程代替多线程。
更换Python解释器，不使用CPython




















