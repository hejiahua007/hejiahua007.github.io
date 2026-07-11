---
title: 安卓————优化
date: 2023-12-25 10:00:00 +0800
categories: [安卓]
tags: [安卓]
pin: false
author: 
    name: hejiahua007
    link: https://space.bilibili.com/507838758
toc: true
comments: true
math: false
mermaid: true

---

## 优化图表

    查询环境数据
    cd /home/pi/Desktop/sleep/file/sqlite_file/
    pi@raspberrypi:~/Desktop/sleep/file/sqlite_file $ sqlite3
    sqlite> .open 2024-01-24.db
    sqlite> .tables
    sqlite> SELECT * FROM tablename;

app查询当天的图表

![alt text](/assets/blog_res/tiaozhan8/image.png)

![alt text](/assets/blog_res/tiaozhan8/image.png)

问题：
1.增加多2个表格，使之能够在电脑上运行（4h）
2.解决电脑端的bug（2h）
3.在手机上运行（4h+4h）

搜索了一圈，发现没必要再增加表格了。开启问题2的解决。

### 调试
https://blog.csdn.net/QAZWCC/article/details/132678621#:~:text=%E7%AC%AC%E4%B8%80%E6%AD%A5%EF%BC%9A%E8%AE%BE%E7%BD%AE%20-%20%3E%20%E5%85%B3%E4%BA%8E%E6%89%8B%E6%9C%BA%EF%BC%8C%E5%A4%9A%E6%AC%A1%E7%82%B9%E5%87%BB%E9%B8%BF%E8%92%99%E7%89%88%E6%9C%AC%EF%BC%88%E7%9B%B4%E5%88%B0%E5%87%BA%E7%8E%B0%E5%AF%86%E7%A0%81%EF%BC%89%20%E7%AC%AC%E4%BA%8C%E6%AD%A5%EF%BC%9A%20%E8%AE%BE%E7%BD%AE%20-%20%3E%E7%B3%BB%E7%BB%9F%E5%92%8C%E6%9B%B4%E6%96%B0,2.%E8%BF%9E%E6%8E%A5%E6%95%B0%E6%8D%AE%E7%BA%BF%20%E7%AC%AC%E4%B8%80%E6%AD%A5%EF%BC%9A%E7%94%A8%E6%95%B0%E6%8D%AE%E7%BA%BF%E8%BF%9E%E6%8E%A5%E6%89%8B%E6%9C%BA%E5%90%8E%EF%BC%8C%E6%89%93%E5%BC%80%E7%94%B5%E8%84%91%EF%BC%8C%20%E8%AE%BE%E5%A4%87%E7%AE%A1%E7%90%86%E5%99%A8%20-%3E%E4%BE%BF%E6%8D%B7%E8%AE%BE%E5%A4%87%20-%3E%E5%8F%B3%E9%94%AE%E6%89%8B%E6%9C%BA%E5%9B%BE%E6%A0%87%20-%3E%E6%9B%B4%E6%96%B0%E9%A9%B1%E5%8A%A8%E7%A8%8B%E5%BA%8F-%3E%E6%B5%8F%E8%A7%88%E6%88%91%E7%9A%84%E7%94%B5%E8%84%91%E4%BB%A5%E6%9F%A5%E6%89%BE%E9%A9%B1%E5%8A%A8%E7%A8%8B%E5%BA%8F%20%E7%AC%AC%E4%BA%8C%E6%AD%A5%EF%BC%9A%E5%AE%89%E8%A3%85%E9%A9%B1%E5%8A%A8%E7%A8%8B%E5%BA%8F%EF%BC%8C%20androidSDK%E7%9A%84%E5%AE%89%E8%A3%85%E8%B7%AF%E5%BE%84-%3Eextras-%3Egoogle-%3Eusb_driver

开始调试,在logcat中查询闪退的原因。

