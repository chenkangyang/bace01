%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "calc.h"

void init_table(); /* 初始化函数表 */

int yylex(void);
void yyerror(char *);

%}
%union {
double     val;  /* For returning numbers.                   */
symrec  *tptr;   /* For returning symbol-table pointers      */
}

%token <val>  NUM        /* Simple double precision number   */
%token <tptr> VAR FNCT   /* Variable and Function            */

/* Reserved KeyWords*/
%token FUN INT
%token COUT CIN TO_RIGHT TO_LEFT
%token FOR WHILE
%token IF
%token ELSE


%right '='
%left '-' '+'
%left '*' '/'
%left NEG     /* Negation--unary minus */
%right '^'    /* Exponentiation        */
%type <val> exp

/* Grammar rules and actions follow */
%%

function: 
           VAR FUN '(' ')' stmt_block { printf("函数\n"); }

stmt_block:
            '{' stmt_list '}' {printf("语句块\n");}
;

stmt_list:
            /* empty string */
            | stmt_list stmt {printf("语句串\n");}
;

stmt:
            | ';'
            | COUT TO_LEFT exp ';'  { printf ("输出语句\n"); }
            | CIN TO_RIGHT exp ';'  { printf ("输入语句\n"); }
            | INT VAR ';' { printf("定义INT变量\n"); }
            | VAR '=' exp ';' { printf("赋值语句\n"); }
            | error ';' { yyerrok; }

exp:         
              NUM                 { $$ = $1;                          }
            | VAR                 { $$ = $1->value.var;               }
            | FNCT '(' exp ')'    { $$ = (*($1->value.fnctptr))($3);  }
            | exp '+' exp         { $$ = $1 + $3;                     }
            | exp '-' exp         { $$ = $1 - $3;                     }
            | exp '*' exp         { $$ = $1 * $3;                     }
            | exp '/' exp         { $$ = $1 / $3;                     }
            | '-' exp  %prec NEG  { $$ = -$2;                         }
            | exp '^' exp         { $$ = pow ($1, $3);                }
            | '(' exp ')'         { $$ = $2;                          }
;
%%

void yyerror(char *s) {
  printf("%s\n", s);
}

int main(void) {
  init_table ();
  yyparse();
  return 0;
}

struct init
{
  char *fname;
  double (*fnct)();
};

struct init arith_fncts[]
  = {
      "sin", sin,
      "cos", cos,
      "atan", atan,
      "ln", log,
      "exp", exp,
      "sqrt", sqrt,
      0, 0
    };

/* The symbol table: a chain of `struct symrec'.  */
symrec *sym_table = (symrec *)0;
void init_table ()  /* puts arithmetic functions in table. */
{
  int i;
  symrec *ptr;
  for (i = 0; arith_fncts[i].fname != 0; i++)
    {
      ptr = putsym (arith_fncts[i].fname, FNCT); // The object is linked to the front of the list, and a pointer to the object is returned. 
      ptr->value.fnctptr = arith_fncts[i].fnct;
    }
}

symrec *
putsym (sym_name,sym_type)
     char *sym_name;
     int sym_type;
{
  symrec *ptr;
  ptr = (symrec *) malloc (sizeof (symrec));
  ptr->name = (char *) malloc (strlen (sym_name) + 1);
  strcpy (ptr->name,sym_name);
  ptr->type = sym_type;
  ptr->value.var = 0; /* set value to 0 even if fctn.  */
  ptr->next = (struct symrec *)sym_table;
  sym_table = ptr;
  return ptr;
}

symrec *
getsym (sym_name)
     char *sym_name;
{
  symrec *ptr;
  for (ptr = sym_table; ptr != (symrec *) 0;
       ptr = (symrec *)ptr->next)
    if (strcmp (ptr->name,sym_name) == 0)
      return ptr;
  return 0;
}

// symrec *
// opr (char)