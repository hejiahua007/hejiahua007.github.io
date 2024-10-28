---
title: 树莓派——python版本切换/环境搭建
date: 2023-11-20 14:00:00 +0800
categories: [树莓派]
tags: [树莓派]
pin: false
author: 
    name: hejiahua007
    link: https://space.bilibili.com/507838758
toc: true
comments: true
math: false
mermaid: true

---
使用VNC连接树莓派4b如何全屏1080p分辨率，一次更改永久有效！
(171条消息) 使用VNC连接树莓派4b如何全屏1080p分辨率，一次更改永久有效！_树莓派4b vnc分辨率_irohaBestKouhai的博客-CSDN博客

## 前言

由于树莓派中的python版本过新，导致部分库没能找到对应的版本，于是乎要删除python3.10，安装python3.7

## 卸载python3.10

这是已经安装了的库
![image](/assets/blog_res/2023-11-16-raspberry_python3.7_change/image.png)

卸载流程：

步骤1：确认Python3的版本

python3 --version

步骤2：卸载Python3

sudo apt-get --purge remove python3

步骤3：清理残留文件

在卸载Python3之后，可能会残留一些文件。为了彻底清理，我们可以使用以下命令：

sudo apt-get autoremove

## 安装python3.7

1 更新树莓派系统

    sudo apt-get update
    sudo apt-get upgrade -y

2 安装python环境

sudo apt-get install build-essential libsqlite3-dev sqlite3 bzip2 libbz2-dev

3 下载python

    #先进行下载
    $ wget https://www.python.org/ftp/python/3.7.0/Python-3.7.0.tgz
    
    #解压
    $ tar zxvf Python-3.7.0.tgz
    
    #切换到目录
    $ cd Python-3.7.0
    
    #编译
    $sudo ./configure
    $sudo make
    $sudo make install
    
    #升级pip
    sudo python3.7 -m pip install upgrade pip

![image-1](/assets/blog_res/2023-11-16-raspberry_python3.7_change/image-1.png)

这里下载太慢了，换源试试看

## 树莓派换源

第一步，先备份源文件，主要有两条命令。

sudo cp /etc/apt/sources.list    /etc/apt/sources.list.bak

sudo cp  /etc/apt/sources.list.d/raspi.list   /etc/apt/sources.list.d/raspi.list.bak

第二步，修改编辑系统源文件

    怎么查看树莓派 | Linux 系统是多少位以及系统版本

    查看系统位数
    查看树莓派系统或者是 Linux 系统是多少位系统的命令：
    getconf LONG_BIT
    如果结果返回 32，说明是 32 位系统；
    如果结果返回 64，说明是 64 位系统。我是32位

    查看系统版本
    键入如下命令：uname -a 即可查看当前系统版本：
    Linux raspberrypi 5.10.63-v7l+ #1457 SMP Tue Sep 28 11:26:14 BST 2021 armv7l GNU/Linux

    查看树莓派系统版本
    lsb_release -a
    oot@raspberrypi:/home/pi/Desktop# lsb_release -a
    No LSB modules are available.
    Distributor ID:	Raspbian
    Description:	Raspbian GNU/Linux 10 (buster)
    Release:	10
    Codename:	buster
    root@raspberrypi:/home/pi/Desktop# apt-get install lldb


![image-2](/assets/blog_res/2023-11-16-raspberry_python3.7_change/image-2.png)

我这里安装树莓派系统的时候是buster，在写系统源链接时要注意是buster，网上很多教程都是之前stretch版本，大家应该根据自己的系统类型，谨慎选择！参考文章如下：
https://shumeipai.nxez.com/2019/06/26/buster-the-new-version-of-raspbian.html

sudo nano /etc/apt/sources.list

将初始的源使用#注释掉，添加如下两行清华的镜像源。

deb http://mirrors.tuna.tsinghua.edu.cn/raspbian/raspbian/ buster main contrib non-free rpi

deb-src http://mirrors.tuna.tsinghua.edu.cn/raspbian/raspbian/ buster main contrib non-free rpi

第三步，更改系统源

sudo nano /etc/apt/sources.list.d/raspi.list

用#注释掉原文件内容用以下内容取代：用#注释掉原文件内容，用以下内容取代：

deb http://mirrors.tuna.tsinghua.edu.cn/raspberrypi/ buster main ui

deb-src http://mirrors.tuna.tsinghua.edu.cn/raspberrypi/ buster main ui

第四步，执行更新

使用命令有两条，第一条，检查更新索引：

sudo apt-get update

第二条，更新可以更新的文件。

sudo apt-get upgrade

写在最后。如果大家更新后出现文件管理器闪退，或者桌面失去响应之类的问题。建议使用如下命令：

sudo apt-get update 

