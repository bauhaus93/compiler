#ifndef SYMBOL_H
#define SYMBOL_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "error.h"

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

extern symbol_t* create_symbol_root(void);
extern symbol_t* create_symbol(symbol_type_t type, const char* id, symbol_t* inherited);

extern symbol_t* get_symbol_by_name(const char* id, symbol_t* symbols);

extern symbol_t* symbol_exists(const char* id, symbol_t* inherited);
extern symbol_t* symbol_with_type_exists(symbol_type_t type, const char* id, symbol_t* inherited);

extern symbol_t* check_if_variable_non_existing(const char* id, symbol_t* inherited);
extern symbol_t* check_if_label_non_existing(const char* id, symbol_t* inherited);

extern symbol_t* error_if_non_existing_in_list(symbol_t* symbols);

extern int get_len(symbol_t* symbols);
extern int count_variables(symbol_t* symbols);


#endif
