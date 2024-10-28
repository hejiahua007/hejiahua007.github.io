---
title: 语音合成
date: 2023-10-13 17:37:00 +0800
categories: [sleep, sleepyuyin]
tags: [语音合成]
pin: false
author: 
    name: hejiahua007
    link: https://space.bilibili.com/507838758
toc: true
comments: true
math: false
mermaid: true

---

## 语音合成

下载vits模型文件

如果你有能力可以自己炼丹出个模型，具体可以参考[这个](https://www.bilibili.com/video/BV1Lo4y1B7JX/)。

或者可以白嫖点大佬训练的模型，比如这个[这个](https://huggingface.co/spaces/zomehwh/vits-uma-genshin-honkai/tree/main)

代码取自这位[大佬](https://github.com/Eerrly/VITSAIChatVtube),然后进行魔改了一番，没有自己造轮子，好多都看不懂，慢慢啃。

speaking.py

```cpp
import subprocess
import argparse
import torch
import time
from torch import no_grad, LongTensor
import asyncio
import utils
from models import SynthesizerTrn
from text import text_to_sequence
import commons
from scipy.io import wavfile
import pygame

#noise_scale(控制感情变化程度)
vitsNoiseScale = 0.6
#noise_scale_w(控制音素发音长度)
vitsNoiseScaleW = 0.668
#length_scale(控制整体语速)
vitsLengthScale = 1.0
_init_vits_model = False

hps_ms = None
device = None
net_g_ms = None

def play_audio(audio_file_name):
    # 初始化pygame
    pygame.init()
    # 设置音频文件
    pygame.mixer.music.load(audio_file_name)
    # 播放音频
    pygame.mixer.music.play()
    # 等待音频播放完毕
    while pygame.mixer.music.get_busy():
        pygame.time.Clock().tick(10)
    # 退出pygame
    pygame.quit()
# def play_audio(audio_file_name):
#     command = f'mpv.exe -vo null {audio_file_name}'
#     subprocess.run(command, shell=True)

def init_vits_model():
    # 全局变量引入
    global hps_ms, device, net_g_ms

    # 创建参数解析器
    parser = argparse.ArgumentParser()
    parser.add_argument('--device', type=str, default='cpu')
    parser.add_argument('--api', action="store_true", default=False)
    parser.add_argument("--share", action="store_true", default=False, help="share gradio app")
    parser.add_argument("--colab", action="store_true", default=False, help="share gradio app")
    args = parser.parse_args()
    device = torch.device(args.device)
    # 从文件中获取VITS模型的参数
    hps_ms = utils.get_hparams_from_file('config.json')
    # 创建VITS模型
    net_g_ms = SynthesizerTrn(
        len(hps_ms.symbols),
        hps_ms.data.filter_length // 2 + 1,
        hps_ms.train.segment_size // hps_ms.data.hop_length,
        n_speakers=hps_ms.data.n_speakers,
        **hps_ms.model)
    # 将VITS模型设置为评估模式，并移动到指定设备
    _ = net_g_ms.eval().to(device)
    # 获取说话者信息
    speakers = hps_ms.speakers
    # 加载模型和优化器
    model, optimizer, learning_rate, epochs = utils.load_checkpoint('G_953000.pth', net_g_ms, None)
    # 标记VITS模型已初始化
    _init_vits_model = True

def get_text(text, hps):
    # 使用text_to_sequence将输入文本转换为模型可用的格式
    text_norm, clean_text = text_to_sequence(text, hps.symbols, hps.data.text_cleaners)
    # 如果需要在文本中添加空白符，则在文本序列中插入0（代表空白符）
    if hps.data.add_blank:
        text_norm = commons.intersperse(text_norm, 0)
    # 将文本序列转换为LongTensor（长整数）格式
    text_norm = LongTensor(text_norm)
    return text_norm, clean_text

def vits(text, language, speaker_id, noise_scale, noise_scale_w, length_scale):
    global over
    # 记录生成开始时间
    start = time.perf_counter()
    # 处理输入文本
    if not len(text):
        return "输入文本不能为空！", None, None
    text = text.replace('\n', ' ').replace('\r', '').replace(" ", "")
    if len(text) > 200:
        return f"输入文字过长！{len(text)}>100", None, None
    # 根据语言类型添加标记
    if language == 0:
        text = f"[ZH]{text}[ZH]"
    elif language == 1:
        text = f"[JA]{text}[JA]"
    else:
        text = f"{text}"
    # 调用get_text将文本转换为模型可用的格式
    stn_tst, clean_text = get_text(text, hps_ms)
    # 使用VITS模型生成音频
    with no_grad():
        x_tst = stn_tst.unsqueeze(0).to(device)
        x_tst_lengths = LongTensor([stn_tst.size(0)]).to(device)
        speaker_id = LongTensor([speaker_id]).to(device)
        audio = net_g_ms.infer(x_tst, x_tst_lengths, sid=speaker_id, noise_scale=noise_scale, noise_scale_w=noise_scale_w,
                               length_scale=length_scale)[0][0, 0].data.cpu().float().numpy()
    # 返回生成成功信息、音频信息以及生成耗时
    return "生成成功!", (22050, audio), f"生成耗时 {round(time.perf_counter()-start, 2)} s"

async def start():
    while True:
        print("请输入 >")
        input_str = await asyncio.get_event_loop().run_in_executor(None, input, '')
        if "关闭AI" in input_str:
            return
        result = input_str
        status, audios, time = vits(result, 0, 124, vitsNoiseScale, vitsNoiseScaleW, vitsLengthScale)
        print("VITS : ", status, time)
        wavfile.write("output.wav", audios[0], audios[1])
        play_audio("output.wav")

async def main():
    if not _init_vits_model:
        init_vits_model()
    await asyncio.gather(start(),)

asyncio.run(main())
```
- 导入库：代码导入了必要的Python库，例如time、os、scipy.io.wavfile、asyncio、subprocess、requests、json、argparse，以及自定义模块utils、models、text和commons中的各种函数和类。
- 变量定义和配置：
  - 定义了一些全局变量，用于配置GPT-3.5模型的访问信息、VITS模型的参数等。
  - 初始化了一些VITS模型的相关参数，并加载了模型。
- 函数定义：
    - send_chatgpt_request(send_msg)：用于向GPT-3.5模型发送请求并获取生成的文本回复。
    - play_audio(audio_file_name)：用于播放音频文件。
    - init_vits_model()：用于初始化VITS模型。
    - get_text(text, hps)：用于处理输入文本，将其转换成模型可用的格式。
    - vits(text, language, speaker_id, noise_scale, noise_scale_w, length_scale)：用于生成语音。
- 异步事件处理：
  - start()：从用户输入中获取文本，发送给GPT-3.5模型获取回复，并使用VITS模型生成对应的语音。
  - main()：主要函数，协调调用start()函数以实现异步处理。
- 程序入口：
  - 使用asyncio.run(main())调用主函数，启动程序运行。

###get_text()函数
get_text函数的目的是将输入文本转换为VITS模型可用的格式，它接受两个参数：text（输入的文本）和hps（VITS模型的参数）。
在get_text函数中，主要有以下步骤：

  1. 调用text_to_sequence函数：
  - text_to_sequence函数用于将文本转换为符号序列，该序列是模型可接受的输入格式。
  - 这个函数的调用将输入文本转换成两部分：text_norm和clean_text。
      - text_norm是转换后的文本序列，使用VITS模型参数中的符号表和文本清理器处理得到。
      - clean_text是原始文本的清理版本。
  1. 添加空白符（如果需要）：
      - 根据模型参数中的add_blank标志，决定是否需要在文本序列中插入0作为空白符。
  2. 将文本序列转换为LongTensor：
      - 最终将处理后的文本序列转换为PyTorch的LongTensor格式，以便模型可以接受它作为输入。

``` cpp
def get_text(text, hps):
    # 使用text_to_sequence将输入文本转换为模型可用的格式
    text_norm, clean_text = text_to_sequence(text, hps.symbols, hps.data.text_cleaners)
    
    # 如果需要在文本中添加空白符，则在文本序列中插入0（代表空白符）
    if hps.data.add_blank:
        text_norm = commons.intersperse(text_norm, 0)
    
    # 将文本序列转换为LongTensor（长整数）格式
    text_norm = LongTensor(text_norm)
    return text_norm, clean_text
```

###text_to_sequence函数
text_to_sequence函数的目的是将文本转换为符号序列，它接受三个参数：text（输入文本）、symbols（符号表）和cleaners（文本清理器）。

在text_to_sequence函数中，主要有以下步骤：
  1. 文本清理：
      - 调用clean_text函数对输入文本进行清理，去除多余的空格、特殊字符等。
  2. 文本转换为符号序列：
      - 遍历清理后的文本，将每个字符转换为对应的符号在符号表中的索引。
      - 如果字符不在符号表中，将其转换为未知符号的索引。
  总的来说，get_text函数使用了text_to_sequence函数将输入文本转换为模型可用的符号序列，并可以选择是否添加空白符。
``` cpp
def text_to_sequence(text, symbols, cleaners):
    # 文本清理，例如去除多余的空格、特殊字符等
    cleaned_text = clean_text(text, cleaners)
    
    # 将文本转换为符号序列
    symbols = symbols + ['[UNK]']  # 符号表增加未知符号
    sequence = []
    for s in cleaned_text:
        if s in symbols:
            sequence.append(symbols.index(s))
        else:
            sequence.append(symbols.index('[UNK]'))
    return sequence, cleaned_text

```

###异步事件处理：

- start()：从用户输入中获取文本，发送给GPT-3.5模型获取回复，并使用VITS模型生成对应的语音。
- main()：主要函数，协调调用start()函数以实现异步处理。

1. async 和 await 关键字
- async: async关键字用于定义一个异步函数，即一个函数的执行可能会被中断，然后在稍后的某个时刻继续执行。异步函数在遇到await时可能会暂停执行，等待另一个异步操作完成。
- await: await关键字用于等待一个异步操作完成。它只能在异步函数内部使用，并且通常与async一起使用。
2. asyncio 模块
asyncio 是 Python 标准库中的模块，用于支持异步编程。它提供了一种事件循环机制，用于管理异步任务和异步函数。

在异步编程中，我们将任务添加到事件循环中，然后让事件循环负责调度这些任务的执行。asyncio 通过事件循环来驱动异步程序的执行，处理异步函数的调用和结果的返回。

3. 异步事件处理流程
现在，让我们来理解代码中的异步事件处理流程：

- start() 函数:

  - 这是一个异步函数，用于处理用户输入。它等待用户的输入，然后将输入文本发送给 GPT-3.5 模型获取回复，并使用 VITS 模型生成对应的语音。这里的 await 用于等待异步操作完成，例如等待用户输入。
- main() 函数:

  - 这是程序的主要函数，也是一个异步函数。它协调调用 start() 函数以实现异步处理。在这里，await start() 用于等待 start() 函数执行完成，然后结束程序。
- 程序入口:
  - 最后，在程序的入口处，我们使用 asyncio.run(main()) 调用主函数 main()，启动整个程序的异步执行。asyncio.run() 是用于运行异步程序的简便方法。
总结一下，异步编程通过使用 async 和 await 关键字以及 asyncio 模块，使程序能够在等待一些耗时的操作时不阻塞，从而提高了程序的效率和响应性。

###关键代码
``` cpp
audio = net_g_ms.infer(x_tst, x_tst_lengths, sid=speaker_id, noise_scale=noise_scale, noise_scale_w=noise_scale_w,
                       length_scale=length_scale)[0][0, 0].data.cpu().float().numpy()
```
这行代码调用了 net_g_ms 对象（一个 VITS 模型）的 infer 方法来生成音频，然后将结果赋给 audio 变量。

逐步解释：

1. net_g_ms: 这是 VITS 模型对象，用于语音合成。

2. infer: 这是 VITS 模型的推理方法，用于生成音频。

3. x_tst: 这是输入的文本序列的 PyTorch tensor，表示待合成的文本。

4. x_tst_lengths: 这是输入文本的长度，以 PyTorch tensor 表示。

5. sid=speaker_id: 这是说话者 ID，用于指定生成音频的说话者。

6. noise_scale, noise_scale_w, length_scale: 这些是控制语音生成的参数，影响生成音频的特征，包括感情变化程度、音素发音长度和整体语速。

7. [0][0, 0]: 这是对生成的音频结果进行索引操作，从生成的音频结果中提取特定部分。具体来说，它提取了生成的音频的第一个样本（可能是第一个批次的第一个样本）的第一个通道的数据。

8. .data.cpu().float().numpy(): 这一系列操作将音频数据从 GPU（如果在 GPU 上）转移到 CPU，并转换为 NumPy 数组，以便后续处理或保存为音频文件。

这行代码调用 VITS 模型的推理方法生成音频，并对生成的音频结果进行一系列处理，最终得到可以播放或保存的音频数据。





