---
title: python_class
date: 2023-10-24 9:30:00 +0800
categories: [python,class]
tags: [python,class]
pin: false
author: 
    name: hejiahua007
    link: https://space.bilibili.com/507838758
toc: true
comments: true
math: false
mermaid: true

---

# python类一定要有__init__()方法吗

什么是–类？

类是对现实事物的抽象，例如人类，人有男人、女人，但概念还是太大，需要继续抽象，思考一下人（不论男女）正常情况都有什么特征，例如名字、性别等固定的特征，一般用名词来限定（属性），有什么行为，例如人会吃饭、看电影、上厕所等行为（方法），一般用动词来描述，我们将属性和方法给抽象出来（一定是普遍的，共有的，非特指或小范围的），就构成了人类这个"类"（Class）。

现在来回答开始时提出的问题：python 类中一定需要有 __init __方法么？没有的会怎样？

我们已经知道了，类是由属性和方法构成的，python类中用__init__方法（也可理解为初始化方法）来定义属性，在实例化一个对象时，会先调用__init__方法，将这个类所具有的相关属性赋予这个对象，然后我们通过这个对象，就可以直接访问他所具有的属性。

还是人类这个例子，看下面的代码：

``` cpp
class Person():
	#定义一个类
    def __init__(self,name,gender):
    	#人有名字
        self.name = name
        #人有性别
        self.gender = gender
    def eat(self):
    	#人需要吃饭，所以定义一个吃饭的方法
        print("%s正在吃饭，有啥事吃完再说。。。"% self.name)
    def watch_movie(self,movie_name):
    	#还需要娱乐，所以定义可以看电影的方法
        print("{}正在看{},这部电影！".format(self.name, movie_name))
    def go_wc(self):
    	#人还需要上厕所，不然憋死了，所以定义一个上厕所的方法
        if self.gender == "男":
        	#男的上男厕所，进错了就是耍流氓，女的就是进错了。。。哈哈公平何在
            print("{}要进{}厕所。。。不然就是耍流
            氓".format(self.name,self.gender) )
        if self.gender == "女":
            print("{}要进{}厕所。。。不然就是走错
            了".format(self.name,self.gender))
            
if __name__ == "__main__":
    #实例化一个人
    person1 = Person("小明","男")
    #查看这个人的名字
    print(person1.name)
    #查看这个人的性别
    print(person1.gender)
    #调用吃饭这个方法，确保不被饿死
    person1.eat()
    #吃完可以看看电影
    person1.watch_movie("色即是空")
    #看电影过程中可能需要上厕所
    person1.go_wc()
```
对比一下面的代码
``` cpp
class Person():
	#定义一个人类
	#没有__init__方法，直接定义行为（方法）
    def eat(self,name):
    	#人需要吃饭，所以定义一个吃饭的方法
        print("%s正在吃饭，有啥事吃完再说。。。"%name)
    def watch_movie(self,name, movie_name):
    	#看电影
        print("{}正在看{},这部电影！".format(name, movie_name))
    def go_wc(self, name,gender):
    	#上厕所
        if gender == "男":
            print("{}要进{}厕所。。。不然就是耍流氓".format(name,gender))
        if gender == "女":
            print("{}要进{}厕所。。。不然就是走错了".format(name,gender))
            
if __name__ == "__main__":
    #实例化一个人，貌似其他动物也有这些行为，例如二哈，不一定是人啊
    person1 = Person()
    #print(person1.name) 没有名字属性，调用报错
    #print(person1.gender) 没有性别属性，调用报错
    #吃饭
    person1.eat("小红")
    #看电影
    person1.watch_movie("小红","红楼梦")
    #上厕所
    person1.go_wc("小红","女")
```
这个修改版本中去掉了__init__方法，这导致这个类没有name和gender属性，如果执行print（self.name）或者print（self.gender）就会报错，而且在调用吃饭，看电影、上厕所这些方法时需要传入过多的重复参数增加了代码的冗余。如果不事先知道是定义了一个“人”类，在没有相关属性的前提前提下不便于确定这个class是什么，毕竟其他动物也会吃饭，也可以看电影（二哈）。。。虽说去掉__init__对于定义这个类并不会报错，但为了便于使用和理解应当定义__init__方法。想一想现实生活中什么东西没有属性（不可用语言描述），但是却有行为。。。怎么感觉怪怪的。。。。

原文链接：https://blog.csdn.net/qq_37980828/article/details/103768351

**__ init__ ()方法**

在python中创建类后，通常会创建一个 __ init__ ()方法，这个方法会在创建类的实例的时候自动执行。 __ init__ ()方法必须包含一个self参数，而且要是第一个参数。

