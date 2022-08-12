---
title: PAT-Count PAT's & Quick Sort
date: 2022-08-04 22:26:00 +0800
categories: [算法刷题, PAT]
tags: [递推]

pin: false
author: 
    name: CALL1CE
    link: https://space.bilibili.com/9330604
toc: true
comments: true
math: false
mermaid: true

---

## A1093 [Count PAT's](https://pintia.cn/problem-sets/994805342720868352/problems/994805373582557184)

```cpp
#include<iostream>
#include<vector>
#include<algorithm>
using namespace std;
const int maxn = 100010;
const int MOD = 1000000007;
int main()
{
    string str;
    cin >> str;
    vector<int>leftP(maxn,0), rightT(maxn, 0);//分别记录每个下标左侧的P个数和下标右侧的T个数
    if (str[0] == 'P') leftP[0] = 1;
    if (str[str.size() - 1] == 'T') rightT[str.size() - 1] = 1;
    for (int i = 1; i < str.size(); i++)//从左到右遍历，统计P个数
    {
        if (str[i] == 'P')
        {
            leftP[i] = leftP[i - 1] + 1;
        }
        else
        {
            leftP[i] = leftP[i - 1];
        }
    }
    int ans = 0;
    //从右往前遍历，统计T个数，并顺便计算最终结果
    for (int i = str.size() - 2; i >= 0; i--)
    {
        if (str[i] == 'T')//如果当前下标是T
        {
            rightT[i] = rightT[i + 1] + 1;//那么当前下标右侧的T个数+1
        }
        else//不是T
        {
            rightT[i] = rightT[i + 1];//那么当前下标右侧的T个数
            if (str[i] == 'A')//如果当前下标是A，那么要算ans
            {
                ans += leftP[i] * rightT[i];
                ans %= MOD;
            }
        }
    }
    cout << ans;
}
```

    这道题其实我想到这个方法了，但我担心复杂度会不会太高了，但忘记可以先把数据存起来了，空间换时间啊。

## A1101 [Quick Sort](https://pintia.cn/problem-sets/994805342720868352/problems/994805366343188480)

```cpp
#include<iostream>
#include<vector>
#include<algorithm>
using namespace std;
const int maxn = 100010;
int main()
{
    int N;//数字个数
    cin >> N;
    vector<int> num(maxn), leftMax(maxn, 0), rightMin(maxn, 0);
    int max = 0;
    int min = 1e9 + 1;
    int ansCnt = 0;
    vector<int> ans;
    for (int i = 0; i < N; i++)//从前往后遍历，记录每个下标左侧的最大值
    {
        cin >> num[i];
        if (num[i] > max)//如果当前下标的数大于左边最大的
        {
            max = num[i];//更新max
        }
        leftMax[i] = max;//记录当前下标左侧最大值（包括当前下标）
    }
    for (int i = N - 1; i >= 0; i--)//从后往前遍历，记录每个下标右侧的最小值，并判断是否为pivot
    {
        if (num[i] < min)//如果当前下标的数小于右边最小的
        {
            min = num[i];//更新min
        }
        rightMin[i] = min;//记录当前下标右侧最小值（包括当前下标）
        if (rightMin[i] == leftMax[i])//如果当前下标最大值和最小值一样（也就是本身）
        {
            ansCnt++;
            ans.emplace_back(rightMin[i]);
        }
    }
    cout << ansCnt << endl;
    for (int i = ans.size() - 1; i >= 0; i--)
    {
        if (i != ans.size() - 1)//如果不是第一个，那就输出前置空格
        {
            cout <<' ' << ans[i];
        }
        else cout << ans[i];
    }
    cout<<endl;
}
```

    这道题和上面那道的做法类似，开始有一个测试点会显示格式错误，在最后加个换行就行了，因为当pivot主元数字个数为0时，下面一行需要一个换行，不能什么都没有。