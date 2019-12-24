<!--
 * @Description: 词法分析器（C--）
 * @Version: 1.0
 * @Autor: Alex
 * @Date: 2019-12-23 20:00:09
 * @LastEditors: Alex
 * @LastEditTime: 2019-12-24 12:13:56
 -->
# 语法分析（C--）

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

构建词法分析器有两大类方法
- 手写的语法分析器，以及手写的词法分析器
    - 清晰，但开发周期长
- 用lex/yacc或类似的生成器构建
    - 可快速构建原型系统或小语言

编译原理课程手写的[词法分析器例子](http://nuptalex.xyz/post/lexical_analyzer/)


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
├── src
│   ├── analyser.tab.c
│   ├── analyser.tab.h
│   ├── analyser.y
│   ├── lex.yy.c
│   ├── parser
│   ├── parser.dSYM
│   │   └── Contents
│   │       ├── Info.plist
│   │       └── Resources
│   │           └── DWARF
│   │               └── parser
│   ├── scanner.c
│   └── scanner.l
└── test
    ├── in.txt
    ├── input.c--
    └── square.pl0
```

其中 Makefile 如下:
```
all:
	flex -o src/scanner.c src/scanner.l
	bison -d src/analyser.y
	gcc -g -o src/parser src/scanner.c src/analyser.tab.c -ll
	./src/parser < test/input.c--

```
`Makefile`解释如下: 

1. 对lex语言描述的词法文件`scanner.l`
使用`flex`转换得到c语言描述的词法文件, 默认输出为 `lex.yy.c` 我们重命名为: `-o scanner.c`
2. 对bison语言描述的语法文件`analyser.y`进行转换得到c语言描述的语法文件, 参数`-d`将`.h`文件和`.c`文件分离, 默认输出为`analyser.tab.c`和`analyser.tab.h`, 将`analyser.tab.h`include进`lex`文件以进行下一步的联合编译
3. 对`1`,`2`中生成文件进行联合编译, 输出可执行程序`parser`, 对输入文件input.c--进行语法分析.
4. 若lex文件没有main函数和yywrap,则在MAC上编译需添加 `-ll`参数, windows下用`-lfl`参数, 意思都是将flex库包含进去


## 初步实验例子

`input.c--`如下:
```c
int do_math(int a) {
  int x = a * 5 + 3
}
do_math(10)
```
`scanner.l`识别源文件对其中的符号进行分类:
```lex
%{
#include "stdio.h"
%}
%%
[\t\n]                  ;
[0-9]+                printf("Int     : %s\n",yytext);
[0-9]*\.[0-9]+        printf("Float   : %s\n",yytext);
[a-zA-Z][a-zA-Z0-9]*  printf("Var     : %s\n",yytext);
[\+\-\*\/\%]          printf("Op      : %s\n",yytext);
.                     printf("Unknown : %c\n",yytext[0]);
%%
```
执行命令:
```
flex -o src/scanner.c src/scanner.l
gcc -g -o src/parser src/scanner.c -ll
./src/parser < test/input.c--
```
分类后的部分结果如下:
```bash
Var     : int
Unknown :
Var     : do
Unknown : _
Var     : math
...
....
```
---

## C--语言的文法分析

### 描述词法




在`Makefile`所在目录执行`make`命令