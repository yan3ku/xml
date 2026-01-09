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

%token <str> STAG_BEG ETAG_BEG PI_TAG_BEG
%token <ch> S CHAR
%token TAG_END ETAG_END PI_TAG_END
%token NEWLINE

%type <node>PROLOG
%type <node>START_TAG
%type <str>END_TAG
%type <node>ELEMENT
%type <node>CONTENT
%type <node>EMPTY_TAG
%%
XDOC:   PROLOG NEWLINE ELEMENT NEWLINE              { $1->next = $3; root = $1; };

PROLOG: PI_TAG_BEG PI_TAG_END               { $$ = mknode(NODE_PI, $1);  }
|       %empty                              { $$ = NULL; }
;

ELEMENT: EMPTY_TAG
|        START_TAG CONTENT END_TAG  {
    if (strcmp($1->content, $3)) {
        yyerror("Tag mismatch!");
        YYERROR;
    }
    $$ = $1;
    $$->child = $2;
    free($3);
 }
;

CONTENT: CONTENT CHAR      { $$ = mknode(NODE_TX, "dummy"); }
|        CONTENT NEWLINE   { $$ = mknode(NODE_TX, "dummy"); }
|        CONTENT S         { $$ = mknode(NODE_TX, "dummy"); }
|        CONTENT ELEMENT   { $$ = mknode(NODE_TX, "dummy"); }
|        %empty            { $$ = mknode(NODE_TX, "dummy"); }
;

 /*dummy right now*/
ATTR_LIST: ATTR_LIST CHAR
|          ATTR_LIST S
|          %empty
;

START_TAG: STAG_BEG ATTR_LIST TAG_END    { $$ = mknode(NODE_EL, $1); };
END_TAG:   ETAG_BEG ATTR_LIST TAG_END    { $$ = $1; };
EMPTY_TAG: STAG_BEG ATTR_LIST ETAG_END   { $$ = mknode(NODE_EL, $1); };

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
