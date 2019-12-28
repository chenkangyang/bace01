%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <math.h>
#include "node.h"

int yylex(void);
void yyerror(char *);
Node * setNum (double);           // 设置数字结点
Node * setVar(varNode *);         // 设置变量结点
Node * setOpr(int, int, ...);     // 设置操作符结点
double executeNode(Node * p);     // 执行节点语句
int setVarTable(char *, double);  // 赋值变量表
void freeNode(Node *);            // 释放结点

varNode * var_table = (varNode *)0;
int var_cnt = 0;

%}
%union {
double     val;      /* 符号取值 */
varNode  *tptr;      /* 变量表指针 */
Node     *nptr;      /* 节点表表指针 */
}

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

/* Grammar rules and actions follow */
%%

function: 
            VOID FUN '(' ')' stmt_block { 
                                          // printf("函数\n");
                                          // printf("执行该语句\n");
                                          executeNode($5);
                                          // printf("执行成功\n");
                                          freeNode($5);
                                          // printf("释放成功\n");
                                        }
;

stmt_block:
            '{' stmt_list '}' {
                                // printf("语句块\n");
                                $$ = $2;
                              }
;

stmt_list:
              stmt            { $$ =$1; }
            | stmt_list stmt  {
                                $$ = setOpr(';', 2, $1, $2);
                              }
;

stmt:
             ';'                        { $$ = setOpr(';', 2, NULL, NULL);     }
            | DOUBLE VAR ';'            {
                                            // printf("声明Double变量\n");
                                            $$ = setOpr(DEF, 1, setVar($2));
                                        }
            | INT VAR ';'               {
                                            // printf("声明Int变量\n");
                                            $$ = setOpr(DEF, 1, setVar($2));
                                        }
            | DOUBLE VAR '=' exp ';'    {
                                            // printf("声明Double变量, 并赋值\n");
                                            $$ = setOpr('=', 2, setVar($2), $4);
                                        }
            | INT VAR '=' exp ';'       {
                                            // printf("声明Int变量, 并赋值\n");
                                            $$ = setOpr('=', 1, setVar($2), $4);
                                        }
            | CIN TO_RIGHT exp ';'      { 
                                          printf("输入语句\n"); 
                                          $$ = setOpr(COUT, 1, $3);            
                                        }
            | COUT TO_LEFT exp ';'      { 
                                          // printf("输出语句\n"); 
                                          $$ = setOpr(COUT, 1, $3);            
                                        }
            | VAR '=' exp ';'           { 
                                          // printf("赋值语句\n"); 
                                          $$ = setOpr('=', 2, setVar($1), $3); 
                                        }
            | WHILE '(' exp ')' stmt  { 
                                              $$ = setOpr(WHILE, 2, $3, $5);  
                                            }

            | IF '(' exp ')' stmt %prec IFX { 
                                              $$ = setOpr(IF, 2, $3, $5); 
                                            }
            | IF '(' exp ')' stmt ELSE stmt %prec ELSE  { 
                                                          $$ = setOpr(IF, 3, $3, $5, $7); 
                                                        }
            | stmt_block                { $$ = $1; }
;
exp:         
              NUM                 { $$ = setNum($1);                  }
            | VAR                 { $$ = setVar($1);                  }
            | exp '+' exp         { $$ = setOpr('+', 2, $1,  $3);     }
            | exp '-' exp         { $$ = setOpr('-', 2, $1,  $3);     }
            | exp '*' exp         { $$ = setOpr('*', 2, $1,  $3);     }
            | exp '/' exp         { $$ = setOpr('/', 2, $1,  $3);     }
            | '-' exp  %prec NEG  { $$ = setOpr(NEG, 1, $2);          }
            | exp GE exp        { $$ = setOpr(GE, 2, $1, $3);          }
            | exp LE exp        { $$ = setOpr(LE, 2, $1, $3);          }
            | exp NE exp        { $$ = setOpr(NE, 2, $1, $3);          }
            | exp EQ exp        { $$ = setOpr(EQ, 2, $1, $3);          }
            | exp AND exp       { $$ = setOpr(AND, 2, $1, $3);         }
            | exp OR exp        { $$ = setOpr(OR, 2, $1, $3);          }
            | '(' exp ')'         { $$ = $2;                          }
;
%%

#define SIZE_OF_NODE ((char *)&p->value - (char *)p)

/* 申请数字结点 */
Node * setNum (double x_value) {
  Node * p;
  size_t sizeNode;
  sizeNode = SIZE_OF_NODE + sizeof(double);

  if ((p = malloc (sizeNode)) == NULL)
    yyerror("out of memory\n");
  // printf("x_value:%f\n", x_value);
  p->type = TYPE_X;
  p->value = x_value;
  return p;
}

