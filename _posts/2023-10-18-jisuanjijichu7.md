---
title: 计算机基础——软件工程
date: 2023-10-18 9:50:00 +0800
categories: [计算机基础,软件工程]
tags: [计算机基础,软件工程]
pin: false
author: 
    name: hejiahua007
    link: https://space.bilibili.com/507838758
toc: true
comments: true
math: false
mermaid: true

---

# 第一章：绪论

1. 数据结构三要素：**逻辑结构、存储结构、数据的运算**；其中逻辑结构包括线性结构（线性表、栈、队列）和非线性结构（树、图、集合）

2. 数据是信息的载体，是描述客观事物属性的数、字符及所有能输入到计算机中并被计算机程序识别和处理的符号的集合。

3. 数据元素是数据的基本单位，可由若干数据项组成，数据项是构成数据元素的不可分割的最小单位

4. 数据对象是具有相同性质的数据元素的集合，是数据的一个子集
   
5. 数据类型是一个值的集合和定义在此集合上的一组操作的总称
6. 数据类型包括：原子类型、结构类型、抽象数据类型
7. 数据结构是相互之间存在一种或多种特定关系的数据元素的集合，它包括逻辑结构、存储结构和数据运算三方面内容
8. 数据的逻辑结构和存储结构是密不可分的，算法的设计取决于所选定的逻辑结构，而算法的实现依赖于采用的存储结构
9. 数据的存储结构主要有顺序存储、连式存储、索引存储和散列存储
10. 施加在数据上的运算包括运算的定义和实现。运算的定义是针对逻辑结构的，指出运算的功能；运算的实现是针对存储结构的，指出运算的具体操作步骤
11. 在存储数据时，通常不仅要存储各数据元素的值，而且要存储数据元素之间的关系
12. 对于两种不同的数据结构，逻辑结构或物理结构一定不同吗？

数据运算也是数据结构的一个重要方面。对于两种不同的数据结构，他们的逻辑结构和物理结构完全有可能相同（比如二叉树和二叉排序树）

13.  链式存储设计时，各个不同结点的存储空间可以不连续，但结点内的存储单元地址必须连续
14. 算法是对特定问题求解步骤的一种描述，它是指令的有限序列，其中每条指令包括一个或多个操作。
15. 算法的五个特性：有穷性、确定性、可行性、输入、输出（字面意思，第一遍看的话建议看看书具体概念）
16. 通常设计一个好的算法应考虑：正确性、可读性、健壮性、效率与低存储量需求
17. 算法的时间复杂度不仅依赖于问题的规模n，也取决于待输入数据的性质
18. 若输入数据所占空间只取决于问题本身而和算法无关，则只需分析除输入和程序之外的额外空间
19. 算法原地工作是指算法所需辅助空间为常量，即O(1)
20. 一个算法应该是问题求解步骤的描述
21. 所谓时间复杂度，是指最欢情况下估算算法执行时间的一个上界
22. 同一个算法，实现语言的级别越高，执行效率越低

# 第二章：线性表

1. 线性表是具有相同数据类型的n个数据元素的有限序列。
2. 线性表特点：表中元素个数有限；表中元素具有逻辑上的顺序性；表中元素都是数据元素；表中元素的数据类型都相同，即每个元素占有相同大小存储空间；表中元素具有抽象性，即仅讨论元素间的逻辑关系而不考虑元素究竟表示什么内容
3. 线性表是一种逻辑结构，表示元素之间一对一的相邻关系。其顺序存储：顺序表；其链式存储：单链表、双链表、循环链表、静态链表。
4. 线性表的顺序存储又称顺序表，特点是表中元素的逻辑顺序与其物理顺序相同。
5. 线性表的顺序存储结构是一种随机存取的存储结构，通常用高级设计语言中的数组来描述线性表的顺序存储结构（线性表中元素位序从1开始）
6. 顺序表最主要特点是随机访问。它的存储密度高，每个结点只存储数据元素，插入和删除操作需要移动大量元素
7. 顺序表插入,删除和查找时间复杂度均为O(n)
8. 头指针和头结点区分：不管带不带头结点，头指针都始终指向链表的第一个结点，而头结点是带头结点的链表中的第一个结点，结点内通常不存储信息
9. 采用头插法建立单链表时，读入数据的顺序与生成的链表中的元素的顺序是相反的，每个结点插入时间为O(1)一共为O(n)
10. 尾插法必须增加一个尾指针使其始终指向当前链表的尾结点
11. 双链表中的按值查找和按位查找的操作与单链表相同，但双链表在插入和删除操作的实现上时间复杂度仅为O(1)
12. 循环单链表中没有指针域为NULL的结点，故循环单链表的判空条件为它是否等于头指针
13. 有时对单链表常做的操作是在表头和表尾进行的，此时对循环单链表不设头指针而仅设尾指针
14. 在循环双链表L中，某结点*p为尾结点时，p->next==L;当循环双链表为空表时，其头结点的prior域和next域都等于L
15. 静态链表借助数组来描述线性表的链式存储结构，结点也有数据域data和指针域next，这里的指针是结点的相对地址（数组下标）
16. 静态链表以next==-1作为其结束的标志
17. 通常较稳定的线性表选择顺序存储，而频繁进行插入、删除操作的线性表宜选择链式存储
18. 链式存储结构比顺序存储结构能更方便地表示各种逻辑结构
19. 顺序存储方式不仅能用于存储线性结构，也可以用于非线性（树和图）
20. 若用单链表来表示队列，这应该选用带尾指针的循环链表
21. 给定n个元素的一维数组，建立一个有序单链表最低时间复杂度为O(nlogn)
22. 单链表中，增加一个头结点的目的是方便运算的实现
23. 与单链表相比，双链表的优点之一是访问前后相邻结点更灵活
24. 某线性表用带头结点的循环单链表存储，头指针为head，当ead->next->next=head时，线性表长度可能是0或1

