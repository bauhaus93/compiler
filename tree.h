#ifndef TREE_H
#define TREE_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "symbol.h"
#include "condition.h"
#include "opdefs.h"

#ifdef USE_IBURG
#ifndef BURM
typedef struct burm_state *STATEPTR_TYPE;
#endif
#else
#define STATEPTR_TYPE int
#endif

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

extern tree_node_t* create_node(int op, const char* id, tree_node_t* left, tree_node_t* right, symbol_t* symbols);
extern tree_node_t* create_conditional_node(int op, tree_node_t* left, tree_node_t* right, symbol_t* symbols, condition_t* condition);
extern tree_node_t* create_number_node(int value);
extern tree_node_t* create_id_node(const char* id, symbol_t* symbols);

#endif