sudo apt full-upgrade


![image-4](/assets/blog_res/2023-11-16-raspberry_python3.7_change/image-4.png)

更新完后这个界面奇奇怪怪的，重新安装系统，用回原版的python

## 转载，加深理解

https://zhuanlan.zhihu.com/p/110951061

    引子

    在 DIY 树莓派各种项目的时候，总要安装各种各样的软件包，一般执行 sudo apt-get install <package> 指令就可以完成安装。如果下载速度太慢，还可以 更换软件源 加速下载。

    树莓派初学者通常到这里就结束了，但如果你想基于树莓派进一步学习 Linux 知识，成为树莓派高阶玩家，就非常有必要了解 apt-get 这条指令背后的原理，以及 Debian 系的包管理知识。

    树莓派官方的 Raspbian 操作系统是 Debian 的衍生版，共用 Debian 的软件包管理机制，两者是相通的。

    起初 GNU/Linux 的世界中只有 .tar.gz。如果用户要使用一个软件，那就必须自己编译。当 Debian 诞生以后，一种能管理操作系统中已安装的软件包的系统显得很有必要，这个系统被命名为 dpkg。软件包一词在此第一次出现在 GNU/Linux。不久之后，红帽公司创建了他们自己的包管理系统 rpm。
    GNU/Linux 的创造者们很快又陷入了新的窘境。他们希望通过一种快捷、实用而且高效的方式来安装软件包，并能自动处理相互之间的依赖关系，还要在软件包升级过程中维护好配置文件。Debian 又一次充当了开路先锋的角色，首创了 APT（Advanced Packaging Tool，高级软件包管理工具）。这一工具后来被 Conectiva 移植到红帽公司的 rpm 包管理系统。在其他一些发行版中，我们也能看到 APT 的身影。

    dpkg (Debian Package)
    在 Linux 发展之初，安装软件的时候是需要下载以 tar.gz 结尾的软件源码包，然后对源码包进行编译安装。这是极其麻烦的使用。后来 Debian 开发了 dpkg(Debian Package) 管理工具来管理软件，软件都是以 deb 结尾的编译好的二进制包，通过 dpkg 命令可以安装软件和卸载软件。

    dpkg -i - 安装软件包
    dpkg -r - 移除软件包
    dpkg -l - 查看某个软件包是否已经安装
    dpkg -L - 查看某个软件包中都包含哪些文件
    dpkg --list - 查看系统上安装的所有软件包和相关状态
    dpkg 是底层的包管理工具，不太常用，最常用的是 apt。

    APT (Advanced Packaging Tool)
    ​dpkg 不够人性化的一点就是不能自动解决依赖问题，比如 A 软件包依赖于 B 软件包，那么你先得安装 B 才能安装 A。而且使用 dpkg 需要将软件下载到本地才能安装。使用 apt 安装软件时会自动从软件仓库下载软件进行安装，并且 apt 能自动解决依赖问题，当有依赖的时候它也会自动从软件仓库下载依赖的包进行安装。当然 apt 底层还是调用 dpkg 来进行软件安装的。

    apt相关文件

    /etc/apt/source.list 配置软件包来源，也就是上面说的软件仓库
    /ect/apt/apt.conf.d 存在apt的零碎配置文件
    /ect/apt/preferences 制定软件包的版本参数
    /var/cache/apt/archives 存放已下载的软件包
    /var/cache/apt/archives/partial 存放正在下载的软件包
    /var/lib/apt/lists 存放已下载的软件包详细信息
    树莓派的 APT 相关配置文件：

![image-5](/assets/blog_res/2023-11-16-raspberry_python3.7_change/image-5.png)

![image-6](/assets/blog_res/2023-11-16-raspberry_python3.7_change/image-6.png)

![image-7](/assets/blog_res/2023-11-16-raspberry_python3.7_change/image-7.png)

    软件源
    软件源(软件仓库)中存放这大量的软件包，apt 会从软件源中下载软件。在 /ect/apt/soure.list 中可以为 apt 配置软件源。在这个文件中 deb 关键字定义已编译的软件包来源，deb-src 定义源码包的来源。每一行的格式如下：

    deb(或deb-src) <软件源地址> <主版本代号> [软件仓库1] [软件仓库2] [软件仓库3] ...
    树莓派的软件仓库一般有四种限定词：

    main：官方支持的符合 DFSG 规范的软件
    contrib：带有非自由依赖关系的 DFSG 兼容软件
    non-free：非 DFSG 兼容软件
    firmware：官方固件，非开源
    DFSG 即 Debian Free Software Guidelines、自由软件指导方针，比如规定软件必须开源等。详细说明见： Debian 社群契约
    树莓派的默认软件源配置：

    deb http://raspbian.raspberrypi.org/raspbian/ buster main contrib non-free rpi
    deb-src http://raspbian.raspberrypi.org/raspbian/ buster main contrib non-free rpi
    软件源里面有什么？如果你在浏览器上打开软件源 url http://raspbian.raspberrypi.org/raspbian/，会发现它其实是一个静态资源目录：

