#ifndef ERROR_H
#define ERROR_H

#include <stdio.h>
#include <stdlib.h>

extern void error_lexer(const char *msg, int lineno);
extern void error_lexer_match(const char *msg, int lineno, const char* match);
extern int yyerror(const char* e);
extern void error_symbol_redefined(const char* symbolId);
extern void error_symbol_non_existing(const char* symbolId);
extern void error_program_logic(const char* msg);

#endif
