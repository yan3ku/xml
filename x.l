%{
#include <stdio.h>
#include <string.h>
#include "x.tab.h"

int escape();
%}

%option noyywrap

IDENT [a-zA-Z0-9]+
                        
%x IN_TAG STR
%%
[ \t\n]+

"<?"         { BEGIN(IN_TAG);  return PI_TAG_BEG; }
"</"         { BEGIN(IN_TAG);  return END_TAG_START; }
"<"          { BEGIN(IN_TAG);  return '<'; }
[^<]+        { yylval.str = yytext; return TEXT; }

<IN_TAG>"?>" { BEGIN(INITIAL); return PI_TAG_END; }
<IN_TAG>"/>" { BEGIN(INITIAL); return EMPTY_TAG_END; }
<IN_TAG>">"  { BEGIN(INITIAL); return '>'; }

<IN_TAG>{IDENT}       { yylval.str = yytext; return IDENT; }
<IN_TAG>=             { return '='; }
<IN_TAG>\"            { BEGIN(STR); }
<STR>([^\\\"]|\\.)*\" { BEGIN(IN_TAG); yytext[yyleng - 1] = 0; escape(); return STRING_LIT; }
<STR><<EOF>>          { yyerror("unterminated string\n"); yyterminate(); }

%%

int
escape()
{
    char *esc = malloc(yyleng);
    char *esc0 = esc;
    int i = 0;
    while (i < yyleng) {
        switch (yytext[i]) {
        case '\\':
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
    *esc = 0;
    yylval.str = esc0;
}
