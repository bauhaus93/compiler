
%{

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "globals.h"
#include "symbol.h"
#include "tree.h"
#include "condition.h"
#include "error.h"
#include "reg.h"
#include "opdefs.h"
#include "asmprint.h"

extern int yylex();
extern int yyparse();
extern void invoke_burm(NODEPTR_TYPE root);

int yyerror(const char* e);

%}

%token END
%token RETURN
%token GOTO
%token IF
%token VAR
%token AND
%token NOT
%token EQUAL
%token NOTEQUAL
%token GREATERTHAN
%token MINUS
%token PLUS
%token MULT
%token IDENTIFIER
%token NUMBER

%start Program

@attributes { char* name; } IDENTIFIER
@attributes { int value; } NUMBER

@attributes { tree_node_t* node; } MinusList
@attributes { symbol_t* symbols; } FuncDef
@attributes { symbol_t* symbolsI; symbol_t* symbolsS; tree_node_t* node; } Expr Term PlusList MultList LExpr
@attributes { symbol_t* symbolsI; symbol_t* symbolsS; condition_t* cond; } CTermList Cond
@attributes { symbol_t* symbolsI; symbol_t* symbolsS; tree_node_t* node; condition_t* cond; } CTerm
@attributes { symbol_t* symbolsI; symbol_t* symbolsS; } Pars LabelList Stmts Stmt LabelDef ExprList

@traversal @preorder codegen
@traversal @postorder codegenpost

//%define parse.error verbose

%%

Program     : FuncList
            ;

FuncList    :
            | FuncList FuncDef ';'
            ;

FuncDef     : IDENTIFIER '(' Pars ')' Stmts END
              @{
                @i @FuncDef.symbols@ = error_if_non_existing_in_list(@Stmts.symbolsS@);
                @i @Stmts.symbolsI@ = @Pars.symbolsS@;
                @i @Pars.symbolsI@ = create_symbol_root();
                @codegen print_function_header(@IDENTIFIER.name@, @Pars.symbolsS@, @FuncDef.symbols@); currFunction = @IDENTIFIER.name@;
              @}
            ;

Pars        : @{
                @i @Pars.symbolsS@ = @Pars.symbolsI@;
              @}
            | IDENTIFIER ',' Pars
              @{
                @i @Pars.1.symbolsI@ = create_symbol(VARIABLE, @IDENTIFIER.name@, @Pars.0.symbolsI@);
                @i @Pars.0.symbolsS@ = @Pars.1.symbolsS@;
              @}
            | IDENTIFIER
            @{
              @i @Pars.symbolsS@ = create_symbol(VARIABLE, @IDENTIFIER.name@, @Pars.symbolsI@);
            @}
            ;

Stmts       : @{
                @i @Stmts.symbolsS@ = @Stmts.symbolsI@;
              @}
            | LabelList Stmt ';' Stmts
              @{
                @i @Stmts.1.symbolsI@ = @LabelList.symbolsS@;
                @i @Stmts.0.symbolsS@ = @Stmts.1.symbolsS@;
                @i @Stmt.symbolsI@ = @Stmts.0.symbolsI@;
                @i @LabelList.symbolsI@ = @Stmt.symbolsS@;
              @}
            ;

LabelList   : @{
                @i @LabelList.symbolsS@ = @LabelList.symbolsI@;
              @}
            | LabelList LabelDef
            @{
              @i @LabelList.1.symbolsI@ = @LabelDef.symbolsS@;
              @i @LabelList.0.symbolsS@ = @LabelList.1.symbolsS@;
              @i @LabelDef.symbolsI@ = @LabelList.0.symbolsI@;
            @}
            ;

LabelDef    : IDENTIFIER ':'
            @{
              @i @LabelDef.symbolsS@ = create_symbol(LABEL, @IDENTIFIER.name@, @LabelDef.symbolsI@);
              @codegen clear_all_regs(@LabelDef.symbolsI@); printf("L_%s_%s:\n", currFunction, @IDENTIFIER.name@);
            @}
            ;