# 第三章：栈和队列

1. 栈是只允许在一端进行插入和删除操作的线性表，操作特性可以明显的概括为后进先出
2. n个不同元素进栈，出栈元素不同排列的个数为C(n:2n)/n+1，即卡特兰数
3. 栈是一种操作受限的线性表，类似于线性表，它也有对应的两种存储方式
4. 采用顺序存储的栈称为顺序栈；栈空：S.top==-1;栈满：S.top==MaxSize-1；栈长：S.top+1
5. 由于顺序栈的入栈操作受数组上界的约束，有可能发生栈上溢

``` cpp
下面是顺序栈上常用的基本运算的实现
1.初始化
	void InitStack(SqStack &S){
		S.top=-1;
	}
2.栈判空
	bool StackEmpty(SqStack S){
		if(S.top==-1)	return true;
		else	return false;
	}
3.进栈
	bool Push(SqStack &S,ElemType x){
		if(S.top==MaxSize-1)	return false;
		S.data[++S.top]=x;	return true;
	}
4.出栈
	bool Pop(SqStack &S,ElemType &x){
		if(S.top==1)	return false;
		x=S.data[S.top--];
		return true;
	}
5.读栈顶元素
	bool GetTop(SqStack S,ElemType &x){
		if(S.top==-1)	return false;
		x=S.data[S.top];
		return true;
	}
```

