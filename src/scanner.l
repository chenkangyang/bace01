/* scanner for a toy C language */
%{
/*
flex -o src/scanner.c src/scanner.l
gcc -g -o src/parser src/scanner.c -ll
./src/parser < test/input.c--
*/
#include <math.h>
%}

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
