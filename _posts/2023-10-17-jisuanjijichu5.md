---
title: 计算机基础——C语言程序设计
date: 2023-10-17 14:30:00 +0800
categories: [计算机基础,C语言程序设计]
tags: [计算机基础,C语言程序设计]
pin: false
author: 
    name: hejiahua007
    link: https://space.bilibili.com/507838758
toc: true
comments: true
math: false
mermaid: true

---
**编译器、编辑器和IDE的区别**

    编译器就是将“一种语言（通常为高级语言）”翻译为“另一种语言（通常为低级语言）”的程序。一个现代编译器的主要工作流程：源代码 (source code) → 预处理器 (preprocessor) → 编译器 (compiler) → 目标代码 (object code) → 链接器 (Linker) → 可执行程序 (executables)。


**动态存储方式和静态存储方式**

- 变量可以分为全局变量和局部变量，即变量的生存周期长短不一。
- 变量的存储有两种方式：静态存储方式和动态存储方式。

    静态存储方式：在程序运行期间有系统分配固定的存储空间的方式；
    动态存储方式：程序运行期间根据需要进行动态分配存储空间的方式。

内存中供用户使用的存储空间的情况：

- 程序区；
- 静态存储区；
- 动态存储区。
- 
全局变量存储在静态存储区。

在动态存储区存放以下数据：

- 函数形式参数；
- 函数中定义的没有用关键字static声明的变量，即自动变量（auto）；
- 函数调用时的现场保护和返回地址等。
  
在C语言中，每一个变量和函数都有两个属性：数据类型（整形、浮点型等）和数据的存储类别（静态存储和动态存储）

C语言的存储类别有四种：自动的auto、静态的static、寄存器的register、外部的extern。

**局部变量的存储类别**

*1.自动变量*

    在调用函数的时候，系统会自动分配这些变量的存储空间，并在函数调用结束的时候自动释放这些空间，这类变量称为自动变量。
    自动变量一般用**auto**作为存储类别的声明，实际上，关键字auto可以省略，不写auto则隐含指定为“自动存储类别”。
    **存储在动态存储区**

**2.静态局部变量**
    即**生命周期为整个文件的开始而开始结束而结束。**
    一般用static进行声明。
    1、对静态局部变量，只赋初值一次，在编译时赋初值；自动变量则是在函数调用时赋初值
    2、对于静态局部变量来说，如果在编译之初不赋初值，系统自动赋初值0或空字符’\0’；对于自动变量则为系统随机的内存地址；
    3、静态局部变量虽然生存周期长，但仍然是局部变量，其他函数不能引用它。
    存储在静态存储区。

**3.寄存器变量**

一般对于使用非常频繁地变量定义为寄存器变量，因为寄存器的存储速度远远高于内存的存取速度，这样可以提高执行效率。
一般用register进行声明。
**存储在CPU中的寄存器中。**

**全局变量的存储类别**

**1)全局变量的存储类别**

    外部变量的生存周期在它定义点到文件结束。它之前的部分不能引用它。可以使用extern进行外部变量声明，就可以从声明处之后引用该变量了。


**2)将外部变量的作用域扩展到其他文件**

    在要调用外部变量的文件中用extern将外部变量的作用域扩展到本文件中来即可。

**3)将外部变量的作用域限制在本文件中**

    当静态外部变量定义声明前加上static，则为限制只能用于本文件的外部变量。
    >用static声明一个变量的作用是;
    1.对局部变量用static声明，把它分配在静态存储区，该变量在整个程序执行期间不释放，其所分配的空间始终存在；
    2.对全局变量用static声明，则该变量的作用域只限于本文件模块。

![image](/assets/blog_res/2023-10-17-jisuanjijichu5/image.png)

**变量的声明和定义**

    我们已经知道一个函数是由两个部分组成：声明部分和执行部分。
    声明部分的作用是对有关的标识符（如：变量、结构体和共用体等）的属性进行声明。
    声明和定义明显，函数的声明是函数的原型，二函数的定义是对函数功能的定义。
    对被调用函数的声明是放在主调函数的声明部分中的，而函数的定义显然不在声明部分的范围内，他是一个独立的模块。

   在声明部分出现的变量通常有两种情况：
   一种是需要建立存储空间的；(如:int a;)
   另一种是不需要建立存储空间的。（如:extern a;）
   第一种称为：定义性声明。简称：定义
   第二种称为：引用性声明。

**内部函数和外部函数**

    根据函数能否被其他源文件调用，将函数区分为内部函数和外部函数。

**1、内部函数**

    如果一个函数只能够被本文件中的其他函数所调用，称为内部函数。又称为静态函数。

**2、外部函数**

    在定义函数时，在函数首部的最左端加extern，则此函数是外部函数，可供其他文件调用。
    函数首部可以为：extern int fun (int a,int b);
    因此当在定义的时候省略了extern，则默认为外部函数。前面所有使用的程序都是外部函数。
    因此在调用此函数的其他文件中，需要对此函数做说明，即使在本文件中调用一个函数，也要用函数原型进行声明，因此每次将main函数放在文件最下面，可以省略声明，但为了严谨也应该进行声明。

