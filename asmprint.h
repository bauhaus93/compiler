#ifndef ASMPRINT_H
#define ASMPRINT_H

#include "tree.h"
#include "globals.h"
#include "reg.h"
#include "condition.h"

extern void print_function_header(const char* fnName, symbol_t* params, symbol_t* symbols);

extern void print_return_direct(tree_node_t* node);
extern void print_return_reg(tree_node_t* node);

extern void print_write_to_var_from_direct(tree_node_t* node);
extern void print_write_to_var_from_reg(tree_node_t* node);

extern void print_write_to_array_from_reg(tree_node_t* node);
extern void print_write_to_array_from_direct(tree_node_t* node);

extern void print_def_direct(tree_node_t* node);
extern void print_def_reg(tree_node_t* node);

extern void print_comparison_gt_direct_direct(tree_node_t* node);
extern void print_comparison_gt_direct_reg(tree_node_t* node);
extern void print_comparison_gt_reg_direct(tree_node_t* node);
extern void print_comparison_gt_reg_reg(tree_node_t* node);

extern void print_comparison_neq_direct_direct(tree_node_t* node);
extern void print_comparison_neq_direct_reg(tree_node_t* node);
extern void print_comparison_neq_reg_direct(tree_node_t* node);
extern void print_comparison_neq_reg_reg(tree_node_t* node);

extern int print_load_array_addr_direct_index(tree_node_t* idNode, tree_node_t* directNode);
extern int print_load_array_addr_reg_index(tree_node_t* idNode, tree_node_t* regNode);
extern int print_load_array_direct_index(tree_node_t* idNode, tree_node_t* directNode);
extern int print_load_array_reg_index(tree_node_t* idNode, tree_node_t* regNode);

extern int print_add_direct_reg(tree_node_t* regNode, tree_node_t* directNode);
extern int print_add_reg_reg(tree_node_t* regA, tree_node_t* regB);

extern int print_mult_direct_reg(tree_node_t* regNode, tree_node_t* directNode);
extern int print_mult_reg_reg(tree_node_t* regA, tree_node_t* regB);

#endif
