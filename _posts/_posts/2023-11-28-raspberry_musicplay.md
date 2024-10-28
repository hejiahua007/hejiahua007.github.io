---
title: 树莓派——音乐播放
date: 2023-11-28 21:40:00 +0800
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

## 音乐播放
播放某个文件夹下面的音乐

```c
import pygame
def play_audio(audio_file_name):
    # Initialize pygame
    pygame.init()
    # Set the audio file
    pygame.mixer.music.load(audio_file_name)
    # Play the audio
    pygame.mixer.music.play()
    # Wait for the audio to finish
    while pygame.mixer.music.get_busy():
        pygame.time.Clock().tick(10)
    # Quit pygame
    pygame.quit()

def m_play_audio():
    # Directory for MP3 files
    directory = "/home/pi/Desktop/sleep/file/music/banzou"

    # Iterate through all files in the directory
    for filename in os.listdir(directory):
        if filename.endswith(".mp3"):
            file_path = os.path.join(directory, filename)
            play_audio(file_path)
```
































































































































