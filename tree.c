#include "tree.h"

tree_node_t* create_node(int op, const char* id, tree_node_t* left, tree_node_t* right, symbol_t* symbols) {
  p_tree_node_t node = malloc(sizeof(tree_node_t));
  memset(node, 0, sizeof(tree_node_t));

  node->op = op;
  node->id = id;
  node->left = left;
  node->right = right;
  node->symbols = symbols;

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

  return node;
}

tree_node_t* create_number_node(int value) {
  p_tree_node_t node = malloc(sizeof(tree_node_t));
  memset(node, 0, sizeof(tree_node_t));

  node->op = OP_NUM;
  node->value = value;

  return node;
}

tree_node_t* create_id_node(const char* id, symbol_t* symbols) {
  p_tree_node_t node = malloc(sizeof(tree_node_t));
  memset(node, 0, sizeof(tree_node_t));

  node->op = OP_ID;
  node->id = id;
  node->symbols = symbols;

  return node;
}
