%define parse.assert
%define parse.error verbose
%code requires {
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

int yylex(void);
void yyerror(const char *s);

typedef enum {
    NODE_EL,
    NODE_TX,
    NODE_PI,
} NodeType;

typedef struct Node {
    NodeType type;
    char *content;
    struct Node *child;
    struct Node *next;
} Node;

Node *mknode(NodeType type, char *content);
int iswhite();
}/*code requires*/
%code {
Node *root = NULL;
}/*code*/

%union {
    char ch;
    char *str;
    Node *node;
};

%token <str>IDENT STRING_LIT
%token PI_TAG_BEG "<?" PI_TAG_END "?>"
%token END_TAG_START "</" EMPTY_TAG_END "/>"
%token <str>TEXT

%type <node>EMPTY_TAG START_TAG
%type <node>ELEMENT CONTENT
%type <str>END_TAG
%type <node>PROLOG

%%
XDOC: PROLOG TEXT_OPT ELEMENT TEXT_OPT  { root = $3; if ($1) { $1->next = $3; root = $1; } };

TEXT_OPT: TEXT | %empty

PROLOG: "<?" IDENT ATTR_LIST "?>" { $$ = mknode(NODE_PI, $2); };
|       %empty                    { $$ = NULL; }
;

ELEMENT: EMPTY_TAG                  { $$ = $1; }
|        START_TAG CONTENT END_TAG  {
    if (strcmp($1->content, $3)) {
        yyerror("not matching tags");
        YYERROR;
    }
    $1->child = $2; $$ = $1;
    $$ = $1;
};

CONTENT: %empty { $$ = NULL; }
| CONTENT TEXT {
    if (iswhite($2)) {
        $$ = $1;
        break;
    }
    Node *new = mknode(NODE_TX, $2);
    if (!$1) {
        $$ = new;
        break;
    }
    Node *curr = $1;
    while (curr->next) curr = curr->next;
    curr->next = new;
    $$ = $1;
}
| CONTENT ELEMENT {
    if (!$1) {
        $$ = $2;
        break;
    }
    Node *curr = $1;
    while (curr->next) curr = curr->next;
    curr->next = $2;
    $$ = $1;
};

START_TAG: '<'  IDENT ATTR_LIST '>'  { $$ = mknode(NODE_EL, $2); } ;
END_TAG:   "</" IDENT ATTR_LIST '>'  { $$ = $2; } ;
EMPTY_TAG: '<'  IDENT ATTR_LIST "/>" { $$ = mknode(NODE_EL, $2); } ;

ATTR_LIST: ATTR_LIST ATTR
|          %empty
;

ATTR: IDENT '=' STRING_LIT ;

%%
Node *
mknode(NodeType type, char *content)
{
    Node *node = malloc(sizeof(Node));
    node->type = type;
    node->content = content;
    node->child = NULL;
    node->next = NULL;
    return node;
}

void
printdom(Node *node, int indent)
{
    if (!node) return;
    for (int i = 0; i < indent; i++) printf(" ");
    switch (node->type) {
    case NODE_EL: printf("ELEM: <%s>\n", node->content); break;
    case NODE_TX: printf("TEXT: <%s>\n", node->content); break;
    case NODE_PI: printf("PI:   <%s>\n", node->content); break;
    }
    printdom(node->child, indent + 4);
    printdom(node->next, indent);
}

int
iswhite(char *text)
{
    while (*text)
        if (!isspace(*text++)) {
            return 0;
        }
    return 1;
}

void
yyerror(const char *s)
{
    fprintf(stderr, "ERROR: %s\n", s);
}

int
main()
{
    yydebug = 1;
    if (!yyparse()) {
        printf("===== DOM =======\n");
        printdom(root, 0);
        printf("=================\n");
    }
}
