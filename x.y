%{
#include <stdio.h>

int yylex();
void yyerror(const char *s);
%}
%union {
    char ch;
    char *str;
};

%token <str> STAG_BEG CTAG_BEG PI_TAG_BEG
%token <ch> S CHAR
%token TAG_END ETAG_END PI_TAG_END
%token NEWLINE
%%
XDOC:   PROLOG NEWLINE ELEMENT ;

PROLOG: PI_TAG_BEG PI_TAG_END { printf("FOUND PROLOG %s", $1);  }
|       %empty
;

ELEMENT: EMPTY_TAG
|        START_TAG CONTENT END_TAG
;

CONTENT: CONTENT CHAR
|        CONTENT NEWLINE
|        CONTENT S
|        CONTENT ELEMENT
|        %empty
;

INSIDE_TAG_STUFF: INSIDE_TAG_STUFF CHAR
|                 INSIDE_TAG_STUFF S
|                 %empty
;

START_TAG: STAG_BEG INSIDE_TAG_STUFF TAG_END    { printf ("FOUND EMPTY %s", $1); };
END_TAG:   CTAG_BEG INSIDE_TAG_STUFF TAG_END  ;
EMPTY_TAG: STAG_BEG INSIDE_TAG_STUFF ETAG_END ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Błąd parsera: %s\n", s);
}

int main() {
    return yyparse();
}
