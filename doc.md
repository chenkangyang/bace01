# C 解析器

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
├── README.md
├── doc.md
├── src
│   ├── analyzer.tab.c
│   ├── analyzer.tab.h
│   ├── analyzer.y
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

其中 `Makefile` 如下:

```
all:
	gcc -g -o src/parser src/*.c
	./src/parser < test/input.c--

bison:
	cd src/ && bison -d analyzer.y

lex:
	flex -o src/scanner.c src/scanner.l

clean:
	rm src/*.c

pair:
	flex -o src/testPair.c src/testPair.l
	gcc -g -o src/testPair src/testPair.c -ll
	./src/testPair < test/input.c--
```
[阮一峰的Makefile教程](http://www.ruanyifeng.com/blog/2015/02/make.html)

`Makefile`部分解释如下: 

1. 对lex语言描述的词法文件`scanner.l`
使用`flex`转换得到c语言描述的词法文件, 默认输出为 `lex.yy.c` 我们重命名为: `-o scanner.c`
2. 对bison语言描述的语法文件`analyzer.y`进行转换得到c语言描述的语法文件, 参数`-d`将`.h`文件和`.c`文件分离, 默认输出为`analyzer.tab.c`和`analyzer.tab.h`, 将`analyzer.tab.h`include进`lex`文件以进行下一步的联合编译
3. 对`1`,`2`中生成文件进行联合编译, 输出可执行程序`parser`, 对输入文件`input.c--`进行语法分析.
4. 若lex文件没有main函数和yywrap,则在MAC上编译需添加 `-ll`参数, windows下用`-lfl`参数, 意思都是将flex库包含进去

命令解释:
```bash

$ make clean  // 清除所有生成的源文件
$ make bison  // 使用bison生成语法解释源程序
$ make lex    // 使用flex生成词法解释源程序
$ make        // 编译生成目标解释程序

$ make clean  // 清除所有生成的源文件
$ make pair   // 测试词法的匹配
```

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
成功识别了标识符`x`和`squ`

---
## 二步实验: 对C--语言进行词法分析

待分析文件: `input.c--`
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
### 描述词法

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

flex文件由以下三个部分构成
```
definitions
%%
rules
%%
user code
```

由此构建出C--语言的相关词法(`testPair.l`):
```lex
/* scanner for a toy C language */
#include <stdlib.h>
void yyerror(char *);
%}

INTEGER    [0-9]+
FLOAT      ([1-9][0-9]*)|0|([0-9]+\.[0-9]*)
ID         [_|A-Za-z]+(_|[A-Za-z]|[0-9])*
HD         #include<*.*>
AT         \/\*(.*)\*\/
DM         ,|;|\(|\)|\{|\}|\[|\]|\'|\"|<|>
STR        \".*?\"|\'.*?\'
%%
[\n]                  {}
{HD}                  { printf("Header\n"); }
"main"                {
                        printf("Main:%s\n", yytext);
                      } 
"cin"                 {
                        printf("Cin:%s\n", yytext);
                      } 
"cout"                {
                        printf("Cout:%s\n", yytext);
                      } /*...*/
{ID}                  {
                        printf("ID:%s\n", yytext);
                      }
{INTEGER}             {
                        printf("int: %d\n", atoi(yytext));
                      }
{FLOAT}               {
                        printf("double: %.10g\n", atof(yytext));
                      }
[()<>=+\-/\*\;{}]     { printf("OP:%s\n", yytext); }
[ \t]+                /* eat up whitespace */
.                     printf( "Unrecognized character: %s\n", yytext );
%%

int yywrap(void) {
  return 1;
}

```
```

部分分析结果如下所示
```bash
$ make pair
flex -o src/testPair.c src/testPair.l
gcc -g -o src/testPair src/testPair.c -ll
./src/testPair < test/input.c--
Header
ID:void
Main:main
OP:(
OP:)
OP:{
ID:double
ID:a_0
...
```
### 描述文法

#### 语义信息
符号的语义信息存储于全局变量 `yylval` 中, 

```Bison
yylval = value;  /* Put value onto Bison stack. */
return INT;      /* Return the type of the token. */
```
```
%union {
  int intval;
  double val;
  symrec *tptr;
}

...
yylval.intval = value; /* Put value onto Bison stack. */
return INT;          /* Return the type of the token. */
...
```
以上代码将符号压栈，并返回类型

#### 移进规约
例：

Bison的解析栈(parser stack)中已经移进(shift)了4个字符：
1 + 5 * 3

接下来遇到了另起一行的符号，根据以下公式将解析栈中的后3个字符进行规约(reduce)
```
expr: expr '*' expr;
```
解析栈中变成3个字符1 + 15

自下而上的解析器将不断对读到的句子进行移进规约操作，直到输入序列只剩文法的开始符号

#### 向前看符号（Look-ahead tokens）

    look-ahead：读到字符但是不急着规约的行为


若定义加法表达式（expr）和符号（term）如下：
```
expr:     term '+' expr
        | term
        ;

term:     '(' expr ')'
        | term '!'
        | NUMBER
        ;
```
若解析栈中移进：`1 + 2`

情况一：
若接着遇到右括号“)”，则栈中三个符号要被规约为`expr`才能接着被规约为`term`, 但这些操作没有对应规则（缺了一个左括号不能完成规约）

情况二：
若接着遇到阶乘符号“!”，否则若栈中`1+2`先发生规约而没有**向前看**，则得到`3!=6`而不是`1+2!=3`

`向前看符号`会被存储在`yychar`变量中

另外在编写的时候还要注意：移进规约冲突，符号优先级，上下文相关优先级


## 三步实验: 对C--语言进行语法分析(v1.0)

程序: [v1.0](https://github.com/chenkangyang/bace01/releases/tag/v1.0)

拿到一份待分析的代码文件，首先做语法分析，更细的再做词法分析；而程序员首先定义词法，再定义语法。

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
```
➜  bace01 git:(master) ✗ make bison
cd src/ && bison -d analyzer.y
analyzer.y: conflicts: 7 shift/reduce
analyzer.y:52.5: warning: rule never reduced because of conflicts: stmt: /* empty */
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

---


## V1.2
程序: [v1.2](https://github.com/chenkangyang/bace01/releases/tag/v1.2)

    语义解析: 加减乘除, 输出语句, while 循环, if-else 

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

  int i = 0;
  while( i <= 10 ) {
    cout << i;
    i = i + 1;
  }
  cout << (i + 999);

  double e = d;
  while (e <= 20) {
    if(e <= 15) {
      cout << e;
    } 
    else {
      cout << 20;
    }
    e = e + 1;
  }
}
```

执行结果如下:
```bash
➜  bace01 git:(master) make clean
rm src/*.c
➜  bace01 git:(master) make bison
cd src/ && bison -d analyzer.y
➜  bace01 git:(master) make lex
flex -o src/scanner.c src/scanner.l
➜  bace01 git:(master) make
gcc -g -o src/parser src/scanner.c src/analyzer.tab.c
./src/parser < test/input.c--
0
5.5
6.14
0
1
2
3
4
5
6
7
8
9
10
1010
6.14
7.14
8.14
9.14
10.14
11.14
12.14
13.14
14.14
20
20
20
20
20
```


### 词法解析

1. 对所有的词进行识别和分类, 在`scanner.l`中定义如下规则:

lex语法中使用正则表达式识别文法, 编写正则表达式时, 可以使用[在线工具](https://c.runoob.com/front-end/854)测试匹配情况.

方便起见, 在最初的版本中所有用于计算的数据类型都统一成`double`型

首先是一些正则表达式的定义(可以看做是宏定义), 写在`definitions`段:
```lex
INTEGER    [0-9]+
FLOAT      ([1-9][0-9]*)|0|([0-9]+\.[0-9]*)
ID         [_|A-Za-z]+(_|[A-Za-z]|[0-9])*
HD         #include<*.*>
...
```
接着定义匹配到的词语所要进行的操作, 写在`rule`段:
```
[\n]                  {
                        row_cnt ++; 
                      }
{HD}                  {} /* 系统保留字单独定义 */
"main"                return FUN;
                      return INT;
"double"              return DOUBLE;
"int"                 return INT;
"void"                return VOID;
"cin"                 return CIN; 
">>"                  return TO_RIGHT;
...

{ID}                  {
                        varNode * vp = searchVarTab(yytext);
                        if (vp == 0) 
                          vp = insertVarTab(yytext);
                        yylval.tptr = vp;
                        return VAR;
                      } /* 每遇到一个标识符就存入变量表 */
{INTEGER}             {
                        yylval.val = atof(yytext); 
                        return NUM;
                      }/*...*/
{FLOAT}               {
                        yylval.val = atof(yytext); 
                        return NUM;
                      }
[()<>=+\-/\*\;\{\}]   return *yytext;
[ \t]+                /* eat up whitespace */
.                     printf( "Unrecognized character: %s\n", yytext );
```

**大写字符**表示`终结符`, 会被`Bison`生成器解析为宏定义, 这些大写字符定义在`.y`文件中, 用`%token`声明, 解析后的结果可以在`*.tab.h`文件中找到, 因此`.l`文件需要`#include <*.tab.h>`, 以将这张包含了全部宏定义的`table`包含进去, 以后遇到`大写字母`就替换成`数字`了:
```h
/* Tokens.  */
#define NUM 258
#define VAR 259
#define FUN 260
#define DEF 261
#define INT 262
...
```

遇到的以`yy*`开头的变量, 基本都是生成器自动定义的全局变量, 便于我们把值存在这些全局变量中, 在`.l`与`.y`文件之间传递

例如, 程序识别到的词会存储在`char *yytext`变量中, 可以将其赋值给`YYSTYPE yylval`变量, `YYSTYPE`默认是`int`类型, 当然我们可以自行定义为结构体类型, 以让程序理解更丰富的语义. `YYSTYPE`就是栈中的元素类型, 后续对这些元素进行移进规约操作. 

例如, 匹配到整数之后, 将`char*`转化成`float`类型, 赋值给全局变量`yylval`, 返回`NUM`替换成的数字, 告知语法识别程序`.y`, 识别到了类型为`NUM`的符号, 这个符号的值, 存储在`yylval`变量中, 若要使用可以在`.y`文件中通过`$`符号访问;

定义一个全局变量表`varNode * var_table`, 每识别一个`标识符ID`, 在表中**按名查找**变量, 若是查询到变量则返回指向这个变量的指针, 否则将这个变量头插法插入到变量表中, 并赋初值为0;

在`node.h`中定义的变量表结构如下:
```h
/* 变量表中的结点 */
typedef struct varNode
{
  char *name;    /* 变量名称 */
  double value;  /* 变量值 */
  struct varNode *next;
}varNode;

extern varNode * var_table;
extern varNode * insertVarTab ();
extern varNode * searchVarTab ();
```

### 语法解析

对所有的语句, 以及语句中的子语句规定一个统一的结构, 以便用统一的接口进行解析. 

所有的元素因为具有统一的结构, 根据移进规约规则可以构造出一棵`语法🌲`, 解析程序边读取程序中的字符, 边识别, 边进行移进规约, 构成一棵语法树, 最后规约到只剩根结点;

从根结点开始向下递归的进行`语义解析`; 

`node.h`中定义如下:
```h
typedef enum { TYPE_X, TYPE_VAR, TYPE_OP } NodeEnum;

/* 操作符 */
typedef struct opNode {
    int type; /* 操作符类型(macro) */
    int num;  /* 操作元个数        */
    struct NodeTag * node[1]; /* 操作元地址 可扩展 */
} opNode;

/* 一切元素(语句,变量,值,函数)都看成结点 */
typedef struct NodeTag
{
  NodeEnum type; /* 树结点类型 */
  union {
    double value;   /* 数值   */
    char *name;     /* 变量名 */
    opNode op;      /* 操作符 */
  };
}Node;
```
若遇到数字, 值存入`double value`;

若遇到变量, 变量名存入`name`;

若遇到操作符, 向`opNode op`中内容赋值;

```yacc
Node * setNum (double);           // 设置数字结点
Node * setVar(varNode *);         // 设置变量结点
Node * setOpr(int, int, ...);     // 设置操作符结点
double executeNode(Node * p);     // 执行结点语句
int setVarTable(char *, double);  // 赋值变量表
void freeNode(Node *);            // 释放结点
```
YYSTYPE 通过 union 声明为3种可选的类型, 分别对应数值, 变量表指针, 和 语法🌲指针
```
%union {
  double     val;      /* 符号取值 */
  varNode  *tptr;      /* 变量表指针 */
  Node     *nptr;      /* 结点表表指针 */
}
```

声明终结符`token`, 算符, 非终结符`%type<nptr>`(语法🌲结点类型)

后定义的优先规约, `%left`向左左结合规约, `%right`向右结合规约, `%nonassoc`没有结合性

声明非终结符

```yacc
/* 终结符 */
%token <val>  NUM
%token <tptr> VAR
%token FUN DEF INT DOUBLE VOID 
%token TO_RIGHT TO_LEFT
%token WHILE IF COUT CIN

/* 算符 */
%nonassoc IFX
%nonassoc ELSE /* if-else嵌套中, else比if优先规约 */
%left AND OR GE LE EQ NE '>' '<'
%right '='
%left '-' '+'
%left '*' '/'
%left NEG     /* 取负 */

/* 非终结符*/
%type <nptr> exp stmt stmt_list stmt_block
```

从"细"到"粗", 声明规约原则:
```yacc
/* Grammar rules and actions follow */
%%

function: 
            VOID FUN '(' ')' stmt_block { 
                                          executeNode($5);
                                          freeNode($5);
                                        }
;

stmt_block:
            '{' stmt_list '}' {
                                $$ = $2;
                              }
;

stmt_list:
              stmt            { $$ =$1; }
            | stmt_list stmt  {
                                $$ = setOpr(';', 2, $1, $2);
                              }
...
stmt:
             ';'                        { $$ = setOpr(';', 2, NULL, NULL);     }
            | DOUBLE VAR ';'            {
                                            $$ = setOpr(DEF, 1, setVar($2));
                                        }
            | INT VAR ';'               {
                                            $$ = setOpr(DEF, 1, setVar($2));
                                        }
...

exp:         
              NUM                 { $$ = setNum($1);                  }
            | VAR                 { $$ = setVar($1);                  }
            | exp '+' exp         { $$ = setOpr('+', 2, $1,  $3);     }
            | exp '-' exp         { $$ = setOpr('-', 2, $1,  $3);     }
...

```
从"细"到"粗"都规约至`Node *`语法树结点, 分别是`exp: 表达式`, `stmt: 语句`, `stmt_list: 语句串`, `stmt_list: 语句块`, `function: 函数`

举个例子
```
exp:         
              NUM                 { $$ = setNum($1);                  }
            | VAR                 { $$ = setVar($1);                  }
            | exp '+' exp         { $$ = setOpr('+', 2, $1,  $3);     }
```

表达式可以由一个数字, 一个变量规约得到, 也可以由"表达式+表达式"这种组合规约得到.
在下列表达式中
```exp: exp '+' exp         { $$ = setOpr('+', 2, $1,  $3);     }```
`$$`: 非终结符`exp` 被一个符号结点赋值
`$1`: 第一个符号`exp`
`$2`: 第二个符号`+`
`$3`: 第三个符号`exp`
`setOpr('+', 2, $1, $3);`: 设置一个类型是`+`的符号结点, 将2个操作数, 存入该结点, 返回结点指针`Node *`给当前结点`$$`.

边读边分析, 最后规约至`语句块结点(stmt_block)`. 调用执行函数`executeNode`, 执行该结点, 根据不同的结点类型决定应该执行的语义操作: 

`TYPE_X`: 数值结点, 直接返回结点值(`double`)
`TYPE_VAR`: 变量结点, 查询变量表`var_table`并返回结点值(`double`)
`TYPE_OP`: 操作符结点, 根据操作符具体类型(根据操作符的宏定义结果)取操作数:`op->node[?]`, 执行对应操作并返回结果(`double`)
