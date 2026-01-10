%{
#include <stdio.h>
#include <string.h>
#include "x.tab.h"

char *transamp();
%}

%option noyywrap nodefault yylineno

IDENT [a-zA-Z][a-zA-Z0-9_.-]+

%x TAG COMM QUOT APOS
%%
[ \t\n]+           {}
"<?"               { BEGIN(TAG);  return PI_TAG_BEG; }
"</"               { BEGIN(TAG);  return END_TAG_START; }
"<"                { BEGIN(TAG);  return '<'; }
"<!--"             { BEGIN(COMM); }
<COMM>"-->"        { BEGIN(INITIAL); }
<COMM>(.|\n)       {}
[^<]+              { transamp(); return TEXT; }

<TAG>"?>"          { BEGIN(INITIAL); return PI_TAG_END; }
<TAG>"/>"          { BEGIN(INITIAL); return EMPTY_TAG_END; }
<TAG>">"           { BEGIN(INITIAL); return '>'; }

<TAG>{IDENT}       { yylval.str = strdup(yytext); return IDENT; }
<TAG>=             { return '='; }
<TAG>\"            { BEGIN(QUOT); }
<TAG>\'            { BEGIN(APOS); }
<TAG>(.|\n)        {}

<QUOT>[^\"]*\"     { BEGIN(TAG); transamp(); return STRING_LIT; }
<QUOT>(.|\n)       { yyerror("unrecognized char"); yyterminate(); }
<QUOT><<EOF>>      { yyerror("no closing quote; start at\n"); yyterminate(); }

<APOS>[^\']*\'     { BEGIN(TAG); transamp(); return STRING_LIT; }
<APOS>(.|\n)       { yyerror("unrecognized char\n"); yyterminate(); }
<APOS><<EOF>>      { yyerror("no closing apostroph\n"); yyterminate(); }

%%

#define TRANSAMP(x, t) if (strncmp(x, yytext+i, strlen(x)) == 0) { *(esc++) = t; i += strlen(x); continue; }

char *
transamp()
{
    char *esc = yylval.str = malloc(yyleng+1);
    int i = 0;
    while (i<yyleng) {
        if (yytext[i] == '&') {
            i++;
            TRANSAMP("lt;",   '<');
            TRANSAMP("gt;",   '>');
            TRANSAMP("amp;",  '&');
            TRANSAMP("apos;", '\'');
            TRANSAMP("quot;", '\"');
            continue;
        }
        *(esc++) = yytext[i++];
    }
    *esc = 0;
}
