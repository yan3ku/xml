%define parse.assert
%define parse.error verbose
%code requires {
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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

%%
XDOC:   PROLOG ELEMENT;

PROLOG: "<?" IDENT ATTR_LIST "?>" ;
|       %empty
;

ELEMENT: EMPTY_TAG
|        START_TAG CONTENT END_TAG ;

CONTENT: CONTENT TEXT     ;
|        CONTENT ELEMENT  ;
|        %empty           ;
;

START_TAG: '<'  IDENT ATTR_LIST '>'  ;
END_TAG:   "</" IDENT ATTR_LIST '>'  ;
EMPTY_TAG: '<'  IDENT ATTR_LIST "/>" ;

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
    case NODE_TX: printf("[ELEMENT] %s\n", node->content); break;
    case NODE_EL: printf("[TEXT]    %s\n", node->content); break;
    case NODE_PI: printf("[PI]      %s\n", node->content); break;
    }
    printdom(node->child, indent + 4);
    printdom(node->next, indent);
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