Stmt        : RETURN Expr
            @{
                @i @Stmt.symbolsS@ = @Expr.symbolsS@;
                @i @Expr.symbolsI@ = @Stmt.symbolsI@;
                @codegen print_condition_data(@Stmt.symbolsI@); invoke_burm(create_node(OP_RET, NULL, @Expr.node@, NULL, @Stmt.symbolsI@));
            @}
            | GOTO IDENTIFIER
            @{
                @i @Stmt.symbolsS@ = check_if_label_non_existing(@IDENTIFIER.name@, @Stmt.symbolsI@);
                @codegen clear_all_regs(@Stmt.symbolsI@); print_condition_data(@Stmt.symbolsI@); printf("jmp L_%s_%s\n", currFunction, @IDENTIFIER.name@);
            @}
            | IF Cond GOTO IDENTIFIER
            @{
                @i @Stmt.symbolsS@ = check_if_label_non_existing(@IDENTIFIER.name@, @Cond.symbolsS@);
                @i @Cond.symbolsI@ = @Stmt.symbolsI@;
                @i @Cond.cond@ = create_condition_data(@IDENTIFIER.name@, 0);
                @codegen print_condition_data(@Stmt.symbolsI@); prevCondition = @Cond.cond@;

            @}
            | VAR IDENTIFIER EQUAL Expr
            @{
                @i @Stmt.symbolsS@ = create_symbol(VARIABLE, @IDENTIFIER.name@, @Stmt.symbolsI@);
                @i @Expr.symbolsI@ = @Stmt.symbolsI@;
                @codegen print_condition_data(@Stmt.symbolsI@); invoke_burm(create_node(OP_DEFINITION, @IDENTIFIER.name@, @Expr.node@, NULL, @Stmt.symbolsS@));
            @}
            | LExpr EQUAL Expr
            @{
                @i @Stmt.symbolsS@ = @LExpr.symbolsS@;
                @i @LExpr.symbolsI@ = @Stmt.symbolsI@;
                @i @Expr.symbolsI@ = @Stmt.symbolsI@;
                @codegen print_condition_data(@Stmt.symbolsI@); invoke_burm(create_node(OP_ASSIGNMENT, NULL, @LExpr.node@, @Expr.node@, @Stmt.symbolsI@));
            @}
            | Term
            @{
                @i @Stmt.symbolsS@ = @Term.symbolsS@;
                @i @Term.symbolsI@ = @Stmt.symbolsI@;
            @}
            ;

Cond        : CTermList
            @{
                @i @Cond.symbolsS@ = @CTermList.symbolsS@;
                @i @CTermList.symbolsI@ = @Cond.symbolsI@;
                @i @CTermList.cond@ = @Cond.cond@;
            @}
            | NOT CTerm
            @{
                @i @Cond.symbolsS@ = @CTerm.symbolsS@;
                @i @CTerm.symbolsI@ = @Cond.symbolsI@;
                @i @CTerm.cond@ = duplicate_condition_inverted(@Cond.cond@);
                @codegen invoke_burm(@CTerm.node@);
            @}
            ;

CTermList   : CTerm AND CTermList
            @{
                @i @CTermList.0.symbolsS@ = @CTermList.1.symbolsS@;
                @i @CTerm.symbolsI@ = @CTermList.0.symbolsI@;
                @i @CTermList.1.symbolsI@ = @CTerm.symbolsS@;
                @i @CTermList.1.cond@ = @CTermList.0.cond@;
                @i @CTerm.cond@ = @CTermList.0.cond@;
                @codegen invoke_burm(@CTerm.node@);
            @}
            | CTerm
            @{
                @i @CTermList.symbolsS@ = @CTerm.symbolsS@;
                @i @CTerm.symbolsI@ = @CTermList.symbolsI@;
                @i @CTerm.cond@ = @CTermList.cond@;
                @codegen invoke_burm(@CTerm.node@);
            @}
            ;

CTerm       : '(' Cond ')'
            @{
                @i @CTerm.symbolsS@ = @Cond.symbolsS@;
                @i @Cond.symbolsI@ = @CTerm.symbolsI@;
                @i @CTerm.node@ = NULL;
                @i @Cond.cond@ = @CTerm.cond@;
            @}
            | Expr NOTEQUAL Expr
            @{
                @i @CTerm.symbolsS@ = @Expr.1.symbolsS@;
                @i @Expr.0.symbolsI@ = @CTerm.symbolsI@;
                @i @Expr.1.symbolsI@ = @Expr.0.symbolsS@;
                @i @CTerm.node@ = create_conditional_node(OP_NEQ, @Expr.0.node@, @Expr.1.node@, @Expr.0.symbolsI@, @CTerm.cond@);
            @}
            | Expr GREATERTHAN Expr
            @{
                @i @CTerm.symbolsS@ = @Expr.1.symbolsS@;
                @i @Expr.0.symbolsI@ = @CTerm.symbolsI@;
                @i @Expr.1.symbolsI@ = @Expr.0.symbolsS@;
                @i @CTerm.node@ = create_conditional_node(OP_GT, @Expr.0.node@, @Expr.1.node@, @Expr.0.symbolsI@, @CTerm.cond@);
            @}
            ;

LExpr       : IDENTIFIER
            @{
              @i @LExpr.symbolsS@ = check_if_variable_non_existing(@IDENTIFIER.name@, @LExpr.symbolsI@);
              @i @LExpr.node@ = create_id_node(@IDENTIFIER.name@, @LExpr.symbolsI@);
            @}
            | Term '[' Expr ']'
            @{
              @i @LExpr.symbolsS@ = @Expr.symbolsS@;
              @i @Expr.symbolsI@ = @LExpr.symbolsI@;
              @i @Term.symbolsI@ = @LExpr.symbolsI@;
              @i @LExpr.node@ = create_node(OP_ARRAY_ACCESS, NULL, @Term.node@, @Expr.node@, @LExpr.symbolsI@);
            @}
            ;