**指针**

    简而言之，指针就是存储的某个地址的一个空间，而地址指向的是某个变量的变量单元。因此将地址形象化地称为“指针”。意思是能通过这个指针找到以它为地址的内存单元。
    对变量的访问可以分为**直接访问**和**间接访问**。
    如果有一个变量专门用来存放另一变量的地址（即指针），则它称为“指针变量”。

    定义指针变量：
    类型名 *指针变量名;
    int *p1,*p2;
    左端的int是在定义指针变量时必须指定的“基类型”。

在定义指针变量时要注意：

- 指针变量前面的*表示该变量为指针型变量；
- 在定义指针变量时必须指定基类型。一个变量的指针的含义包含两个方面：一是一
- 储单元编号表示的纯地址，一是它指向的存储单元的数据类型；
- 整数型指针用int *,读作指向int类型的指针或int指针；
- 指针变量中只能存放地址。

    p=&a;//给指针变量赋值
    printf("%d",*p);//输出a的值，即以整数形式输出指针变量p所指向的变量的值
    printf("%o",p);//以八进制的形式输出指针p的值，也就是a的地址

C语言中实参变量和形参变量之间的数据传递是单向的“值传递”方式。

**通过指针引用数组**

    所谓数组元素的指针就是数组元素的地址。
    引用数组元素可以用下标法，也可以用指针法，即通过指向数组元素的指针找到所需的元素。

    int *p=&a[0];
    //等价于
    int *p;
    p=&a[0];
    //等价于
    int *p=a;
    //即：将a[0]的首地址给指针变量p;

    注意：
    在指针已指向一个数组元素时，可以对指针进行自加或自减运算。
    1、如果指针p已经指向数组中的一个元素，则p+1指向同一个数组中的下一个元素，p-1指向同一数组中的上一个元素；
    2、如果p的初值为&a[0],则p+i和a+i就是数组元素a[i]的地址；
    3、其实在编译时候a[i]就是按照 *a[i+1]处理的，即按照数组首元素的地址加上相对位移量得到要找的元素的地址，然后找出该单元中的内容，即： *(p+5)=*(a+5)=a[5]。[]实际上就是变址运算符，即将a[i]按a+i计算地址，然后找出此地址单元中的值；
    4、如果指针变量P1和P2都指向同一数组中的元素，如执行p2-p1,结果是p2-p1的值除以数组元素的长度，即：两个指针所指元素之间的距离。
    两指针不能相加，相加毫无意义。
    不用变化指针p的方式，换做变换数组a的方式即 ：a++是不行的，因为a是常量，a++无法实现

    *(p--)相当于a[i--];
    *(++p)相当于a[++i];
    *(--p)相当于a[--i];

指针在多维数组元素中的运用

    一个二维数组：a[n][n],其中a+1为a[1][0]。
    在二维数组中：a+i,a[i],*(a+i),&a[i],&a[i][0]的值相同，即它们都代表同一地址，但基类型不同。

    #include <stdio.h>
    int main(){
        int a[3][4]={
            1,3,5,7,9,11,13,15,17,19,21,23
        };
        printf("%d,%d\n",a,*a);
        printf("%d,%d\n",a[0],*(a+0));
        printf("%d,%d\n",&a[0],&a[0][0]);
        printf("%d,%d\n",a[1],a+1);
        printf("%d,%d\n",&a[1][0],*(a+1)+0);
        printf("%d,%d\n",a[2],*(a+2));
        printf("%d,%d\n",&a[2],a+2);
        printf("%d,%d\n",a[1][0],*(*(a+1)+0));
        printf("%d,%d\n",*a[2],*(*(a+2)+0));
        return 0;
    }

![image-1](/assets/blog_res/2023-10-17-jisuanjijichu5/image-1.png)

int (*p)[4];//表示定义p为一个指针变量，它指向包含4个整形元素的一维数组；
int *p[4];//表示的是指针数组。（因为[]的运算优先级别高所以会从左至右运行。）

**通过指针引用字符串**

1、字符数组由若干个元素组成，每个元素中放一个字符，而字符指针变量中存放的是地址（字符串第1个字符的地址），绝不是将字符串放到字符指针变量中；

2、可以对字符指针变量赋值，但不能对数组名赋值；

**3、可以在定义时对各元素赋初值，但不能用赋值语句对字符数组中全部元素整体赋值；**

4、编译时为字符数组分配若干存储单元，以存放各元素的值，而对字符指针变量，只分配一个存储单元；

5、指针变量的值是可以改变的，而字符数组名代表一个固定的值，不能改变；

6、字符数组中各元素的值是可以改变的（可以对它们再赋值），但字符指针变量指向的字符串常量中的内容是不可以被取代的；