比如下面例子中的代码，我们在实例化Bob这个对象的时候， __ init__ ()方法就已经自动执行了，但是如果不是 __ init__ ()方法，比如说eat（）方法，那肯定就只有调用才执行

    class Person():
        def __init__(self):
            print("是一个人")
        def eat(self):
            print("要吃饭" )
    Bob=Person()

![image-7](/assets/blog_res/2023-10-24-python_class/image-7.png)

# python——class类和方法的用法详解

## 类和方法的概念和实例

- **类(Class)：**用来描述具有相同的属性和方法的对象的集合。它定义了该集合中每个对象所共有的属性和方法。对象是类的实例。
- **方法：**类中定义的函数。
- **类的构造方法__init__()：**类有一个名为 init() 的特殊方法（构造方法），该方法在类实例化时会自动调用。
- **实例变量：**在类的声明中，属性是用变量来表示的，这种变量就称为实例变量，实例变量就是一个用 self 修饰的变量。
- **实例化：**创建一个类的实例，类的具体对象。
- **继承：**即一个派生类（derived class）继承基类（base class）的字段和方法。继承也允许把一个派生类的对象作为一个基类对象对待。例如，有这样一个设计：一个Dog类型的对象派生自Animal类，这是模拟"是一个（is-a）"关系（例图，Dog是一个Animal）。


1. python类:class

python的class（类）相当于一个多个函数组成的家族，如果在这个Myclass大家族里有一个人叫f，假如这个f具有print天气的作用，那么如果有一天我需要这个f来print一下今天的天气，那么我必须叫他的全名MyClass.f才可以让他给我print，即在调用他的时候需要带上他的家族名称+他的名称。

- 属性：属性就是在这个类里的变量。如果变量是物品，那么不同的属性就是这个大家族里不同的物品
- 方法：方法就是在这个类里的函数。如果函数是人，那么不同的方法就是这个大家族里不同的人。

MyClass实例：
``` cpp
#Myclass家族，但是这个家族只有一个人f
class MyClass:   
  """一个简单的类实例"""    
  i = 12345    
  def f(self):        
    return 'hello world'
# 实例化类
x = MyClass() 
# 访问类的属性和方法
print("MyClass 类的属性 i 为：", x.i) #家族x + 物品名i
print("MyClass 类的方法 f 输出为：", x.f()) #家族x + 人名f
```
输出结果：
![image](/assets/blog_res/2023-10-24-python_class/image.png)

2. 类的构造方法__init__()

假如init()也是人，但是他是家族和外界联络员，当外界的人想调用自己家族的人，就必须要先告诉他，**所以只要家族的人被调用，那么init()就会被先执行**，然后由他去告诉那个被调用的人，执行被调用的。

init()实例：

``` cpp
class Complex:
    def __init__(self, realpart, imagpart): #必须要有一个self参数，
        self.r = realpart
        self.i = imagpart
x = Complex(3.0, -4.5)
print(x.r, x.i)   # 输出结果：3.0 -4.5
```
输出结果：
![image-1](/assets/blog_res/2023-10-24-python_class/image-1.png)

3. 类中方法的参数self

在类的内部，使用 def 关键字来定义一个方法，与一般函数定义不同，类方法必须包含参数self, 且为第一个参数，self代表的是类的实例。

- self：**类的方法与普通的函数只有一个特别的区别**——必须有一个额外的第一个参数名称, 按照惯例它的名称是self。

- 类的实例：是将类应用在实例场景之中，比如有个类里的函数是f，假如这个f具有print某一时刻的天气状况的能力，那么如果我需要这个f来print一下今天12点的天气，**那么让他打印今天12点的天气这个动作，就是类的实例化**，让类中的函数具有的能力变成真实的动作。
实例化实例：
``` cpp
#类定义
class people:
    #定义基本属性
    name = ''
    age = 0
    #定义私有属性,私有属性在类外部无法直接进行访问
    #定义构造方法
    def __init__(self,n,a):
        self.name = n
        self.age = a
    def speak(self):
        print("%s 说: 我 %d 岁。" %(self.name,self.age))

# 实例化类
p = people('Python',10,30)
p.speak()
```
输出结果：

![image-2](/assets/blog_res/2023-10-24-python_class/image-2.png)

4. 继承

假如有两个家族，有一个家族A开始没落了，另一个新兴的家族B想继承A家族的物资和佣人，那么就可以通过如下的方式实现继承，在这里，家族A即是父类，家族B是子类。在用法上，如果B家族可以任意使用A家族的物品和佣人。

    class [子类]([父类]):

- **BaseClassName**（示例中的基类名）必须与派生类定义在一个作用域内。除了类，还可以用表达式，基类定义在另一个模块中时这一点非常有用。
- python还支持**多继承**，即可以继承多个父类。继承方式和单继承方式一样，方式如下：

    class [子类]([父类]1, [父类]2, [父类]3):