6. 利用栈底位置相对不变的特性，可让两个顺序栈共享一个一维数组空间，将两个栈的栈底分别设置在共享空间的两端，两个栈顶向共享空间的中间延伸
7. 采用连式存储的栈称为链栈，链栈的优点是便于多个栈共享存储空间和提高其效率，且不存在栈满上溢的情况，通常采用单链表实现
8. 栈和队列具有相同的逻辑结构，他们都属于线性表，但是运算不同
9. 队列简称队，也是一种操作受限的线性表，队尾插入队头删除，操作特性为先进先出
10. 队列的顺序存储，队头指针front指向队头元素，队尾指针rear指向队尾元素的下一个位置
11. 循环队列队空：Q.front==Q.rear ； 队满(Q.rear+1）%MaxSize == Q.front；

``` cpp
循环队列的操作
1.初始化
	void InitQueue(SqQueue &Q){
		Q.rear=Q.front=0;
	}
2.判队空
	bool isEmpty(SqQueue &Q){
		if(Q.rear==Q.front) return true;
		else	return false;
	}
3.入队
	bool EnQueue(SqQueue &Q,ElemType x){
		if((Q.rear+1)%MaxSize==Q.front) return false;
		Q.data[Q.rear]=x;
		Q.rear=(Q.rear+1)%MaxSize;
		return true;
	}
4.出队
	bool DeQueue(SqQueue &Q,ElemType &x){
		if(Q.rear==Q.front)	return fasle;
		x=Q.data[Q.front];
		Q.front=(Q.front+1)%MaxSize;
		return true;
	}
	
```
12. 队列的链式表示称为链队列，它实际上是一个同时带有队头指针和队尾指针的单链表。当Q.front== NULL且Q.rear==NULL时，链表队列为空
13. 通常将链式队列设计成一个带头结点的单链表

```cpp
链式队列的基本操作
1.初始化
	void InitQueue(LinkQueue &Q){
		Q.front=Q.rear=(LinkNode*)malloc(sizeof(LinkNode));
		Q.front->next=NULL;
	}
2，判队空
	bool IsEmpty(LinkQueue Q){
		if(Q.front==Q.rear)	return true;
		else	return false;
	}
3.入队
	void EnQueue(LinkQueue &Q,ElemType x){
		LinkNode *s=(LinkNode *)malloc(sizeof(LinkNode));
		s->data=x; s->next=NULL;
		Q.rear->next=s; Q.rear=s;
	}
4，出队
	bool DeQueue(LinkQueue &Q,ElemType &x){
		if(Q.front==Q.rear)	return false;
		LinkNode *p=Q.front->next;
		x=p->data;
		Q.front->next=p->next;
		if(Q.rear==p)	Q.rear=Q.front;
		free(p);
		return true;
	}

```
# 第四章：串（重点为KMP，但统考通常不考）

1. 字符串简称串，串由零个或多个字符组成的有限序列
2. 串的逻辑结构和线性表极为相似，区别仅在于串的数据对象限定为字符集
3. 串的存储结构：定长顺序存储表示、堆分配存储表示、块链存储表示
4. 子串的定位操作通常称为串的模式匹配，它求的是子串在主串中的位置。

```cpp
暴力匹配算法：
int Index(SString S,SString T){
	int i=1,j=1;
	while(i<=S.length&&j<=T.length){
		if(S.ch[i]==T.ch[i]){
			++i; ++j;
		}
		else{ i=i-j+2; j=1;}
	}
	if(j>T.length)	return i-T,length;
	else return 0;
}
KMP算法：（非王道代码）
求Next数组：
//s[]是模式串，p[]是模板串，n是s的长度，m是p的长度
for(int i=2,j=0;i<=m;i++)
{
	while(j&&p[i]!=p[j+1]) j=ne[j];
	if(p[i]==p[j+1])	j++;
	ne[i]=j;
}
//匹配
for(int i=1,j=0;i<=n;i++)
{
	while(j&&s[i]!=p[j+1])	j=ne[j];
	if(s[i]==p[j+1])	j++;
	if(j==m)
	{
		j=ne[j];
		//匹配成功后的逻辑
	}
} 
 ```

# 第五章：树与二叉树
```cpp
1.先序遍历
void PreOrder(BiTree T){
	if(T!=NULL){
		visit(T);
		PreOrder(T->lchild);
		PreOrder(T->rchild);
	}
}
2.中序遍历
void PreOrder(BiTree T){
	if(T!=NULL){
		PreOrder(T->lchild);
		visit(T);
		PreOrder(T->rchild);
	}
}
3.后序遍历
void PreOrder(BiTree T){
	if(T!=NULL){
		PreOrder(T->lchild);
		PreOrder(T->rchild);
		visit(T);
	}
}
时间复杂度、空间复杂度均为O(n)
```
```cpp
BSTNode *BST_Search(BiTree T,ElemType key){
	while(T!=NULL&&key!=T->data){
		if(key<T->data)	T=T->lchild;
		else	T=T->rchild;
		}
		return T;
	}
```
```cpp
int BST_Insert(BiTree &T,KeyType k){
	if(T==NULL){
		T=(BiTree)malloc(sizeof(BSTNode));
		T->key=k;
		T->lchild=T->rchild=NULL;
		return 1;
	}
	else if(k==T->key)	return 0;
	else if(k<T->key)
		return BST_Insert(T->lchild,k);
	else	
		return BST_Insert(T->rchild,k);
	}
```
```cpp
void Creat_BST(BiTree &T,KeyType str[],int n){
	T=NULL;
	int i=0;
	while(i<n){
		BST_Insert(T,str[i]);
		i++;
	}
}

```
# 第六章：图
```cpp
二分查找：
int Binary_Search(SeqList L,ElemType key){
	int low=0,high=L.TableLen-1,mid;
	while(low<=high){
		mid=(low+high)/2;
		if(L.elem[mid]==key)	return mid;
		else if(L.elem[mid]>key)	high=mid-1;
		else	low=mid+1;
	}
	return -1;
}
```
# 第八章：排序

```cpp
void InsertSort(ElemType A[],int n){
	int i,j;
	for(i=2;i<=n;i++)	//依次将A2~An插入到前面已排序序列
		if(A[i]<A[i-1]){ //若Ai关键码小于前驱，将Ai插到前面
			A[0]=A[i];	//复制为哨兵，A0不存放元素
			for(j=i-1;A[0]<A[j];--j)	//从后往前查找待插入位置
				A[j+1]=A[j]; //向后挪位
			A[j+1]=A[0]; //复制到插入位置
		}
}
```

```cpp
void InsertSort(ElemType A[],int n){
	int i,j,low,high,mid;
	for(i=2;i<=n;i++){
		A[0]=A[i];
		low=1;high=i-1;
		while(low<=high){
			mid=(low+high)/2;
			if(A[mid]>A[0]) high=mid-1;
			else	low=mid+1;
		}
		for(j=i=1;j>=high+1;--j)
			A[j+1]=A[j];
		A[high+1]=A[0];
	}
}
```
```cpp
void ShellSort(ElemType A[],int n){
	for(dk=n/2;dk>=1;dk=dk/2)
		for(i=dk+1;i<=n;i++)
			if(A[i]<A[i-dk]){
				A[0]=A[i];
				for(j=i-dk;j>0&&A[0]<A[j];j-=dk)
					A[j+dk]=A[j];
				A[j+dk]=A[0];
			}
}
```
```cpp
void BubbleSort(ElemType A[],int n){
	for(i=0;i<n-1;i++){
		flag=false;
		for(j=n-1;j>i;j--)
			if(A[j-1]>A[j]){
				swap(A[j-1],A[j]);
				flag=true;
			}
		if(flag==false)	return;
	}
}
```
```cpp
void SelectSort(ElemType A[],int n){
	for(i=0;i<n-1;i++){
		min=j;
		for(j=i+1;j<n;j++)
			if(A[j]<A[min])	min=j;
		if(min!=i)	swap(A[i],A[min]);
	}
}

```