![alt text](/assets/blog_res/2024-4-26-Android_youhua1/image.png)

    2024-04-27 10:16:29.669  1706-2002  HwCameraServiceProxy    system_server                        I  Camera device is auto popup camera.
    ---------------------------- PROCESS ENDED (23967) for package com.example.myapplication ----------------------------
    2024-04-27 10:16:29.670  1706-2807  WindowManager           system_server                        V  notifyAppResumed: wasStopped=true AppWindowToken{5be0609 token=Token{5be9ba3 ActivityRecord{5be07c2 u0 com.huawei.android.launcher/.unihome.UniHomeLauncher t1}}}
    2024-04-27 10:16:29.671  5666-24060 CAWARENESS...yScheduler com.huawei.hiai.engineservice        I  query {dataId=100000102, mode=0} from ecommerce_app_behavior_collection_ability
    2024-04-27 10:16:29.672   667-667   Zygote                  pid-667                              I  Process 23967 exited due to signal 9 (Killed)
    2024-04-27 10:16:29.672  8389-8389  HwIME_Pro               com.baidu.input_huawei               I  ImeService>>>setCandidatesViewShown:false
                                                                                                        java.lang.Throwable
                                                                                                            at com.baidu.input_huawei.ImeService.setCandidatesViewShown(Proguard:2)
                                                                                                            at com.baidu.input_huawei.ImeService.hideSoft(Proguard:6)
                                                                                                            at com.baidu.input_huawei.ImeService.hideSoft(Proguard:1)
                                                                                                            at com.baidu.input_huawei.ImeService.onUnbindInput(Proguard:14)
                                                                                                            at android.inputmethodservice.InputMethodService$InputMethodImpl.unbindInput(InputMethodService.java:685)
                                                                                                            at android.inputmethodservice.IInputMethodWrapper.executeMessage(IInputMethodWrapper.java:180)
                                                                                                            at com.android.internal.os.HandlerCaller$MyHandler.handleMessage(HandlerCaller.java:44)
                                                                                                            at android.os.Handler.dispatchMessage(Handler.java:110)
                                                                                                            at android.os.Looper.loop(Looper.java:219)
                                                                                                            at android.app.ActivityThread.main(ActivityThread.java:8673)
                                                                                                            at java.lang.reflect.Method.invoke(Native Method)
                                                                                                            at com.android.internal.os.RuntimeInit$MethodAndArgsCaller.run(RuntimeInit.java:513)
                                                                                                            at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:1109)
    2024-04-27 10:16:29.672  5666-24052 CAWARENESS...ityContext com.huawei.hiai.engineservice        I  [1714184189996] deliver {dataId=100000258, mode=0} to null
    2024-04-27 10:16:29.673  1706-3097  InputMetho...gerService system_server                        D  onInputHide

