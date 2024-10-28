---
title: python环境复制
date: 2023-10-14 21:50:00 +0800
categories: [python]
tags: [python环境]
pin: false
author: 
    name: hejiahua007
    link: https://space.bilibili.com/507838758
toc: true
comments: true
math: false
mermaid: true

---

### Python venv创建的虚拟环境复制到其他路径，如何断开与原始虚拟环境的连接，成为一个全新的虚拟环境，且两个虚拟环境之间的更新互不影响？

传统方法可能就是使用pip freeze和pip install命令来依次安装requirements.txt中的包。

这个时候可能有些同志就想起了，我直接将已有的venv环境复制到其他地方不就行了吗？

因为直接复制过去，虽然你能使用\venv\Scripts\activate激活虚拟环境，但你的环境其实指向的还是老环境的python环境，不信我们看：

直接激活新环境的虚拟环境，然后输入where python：

注：我这里已有的venv环境位于：E:\Code\Python\Git\stable-diffusion-webui
新的venv环境位于：E:\Code\Python\Git\kohya_ss

特别是如果你使用where pip命令，返回的路径是你新venv的路径：

但实际pip依然是老venv中的pip：

这意味着你如果要在新的环境安装其他版本的软件包，修改的却是老版本的venv软件包，这样还可能导致老的venv因为包冲突而无法使用！

3.解决方法🐡

这其实是因为你粗暴的将老环境复制过来，其中文件中的指向依然是老环境，因此，我们只需要将这些文件中的路径指向新环境即可！

3.1.方法

1：先复制所有软件包，然后直接修改路径指向

将venv\pyvenv.cfg文件内的home修改为新venv的安装路径：

![image](/assets/blog_res/2023-10-14-pythonvenv/image.png)

如我这边使用conda安装的python，就直接将紫框中的内容修改为：

E:\Code\Python\Git\kohya_ss\conda\py3106。如果你是独立下载python安装包，那就填入python的安装路径！

2：修改venv\Scripts\activate中的VIRTUAL_ENV指向新的venv路径

![image-1](/assets/blog_res/2023-10-14-pythonvenv/image-1.png)

3：修改venv\Scripts\activate.bat中的VIRTUAL_ENV指向新的venv路径

![image-2](/assets/blog_res/2023-10-14-pythonvenv/image-2.png)

4：重新安装pip

首先激活新venv，然后卸载新环境中的旧pip：

python -m pip uninstall pip

然后重新安装pip， 这个时候你可以选择去官网下载pip安装包进行，但是这样感觉有点太麻烦了，推荐直接使用如下命令安装：

python -m ensurepip --default-pip

并升级到最新版本：

python -m pip install --upgrade pip

转自：Python直接复制已有的venv虚拟环境以创建新的虚拟环境_virtualenv复制环境_任博啥时候能毕业？的博客-CSDN博客

