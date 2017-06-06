#include "condition.h"

condition_t* prevCondition = NULL;
int failLabelCounter = 0;

int acquire_next_fail_label(void) {
  return failLabelCounter++;
}

condition_t* create_condition_data(const char* jumpTarget, int inversed) {
  condition_t* cond = malloc(sizeof(condition_t));
  char *failTarget = malloc(20);

  cond->jumpTarget = jumpTarget;
  cond->inversed = inversed;
  snprintf(failTarget, 20, "TARGET_%d", acquire_next_fail_label());
  cond->failTarget = failTarget;
  return cond;
}

condition_t* duplicate_condition_inverted(condition_t* data) {
  condition_t* cond = malloc(sizeof(condition_t));
  cond->jumpTarget = data->jumpTarget;
  cond->failTarget = data->failTarget;
  cond->inversed = !data->inversed;
  return cond;
}

void print_condition_data(symbol_t* symbols) {
  if (prevCondition != NULL) {
    clear_all_regs(symbols);
    printf("jmp L_%s_%s\nL_%s_%s:\n", currFunction, prevCondition->jumpTarget, currFunction, prevCondition->failTarget);
    free(prevCondition);
    prevCondition = NULL;
  }
  printf("#Statement\n");
}
