%{
#include <stdio.h>
#include "oxout.tab.h"
#include "error.h"
#include "symbol.h"
#include "tree.h"

long get_number(const char *str, size_t len);

%}

%option yylineno
%option noyywrap

digit [0-9_]
letter_lower [a-z]
letter_upper [A-Z]
letter [a-zA-Z]
alnum [0-9a-zA-Z]
whitespace [ \t\n]

%Start COMMENT

%%

<COMMENT><<EOF>> error_lexer("In state COMMENT, but found EOF", yylineno);

<INITIAL>"(*" BEGIN COMMENT;
<COMMENT>"*)" BEGIN INITIAL;
<COMMENT>. ;
<COMMENT>\n ;

<INITIAL>"end"      return END;
<INITIAL>"return"   return RETURN;
<INITIAL>"goto"     return GOTO;
<INITIAL>"if"       return IF;
<INITIAL>"var"      return VAR;
<INITIAL>"and"      return AND;
<INITIAL>"not"      return NOT;
<INITIAL>";"        return ';';
<INITIAL>"("        return '(';
<INITIAL>")"        return ')';
<INITIAL>","        return ',';
<INITIAL>":"        return ':';
<INITIAL>"="        return EQUAL;
<INITIAL>"!="       return NOTEQUAL;
<INITIAL>">"        return GREATERTHAN;
<INITIAL>"["        return '[';
<INITIAL>"]"        return ']';
<INITIAL>"-"        return MINUS;
<INITIAL>"+"        return PLUS;
<INITIAL>"*"        return MULT;

<INITIAL>{letter}+{alnum}*  return IDENTIFIER; @{ @IDENTIFIER.name@ = strdup(yytext); @}
<INITIAL>{digit}+ return NUMBER; @{ @NUMBER.value@ = get_number(yytext, yyleng); @}

<INITIAL>{whitespace}+ ;

. error_lexer_match("Unexpected sequence found", yylineno, yytext);

%%

long get_number(const char *str, size_t len) {
  char *stripped = (char*) malloc(len * sizeof(char));
  memset(stripped, 0, len * sizeof(char));

  size_t destPos = 0;
  for (size_t i = 0; i < len; i++) {
    if (str[i] != '_') {
      stripped[destPos++] = str[i];
    }
  }

  long result = atol(stripped);
  free(stripped);
  return result;
}
