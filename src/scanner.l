/* scanner for a toy C language */
%{
/*
flex -o src/scanner.c src/scanner.l
gcc -g -o src/parser src/scanner.c -ll
./src/parser < test/input.c--
*/
#include <stdlib.h>
#include "userdef.h"
#include "analyser.tab.h"

void yyerror(char *);
void add_buff(char *);
void add_var(char *);

extern char sBuff[10][20]; //引用其他地方定义的sBuff，存放源代码
extern int iBuffX; //源代码第几行
extern int iBuffY; //源代码第几列

extern varIndex strMem[256]; //存放标识符
extern int iMaxIndex; //标识符的个数
extern int iCurIndex; //当前指向第几个标识符
%}

INTEGER    [0-9]+
KEY        "break"|"case"|"const"|"continue"|"default"|"do"|"int"|"else"|"if"|"return"|"sizeof"|"void"|"struct"|"typedef"|"while"
ID         [_|A-Za-z]+(_|[A-Za-z]|[0-9])*
HD         #include<*.*>
AT         \/\*(.*)\*\/
DM         ,|;|\(|\)|\{|\}|\[|\]|\'|\"|<|>
STR        \".*?\"|\'.*?\'
OP         [-+*/=()]
%%

{HD}        {printf( "A header: %s\n", yytext );}
{ID}        {add_var(yytext); yylval = iCurIndex; return VAR;}
{INTEGER}   {yylval = atoi(yytext); add_buff(yytext); return INT;}
{OP}        {yylval = *yytext; add_buff(yytext); return *yytext;}
{AT}        {}
[\n]        {yylval = *yytext; iBuffY=0; iBuffX++; return *yytext; }
"{"[^}\n]*"}"     /* eat up one-line comments */
[ \t\n]+          /* eat up whitespace */
.           printf( "Unrecognized character: %s\n", yytext );

%%
void add_buff(char * buff) {
    strcat(sBuff[iBuffX], buff);
    iBuffY += strlen(buff);
}


void add_var(char * mark) {
    if(iMaxIndex==0){
        strcpy(strMem[0].sMark,mark);
        iMaxIndex++;
        iCurIndex=0;
        return;
    }
    int i;
    for(i=0;i<=iMaxIndex-1;i++) {
        if(strcmp(strMem[i].sMark,mark)==0) {
            iCurIndex=i;
            return;
        }
    }
    strcpy(strMem[iMaxIndex].sMark,mark);
    iCurIndex=iMaxIndex;
    iMaxIndex++;
}

int yywrap(void) {
  return 1;
}
