%{
#include <stdio.h>
#include <string.h>
#include "x.tab.h"
%}

%option noyywrap

%%
"<?"[a-zA-Z0-9]+ {
    yylval.str = strdup(yytext + 2); 
    return PI_TAG_BEG;
}

"?>" {
    return PI_TAG_END;
}

"<"[a-zA-Z0-9]+ {
    yylval.str = strdup(yytext + 2); 
    return STAG_BEG;
}

">" {
    return TAG_END;
}

\n { return NEWLINE; }

[ \t]+ {  }

. { 
    yylval.ch = yytext[0];
    return CHAR; 
}

%%
