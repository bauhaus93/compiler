#include "symbol.h"

symbol_t* create_symbol_root(void) {
  symbol_t *s = malloc(sizeof(symbol_t));
  memset(s, 0, sizeof(symbol_t));
  return s;
}

symbol_t* create_symbol(symbol_type_t type, const char* id, symbol_t* inherited) {
  symbol_t* s = malloc(sizeof(symbol_t));
  memset(s, 0, sizeof(symbol_t));

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

symbol_t* get_symbol_by_name(const char* id, symbol_t* symbols) {
  for(symbol_t* ptr = symbols; ptr != NULL; ptr = ptr->next) {
    if(strcmp(id, ptr->id) == 0) {
      return ptr;
    }
  }
  error_program_logic("get_symbol_by_name: Symbol not found");
  return NULL;
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

    if (ptr->existing == 0)
      error_symbol_non_existing(ptr->id);
    prev = ptr;
  }
  return symbols;
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