// /* 申请变量节点 */
Node * setVar (varNode * vp) {
  Node * p;
  size_t sizeNode;
  // printf("====== 变量表个数 ====== %d\n", var_cnt);
  char * var_name = vp->name;
  sizeNode = SIZE_OF_NODE + (strlen (var_name) + 1) + sizeof(double);
  if ((p = malloc (sizeNode)) == NULL)
    yyerror("out of memory\n");
  // printf("%s申请了空间%zu\n", vp->name, sizeNode);
  p->type = TYPE_VAR;
  p->value = 0; // 节点初值为 0
  p->name = var_name;
  // strcpy (p->name, var_name);
  return p;
}

Node * setOpr (int op_type, int num, ...) {
  va_list valist;
  Node * p;
  size_t sizeNode;
  sizeNode = SIZE_OF_NODE + sizeof(opNode) + (num - 1) * sizeof(Node *);
  if ((p = malloc (sizeNode)) == NULL)
    yyerror("out of memory\n");
  
  p->type = TYPE_OP;
  p->op.type = op_type;
  p->op.num = num;
  va_start(valist, num);
  for(int i = 0; i < num; i++) 
    p->op.node[i] = va_arg(valist, Node*);
  va_end(valist);
  // printf("operator success\n");
  return p;
}

double executeNode(Node * p) {
  // printf("\n执行函数传入类型为:%d, 值为%lf\n", p->type, p->value);
  if (!p) return 0;
  switch (p->type) {
    case TYPE_X:    {
      // printf("TYPE_X:%lf\n",p->value);
      return p->value;
    }
    case TYPE_VAR:  {
      // printf("TYPE_VAR:%lf\n",p->value);
      varNode * vp = searchVarTab(p->name);
      return vp->value;
    }
    case TYPE_OP: 
      switch(p->op.type) {
        case DEF: {
          char * var_name = p->op.node[0]->name;
          return setVarTable(var_name, 0); // 新定义变量直接赋初值为 0
        }
        case ';':  {
          // printf("TYPE_OP:%d\n", p->op.type);
          executeNode(p->op.node[0]);
          return executeNode(p->op.node[1]);
        }
        case COUT: {
            // printf("执行COUT: COUT_TYPE_OP:%d\n", p->op.type);
            printf("%g\n", executeNode(p->op.node[0]));
            return 0;
        }
        case CIN: {
          double in;
          scanf("%lf", &in);
          printf("输入成功");
          char * var_name = p->op.node[0]->name;
          return setVarTable(var_name, in);
        }
        case '=': {
          // printf("\n执行赋值'='类型为:%d\n", p->op.type);
          // 变量表中按名查找, 并赋值
          char * var_name = p->op.node[0]->name;
          double var_value = executeNode(p->op.node[1]);
          return setVarTable(var_name, var_value);
        }
        case WHILE:  {
          while (executeNode(p->op.node[0]))
            executeNode(p->op.node[1]);
          return 0;
        }
        case IF:     {
          if (executeNode(p->op.node[0]))
            executeNode(p->op.node[1]);
          else if (p->op.num > 2)
            executeNode(p->op.node[2]);
          return 0;
        }
        case NEG:    return (-1) * executeNode(p->op.node[0]);
        case '+':    return executeNode(p->op.node[0]) + executeNode(p->op.node[1]);
        case '-':    return executeNode(p->op.node[0]) - executeNode(p->op.node[1]);
        case '*':    return executeNode(p->op.node[0]) * executeNode(p->op.node[1]);
        case '/':    return executeNode(p->op.node[0]) / executeNode(p->op.node[1]);
        case GE:     return executeNode(p->op.node[0]) >= executeNode(p->op.node[1]);
        case LE:     return executeNode(p->op.node[0]) <= executeNode(p->op.node[1]);
        case NE:     return executeNode(p->op.node[0]) != executeNode(p->op.node[1]);
        case EQ:     return executeNode(p->op.node[0]) == executeNode(p->op.node[1]);
        case AND:    return executeNode(p->op.node[0]) && executeNode(p->op.node[1]);
        case OR:     return executeNode(p->op.node[0]) || executeNode(p->op.node[1]);
      }
  }
  return 0;
}

void freeNode(Node *p) {
  if (!p) return;
  if (p->type == TYPE_OP) {
      for (int i = 0; i < p->op.num; i++)
        freeNode(p->op.node[i]); 
  }
  free(p);
}

int setVarTable(char *var_name, double var_value) {
  varNode *vp;
  /* 按变量名查表并赋值 */
  for (vp = var_table; vp != (varNode *) 0; vp = (varNode *)vp->next) {
    if (strcmp (vp->name, var_name) == 0) {
      // printf("变量表按名查找到:%s\n", vp->name);
      return vp->value = var_value;
    }
  }
  return 0;
}

varNode * searchVarTab (char * var_name)
{
  varNode *vp;
  for (vp = var_table; vp != (varNode *) 0; vp = (varNode *)vp->next)
    if (strcmp (vp->name, var_name) == 0) {
      // printf("变量表按名查找到:%s\n", vp->name);
      return vp;
    }
  return 0;
}

void yyerror(char *s) {

  printf("<Parser Error> Line %d :", row_cnt + 1);
  printf("%s\n", s);
}

int main(void) {
  yyparse();
  return 0;
}