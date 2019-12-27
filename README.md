<!--
 * @Description: 解析器（C--）
 * @Version: 1.0
 * @Autor: Alex
 * @Date: 2019-12-23 20:00:09
 * @LastEditors  : Alex
 * @LastEditTime : 2019-12-26 23:06:28
 -->
# C 解析器 (Parser)

---
描述C--语言的文法(grammar)规则如下：

```
<程序>∷=void main() <语句块>
<语句块>∷={<语句串>} 
<语句串>∷=<语句串><语句>|
<语句>∷=<赋值语句>|<输入语句>|<输出语句> 
<赋值语句>∷=<标识符> = E;
<标识符>∷=<字母>|_|<标识符><字母>|<标识符>_|<标识符><数字>
<整数>∷=<数字>|<非0数字><整数串><数字>|<非0数字><数字>
<整数串>∷=<整数串><数字>|<数字>
<非0数字>∷=1|2|3|…|9
<数字>∷=0|<非0数字>
<字母>∷=a|b|c|…|z
E∷=T|E+T 
T∷=F|T*F
F∷= (E)|<标识符>|整数
<输入语句>∷=cin>><标识符>;
<输出语句>∷=cout<<<标识符>;
```


```
                   +-------+                      +--------+
-- source code --> | lexer | --> token stream --> | parser | --> assembly
                   +-------+                      +--------+
```

## 环境

MAC下自带了Flex 和 Bosin 的编译环境

```bash
$ gcc -v

Configured with: --prefix=/Library/Developer/CommandLineTools/usr --with-gxx-include-dir=/Library/Developer/CommandLineTools/SDKs/MacOSX10.14.sdk/usr/include/c++/4.2.1
Apple LLVM version 10.0.1 (clang-1001.0.46.3)
Target: x86_64-apple-darwin18.5.0
Thread model: posix
InstalledDir: /Library/Developer/CommandLineTools/usr/bin

```

其他的操作系统下需要自行配置环境（gcc, lex/flex, yacc/bison）

- Lex - A Lexical Analyzer Generator
- Yacc: Yet Another Compiler-Compiler
- Flex, A fast scanner generator
- Bison, The YACC-compatible Parser Generator

关于lex，yacc，flex，bison，文档以及一些小例子可以查看：[文档](http://dinosaur.compilertools.net/)

## 项目目录

```bash
.
├── Makefile
├── README.md
├── doc.md
├── src
│   ├── analyser.tab.c
│   ├── analyser.tab.h
│   ├── analyser.y
│   ├── node.h
│   ├── parser
│   ├── scanner.c
│   ├── scanner.l
│   ├── testPair
│   └── testPair.l
└── test
    ├── cacl.txt
    ├── in.txt
    ├── input.c--
    └── square.pl0
```

命令解释:
```bash

$ make clean  // 清除所有生成的源文件
$ make bison  // 使用bison生成语法解释源程序
$ make lex    // 使用flex生成词法解释源程序
$ make        // 编译生成目标解释程序

$ make clean  // 清除所有生成的源文件
$ make pair   // 测试词法的匹配
```
---

## V1.0
程序: [v1.0](https://github.com/chenkangyang/bace01/releases/tag/v1.0)

    文法识别

待分析代码`input.c--`如下：

```c
#include <stdio.h>
void main() {
  int a;
  cin >> a;
  a = a * 5 + 3.1415926536 - a / a;
  cout << x;
}
```

分析结果如下：
```bash
➜  bace01 git:(master) ✗ make bison
cd src/ && bison -d analyser.y
analyser.y: conflicts: 7 shift/reduce
analyser.y:52.5: warning: rule never reduced because of conflicts: stmt: /* empty */
flex -o src/scanner.c src/scanner.l
gcc -g -o src/parser src/*.c
./src/parser < test/input.c--
Header
定义INT变量
语句串
输入语句
语句串
赋值语句
语句串
输出语句
语句串
语句块
函数
```
根据在 `.y` 文件中定义的文法的先后, 越后定义文法的越先识别, 并且别识别边`规约`. 因此程序从细到粗依次识别了: 变量(`int a` ), 语句串(`int a;`), 输入语句`cin >> a;`, 语句串(`int a; cin >> a;`), 赋值语句, `...` , 语句块(`{ ... }`), 函数(`void main() {...}`);

## V1.1
程序: [v1.1](https://github.com/chenkangyang/bace01/releases/tag/v1.1)

    语义解析: 加减乘除和输出语句

待分析代码`input.c--`如下：

```c
#include <stdio.h>

void main() {

  double a_0;
  double b;
  double c;
  double d;
  
  cout << a_0;

  a_0 = 4 + 3 / 2 - 1 * 0;
  cout << a_0;

  b = 3;
  c = 3.14;
  d = b + c;
  cout << d;
}
```

执行结果如下：
```bash
➜  bace01 git:(master) ✗ make clean
rm src/*.c
➜  bace01 git:(master) ✗ make bison
cd src/ && bison -d analyser.y
➜  bace01 git:(master) ✗ make lex
flex -o src/scanner.c src/scanner.l
➜  bace01 git:(master) ✗ make
gcc -g -o src/parser src/scanner.c src/analyser.tab.c
./src/parser < test/input.c--
0
5.5
6.14
```