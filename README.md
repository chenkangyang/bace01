<!--
 * @Description: 词法分析器（C--）
 * @Version: 1.0
 * @Autor: Alex
 * @Date: 2019-12-23 20:00:09
 * @LastEditors: Alex
 * @LastEditTime: 2019-12-24 15:32:16
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
bison:
	flex -o src/scanner.c src/scanner.l
	bison -d src/analyser.y
	gcc -g -o src/parser src/scanner.c src/analyser.tab.c -ll
	./src/parser < test/input.c--

lex:
	flex -o src/scanner.c src/scanner.l
	gcc -g -o src/parser src/scanner.c -ll
	./src/parser < test/input.c--
```
`Makefile`部分解释如下: 

1. 对lex语言描述的词法文件`scanner.l`
使用`flex`转换得到c语言描述的词法文件, 默认输出为 `lex.yy.c` 我们重命名为: `-o scanner.c`
2. 对bison语言描述的语法文件`analyser.y`进行转换得到c语言描述的语法文件, 参数`-d`将`.h`文件和`.c`文件分离, 默认输出为`analyser.tab.c`和`analyser.tab.h`, 将`analyser.tab.h`include进`lex`文件以进行下一步的联合编译
3. 对`1`,`2`中生成文件进行联合编译, 输出可执行程序`parser`, 对输入文件input.c--进行语法分析.
4. 若lex文件没有main函数和yywrap,则在MAC上编译需添加 `-ll`参数, windows下用`-lfl`参数, 意思都是将flex库包含进去


## 初步实验: 对PL/0语言进行词法分析

-- 来自于官方文档 --

待分析文件: `square.pl0`
```pascal
VAR x, squ;

PRECEDURE square;
BEGIN
	squ:= x * x
END;

BEGIN
	x := 1;
	WHILE x <= 10 DO
	BEGIN
		CALL square;
		1 squ;
		x := x + 1
	END
END.
```
`scanner.l` 符号识别分类:
```lex
/* scanner for a toy Pascal-like language */

%{
/* need this for the call to atof() below */
#include <math.h>
%}

DIGIT    [0-9]
ID       [a-z][a-z0-9]*

%%

{DIGIT}+    {
            printf( "An integer: %s (%d)\n", yytext,
                    atoi( yytext ) );
            }

{DIGIT}+"."{DIGIT}*        {
            printf( "A float: %s (%g)\n", yytext,
                    atof( yytext ) );
            }

if|then|begin|end|procedure|function        {
            printf( "A keyword: %s\n", yytext );
            }

{ID}        printf( "An identifier: %s\n", yytext );

"+"|"-"|"*"|"/"   printf( "An operator: %s\n", yytext );

"{"[^}\n]*"}"     /* eat up one-line comments */

[ \t\n]+          /* eat up whitespace */

.           printf( "Unrecognized character: %s\n", yytext );

%%

main( argc, argv )
int argc;
char **argv;
    {
    ++argv, --argc;  /* skip over program name */
    if ( argc > 0 )
            yyin = fopen( argv[0], "r" );
    else
            yyin = stdin;

    yylex();
    }
%%
```
执行命令:
```
flex -o src/scanner.c src/scanner.l
gcc -g -o src/parser src/scanner.c -ll
./src/parser < test/square.pl0
```
分类后的部分结果如下:
```bash
Unrecognized character: V
Unrecognized character: A
Unrecognized character: R
An identifier: x
Unrecognized character: ,
An identifier: squ
...
....
```
成功识别了标识符x和squ

---

## C--语言的文法分析

### 描述词法
flex文件由以下三个部分构成
```
definitions
%%
rules
%%
user code
```

#### 正规文法转换成正则匹配式

根据公式：
```
右线性文法（X=aX|b）通解形式：X=a*b
左线性文法（X=Xa|b）通解形式：X=ba*
```
---
`标识符`转换过程如下：

<标识符>∷=<字母>|_|<标识符><字母>|<标识符>_|<标识符><数字>

即

<标识符>∷=<标识符>(<字母>+_+<数字>)+<字母>+_

即

<标识符>∷=(<字母>|_)(<字母>|_|<数字>)*

即
```lex
ID         [_|A-Za-z]+(_|[A-Za-z]|[0-9])*
```
---
`整数`转换过程如下

联立：
```lex
<整数>∷=<数字>|<非0数字><整数串><数字>|<非0数字><数字>
<整数串>∷=<整数串><数字>|<数字>
```
即
```
<整数>∷=<数字>|<非0数字><整数串><数字>|<非0数字><数字>
<整数串>∷=<数字>+
```
即
```
<整数>∷=<数字>|<非0数字><数字>+<数字>|<非0数字><数字>
<数字>∷=0|<非0数字>
```
即
```
INTEGER    [0-9]+
```
---
由此构建出C--语言的相关词法
```lex
INTEGER    [0-9]+
KEY        "break"|"case"|"const"|"continue"|"default"|"do"|"int"|"else"|"if"|"return"|"sizeof"|"void"|"struct"|"typedef"|"while"
ID         [_|A-Za-z]+(_|[A-Za-z]|[0-9])*
OP         "+"|"-"|"*"|"/"|"<<"|">>"|"="
HD         #include<*.*>
AT         \/\*(.*)\*\/
DM         ,|;|\(|\)|\{|\}|\[|\]|\'|\"|<|>
STR        \".*?\"|\'.*?\'
%%

{HD}        {printf( "A header: %s\n", yytext );}
{INTEGER}   {printf( "An integer: %s (%d)\n", yytext, atoi( yytext ) );}
{KEY}       {printf( "A keyword: %s\n", yytext );}
{ID}        {printf( "An identifier: %s\n", yytext );}
{OP}        {printf( "An operator: %s\n", yytext );}
{DM}        {printf( "A delimiter: %s\n", yytext );}
{STR}       {printf( "A string: %s\n", yytext );}
{AT}        {}
"{"[^}\n]*"}"     /* eat up one-line comments */
[ \t\n]+          /* eat up whitespace */
.           printf( "Unrecognized character: %s\n", yytext );

```
待分析文件: `input.c--`
```
#include <stdio.h>

void main() {
  int a, int b;
  cin << a << b;
  int x = a * 5 + 0
  cout >> x;
}
```

部分分析结果如下所示
```bash

$ flex -o src/scanner.c src/scanner.l
gcc -g -o src/parser src/scanner.c -ll
./src/parser < test/input.c--

A header: #include <stdio.h>
A keyword: void
An identifier: main
A delimiter: (
A delimiter: )
A delimiter: {
A keyword: int
An identifier: a
...
```

在`Makefile`所在目录执行`make`命令