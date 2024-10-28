---
title: python_信息隔离5
date: 2023-10-24 11:10:00 +0800
categories: [python,信息隔离]
tags: [python,信息隔离]
pin: false
author: 
    name: hejiahua007
    link: https://space.bilibili.com/507838758
toc: true
comments: true
math: false
mermaid: true

---

# 为什么要使用协程Python并发编程之线程中的信息隔离（五）

# 本文目录

- 初步认识信息隔离
- 信息隔离的意义何在

## 初步认识信息隔离

什么是信息隔离？

比如说，咱有两个线程，线程A里的变量，和线程B里的变量值不能共享。这就是信息隔离。

你可能要说，那变量名取不一样不就好啦？

是的，如果所有的线程都不是由一个class实例化出来的同一个对象，确实是可以。这个问题我们暂且挂着，后面我再说明。

那么，如何实现信息隔离呢？在Python中，其提供了threading.local这个类，可以很方便的控制变量的隔离，即使是同一个变量，在不同的线程中，其值也是不能共享的。

用代码来看下

``` cpp
from threading import local, Thread, currentThread

# 定义一个local实例
local_data = local()
# 在主线中，存入name这个变量
local_data.name = 'local_data'


class MyThread(Thread):
    def run(self):
        print("赋值前-子线程：", currentThread(),local_data.__dict__)
        # 在子线程中存入name这个变量
        local_data.name = self.getName()
        print("赋值后-子线程：",currentThread(), local_data.__dict__)


if __name__ == '__main__':
    print("开始前-主线程：",local_data.__dict__)

    t1 = MyThread()
    t1.start()
    t1.join()

    t2 = MyThread()
    t2.start()
    t2.join()

    print("结束后-主线程：",local_data.__dict__)

```
来看看输出结果

    复制代码开始前-主线程： {'name': 'local_data'}

    赋值前-子线程： <MyThread(Thread-1, started 4832)> {}
    赋值后-子线程： <MyThread(Thread-1, started 4832)> {'name': 'Thread-1'}

    赋值前-子线程： <MyThread(Thread-2, started 5616)> {}
    赋值后-子线程： <MyThread(Thread-2, started 5616)> {'name': 'Thread-2'}

    结束后-主线程： {'name': 'local_data'}

从输出来看，我们可以知道，local实际是一个字典型的对象，其内部可以以key-value的形式存入你要做信息隔离的变量。local实例可以是全局唯一的，只有一个。因为你在给local存入或访问变量时，它会根据当前的线程的不同从不同的存储空间存入或获取。

基于此，我们可以得出以下三点结论：

    主线程中的变量，不会因为其是全局变量，而被子线程获取到；
    主线程也不能获取到子线程中的变量；
    子线程与子线程之间的变量也不能互相访问。

所以如果想在当前线程保存一个全局值，并且各自线程（包括主线程）互不干扰，使用local类吧。

## 信息隔离的意义何在

细心的你，一定已经发现了，上面那个例子，即使我们不用threading.local来做信息隔离，两个线程self.getName()本身就是隔离的，没有任何关系的。因为这两个线程是由一个class实例出的两个不同的实例对象。自然是可以不用做隔离，因为其本身就是隔离的。

但是，现实开发中。不可排除有多个线程，是由一个class实例出的同一个实例对象而实现的。

譬如，现在新手特别喜欢的爬虫项目。通常都是先给爬虫一个主页，然后获取主页下的所有链接，对这个链接再进行遍历，一直往下，直到把所有的链接都爬完，获取到我们所需的内容。

由于单线程的爬取效率实在是太低了，我们考虑使用多线程来工作。先使用socket和www.sina.con.cn建立一个TCP连接。然后在这个连接的基础上，对主页上的每个链接（我们这里只举news.sina.com.cn和blog.sina.com.cn这两个子链接做例子）创建一个线程，这样效率就高多了。

友情提醒：
以下代码，若要理解，可能需要你了解下socket的网络编程相关内容。

``` c
import threading
from functools import partial
from socket import socket, AF_INET, SOCK_STREAM

class LazyConnection:
    def __init__(self, address, family=AF_INET, type=SOCK_STREAM):
        self.address = address
        self.family = AF_INET
        self.type = SOCK_STREAM
        self.local = threading.local()

    def __enter__(self):
        if hasattr(self.local, 'sock'):
            raise RuntimeError('Already connected')
        # 把socket连接存入local中
        self.local.sock = socket(self.family, self.type)
        self.local.sock.connect(self.address)
        return self.local.sock

    def __exit__(self, exc_ty, exc_val, tb):
        self.local.sock.close()
        del self.local.sock

def spider(conn, website):
    with conn as s:
        header = 'GET / HTTP/1.1\r\nHost: {}\r\nConnection: close\r\n\r\n'.format(website)
        s.send(header.encode("utf-8"))
        resp = b''.join(iter(partial(s.recv, 100000), b''))
    print('Got {} bytes'.format(len(resp)))

if __name__ == '__main__':
    # 建立一个TCP连接
    conn = LazyConnection(('www.sina.com.cn', 80))

    # 爬取两个页面
    t1 = threading.Thread(target=spider, args=(conn,"news.sina.com.cn"))
    t2 = threading.Thread(target=spider, args=(conn,"blog.sina.com.cn"))
    t1.start()
    t2.start()
    t1.join()
    t2.join()

```




