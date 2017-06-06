#include "reg.h"

const char* regs[]= {"%rdi", "%rsi", "%rdx", "%rcx", "%r8", "%r9", "%r10", "%r11"};
int currReg = 0;

int acquire_reg(symbol_t* symbols) {
  int ret = currReg;

  clear_reg(currReg, symbols);

  currReg++;
  if (currReg >= 8)
    currReg = 0;
  return ret;
}

void clear_reg(int regId, symbol_t* symbols) {
  for(symbol_t* ptr = symbols; ptr != NULL; ptr = ptr->next) {
    if(ptr->type == VARIABLE) {
      if (ptr->regId == regId) {
        printf("movq %s, %d(%%rbp)\t#write %s back on stack, bc reg is needed\n", regs[regId], ptr->frameOffset, ptr->id);
        ptr->regId = -1;
        break;
      }
    }
  }
}

void clear_all_regs(symbol_t* symbols) {
  for(symbol_t* ptr = symbols; ptr != NULL; ptr = ptr->next) {
    if(ptr->type == VARIABLE && ptr->regId != -1) {
      printf("movq %s, %d(%%rbp)\t#write %s back on stack, bc jmp\n", regs[ptr->regId], ptr->frameOffset, ptr->id);
      ptr->regId = -1;
    }
  }
}

int load_symbol_into_reg(const char* id, symbol_t* symbols) {
	int regId = get_symbol_reg(id, symbols);
	if (regId == -1){
		regId = assign_reg_to_symbol(id, symbols);
		symbol_t* symbol = get_symbol_by_name(id, symbols);
		printf("movq %d(%%rbp), %s\t#load symbol %s\n", symbol->frameOffset, regs[regId], id);
	}
	return regId;
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
