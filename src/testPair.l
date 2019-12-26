/* scanner for a toy C language */
%{
/*
flex -o src/scanner.c src/scanner.l
gcc -g -o src/parser src/scanner.c -ll
./src/parser < test/input.c--
*/
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
[()<>=+\-/\*\;{}]      { printf("OP:%s\n", yytext); }
[ \t]+                /* eat up whitespace */
.                     printf( "Unrecognized character: %s\n", yytext );

%%

int yywrap(void) {
  return 1;
}