您提供的日志信息显示了一系列系统和应用程序事件。这里有几个关键点：

    HwCameraServiceProxy 表明华为系统服务正在处理一个自动弹出式摄像头的事件。
    PROCESS ENDED 消息表明 com.example.myapplication 这个进程被信号9（通常表示被系统杀死）终止了。
    WindowManager 和 CAWARENESS…yScheduler 条目可能与系统窗口管理和华为的HiAI引擎的行为收集功能有关。
    Zygote 的日志表明进程23967因为信号9而退出，这与上面提到的应用程序进程结束是一致的。
    HwIME_Pro 条目显示了百度输入法华为版（com.baidu.input_huawei）的一个异常堆栈跟踪，这可能是因为输入法服务试图隐藏候选词视图但遇到了问题。
    这些信息表明您的应用程序可能因为某些系统级事件或资源管理问题而被终止。要解决这个问题，您可以尝试以下步骤：

    查看详细日志：使用Android Studio的Logcat来查看更详细的错误信息和堆栈跟踪。
    断点调试：在您怀疑的代码区域设置断点，然后逐步执行，观察变量的值和程序的行为。
    性能分析：使用Android Studio的Profiler工具来分析应用的性能，查看是否有内存泄漏或其他性能问题。
    代码审查：检查代码，确保没有明显的逻辑错误，如空指针异常、资源未找到等。

        2024-04-27 10:29:26.069 26201-26201 AndroidRuntime          com.example.myapplication            E  FATAL EXCEPTION: main
                                                                                                            Process: com.example.myapplication, PID: 26201
                                                                                                            android.os.NetworkOnMainThreadException
                                                                                                                at android.os.StrictMode$AndroidBlockGuardPolicy.onNetwork(StrictMode.java:1565)
                                                                                                                at java.net.SocketOutputStream.socketWrite(SocketOutputStream.java:116)
                                                                                                                at java.net.SocketOutputStream.write(SocketOutputStream.java:149)
                                                                                                                at com.example.myapplication.TubiaoActivity.sendDataToServer(TubiaoActivity.java:518)
                                                                                                                at com.example.myapplication.TubiaoActivity.access$900(TubiaoActivity.java:37)
                                                                                                                at com.example.myapplication.TubiaoActivity$5$1.onTimeSet(TubiaoActivity.java:238)
                                                                                                                at android.app.TimePickerDialog.onClick(TimePickerDialog.java:174)
                                                                                                                at android.app.TimePickerDialog$1.onClick(TimePickerDialog.java:156)
                                                                                                                at android.view.View.performClick(View.java:7322)
                                                                                                                at com.google.android.material.button.MaterialButton.performClick(MaterialButton.java:1202)
                                                                                                                at android.view.View.performClickInternal(View.java:7296)
                                                                                                                at android.view.View.access$3600(View.java:839)
                                                                                                                at android.view.View$PerformClick.run(View.java:28319)
                                                                                                                at android.os.Handler.handleCallback(Handler.java:900)
                                                                                                                at android.os.Handler.dispatchMessage(Handler.java:103)
                                                                                                                at android.os.Looper.loop(Looper.java:219)
                                                                                                                at android.app.ActivityThread.main(ActivityThread.java:8673)
                                                                                                                at java.lang.reflect.Method.invoke(Native Method)
                                                                                                                at com.android.internal.os.RuntimeInit$MethodAndArgsCaller.run(RuntimeInit.java:513)
                                                                                                                at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:1109)

        您的应用程序再次遇到了 android.os.NetworkOnMainThreadException 异常。这个异常发生在尝试在主线程（UI线程）上执行网络操作时。在Android中，所有的网络请求都应该在后台线程中进行，以避免阻塞UI线程，导致应用无响应。

        从日志中可以看出，TubiaoActivity 的 sendDataToServer 方法在主线程中尝试进行网络通信，这是不允许的。您需要将网络操作移到后台线程。这可以通过以下几种方式实现：

        使用 AsyncTask：创建一个继承自 AsyncTask 的内部类，然后在 doInBackground 方法中执行网络操作。
        使用 Thread 或 Runnable：创建一个新的线程来执行网络请求。
        使用 Handler 和 Looper：在后台线程中创建一个 Handler，然后将网络操作的代码发送到该 Handler 执行。
        使用 Coroutine：如果您使用Kotlin开发，可以利用协程在后台线程中执行网络操作。
        使用 RxJava 或其他第三方库：这些库提供了更简洁和强大的方式来处理异步操作和网络请求。

        从您的代码片段中可以看到，sendDataToServer() 方法被调用时还是在主线程上，这导致了 NetworkOnMainThreadException 异常。为了解决这个问题，我们需要将网络请求的处理移至后台线程。您已经在处理数据接收时使用了新线程，我们可以采用类似的方法将 sendDataToServer() 方法的执行也放在新线程中。

        以下是修改后的 onClick 方法，将 sendDataToServer() 方法的调用也包裹在新线程中，以避免在主线程上执行网络操作：

    ```c
                    // 在新线程中处理 sendDataToServer 调用
                    new Thread(new Runnable() {
                        @Override
                        public void run() {
                            sendDataToServer();
                        }
                    }).start();
    ```

    2024-04-27 10:43:27.574 30755-30755 AndroidRuntime          com.example.myapplication            E  FATAL EXCEPTION: main
                                                                                                        Process: com.example.myapplication, PID: 30755
                                                                                                        android.os.NetworkOnMainThreadException
                                                                                                            at android.os.StrictMode$AndroidBlockGuardPolicy.onNetwork(StrictMode.java:1565)
                                                                                                            at java.net.SocketOutputStream.socketWrite(SocketOutputStream.java:116)
                                                                                                            at java.net.SocketOutputStream.write(SocketOutputStream.java:149)
                                                                                                            at com.example.myapplication.JiajuActivity.askstates(JiajuActivity.java:434)
                                                                                                            at com.example.myapplication.JiajuActivity.access$300(JiajuActivity.java:26)
                                                                                                            at com.example.myapplication.JiajuActivity$4.onClick(JiajuActivity.java:127)
                                                                                                            at android.view.View.performClick(View.java:7322)
                                                                                                            at android.view.View.performClickInternal(View.java:7296)
                                                                                                            at android.view.View.access$3600(View.java:839)
                                                                                                            at android.view.View$PerformClick.run(View.java:28319)
                                                                                                            at android.os.Handler.handleCallback(Handler.java:900)
                                                                                                            at android.os.Handler.dispatchMessage(Handler.java:103)
                                                                                                            at android.os.Looper.loop(Looper.java:219)
                                                                                                            at android.app.ActivityThread.main(ActivityThread.java:8673)
                                                                                                            at java.lang.reflect.Method.invoke(Native Method)
                                                                                                            at com.android.internal.os.RuntimeInit$MethodAndArgsCaller.run(RuntimeInit.java:513)
                                                                                                            at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:1109)

    这个错误日志明确指出了问题——android.os.NetworkOnMainThreadException。这个异常表示您的应用在Android主线程（也称为UI线程）上执行了网络操作。在Android开发中，执行网络操作必须在非主线程（比如新建的工作线程）上进行，因为网络请求可能涉及长时间的等待，如果在主线程上进行，会导致应用界面冻结，从而影响用户体验。

    错误日志显示出错的代码位于 JiajuActivity.java 文件的第 434 行的 askstates() 方法中，并且是由点击事件触发的。解决这个问题的基本策略是将 askstates() 方法中的网络操作移到新的线程中。您可以使用 Thread 或者 AsyncTask，或者利用现代的并发库如 Executors, RxJava 或 Kotlin Coroutines（如果您使用Kotlin）。

### 优化家居界面











