//  language idea and grammar generated from Claude , I will be working mainly on the semantics
grammar slang;

// PARSER RULES

program
    : function*
    ;

function
    : FN IDENT LPAREN parameters? RPAREN ARROW type block
    ;

parameters
    : parameter (COMMA parameter)*
    ;

parameter
    : IDENT COLON type
    ;

type
    : I32
    | BOOL
    | VOID
    ;

block
    : LBRACE statement* RBRACE
    ;

statement
    : variableDeclaration
    | assignment
    | ifStatement
    | whileStatement
    | returnStatement
    | expressionStatement
    | block
    ;

variableDeclaration
    : LET IDENT COLON type ASSIGN expression SEMICOLON
    ;

assignment
    : IDENT ASSIGN expression SEMICOLON
    ;

ifStatement
    : IF expression block
      (ELSE block)?
    ;

whileStatement
    : WHILE expression block
    ;

returnStatement
    : RETURN expression? SEMICOLON
    ;

expressionStatement
    : expression SEMICOLON
    ;


// EXPRESSIONS


expression
    : logicalOr
    ;

logicalOr
    : logicalAnd (OR logicalAnd)*
    ;

logicalAnd
    : equality (AND equality)*
    ;

equality
    : comparison ((EQ | NEQ) comparison)*
    ;

comparison
    : addition ((LT | GT | LE | GE) addition)*
    ;

addition
    : multiplication ((PLUS | MINUS) multiplication)*
    ;

multiplication
    : unary ((STAR | SLASH | MOD) unary)*
    ;

unary
    : (MINUS | NOT) unary
    | primary
    ;

primary
    : INTEGER
    | TRUE
    | FALSE
    | functionCall
    | IDENT
    | LPAREN expression RPAREN
    ;

functionCall
    : IDENT LPAREN arguments? RPAREN
    ;

arguments
    : expression (COMMA expression)*
    ;


// LEXER RULES


// Keywords

FN
    : 'fn'
    ;

LET
    : 'let'
    ;

IF
    : 'if'
    ;

ELSE
    : 'else'
    ;

WHILE
    : 'while'
    ;

RETURN
    : 'return'
    ;

// Types

I32
    : 'i32'
    ;

BOOL
    : 'bool'
    ;

VOID
    : 'void'
    ;

// Boolean literals

TRUE
    : 'true'
    ;

FALSE
    : 'false'
    ;

// Operators

ARROW
    : '->'
    ;

OR
    : '||'
    ;

AND
    : '&&'
    ;

EQ
    : '=='
    ;

NEQ
    : '!='
    ;

LE
    : '<='
    ;

GE
    : '>='
    ;

LT
    : '<'
    ;

GT
    : '>'
    ;

PLUS
    : '+'
    ;

MINUS
    : '-'
    ;

STAR
    : '*'
    ;

SLASH
    : '/'
    ;

MOD
    : '%'
    ;

NOT
    : '!'
    ;

ASSIGN
    : '='
    ;

// Punctuation

COLON
    : ':'
    ;

COMMA
    : ','
    ;

SEMICOLON
    : ';'
    ;

LPAREN
    : '('
    ;

RPAREN
    : ')'
    ;

LBRACE
    : '{'
    ;

RBRACE
    : '}'
    ;

// Identifiers and literals

INTEGER
    : [0-9]+
    ;

IDENT
    : [a-zA-Z_] [a-zA-Z0-9_]*
    ;

// Whitespace

WS
    : [ \t\r\n]+ -> skip
    ;