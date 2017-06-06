
%{

  #include <stdlib.h>
  #include <stdio.h>
  #include <string.h>

  #include "codeb.h"

  extern int yylex();
  extern int yyparse();
  extern void invoke_burm(NODEPTR_TYPE root);

  int yyerror(const char* e);

  symbol_t* create_symbol_root(void);
  symbol_t* create_symbol(symbol_type_t type, const char* id, symbol_t* inherited);
  symbol_t* symbol_exists(const char* id, symbol_t* inherited);
  symbol_t* symbol_with_type_exists(symbol_type_t type, const char* id, symbol_t* inherited);

  tree_node_t* create_node(int op, const char* id, tree_node_t* left, tree_node_t* right, symbol_t* symbols);
  tree_node_t* create_conditional_node(int op, tree_node_t* left, tree_node_t* right, symbol_t* symbols, condition_t* condition);
  tree_node_t* create_number_node(int value);
  tree_node_t* create_id_node(const char* name, symbol_t* symbols);

  int get_len(symbol_t* symbols);
  int count_variables(symbol_t* symbols);

  void write_function_header(const char* fnName, symbol_t* params, symbol_t* symbols);
  condition_t* create_condition_data(const char* jumpTarget, int inversed);
  condition_t* duplicate_condition_inverted(condition_t* data);

  int acquire_next_fail_label(void);

  const char* regs[]= {"%rdi", "%rsi", "%rdx", "%rcx", "%r8", "%r9", "%r10", "%r11"};
  int currReg = 0;
  int failLabelCounter = 0;
  condition_t* prevCondition = NULL;
  const char* currFunction = NULL;

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
                @codegen write_function_header(@IDENTIFIER.name@, @Pars.symbolsS@, @FuncDef.symbols@); currFunction = @IDENTIFIER.name@;
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

int yyerror(const char* e) {
  printf("[ParseError] %s\n", e);
  exit(2);
}

void error_symbol_redefined(const char* symbolId) {
  printf("[SemanticError] Redefined already existing symbol \"%s\"\n", symbolId);
  exit(3);
}

void error_symbol_non_existing(const char* symbolId) {
  printf("[SemanticError] Wanted to access non-existing symbol: \"%s\"\n", symbolId);
  exit(3);
}

void print_condition_data(symbol_t* symbols) {
  if (prevCondition != NULL) {
    clear_all_regs(symbols);
    printf("jmp L_%s_%s\nL_%s_%s:\n", currFunction, prevCondition->jumpTarget, currFunction, prevCondition->failTarget);
    free(prevCondition);
    prevCondition = NULL;
  }
}

int acquire_next_fail_label(void) {
  return failLabelCounter++;
}

tree_node_t* create_node(int op, const char* id, tree_node_t* left, tree_node_t* right, symbol_t* symbols) {
  p_tree_node_t node = malloc(sizeof(tree_node_t));
  memset(node, 0, sizeof(tree_node_t));

  node->op = op;
  node->id = id;
  node->left = left;
  node->right = right;
  node->symbols = symbols;

  //printf("creating node, op = %d\n", op);

  return node;
}

tree_node_t* create_conditional_node(int op, tree_node_t* left, tree_node_t* right, symbol_t* symbols, condition_t* condition) {
  p_tree_node_t node = malloc(sizeof(tree_node_t));
  memset(node, 0, sizeof(tree_node_t));

  node->op = op;
  node->left = left;
  node->right = right;
  node->symbols = symbols;
  node->condition = condition;

  //printf("creating node, op = %d\n", op);

  return node;
}

void write_function_header(const char* fnName, symbol_t* params, symbol_t* symbols) {
  int varCount = count_variables(symbols);
  int argCount = count_variables(params);
  int currOffset = -8, reg = 0;
  static const char* argRegs[] = {"%rdi", "%rsi", "%rdx", "%rcx", "%r8", "%r9"};

  printf(".globl %s\n.type %s, %cfunction\n%s:\n", fnName, fnName, 64, fnName);
  printf("push %rbp\nmov %rsp, %rbp\nsub $%d, %rsp\n", varCount * 8);

  //assign arguments frame offsets
  int i = 0;
  for(symbol_t* ptr = params; ptr != NULL; ptr = ptr->next) {
    reg = argCount - i - 1;
    currOffset = -8 * (argCount - i);
    ptr->frameOffset = currOffset;
    ptr->regId = reg;
    printf("movq %s, %d(%rbp)\t#arg %d: %s\n", argRegs[reg], currOffset, argCount - i, ptr->id);

    i++;
  }
  currOffset = -8 * (argCount + 1);

  currReg = argCount;

  //assign arguments frame offsets
  for(symbol_t* ptr = symbols; ptr != NULL && ptr->frameOffset == 0; ptr = ptr->next) {
    if (ptr->type == VARIABLE) {
      ptr->frameOffset = currOffset;
      ptr->regId = -1;
      currOffset -= 8;
    }
  }

  /*for(symbol_t* ptr = symbols; ptr != NULL; ptr = ptr->next) {
    if (ptr->type == VARIABLE) {
      printf("var: %s -> offset: %d\n", ptr->id, ptr->frameOffset);
    }
  }*/
  printf("\n");
}


condition_t* create_condition_data(const char* jumpTarget, int inversed) {
  condition_t* cond = malloc(sizeof(condition_t));
  char *failTarget = malloc(20);

  cond->jumpTarget = jumpTarget;
  cond->inversed = inversed;
  snprintf(failTarget, 20, "TARGET_%d", acquire_next_fail_label());
  cond->failTarget = failTarget;
  return cond;
}

condition_t* duplicate_condition_inverted(condition_t* data) {
  condition_t* cond = malloc(sizeof(condition_t));
  cond->jumpTarget = data->jumpTarget;
  cond->failTarget = data->failTarget;
  cond->inversed = !data->inversed;
  return cond;
}

tree_node_t* create_number_node(int value) {
  p_tree_node_t node = malloc(sizeof(tree_node_t));
  memset(node, 0, sizeof(tree_node_t));

  node->op = OP_NUM;
  node->value = value;

  //printf("creating number node, num = %d\n", value);
  return node;
}

tree_node_t* create_id_node(const char* id, symbol_t* symbols) {
  p_tree_node_t node = malloc(sizeof(tree_node_t));
  memset(node, 0, sizeof(tree_node_t));

  node->op = OP_ID;
  node->id = id;
  node->symbols = symbols;

  //printf("creating id node: %s\n", node->id);
  return node;
}

int assign_reg_to_symbol(const char* id, symbol_t* symbols) {
  for(symbol_t* ptr = symbols; ptr != NULL; ptr = ptr->next) {
    if(ptr->type == VARIABLE && strcmp(id, ptr->id) == 0) {
      if (ptr->regId == -1) {
        ptr->regId = acquire_reg(symbols);
        return ptr->regId;
      }
      else {
        printf("assign_reg_to_symbol: Symbol is already assigned to a register!\n");
        exit(4);
      }
    }
  }
  printf("assign_reg_to_symbol: Symbol not found!\n");
  exit(4);
}

int get_symbol_reg(const char* id, symbol_t* symbols) {
  for(symbol_t* ptr = symbols; ptr != NULL; ptr = ptr->next) {
    if(ptr->type == VARIABLE && strcmp(id, ptr->id) == 0) {
      return ptr->regId;
    }
  }
  printf("get_symbol_reg: Symbol not found!\n");
  exit(4);
}

symbol_t* get_symbol_by_name(const char* id, symbol_t* symbols) {
  for(symbol_t* ptr = symbols; ptr != NULL; ptr = ptr->next) {
    if(strcmp(id, ptr->id) == 0) {
      return ptr;
    }
  }
}

int acquire_reg(symbol_t* symbols) {
  int ret = currReg;

  clear_reg(currReg, symbols);

  currReg++;
  if (currReg >= 8)
    currReg = 0;
  return ret;
}

int clear_reg(int regId, symbol_t* symbols) {
  int n = 0;
  for(symbol_t* ptr = symbols; ptr != NULL; ptr = ptr->next) {
    if(ptr->type == VARIABLE) {
      n++;
      if (ptr->regId == regId) {
        printf("movq %s, %d(%rbp)\t#write %s back on stack, bc reg is needed\n", regs[regId], ptr->frameOffset, ptr->id);
        ptr->regId = -1;
        break;
      }
    }
  }
}

int clear_all_regs(symbol_t* symbols) {
  for(symbol_t* ptr = symbols; ptr != NULL; ptr = ptr->next) {
    if(ptr->type == VARIABLE && ptr->regId != -1) {
      printf("movq %s, %d(%rbp)\t#write %s back on stack, bc jmp\n", regs[ptr->regId], ptr->frameOffset, ptr->id);
      ptr->regId = -1;
    }
  }
}

int get_len(symbol_t* symbols) {
  int i = 0;
  for(symbol_t* ptr = symbols; ptr != NULL && ptr->id != NULL; ptr = ptr->next) {
    i++;
  }
  return i;
}

int count_variables(symbol_t* symbols) {
  int i = 0;
  for(symbol_t* ptr = symbols; ptr != NULL && ptr->id != NULL; ptr = ptr->next) {
    if (ptr->id != NULL && ptr->type == VARIABLE)
      i++;
  }
  return i;
}

symbol_t* error_if_non_existing_in_list(symbol_t* symbols) {
  symbol_t* prev = NULL;
  for (symbol_t* ptr = symbols; ptr != NULL; ptr = ptr->next) {
    if (ptr->id == NULL){
      if (ptr->next != NULL) {
        printf("wanted to eliminate dummy symbol, but is not last item in list!\n");
        exit(4);
      }
      free(ptr);
      prev->next = NULL;
      continue;
    }
    //printf("sym: %s -> %d\n", ptr->id, ptr->existing);
    if (ptr->existing == 0)
      error_symbol_non_existing(ptr->id);
    prev = ptr;
  }
  return symbols;
}

symbol_t* check_if_variable_non_existing(const char* id, symbol_t* inherited) {
  if (!symbol_with_type_exists(VARIABLE, id, inherited))
    error_symbol_non_existing(id);
  return inherited;
}

symbol_t* check_if_label_non_existing(const char* id, symbol_t* inherited) {


  size_t len = strlen(id);
  for (symbol_t* ptr = inherited; ptr != NULL; ptr = ptr->next) {
    if (ptr->id == NULL)
      continue;
    if (strlen(ptr->id) == len && ptr->type == LABEL && strncmp(ptr->id, id, len) == 0) {
      return inherited;
    }
  }

  symbol_t* s = malloc(sizeof(symbol_t));
  memset(s, 0, sizeof(symbol_t));

  if (symbol_exists(id, inherited))
    error_symbol_redefined(id);

  s->type = LABEL;
  s->id = strdup(id);
  s->next = inherited;
  s->existing = 0;

  return s;
}

symbol_t* create_symbol_root(void) {
  symbol_t *s = malloc(sizeof(symbol_t));
  memset(s, 0, sizeof(symbol_t));
  return s;
}

symbol_t* symbol_exists(const char* id, symbol_t* inherited) {
  size_t len = strlen(id);
  for (symbol_t* ptr = inherited; ptr != NULL; ptr = ptr->next) {
    if ( ptr->id == NULL)
      continue;
    if (strlen(ptr->id) == len && strncmp(ptr->id, id, len) == 0) {
      return ptr;
    }
  }
  return NULL;
}

symbol_t* symbol_with_type_exists(symbol_type_t type, const char* id, symbol_t* inherited) {
  size_t len = strlen(id);
  for (symbol_t* ptr = inherited; ptr != NULL; ptr = ptr->next) {
    if (ptr->id == NULL)
      continue;
    if (strlen(ptr->id) == len && ptr->type == type && strncmp(ptr->id, id, len) == 0) {
      return ptr;
    }
  }
  return NULL;
}

symbol_t* create_symbol(symbol_type_t type, const char* id, symbol_t* inherited) {
  symbol_t* s = malloc(sizeof(symbol_t));
  memset(s, 0, sizeof(symbol_t));

  /*printf("creating symbol %s\n", id);
  for (symbol_t* ptr = inherited; ptr != NULL; ptr = ptr->next) {
    printf("inherited: %s\n", ptr->id);
  }*/

  symbol_t* existing = symbol_exists(id, inherited);
  if (existing != NULL) {
    if (existing->existing == 1)
      error_symbol_redefined(id);
    else {
      if (existing->type == type) {
        existing->existing = 1;
        return inherited;
      }
    }
  }

  s->type = type;
  s->id = strdup(id);
  s->next = inherited;
  s->existing = 1;

  return s;
}



int main(int argc, char **argv) {
  yyparse();
  return 0;
}
