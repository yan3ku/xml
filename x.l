%{
#include <stdio.h>
#include <string.h>
#include "x.tab.h"

char *escape();
char *transamp();
%}

%option noyywrap

IDENT [a-zA-Z][a-zA-Z0-9_.-]+

%x IN_TAG STR COMMENT
%%
[ \t\n]+

"<?"           { BEGIN(IN_TAG);  return PI_TAG_BEG; }
"</"           { BEGIN(IN_TAG);  return END_TAG_START; }
"<"            { BEGIN(IN_TAG);  return '<'; }
"<!--"         { BEGIN(COMMENT); }
<COMMENT>"-->" { BEGIN(INITIAL); }
<COMMENT>.     {}
[^<]+          { yylval.str = transamp(); return TEXT; }

<IN_TAG>"?>"   { BEGIN(INITIAL); return PI_TAG_END; }
<IN_TAG>"/>"   { BEGIN(INITIAL); return EMPTY_TAG_END; }
<IN_TAG>">"    { BEGIN(INITIAL); return '>'; }


<IN_TAG>{IDENT}       { yylval.str = yytext; return IDENT; }
<IN_TAG>=             { return '='; }
<IN_TAG>\"            { BEGIN(STR); }
<STR>([^\\\"]|\\.)*\" { BEGIN(IN_TAG); yylval.str = escape(); return STRING_LIT; }
<STR><<EOF>>          { yyerror("unterminated string\n"); yyterminate(); }

%%

#define TRANSAMP(x, t) if (strncmp(x, yytext+i, strlen(x)) == 0) { *(esc++) = t; i += strlen(x); continue; }

char *
transamp()
{
    char *esc = malloc(yyleng+1);
    char *esc0 = esc;
    int i = 0;
    while (i<yyleng) {
        TRANSAMP("&lt;", '<');
        TRANSAMP("&gt;", '>');
        TRANSAMP("&amp;", '&');
        TRANSAMP("&apos;", '\'');
        TRANSAMP("&quot;", '\"');
        *(esc++) = yytext[i++];
    }
    *esc = 0;
    printf("TRANS: %s\n", esc0);
    return esc0;
}

char *
escape()
{
    char *esc = malloc(yyleng+1);
    char *esc0 = esc;
    int i = 0;
    while (i < yyleng-1) {      /* -1 for the closing quote */
        switch (yytext[i]) {
        case '\\':
            if (i+1 >= yyleng) goto ESCAPE_EXIT;
            switch (yytext[i+1]) {
            case 'n': *(esc++) = '\n';        break;
            case 't': *(esc++) = '\t';        break;
            default:  *(esc++) = yytext[i+1]; break;
            }
            i += 2;
            continue;
        }
        *(esc++) = yytext[i++];
    }
ESCAPE_EXIT:
    *esc = 0;
    return esc0;
}
