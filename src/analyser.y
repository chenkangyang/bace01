%{
#include <stdlib.h>
#include <stdio.h>
int yylex(void);
void yyerror(char *);
%}
%token INTEGER
%left '+' '-'
%left '*' '/'
%%
program:
program expr '\n' { printf("%d\n", $2); }
|
; /* 先理解expr，再递归理解program。首先program可以为空，也可以用单单的expr加下“/n”回车符组成，结合起来看program定义的就是多个表达式组成的文件内容 */
expr:
INTEGER { $$ = $1; }
| expr '*' expr { $$ = $1 * $3; }
| expr '/' expr { $$ = $1 / $3; }
| expr '+' expr { $$ = $1 + $3; }
| expr '-' expr { $$ = $1 - $3; }
; /* 可以由单个INTEGER值组成，也可以有多个INTERGER和运算符组合组成。以表达式“1+4/2*3-0”为例，1 4 2 3 都是expr，就是expr+expr/expr*expr-expr说到底最后还是个expr。递归思想正好与之相反，逆推下去会发现expr这个规则标记能表示所有的数值运算表达式 */
%%
void yyerror(char *s) {
  printf("%s\n", s);
}
int main(void) {
  yyparse();
  return 0;
}