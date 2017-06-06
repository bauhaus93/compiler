#ifndef REG_H
#define REG_H

#include <stdio.h>

#include "globals.h"
#include "symbol.h"

extern int acquire_reg(symbol_t* symbols);
extern void clear_reg(int regId, symbol_t* symbols);
extern void clear_all_regs(symbol_t* symbols);

extern int load_symbol_into_reg(const char* id, symbol_t* symbols);
extern int assign_reg_to_symbol(const char* id, symbol_t* symbols);
extern int get_symbol_reg(const char* id, symbol_t* symbols);
extern symbol_t* get_symbol_by_name(const char* id, symbol_t* symbols);

extern const char* regs[];
extern int currReg;

#endif
