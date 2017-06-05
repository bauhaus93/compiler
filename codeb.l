%{
#include <stdio.h>
#include "oxout.tab.h"
#include "codeb.h"

//extern int yylex();

long GetNumber(const char *str, size_t len);
void ExitError(const char *msg);
void ExitErrorWithMatch(const char *msg);

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

<COMMENT><<EOF>> ExitError("In state COMMENT, but found EOF");

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
<INITIAL>{digit}+ return NUMBER; @{ @NUMBER.value@ = GetNumber(yytext, yyleng); @}

<INITIAL>{whitespace}+ ;

. ExitErrorWithMatch("Unexpected sequence found");

%%

long GetNumber(const char *str, size_t len) {
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

void ExitError(const char *msg) {
  printf("[LexError] near line %d: %s\n", yylineno, msg);
  exit(1);
}

void ExitErrorWithMatch(const char *msg) {
  printf("[LexError] near line %d: %s @ : \"%s\"\n", yylineno, msg, yytext);
  exit(1);
}

/*int main(int argc, char **argv) {
  yylex();
  return 0;
}*/
