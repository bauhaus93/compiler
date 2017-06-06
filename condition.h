#ifndef CONDITION_H
#define CONDITION_H

#include <stdio.h>
#include <stdlib.h>

#include "symbol.h"
#include "reg.h"

typedef struct {
  const char*     jumpTarget;
  const char*     failTarget;
  int             inversed;
} condition_t;

extern int acquire_next_fail_label(void);
extern condition_t* create_condition_data(const char* jumpTarget, int inversed);
extern condition_t* duplicate_condition_inverted(condition_t* data);
extern void print_condition_data(symbol_t* symbols);

extern condition_t* prevCondition;
extern int failLabelCounter;

#endif
