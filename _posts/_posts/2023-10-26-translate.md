---
title: 有道云翻译
date: 2023-10-26 10:14:00 +0800
categories: [sleep, sleepyfanyi]
tags: [文本翻译]
pin: false
author: 
    name: hejiahua007
    link: https://space.bilibili.com/507838758
toc: true
comments: true
math: false
mermaid: true

---

## 有道云翻译api

搜索有道云翻译api，注册账号，获得id和key即可


``` c
import hashlib
import uuid
import time
import requests
import json
# 有道云api的key
youdao_Id = "xxxxxxxx"
youdao_key = "xxxxxxxxxx"

# 文本翻译
def text2text_translate(words, model="youdao",src_lang="ja",target_lang="zh-CHS"):
    if model == "youdao":
        def encrypt(signStr):
            hash_algorithm = hashlib.sha256()
            hash_algorithm.update(signStr.encode('utf-8'))
            return hash_algorithm.hexdigest()

        def truncate(q):
            if q is None:
                return None
            size = len(q)
            return q if size <= 20 else q[0:10] + str(size) + q[size - 10:size]

        def do_request(data):
            youdao_url = 'https://openapi.youdao.com/api'
            headers = {'Content-Type': 'application/x-www-form-urlencoded'}
            return requests.post(youdao_url, data=data, headers=headers)
        q = words
        data = {}
        data['from'] = src_lang         # 翻译源语言
        data['to'] = target_lang       # 翻译目标语言
        data['signType'] = 'v3'
        curtime = str(int(time.time()))
        data['curtime'] = curtime  # 时间戳
        salt = str(uuid.uuid1())
        signStr = youdao_Id + truncate(q) + salt + curtime + youdao_key
        sign = encrypt(signStr)
        data['appKey'] = youdao_Id      # 应用ID
        data['q'] = q                   # 翻译语句
        data['salt'] = salt
        data['sign'] = sign
        response = do_request(data)

        # 回复解码
        json_data = response.content.decode('utf-8')
        data = json.loads(json_data)
        translation = data['translation']

    return translation[0]
```

def text2text_translate(words, model="youdao",src_lang="ja",target_lang="zh-CHS"):

text2text_translate函数：
words：翻译的字符串
src_lang：翻译前的语言设置（默认为日语）
target_lang：翻译后的语言设置（默认翻译成中文）

