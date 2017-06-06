#include "error.h"

void error_lexer(const char *msg, int lineno) {
  printf("[LexError] near line %d: %s\n", lineno, msg);
  exit(1);
}

void error_lexer_match(const char *msg, int lineno, const char* match) {
  printf("[LexError] near line %d: %s @ : \"%s\"\n", lineno, msg, match);
  exit(1);
}

int yyerror(const char* e) {
  printf("[ParseError] %s\n", e);
  exit(2);
}

void error_symbol_redefined(const char* symbolId) {
  printf("[SemanticError] Redefined already existing symbol \"%s\"\n", symbolId);
  exit(3);
}

void error_symbol_non_existing(const char* symbolId) {
  printf("[SemanticError] Wanted to access non-existing symbol: \"%s\"\n", symbolId);
  exit(3);
}

void error_program_logic(const char* msg) {
  printf("[ProgramLogicError] %s\n", msg);
  exit(4);
}
