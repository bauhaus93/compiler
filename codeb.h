#ifndef CODEB_H
#define CODEB_H

#define OP_STMT 1
#define OP_NUM 2
#define OP_ID 3
#define OP_ADD 4
#define OP_MULT 5
#define OP_MINUS 6
#define OP_RET 7
#define OP_ARRAY_ACCESS 8
#define OP_GT 9
#define OP_NEQ 10
#define OP_IF 11
#define OP_DEFINITION 12
#define OP_ASSIGNMENT 13

#ifdef USE_IBURG
#ifndef BURM
typedef struct burm_state *STATEPTR_TYPE;
#endif
#else
#define STATEPTR_TYPE int
#endif

typedef enum SymbolType {
  VARIABLE,
  LABEL
} symbol_type_t;

typedef struct Symbol {
  enum SymbolType type;
  const char*     id;
  int             existing;
  int             regId;
  int             frameOffset;
  struct Symbol*  next;
} symbol_t, *p_symbol_t;

typedef struct {
  const char*     jumpTarget;
  const char*     failTarget;
  int             inversed;
} condition_t;

typedef struct TreeNode {
    int op;
    struct TreeNode* left;
    struct TreeNode* right;
    const char* id;
    int value;
    condition_t* condition;
    symbol_t* symbols;

    STATEPTR_TYPE state;
} tree_node_t, *p_tree_node_t;

#define NODEPTR_TYPE p_tree_node_t
#define OP_LABEL(p)	((p)->op)
#define LEFT_CHILD(p) ((p)->left)
#define RIGHT_CHILD(p) ((p)->right)
#define STATE_LABEL(p) ((p)->state)
#define PANIC printf

extern const char* regs[];
extern int failLabelCounter;
extern int currReg;
extern const char* currFunction;
extern int assign_reg_to_symbol(const char* id, symbol_t* symbols);
extern int get_symbol_reg(const char* id, symbol_t* symbols);
extern symbol_t* get_symbol_by_name(const char* id, symbol_t* symbols);
extern int acquire_reg(symbol_t* symbols);
extern int clear_reg(int regId, symbol_t* symbols);
int clear_all_regs(symbol_t* symbols);

#endif