继承实例：
``` cpp
#类定义
class people:
    #定义基本属性
    name = ''
    age = 0
    #定义私有属性,私有属性在类外部无法直接进行访问
    __weight = 0
    #定义构造方法
    def __init__(self,n,a,w):
        self.name = n
        self.age = a
        self.__weight = w
    def speak(self):
        print("%s 说: 我 %d 岁。" %(self.name,self.age))

#单继承示例
class student(people): #student为子类，people为父类
    grade = ''
    def __init__(self,n,a,w,g):
        #调用父类的构函
        people.__init__(self,n,a,w)
        self.grade = g
    #覆写父类的方法
    def speak(self):
        print("%s 说: 我 %d 岁了，我在读 %d 年级"%(self.name,self.age,self.grade))

s = student('ken',10,60,3)
s.speak()
```
运行结果：

![image-3](/assets/blog_res/2023-10-24-python_class/image-3.png)

5. 方法重写


如果你的父类方法的功能不能满足你的需求，你可以在子类重写你父类的方法。即如果B家族继承了A家族，但是B家族有个佣人只会扫地，于是A家族给这个人洗脑，让他啥都不会，然后再教这个佣人洗碗、擦桌子的技能，那么这个佣人就只会洗碗和擦桌子了。

- super()函数是用于调用父类(超类)的一个方法。

方法重写实例：

``` cpp
class Parent:        # 定义父类
   def myMethod(self):
      print('调用父类方法')

class Child(Parent): # 定义子类
   def myMethod(self):
      print('调用子类方法')

c = Child()          # 子类实例
c.myMethod()         # 子类调用重写方法
super(Child,c).myMethod() #用子类对象调用父类已被覆盖的方法
```
输出结果：
![image-4](/assets/blog_res/2023-10-24-python_class/image-4.png)

## 类的特殊属性与方法

**类的私有属性**

- _private_attrs：两个下划线开头，声明该属性为私有，不能在类的外部被使用或直接访问。在类内部的方法中使用时 self.__private_attrs。

私有属性实例：
``` cpp
class JustCounter:
    __secretCount = 0  # 私有变量
    publicCount = 0    # 公开变量

    def count(self):
        self.__secretCount += 1
        self.publicCount += 1
        print(self.__secretCount)

counter = JustCounter()
counter.count()
counter.count()
print(counter.publicCount)
print(counter.__secretCount)  # 报错，实例不能访问私有变量
```
输出结果：
![image-5](/assets/blog_res/2023-10-24-python_class/image-5.png)

**类的私有方法**

__private_method：两个下划线开头，声明该方法为私有方法，只能在类的内部调用 ，不能在类的外部调用。self.__private_methods。

私有方法实例：

``` cpp
class Site:
    def __init__(self, name, url):
        self.name = name       # public
        self.__url = url   # private

    def who(self):
        print('name  : ', self.name)
        print('url : ', self.__url)

    def __foo(self):          # 私有方法
        print('这是私有方法')

    def foo(self):            # 公共方法
        print('这是公共方法')
        self.__foo()

x = Site('Python', 'www.irvingao.com')
x.who()        # 正常输出
x.foo()        # 正常输出
x.__foo()      # 报错
```
输出结果：
![image-6](/assets/blog_res/2023-10-24-python_class/image-6.png)

补充：
## super(Net, self).init()

**super(Net, self).init()**

python中的super(Net, self).init()是指首先找到Net的父类（比如是类NNet），然后把类Net的对象self转换为类NNet的对象，然后“被转换”的类NNet对象调用自己的init函数，其实简单理解就是子类把父类的__init__()放到自己的__init__()当中，这样子类就有了父类的__init__()的那些东西。

回过头来看看我们的我们最上面的代码，Net类继承nn.Module，super(Net, self).init()就是对继承自父类nn.Module的属性进行初始化。而且是用nn.Module的初始化方法来初始化继承的属性。

    class Net(nn.Module):

        def __init__(self):
            super(Net, self).__init__()
            # 输入图像channel：1；输出channel：6；5x5卷积核
            self.conv1 = nn.Conv2d(1, 6, 5)

也就是说，子类继承了父类的所有属性和方法，父类属性自然会用父类方法来进行初始化。
当然，如果初始化的逻辑与父类的不同，不使用父类的方法，自己重新初始化也是可以的。比如：

``` cpp
#!/usr/bin/env python
# -*- coding:utf-8 -*-
 
class Person(object):
    def __init__(self,name,gender,age):
        self.name = name
        self.gender = gender
        self.age = age
 
class Student(Person):
    def __init__(self,name,gender,age,school,score):
        #super(Student,self).__init__(name,gender,age)
        self.name = name.upper()  
        self.gender = gender.upper()
        self.school = school
        self.score = score
 
s = Student('Alice','female',18,'Middle school',87)
print s.school
print s.name
```

