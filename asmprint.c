#include "asmprint.h"

void print_function_header(const char* fnName, symbol_t* params, symbol_t* symbols) {
  int varCount = count_variables(symbols);
  int argCount = count_variables(params);
  int currOffset = -8;
  static const char* argRegs[] = {"%rdi", "%rsi", "%rdx", "%rcx", "%r8", "%r9"};

  printf(".globl %s\n.type %s, %cfunction\n%s:\n", fnName, fnName, 64, fnName);
  printf("push %%rbp\nmov %%rsp, %%rbp\nsub $%d, %%rsp\n", varCount * 8);

  //assign arguments frame offsets
  int i = 0;
  for(symbol_t* ptr = params; ptr != NULL; ptr = ptr->next) {
    int reg = argCount - i - 1;
    currOffset = -8 * (argCount - i);
    ptr->frameOffset = currOffset;
    ptr->regId = reg;
    printf("movq %s, %d(%%rbp)\t#arg %d: %s\n", argRegs[reg], currOffset, argCount - i, ptr->id);

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
}

void print_return_direct(tree_node_t* node) {
	printf("movq $%d, %%rax\nleave\nret\n", node->left->value);
}

void print_return_reg(tree_node_t* node) {
	int reg = (node->left->id != NULL ? load_symbol_into_reg(node->left->id, node->left->symbols) : node->left->value);
	printf("movq %s, %%rax\t#return %s\nleave\nret\n", regs[reg], node->left->id == NULL ? "<intermediate>" : node->left->id);
}

void print_write_to_var_from_direct(tree_node_t* node) {
	int reg = (node->left->id != NULL ? load_symbol_into_reg(node->left->id, node->left->symbols) : -1);
	if (reg == -1) {
		printf("node has no id but must have one!\n");
		exit(4);
	}
	printf("movq $%d, %s\t#write to %s\n", node->right->value, regs[reg], node->left->id);
}

void print_write_to_var_from_reg(tree_node_t* node) {
	int regDest = (node->left->id != NULL ? load_symbol_into_reg(node->left->id, node->left->symbols) : -1);
	if (regDest == -1) {
		printf("node has no id but must have one!\n");
		exit(4);
	}
	int regSrc = (node->right->id != NULL ? load_symbol_into_reg(node->right->id, node->right->symbols) : node->right->value);

	printf("movq %s, %s\t#write %s to %s\n", regs[regSrc], regs[regDest], node->right->id == NULL ? "<intermediate>" : node->right->id, node->left->id);

}

void print_write_to_array_from_reg(tree_node_t* node) {
	int destReg = (node->left->id != NULL ? -1 : node->left->value);
	if (destReg == -1) {
		printf("node does not save index of address register!\n");
		exit(4);
	}
	int srcReg = (node->right->id != NULL ? load_symbol_into_reg(node->right->id, node->right->symbols) : node->right->value);
	printf("movq %s, (%s)\t#write to array \n", regs[srcReg], regs[destReg]);
}

void print_write_to_array_from_direct(tree_node_t* node) {
	int destReg = (node->left->id != NULL ? -1 : node->left->value);
	if (destReg == -1) {
		printf("node does not save index of address register!\n");
		exit(4);
	}
	printf("movq $%d, (%s)\t#write to array \n", node->right->value, regs[destReg]);
}

void print_def_direct(tree_node_t* node) {
	symbol_t* symbol = get_symbol_by_name(node->id, node->symbols);
	printf("movq $%d, %d(%%rbp)\t#definition of var %s\n", node->left->value, symbol->frameOffset, node->id);
}

void print_def_reg(tree_node_t* node) {
	symbol_t* symbol = get_symbol_by_name(node->id, node->symbols);
	int regExpr = (node->left->id != NULL ? load_symbol_into_reg(node->left->id, node->left->symbols) : node->left->value);
	printf("movq %s, %d(%%rbp)\t#definition of var %s\n", regs[regExpr], symbol->frameOffset, node->id);
}

void print_comparison_gt_direct_direct(tree_node_t* node) {
	if (node->left->value > node->right->value && node->condition->inversed) {
		clear_all_regs(node->symbols);
		printf("jmp L_%s\t#would-be conditional jmp -> always true\n", node->condition->failTarget);
	}
	else {
		printf("#here would be a conditional jump that is always false\n");
	}
}

void print_comparison_gt_direct_reg(tree_node_t* node) {
	int reg = (node->right->id != NULL ? load_symbol_into_reg(node->right->id, node->right->symbols) : node->right->value);
	printf("cmpq $%d, %s\t#cmp with %s\n", node->left->value, regs[reg], node->right->id != NULL ? node->right->id : "<intermediate>");
	clear_all_regs(node->symbols);
	if(!node->condition->inversed)
		printf("jge L_%s_%s\n", currFunction, node->condition->failTarget);
	else
		printf("jl L_%s_%s\n", currFunction, node->condition->failTarget);
}

void print_comparison_gt_reg_direct(tree_node_t* node) {
	int reg = (node->left->id != NULL ? load_symbol_into_reg(node->left->id, node->left->symbols) : node->left->value);
	printf("cmpq $%d, %s\t#cmp with %s\n", node->right->value, regs[reg], node->left->id != NULL ? node->left->id : "<intermediate>");
	clear_all_regs(node->symbols);
	if(node->condition->inversed)
		printf("jge L_%s_%s\n", currFunction, node->condition->failTarget);
	else
		printf("jle L_%s_%s\n", currFunction, node->condition->failTarget);
}

void print_comparison_gt_reg_reg(tree_node_t* node) {
	int regLeft = (node->left->id != NULL ? load_symbol_into_reg(node->left->id, node->left->symbols) : node->left->value);
	int regRight = (node->right->id != NULL ? load_symbol_into_reg(node->right->id, node->right->symbols) : node->right->value);

	printf("cmpq %s, %s\t#cmp %s with %s\n", regs[regRight], regs[regLeft], node->left->id != NULL ? node->left->id : "<intermediate>", node->right->id != NULL ? node->right->id : "<intermediate>");
	clear_all_regs(node->symbols);
	if(node->condition->inversed)
		printf("jg L_%s_%s\n", currFunction, node->condition->failTarget);
	else
		printf("jle L_%s_%s\n", currFunction, node->condition->failTarget);
}

void print_comparison_neq_direct_direct(tree_node_t* node) {
	if (node->left->value != node->right->value && node->condition->inversed) {
		clear_all_regs(node->symbols);
		printf("jmp L_%s_%s\t#would-be conditional jmp -> always true\n", currFunction, node->condition->failTarget);
	}
	else {
		printf("#here would be a conditional jump that is always false\n");
	}
}

void print_comparison_neq_direct_reg(tree_node_t* node) {
	int reg = (node->right->id != NULL ? load_symbol_into_reg(node->right->id, node->right->symbols) : node->right->value);
	printf("cmpq $%d, %s\t#cmp with %s\n", node->left->value, regs[reg], node->right->id != NULL ? node->right->id : "<intermediate>");
	clear_all_regs(node->symbols);
	if(node->condition->inversed)
		printf("jne L_%s_%s\n", currFunction, node->condition->failTarget);
	else
		printf("je L_%s_%s\n", currFunction, node->condition->failTarget);
}

void print_comparison_neq_reg_direct(tree_node_t* node) {
	int reg = (node->left->id != NULL ? load_symbol_into_reg(node->left->id, node->left->symbols) : node->left->value);
	printf("cmpq $%d, %s\t#cmp with %s\n", node->right->value, regs[reg], node->left->id != NULL ? node->left->id : "<intermediate>");
	clear_all_regs(node->symbols);
	if(node->condition->inversed)
		printf("jne L_%s_%s\n", currFunction, node->condition->failTarget);
	else
		printf("je L_%s_%s\n", currFunction, node->condition->failTarget);
}

void print_comparison_neq_reg_reg(tree_node_t* node) {
	int regLeft = (node->left->id != NULL ? load_symbol_into_reg(node->left->id, node->left->symbols) : node->left->value);
	int regRight = (node->right->id != NULL ? load_symbol_into_reg(node->right->id, node->right->symbols) : node->right->value);

	printf("cmpq %s, %s\t#cmp %s with %s\n", regs[regRight], regs[regLeft], node->left->id != NULL ? node->left->id : "<intermediate>", node->right->id != NULL ? node->right->id : "<intermediate>");
	clear_all_regs(node->symbols);
	if(node->condition->inversed)
		printf("jne L_%s_%s\n", currFunction, node->condition->failTarget);
	else
		printf("je L_%s_%s\n", currFunction, node->condition->failTarget);
}

int print_load_array_addr_direct_index(tree_node_t* idNode, tree_node_t* directNode) {
	symbol_t* symbol = get_symbol_by_name(idNode->id, idNode->symbols);
	int destReg = acquire_reg(idNode->symbols);
	printf("movq %d(%%rbp), %s\t#load array ptr for %s\n", symbol->frameOffset, regs[destReg], idNode->id);
	printf("leaq %d(%s), %s\n", directNode->value * 8, regs[destReg], regs[destReg]);
	return destReg;
}

int print_load_array_addr_reg_index(tree_node_t* idNode, tree_node_t* regNode) {
	symbol_t* symbol = get_symbol_by_name(idNode->id, idNode->symbols);
	int srcReg = (regNode->id != NULL ? load_symbol_into_reg(regNode->id, regNode->symbols) : regNode->value);
	int destReg = acquire_reg(idNode->symbols);
	printf("movq %d(%%rbp), %s\t#load array ptr for %s\n", symbol->frameOffset, regs[destReg], idNode->id);
	printf("leaq (%s, %s, 8), %s\n", regs[destReg], regs[srcReg], regs[destReg]);
	return destReg;
}

int print_load_array_direct_index(tree_node_t* idNode, tree_node_t* directNode) {
	int reg = print_load_array_addr_direct_index(idNode, directNode);

	printf("movq (%s), %s\t#dereference array addr\n", regs[reg], regs[reg]);
	return reg;
}

int print_load_array_reg_index(tree_node_t* idNode, tree_node_t* regNode) {
	int reg = print_load_array_addr_reg_index(idNode, regNode);
	printf("movq (%s), %s\t#derefence array addr\n", regs[reg], regs[reg]);
	return reg;
}

int print_add_direct_reg(tree_node_t* regNode, tree_node_t* directNode) {
	int srcReg = (regNode->id != NULL ? load_symbol_into_reg(regNode->id, regNode->symbols) : regNode->value);
	int destReg = acquire_reg(regNode->symbols);
	printf("movq $%d, %s\n", directNode->value, regs[destReg]);
	printf("addq %s, %s\n", regs[srcReg], regs[destReg]);
	return destReg;
}

int print_add_reg_reg(tree_node_t* regA, tree_node_t* regB) {
	int srcAReg = (regA->id != NULL ? load_symbol_into_reg(regA->id, regA->symbols) : regA->value);
	int srcBReg = (regB->id != NULL ? load_symbol_into_reg(regB->id, regB->symbols) : regB->value);
	int destReg = acquire_reg(regA->symbols);

	printf("movq %s, %s\n", regs[srcAReg], regs[destReg]);
	printf("addq %s, %s\n", regs[srcBReg], regs[destReg]);
	return destReg;
}

int print_mult_direct_reg(tree_node_t* regNode, tree_node_t* directNode) {
	int srcReg = (regNode->id != NULL ? load_symbol_into_reg(regNode->id, regNode->symbols) : regNode->value);
	int destReg = acquire_reg(regNode->symbols);
	printf("movq $%d, %s\n", directNode->value, regs[destReg]);
	printf("imul %s, %s\n", regs[srcReg], regs[destReg]);
	return destReg;
}

int print_mult_reg_reg(tree_node_t* regA, tree_node_t* regB) {
  int srcAReg = (regA->id != NULL ? load_symbol_into_reg(regA->id, regA->symbols) : regA->value);
	int srcBReg = (regB->id != NULL ? load_symbol_into_reg(regB->id, regB->symbols) : regB->value);
	int destReg = acquire_reg(regA->symbols);

	printf("movq %s, %s\n", regs[srcAReg], regs[destReg]);
	printf("imul %s, %s\n", regs[srcBReg], regs[destReg]);
	return destReg;
}
