---
title: 树莓派——YOLOv5-Lite 5
date: 2024-5-18 16:15:00 +0800
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

## 前言

需要将模型的部署移植到系统中。

### 查看原本的环境

进入虚拟环境

cd /home/pi/Desktop/test

source venv/bin/activate

![alt text](/assets/blog_res/2024-5-18-raspberry_zhuangtaijiance5/image.png)

查阅需要的库：pip3 list

    flatbuffers   23.5.26 
    numpy         1.21.6  
    onnxruntime   1.9.1   
    opencv-python 4.5.5.62
    pip           18.1    
    pkg-resources 0.0.0   
    protobuf      4.24.4  
    setuptools    40.8.0 

退出虚拟环境 deactivate

系统环境
---

pip list



pip3 list

    api                0.0.7
    audioread          3.0.1
    baidu-aip          4.16.13
    cachetools         5.3.2
    certifi            2023.11.17
    cffi               1.15.1
    chardet            5.2.0
    charset-normalizer 3.3.2
    cn2an              0.5.22
    dataclasses        0.6
    decorator          5.1.1
    future             0.18.3
    idna               3.4
    jamo               0.4.1
    jieba              0.42.1
    joblib             1.3.2
    librosa            0.8.0
    llvmlite           0.31.0
    nose               1.3.7
    numba              0.48.0
    numpy              1.21.6
    packaging          23.2
    Pillow             9.5.0
    pip                20.1.1
    platformdirs       4.0.0
    pooch              1.8.0
    proces             0.1.7
    pvcobra            2.0.1
    pvporcupine        3.0.1
    PyAudio            0.2.14
    pycairo            1.23.0
    pycparser          2.21
    pydub              0.25.1
    pygame             2.0.0
    PyJWT              2.8.0
    pyopenjtalk        0.3.3
    pypinyin           0.49.0
    PyYAML             6.0.1
    requests           2.31.0
    resampy            0.2.2
    scikit-learn       1.0.2
    scipy              1.6.3
    setuptools         68.0.0
    six                1.16.0
    soundfile          0.12.1
    threadpoolctl      3.1.0
    torch              1.6.0a0+b31f58d
    torchvision        0.8.0a0+10d5a55
    tqdm               4.66.1
    typing-extensions  4.7.1
    Unidecode          1.3.7
    urllib3            2.0.7
    wheel              0.34.2
    zhipuai            1.0.7

    api                0.0.7
    audioread          3.0.1
    baidu-aip          4.16.13
    cachetools         5.3.2
    certifi            2023.11.17
    cffi               1.15.1
    chardet            5.2.0
    charset-normalizer 3.3.2
    cn2an              0.5.22
    dataclasses        0.6
    decorator          5.1.1
    future             0.18.3
    idna               3.4
    jamo               0.4.1
    jieba              0.42.1
    joblib             1.3.2
    librosa            0.8.0
    llvmlite           0.31.0
    nose               1.3.7
    numba              0.48.0
    numpy              1.21.6
    packaging          23.2
    Pillow             9.5.0
    pip                20.1.1
    platformdirs       4.0.0
    pooch              1.8.0
    proces             0.1.7
    pvcobra            2.0.1
    pvporcupine        3.0.1
    PyAudio            0.2.14
    pycairo            1.23.0
    pycparser          2.21
    pydub              0.25.1
    pygame             2.0.0
    PyJWT              2.8.0
    pyopenjtalk        0.3.3
    pypinyin           0.49.0
    PyYAML             6.0.1
    requests           2.31.0
    resampy            0.2.2
    scikit-learn       1.0.2
    scipy              1.6.3
    setuptools         68.0.0
    six                1.16.0
    soundfile          0.12.1
    threadpoolctl      3.1.0
    torch              1.6.0a0+b31f58d
    torchvision        0.8.0a0+10d5a55
    tqdm               4.66.1
    typing-extensions  4.7.1
    Unidecode          1.3.7
    urllib3            2.0.7
    wheel              0.34.2
    zhipuai            1.0.7

---




















































































































































































































































