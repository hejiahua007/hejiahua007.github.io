---
title: python_创建多线程2
date: 2023-10-24 8:30:00 +0800
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
# Python并发编程之创建多线程的几种方法（二）

今天的内容会比较基础，主要是为了让新手也能无障碍地阅读，所以还是要再巩固下基础。学完了基础，你们也就能很顺畅地跟着我的思路理解以后的文章。

# 本文目录

- 学会使用函数创建多线程
- 学会使用类创建多线程
- 多线程：必学函数讲解
经过总结，Python创建多线程主要有如下两种方法：
- 函数
- 类

# 学会使用函数创建多线程

在Python3中，Python提供了一个内置模块 threading.Thread，可以很方便地让我们创建多线程。

threading.Thread() 一般接收两个参数：
    - 线程函数名：要放置线程让其后台执行的函数，由我们自已定义，注意不要加()；
    - 线程函数的参数：线程函数名所需的参数，以元组的形式传入。若不需要参数，可以不指定。
  
举个例子

![image](/assets/blog_res/2023-10-24-python_duoxiancheng/image.png)

可以看到输出

    hello Python
    hello MING
    hello Python
    hello MING

# 学会使用类创建多线程

相比较函数而言，使用类创建线程，会比较麻烦一点。

首先，我们要自定义一个类，对于这个类有两点要求，

- 必须继承 threading.Thread 这个父类；
- 必须覆写 run 方法。
  
这里的 run 方法，和我们上面线程函数的性质是一样的，可以写我们的业务逻辑程序。在 start() 后将会调用。

来看一下例子，为了方便对比，run函数我复用上面的main。

![image-1](/assets/blog_res/2023-10-24-python_duoxiancheng/image-1.png)

当然结果也是一样的。

    hello Python
    hello MING
    hello Python
    hello MING

# 多线程：必学函数讲解

学完了两种创建线程的方式，你一定会惊叹，咋么这么简单，一点难度都没有。

其实不然，上面我们的线程函数 为了方便理解，都使用的最简单的代码逻辑。而在实际使用当中，多线程运行期间，还会出现诸多问题，只是我们现在还没体会到它的复杂而已。

不过，你也不必担心，在后面的章节中，我会带着大家一起来探讨一下，都有哪些难题，应该如何解决。

磨刀不误吹柴工，我们首先得来认识一下，Python给我们提供的 Thread 都有哪些函数和属性，实现哪些功能。

学习完这些，在后期的学习中，我们才能更加得以应手。经过我的总结，大约常用的方法有如下这些：

![image-2](/assets/blog_res/2023-10-24-python_duoxiancheng/image-2.png)