Expr        : Term
            @{
              @i @Expr.symbolsS@ = @Term.symbolsS@;
              @i @Term.symbolsI@ = @Expr.symbolsI@;
              @i @Expr.node@ = @Term.node@;
            @}
            | Term PlusList
            @{
              @i @Expr.symbolsS@ = @Term.symbolsS@;
              @i @Term.symbolsI@ = @Expr.symbolsI@;
              @i @PlusList.symbolsI@ = @Term.symbolsS@;
              @i @Expr.node@ = create_node(OP_ADD, NULL, @Term.node@, @PlusList.node@, @Expr.symbolsI@);
            @}
            | Term MultList
            @{
              @i @Expr.symbolsS@ = @Term.symbolsS@;
              @i @Term.symbolsI@ = @Expr.symbolsI@;
              @i @MultList.symbolsI@ = @Term.symbolsS@;
              @i @Expr.node@ = create_node(OP_MULT, NULL, @Term.node@, @MultList.node@, @Expr.symbolsI@);
            @}
            | MinusList Term
            @{
              @i @Expr.symbolsS@ = @Term.symbolsS@;
              @i @Term.symbolsI@ = @Expr.symbolsI@;
              @i @Expr.node@ = create_node(OP_MINUS, NULL, @MinusList.node@, @Term.node@, @Expr.symbolsI@);
            @}
            ;
PlusList    : PlusList PLUS Term
            @{
              @i @PlusList.0.symbolsS@ = @PlusList.1.symbolsS@;
              @i @Term.symbolsI@ = @PlusList.0.symbolsI@;
              @i @PlusList.1.symbolsI@ = @Term.symbolsS@;
              @i @PlusList.0.node@ = create_node(OP_ADD, NULL, @Term.node@, @PlusList.1.node@, @PlusList.0.symbolsI@);
            @}
            | PLUS Term
            @{
              @i @PlusList.symbolsS@ = @Term.symbolsS@;
              @i @Term.symbolsI@ = @PlusList.symbolsI@;
              @i @PlusList.node@ = @Term.node@;
            @}
            ;

MultList    : MultList MULT Term
            @{
              @i @MultList.0.symbolsS@ = @MultList.1.symbolsS@;
              @i @Term.symbolsI@ = @MultList.0.symbolsI@;
              @i @MultList.1.symbolsI@ = @Term.symbolsS@;
              @i @MultList.0.node@ = create_node(OP_MULT, NULL, @Term.node@, @MultList.1.node@, @MultList.0.symbolsI@);
            @}
            | MULT Term
            @{
              @i @MultList.symbolsS@ = @Term.symbolsS@;
              @i @Term.symbolsI@ = @MultList.symbolsI@;
              @i @MultList.node@ = @Term.node@;
            @}
            ;

MinusList   : MinusList MINUS
              @{
                @i @MinusList.0.node@ = create_node(OP_MINUS, NULL, @MinusList.1.node@, create_number_node(-1), NULL);
              @}
            | MINUS
            @{
              @i @MinusList.node@ = create_number_node(-1);
            @}
            ;

Term        : '(' Expr ')'
            @{
              @i @Term.symbolsS@ = @Expr.symbolsS@;
              @i @Expr.symbolsI@ = @Term.symbolsI@;
              @i @Term.node@ = @Expr.node@;
            @}
            | NUMBER
            @{
              @i @Term.symbolsS@ = @Term.symbolsI@;
              @i @Term.node@ = create_number_node(@NUMBER.value@);
            @}
            | Term '[' Expr ']'
            @{
              @i @Term.0.symbolsS@ = @Expr.symbolsS@;
              @i @Term.1.symbolsI@ = @Term.0.symbolsI@;
              @i @Expr.symbolsI@ = @Term.1.symbolsS@;
              @i @Term.0.node@ = create_node(OP_ARRAY_ACCESS, NULL, @Term.1.node@, @Expr.node@, @Term.0.symbolsI@);
            @}
            | IDENTIFIER
            @{
              @i @Term.symbolsS@ = check_if_variable_non_existing(@IDENTIFIER.name@, @Term.symbolsI@);
              @i @Term.node@ = create_id_node(@IDENTIFIER.name@, @Term.symbolsI@);
            @}
            | IDENTIFIER '('  ExprList ')'
            @{
              @i @Term.symbolsS@ = check_if_variable_non_existing(@IDENTIFIER.name@, @Term.symbolsI@);
              @i @ExprList.symbolsI@ = @Term.symbolsI@;
              @i @Term.node@ = create_number_node(1337);
            @}
            ;

ExprList    : @{
                @i @ExprList.symbolsS@ = @ExprList.symbolsI@;
            @}
            | Expr
            @{
              @i @ExprList.symbolsS@ = @Expr.symbolsS@;
              @i @Expr.symbolsI@ = @ExprList.symbolsI@;
            @}
            | Expr ',' ExprList
            @{
              @i @ExprList.symbolsS@ = @ExprList.1.symbolsS@;
              @i @Expr.symbolsI@ = @ExprList.0.symbolsI@;
              @i @ExprList.1.symbolsI@ = @Expr.symbolsS@;
            @}
            ;

%%

int main(int argc, char **argv) {
  yyparse();
  return 0;
}