![image-8](/assets/blog_res/2023-11-16-raspberry_python3.7_change/image-8.png)

    dists 目录包含 Raspbian 的各个发行版，既包括像 buster 一样的具体发行版本，也包括像 stable、testing 和 unstable 的代号
    pool 目录为软件包的下载地址。为了方便管理，pool 目录下会继续划分 main、contrib 和 non-free 等子目录。比如 python3 就位于 pool/main/p/python3-defaults 这个目录下。
    apt-get 命令
    apt-get 命令一般用于软件包的安装，更新和移除

    apt-get update - 更新本地的软件源索引。在你更改了 Raspbian 的 /etc/apt/sources.list 或 /etc/apt/preferences 后，需要运行这个命令让改动生效。最好能定期运行该命令，以确保软件源索引是最新的。
    apt-get upgrade - 更新所有已安装的软件包
    apt-get install - 安装软件包
    apt-get reinstall - 重装软件包
    apt-get remove - 删除已安装的软件包（保留配置文件）
    apt-get purge- 删除已安装包，同时删除配置文件
    apt-get autoremove - 删除未使用的安装包
    apt-get dist-upgrade - 更新整个系统到最新的发行版，相当于升级 Raspbian 系统
    apt-get clean - 删除本地所有的 deb 包（不会删除软件）
    apt-get autoclean - 删除本地已经安装过的 deb 包
    apt-get check - 检查是否存在未安装的软件包依赖
    apt-get source - 下载 deb 源码包到本地
    apt-get download - 下载 deb 包到本地
    apt-get changelog- 打印软件包的版本变更日志
    apt-cache 命令
    apt-cache 一般用于软件包查找和显示软件包信息。

    apt-cache search - 搜索软件包。当你不知道软件包全名的时候，可以用这个指令搜索关键词
    apt-cache depends - 打印软件包的依赖包信息
    apt-cache rdepends - 打印依赖这个包的软件包信息（反向依赖）
    常用命令组合
    查看系统上安装的软件包
    查看系统上安装的所有软件包和相关状态，执行

    dpkg --list
    输出每个软件包的一行简单介绍，2 字符的状态标志，包名，所安装版本和简要描述。

![image-9](/assets/blog_res/2023-11-16-raspberry_python3.7_change/image-9.png)

    如果要过滤包名，比如只显示 python 开头的包，执行

    dpkg --list python*
    要获取软件包的更详细信息，比如 python3，执行:

    dpkg --status python3
    输出状态、版本号、依赖包等信息。

![image-10](/assets/blog_res/2023-11-16-raspberry_python3.7_change/image-10.png)

    列出软件包包含的文件
    要找出一个软件包包含的所有文件，比如找出 rclone 安装过程中生成了哪些文件，执行：

    dpkg --listfiles rclone

![image-11](/assets/blog_res/2023-11-16-raspberry_python3.7_change/image-11.png)

    rclone 一是款文件同步工具，支持本地文件和 Microsoft OneDrive，Amazon Cloud Drive，Dropbox，FTP，SSH/SFTP 等多种云存储同步 —— 如何在树莓派上免费获取 GB 级存储空间 - 硬核树莓派
    也可以直接查看 deb 包内的文件，执行：

    dpkg-deb --contents rclone_1.45-3_armhf.deb

![image-12](/assets/blog_res/2023-11-16-raspberry_python3.7_change/image-12.png)

    还可以把 deb 包内的文件解压到当前的 temp 目录（这不是安装，而是在本地目录测试包内容的简单方法），执行：

    dpkg-deb --extract rclone_1.45-3_armhf.deb temp
    但如果你只想知道某个文件是哪个软件包生成的，执行：

    dpkg --search rclone

![image-13](/assets/blog_res/2023-11-16-raspberry_python3.7_change/image-13.png)

    其他常用命令
    Raspbian 不一定默认带有下面这些命令。如果没有的话，apt-get install 安装即可。

    apt-show-versions - 打印系统中所有已安装的包的当前版本和可升级版本
    apt-config - apt 的配置工具
    tasksel - 用于安装软件集，例如一键安装 gnome 桌面、xfce 桌面等等。--list-tasks 参数可以列出所有支持的软件集。
    dselect - 包管理系统的图形菜单界面，对第一次安装和大范围升级特别有用
    dpkg-deb - 用于操作 deb 文件，比如探查包内文件等
    dpkg-split - 大软件包分割工具，例如把一个大 deb 分割成 N 部分，每部分 460KB


