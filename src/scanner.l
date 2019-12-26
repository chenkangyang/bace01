/* scanner for a toy C language */
%{
/*
flex -o src/scanner.c src/scanner.l
gcc -g -o src/parser src/scanner.c -ll
./src/parser < test/input.c--
*/
#include <stdlib.h>
#include "node.h"
#include "analyser.tab.h"

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
{HD}                  {} /* 系统保留字单独定义 */
"main"                {
                        return FUN;
                      } 
"int"                 { return INT;}
"double"              { return DOUBLE;}
"void"                { return VOID;}
"cin"                 {
                        return CIN;
                      } 
">>"                  {
                        return TO_RIGHT;
                      }
"cout"                {
                        return COUT;
                      }
"<<"                  {
                        return TO_LEFT;
                      } /*...*/
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
                      }
{FLOAT}               {
                        yylval.val = atof(yytext); 
                        return NUM;
                      }
[()<>=+\-/\*\;\{\}]   { return *yytext; }
[ \t]+                /* eat up whitespace */
.                     printf( "Unrecognized character: %s\n", yytext );

%%

varNode * insertVarTab (char * var_name)
{
  varNode *vp;
  vp = (varNode *) malloc (sizeof (varNode));
  vp->name = (char *) malloc (strlen (var_name) + 1); strcpy (vp->name, var_name);
  // vp->type = VAR;
  vp->value = 0; // 所有变量的默认值都是0
  /* 头插进变量表 */
  vp->next = (struct varNode *)var_table;
  var_table = vp;
  
  var_cnt ++;

  return vp;
}

int yywrap(void) {
  return 1;
}
