%{
#include <stdio.h>
#include <string.h>
#include "x.tab.h"
%}

%option noyywrap

IDENT [a-zA-Z0-9]+
                        
%x IN_TAG
%%
"<?"         { BEGIN(IN_TAG);  return PI_TAG_BEG; }
"</"         { BEGIN(IN_TAG);  return END_TAG_START; }
"<"          { BEGIN(IN_TAG);  return '<'; }
[^<]+        { yylval = yytext; return TEXT; }

<IN_TAG>"?>" { BEGIN(INITIAL); return PI_TAG_END; }
<IN_TAG>"/>" { BEGIN(INITIAL); return EMPTY_TAG_END; }
<IN_TAG>">"  { BEGIN(INITIAL); return '>'; }

<IN_TAG>{IDENT}    { yylval.str = yytext; return IDENT; }
<IN_TAG>=        { return '='; }
<IN_TAG>\".*\"     { yylval.str = yytext; return STRING_LIT; }

[ \t\n]+

%%
