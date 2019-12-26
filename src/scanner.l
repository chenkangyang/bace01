/* scanner for a toy C language */
%{
/*
flex -o src/scanner.c src/scanner.l
gcc -g -o src/parser src/scanner.c -ll
./src/parser < test/input.c--
*/
#include <stdlib.h>
#include "calc.h"
#include "analyser.tab.h"

extern symrec * getsym (char *);
extern symrec * putsym (char *, int);
symrec * char2symrec(char *, int , int);

struct VarDefine G_Def[MAX_DEFS];             /* 存储的变量数组 */
char G_sBuff[MAX_BUFF_ROWS][MAX_BUFF_COLS];   /* 存储分析语句   */
int G_iBuffRowCount = 0;     /* 当前语句行数 */
int G_iBuffColCount = 0;     /* 当前语句列数 */
extern void add_var(char *);  /* 在内存中添加变量 */
void add_buff(char *); /* 在内存中添加语句 */

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
[\n]                  {
                        G_iBuffColCount = 0;
                        G_iBuffRowCount++;
                      }
{HD}                  { printf("Header\n"); } /* 系统保留字单独定义 */
"main"                {
                        return FUN;
                      } 
"int"                 { return INT;}
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
                        symrec *s = char2symrec(yytext, yyleng, VAR);
                        yylval.tptr = s;
                        return s->type;
                      }
{INTEGER}             {
                        yylval.val = atof(yytext); 
                        return NUM;
                      }
{FLOAT}               {
                        yylval.val = atof(yytext); 
                        return NUM;
                      }
[()<>=+\-/\*\;\{\}]   { add_buff(yytext); return *yytext; }
[ \t]+                /* eat up whitespace */
.                     printf( "Unrecognized character: %s\n", yytext );

%%
void add_buff(char * buff) {
    strcat(G_sBuff[G_iBuffRowCount], buff);
    G_iBuffColCount = G_iBuffColCount + strlen(buff);
}


symrec *
char2symrec(text, leng, sym_type) 
char* text;
int leng;
int sym_type;
{
  symrec *s;
  s = getsym (text);
  if (s == 0)
    s = putsym (text, sym_type);
  return s;
}

int yywrap(void) {
  return 1;
}