## 环境搭建最终版
源：

    #查看系统版本
    root@raspberrypi:/home/pi/Desktop# lsb_release -a
    No LSB modules are available.
    Distributor ID:	Raspbian
    Description:	Raspbian GNU/Linux 10 (buster)
    Release:	10
    Codename:	buster
    #查看系统架构
    root@raspberrypi:/home/pi/Desktop# uname -m
    armv7l
    #查看系统位数
    root@raspberrypi:/home/pi/Desktop# getconf LONG_BIT
    32

配置软件源

    sudo nano /etc/apt/sources.list

    deb https://mirrors.tuna.tsinghua.edu.cn/raspbian/raspbian/ buster main non-free contrib rpi

    deb-src https://mirrors.tuna.tsinghua.edu.cn/raspbian/raspbian/ buster main non-free contrib rpi

    sudo nano /etc/apt/sources.list.d/raspi.list
    同样的方法，把 /etc/apt/sources.list.d/raspi.list 文件也替换成下面的内容：

    deb http://mirrors.tuna.tsinghua.edu.cn/raspberrypi/ buster main ui

    sudo apt-get update

报错：

    Certificate verification failed: The certificate is NOT trusted. The certificate chain uses expired certificate.  Could not handshake: Error in the certificate verification. [IP: 2402:f000:1:400::2 443]
    获取:4 http://raspbian.raspberrypi.org/raspbian buster InRelease [15.0 kB]
    正在读取软件包列表... 完成       
    E: 仓库 “https://mirrors.tuna.tsinghua.edu.cn/raspbian/raspbian buster Release” 没有 Release 文件。
    N: 无法安全地用该源进行更新，所以默认禁用该源。
    N: 参见 apt-secure(8) 手册以了解仓库创建和用户配置方面的细节。
    E: 仓库'http://raspbian.raspberrypi.org/raspbian buster InRelease'将其'Suite'值从'stable'修改到了'oldoldstable'
    N: 为了让这个仓库能够应用，这必须在更新之前显式接受。更多细节请参阅 apt-secure(8) 手册。

![image-4](/assets/blog_res/2023-11-5-raspberry_speaking/image-4.png)

1.为了让这个仓库能够应用，这必须在更新之前显式接受。更多细节请参阅 apt-secure(8) 手册。

解决方案：sudo apt update,然后按Y

2.证书不被信任，树莓派清华源 Certificate verification failed: The certificate is NOT trusted

解决方案：使用http协议，sudo nano /etc/apt/sources.list，将里面的https换成http（成功）

配置pip源

    sudo nano /etc/pip.conf 

    [global]
    timeout=100
    index-url=https://pypi.tuna.tsinghua.edu.cn/simple/
    extra-index-url= http://mirrors.aliyun.com/pypi/simple/
    [install]
    trusted-host=
            pypi.tuna.tsinghua.edu.cn
            mirrors.aliyun.com

python -m pip install --upgrade pip
python3 -m pip install --upgrade pip

我发现了一个管理虚拟环境的工具，之前我也接触过，virtualenv，应该很有用

**在树莓派中配置虚拟环境virtualenv**

1.树莓派安装python虚拟环境virtualenvwrapper

    安装virtualenv和virtualenvwrapper
    sudo apt-get install virtualenv
    sudo apt-get install virtualenvwrapper

    配置virtualenvwrapper
    sudo nano ~/.bashrc
    将以下命令行加入到加入到~/.bashrc的最后
    #export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
    export WORKON_HOME=$HOME/.virtualenvs
    source /usr/share/virtualenvwrapper/virtualenvwrapper.sh

    输入命令运行
    source ~/.bashrc

2.搭建虚拟目录

    1.查看树莓派中python安装路径
    python3
    import sys
    print(sys.path)

    2.切换到想要存放虚拟环境的目录
    例如：我存放的路径为：/home/pi/virtualenv_python
    cd 你想要存放目录的路径下

    3.新建虚拟环境
    virtualenv -p /usr/bin/python3 test_vir_env
    说明：
    -p /usr/bin/python3 ： 代表使用/usr/bin/ 目录下的python3创建一个虚拟环境；
    test_vir_env ：本次创建的虚拟环境的位置；

    4.开启虚拟环境
    例如我的路径下：source /home/pi/Desktop/sleep/bin/activate
    source /你的路径/venv/bin/activate

    5.查看安装的包
    pip list

    6.安装什么的
    pip3 install 包名

    7.退出虚拟环境
    deactivate

    补充：删除环境:
    rm virtualenv 环境名

3.使用创建的虚拟环境

1. 使用ThonnyIDE编辑python脚本文件

    import numpy

    a = numpy.ones((3, 5))

    print (a)