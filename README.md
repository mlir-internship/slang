# SLANG

> A small, statically-typed, C-like language for learning compiler construction with **MLIR** and **LLVM**.

**Status:** 🚧 Specification complete (v0.1) — compiler implementation in progress.

SLANG is not trying to be a "real" production language. It exists to be *small enough to finish* while still forcing you through every fundamental compiler problem: lexing, parsing, ASTs, symbol tables, type checking, control flow, an MLIR dialect, lowering passes, LLVM IR, and native codegen.

---

## Table of Contents

- [Why SLANG?](#why-slang)
- [Quick Look](#quick-look)
- [Language Tour](#language-tour)
  - [Comments](#comments)
  - [Identifiers & Keywords](#identifiers--keywords)
  - [Types](#types)
  - [Variables](#variables)
  - [Operators & Precedence](#operators--precedence)
  - [Control Flow](#control-flow)
  - [Functions](#functions)
  - [Built-in `print`](#built-in-print)
  - [Statements & Blocks](#statements--blocks)
- [Grammar](#grammar)
- [Type Rules](#type-rules)
- [Out of Scope (v0.1)](#out-of-scope-v01)
- [Compiler Architecture](#compiler-architecture)
- [Test Programs](#test-programs)
- [Roadmap](#roadmap)
- [License](#license)

---

## Why SLANG?

SLANG is:

- **Statically typed** — no implicit conversions, ever.
- **Compiled** — down to a native executable via LLVM.
- **Imperative** — no functional or OOP baggage.
- **C-like, but deliberately simpler** — a handful of keywords, one grammar file.
- **A teaching vehicle for MLIR + LLVM** — the point is the pipeline, not the language.

There's no garbage collector, no classes, no generics, no pointers exposed to the programmer, and no exceptions. Every rule that isn't load-bearing for learning the compiler pipeline was cut, on purpose, so the project stays finishable.

## Quick Look

```rust
fn factorial(n: i32) -> i32 {
    let result: i32 = 1;
    let i: i32 = 1;

    while i <= n {
        result = result * i;
        i = i + 1;
    }

    return result;
}

fn main() -> i32 {
    let result: i32 = factorial(5);
    print(result);
    return 0;
}
```

---

## Language Tour

### Comments

Single-line only, for now:

```rust
// this is a comment
let x: i32 = 10; // trailing comment too
```

Block comments (`/* ... */`) are not part of v0.1.

### Identifiers & Keywords

```
identifier := letter (letter | digit | "_")*
```

An identifier may not start with a digit — `counter2` is valid, `1hello` is not.

Reserved keywords in v0.1:

```
fn  let  if  else  while  return  true  false  i32  bool
```

### Types

Three primitive types, no more:

| Type   | Meaning                     | Example                  |
|--------|------------------------------|---------------------------|
| `i32`  | Signed 32-bit integer         | `let x: i32 = 42;`        |
| `bool` | Boolean                       | `let ok: bool = true;`    |
| `void` | Function has no return value  | `fn log() -> void { ... }` |

`void` is not a value type — you can't declare `let x: void = ...;`.

### Variables

```rust
let x: i32 = 10;
let y: i32 = x + 5;
let flag: bool = true;
```

The type annotation is **required** — `let x = 10;` is invalid. There is no type inference in v0.1.

Declared variables can be reassigned, but assignment requires matching types:

```rust
let x: i32 = 10;
x = 20;      // ok
x = true;    // error: cannot assign bool to variable 'x' of type i32
```

Scope is lexical/block-based. A variable declared inside an `if` or `while` block does not exist outside it:

```rust
fn main() -> i32 {
    if true {
        let x: i32 = 10;
    }

    print(x); // ERROR — x is out of scope here
    return 0;
}
```

### Operators & Precedence

**Arithmetic** (`i32, i32 -> i32`): `+  -  *  /  %`

**Comparison** (`i32, i32 -> bool`): `==  !=  <  >  <=  >=`

**Boolean** (`bool, bool -> bool`, or `bool -> bool` for `!`): `&&  ||  !`

From highest to lowest precedence:

| Precedence | Operators       |
|------------|------------------|
| 1 (highest)| unary `-`, `!`   |
| 2          | `*` `/` `%`      |
| 3          | `+` `-`          |
| 4          | `<` `<=` `>` `>=`|
| 5          | `==` `!=`        |
| 6          | `&&`             |
| 7 (lowest) | `\|\|`             |

So `2 + 3 * 4` means `2 + (3 * 4)`, not `(2 + 3) * 4`. Parentheses override precedence as usual, and are also optional around `if`/`while` conditions:

```rust
if x > 10 { ... }
if (x > 10) { ... }   // also valid
```

### Control Flow

```rust
if x > 10 {
    print(1);
} else {
    print(2);
}

while x < 10 {
    print(x);
    x = x + 1;
}
```

Conditions must be `bool` — there is no C-style truthiness. `if 10 { ... }` is a type error.

`for`, `break`, and `continue` are intentionally absent from v0.1; a single `while` is enough to exercise control-flow lowering.

### Functions

```rust
fn add(a: i32, b: i32) -> i32 {
    return a + b;
}

fn say_hello() -> void {
    print(42);
    return;
}
```

Argument types must match parameter types exactly, and a function's `return` expression must match its declared return type — both are checked, not coerced.

### Built-in `print`

SLANG ships exactly one built-in, overloaded for its two value types:

```rust
print(i32);
print(bool);
```

Conceptually, `print(x)` lowers to a runtime call such as `slang_print_i32(x)` — a small, deliberate excuse to learn external function calls from LLVM IR.

### Statements & Blocks

Statements end in a semicolon; blocks don't:

```rust
let x: i32 = 10;   // statement — semicolon
x = 20;            // statement — semicolon
print(x);          // statement — semicolon
return x;          // statement — semicolon

if x > 10 {        // block — no semicolon
    print(x);
}
```

A block is just `{ statement* }`, reused identically for function bodies, `if` arms, and `while` bodies — one AST shape for all three.

---

## Grammar

```ebnf
program    ::= function* ;

function   ::= "fn" IDENT "(" parameters? ")" "->" type block ;
parameters ::= parameter ("," parameter)* ;
parameter  ::= IDENT ":" type ;
type       ::= "i32" | "bool" | "void" ;

block      ::= "{" statement* "}" ;

statement  ::= variable_declaration
             | assignment
             | if_statement
             | while_statement
             | return_statement
             | expression_statement
             | block ;

variable_declaration ::= "let" IDENT ":" type "=" expression ";" ;
assignment            ::= IDENT "=" expression ";" ;
if_statement          ::= "if" expression block ("else" block)? ;
while_statement       ::= "while" expression block ;
return_statement      ::= "return" expression? ";" ;
expression_statement  ::= expression ";" ;

expression     ::= logical_or ;
logical_or     ::= logical_and ("||" logical_and)* ;
logical_and    ::= equality ("&&" equality)* ;
equality       ::= comparison (("==" | "!=") comparison)* ;
comparison     ::= addition (("<" | ">" | "<=" | ">=") addition)* ;
addition       ::= multiplication (("+" | "-") multiplication)* ;
multiplication ::= unary (("*" | "/" | "%") unary)* ;
unary          ::= ("-" | "!") unary | primary ;

primary        ::= INTEGER | "true" | "false" | IDENT
                  | function_call | "(" expression ")" ;

function_call  ::= IDENT "(" arguments? ")" ;
arguments      ::= expression ("," expression)* ;
```

> Parser note: an `IDENT` immediately followed by `(` must be disambiguated as a function call rather than a variable reference.

---

## Type Rules

| Operation      | Input        | Result |
|----------------|--------------|--------|
| `+ - * / %`    | `i32, i32`   | `i32`  |
| `< > <= >=`    | `i32, i32`   | `bool` |
| `== !=`        | same type    | `bool` |
| `&& \|\|`       | `bool, bool` | `bool` |
| `!`            | `bool`       | `bool` |
| unary `-`      | `i32`        | `i32`  |

No implicit conversions exist anywhere in this table — every mismatch is a compile-time type error, reported with `file:line:column`, not a crash.

---

## Out of Scope (v0.1)

Left out on purpose, to keep the project finishable — not because any of these are bad ideas:

```
classes · structs · arrays · pointers · references · generics
interfaces · traits · enums · pattern matching · closures · lambdas
exceptions · modules · imports · macros · async · threads
garbage collection · operator overloading · type inference
implicit conversion · for-loops · break · continue
```

---

## Compiler Architecture

### Pipeline

```
SLANG source
   │  lexer
   ▼
tokens
   │  parser
   ▼
AST
   │  type checker (symbol table w/ nested scopes)
   ▼
typed AST
   │  codegen
   ▼
SLANG dialect (MLIR)
   │  lowering
   ▼
arith / scf dialects
   │  lowering
   ▼
LLVM dialect
   │  translation
   ▼
LLVM IR
   │  llc / JIT
   ▼
native executable
```

### Planned SLANG MLIR Dialect

Don't create the whole dialect on day one — start with just `slang.constant`, `slang.add`, and `slang.return`, get `return 10 + 20;` compiling end-to-end, then expand:

```
slang.constant   slang.add    slang.sub   slang.mul   slang.div   slang.rem
slang.cmp
slang.alloc      slang.load   slang.store
slang.call       slang.return
slang.if         slang.while
```

Milestone target for the first working slice:

```mlir
module {
  func.func @main() -> i32 {
    %0 = slang.constant 10 : i32
    %1 = slang.constant 20 : i32
    %2 = slang.add %0, %1 : i32
    return %2 : i32
  }
}
```

### Implementation Order

Recommended build order — each step should stay compilable before moving to the next:

1. Lexer
2. Integer literals
3. `+ - * /`
4. Parentheses
5. AST
6. `let`
7. Variables
8. Type checking
9. `== < > ...`
10. `if`
11. `while`
12. Functions
13. Function calls
14. `return`
15. `bool`
16. `print`
17. AST interpreter *(you have a working language here)*
18. SLANG MLIR dialect
19. SLANG → MLIR
20. MLIR lowering
21. MLIR → LLVM
22. Native executable *(you have a working compiler here)*

---

## Test Programs

<details>
<summary>10 acceptance programs — click to expand</summary>

**1. Hello integer**
```rust
fn main() -> i32 { return 42; }
```

**2. Arithmetic**
```rust
fn main() -> i32 { return 10 + 20 * 3; }
```

**3. Variables**
```rust
fn main() -> i32 {
    let x: i32 = 10;
    let y: i32 = 20;
    return x + y;
}
```

**4. Assignment**
```rust
fn main() -> i32 {
    let x: i32 = 10;
    x = x + 5;
    return x;
}
```

**5. If / else**
```rust
fn main() -> i32 {
    let x: i32 = 10;
    if x > 5 {
        return 1;
    } else {
        return 0;
    }
}
```

**6. While**
```rust
fn main() -> i32 {
    let x: i32 = 0;
    while x < 10 {
        x = x + 1;
    }
    return x;
}
```

**7. Function**
```rust
fn add(a: i32, b: i32) -> i32 {
    return a + b;
}

fn main() -> i32 {
    return add(10, 20);
}
```

**8. Boolean logic**
```rust
fn main() -> i32 {
    let x: i32 = 10;
    if x > 5 && x < 20 {
        return 1;
    }
    return 0;
}
```

**9. Nested control flow**
```rust
fn main() -> i32 {
    let x: i32 = 0;
    while x < 10 {
        if x == 5 {
            return x;
        }
        x = x + 1;
    }
    return -1;
}
```

**10. Factorial (full program)**
```rust
fn factorial(n: i32) -> i32 {
    let result: i32 = 1;
    let i: i32 = 1;
    while i <= n {
        result = result * i;
        i = i + 1;
    }
    return result;
}

fn main() -> i32 {
    let result: i32 = factorial(5);
    print(result);
    return 0;
}
```

</details>

If the compiler can build Test 10 into a native executable, that's v0.1, done.

---

## Roadmap

- [ ] Lexer + parser + AST
- [ ] Type checker with nested scopes
- [ ] Tree-walking interpreter (fast feedback loop before touching MLIR)
- [ ] `slang` MLIR dialect + SLANG → MLIR codegen
- [ ] Lowering: `slang` → `arith`/`scf` → `llvm`
- [ ] LLVM IR emission + native executable output
- [ ] All 10 test programs passing end-to-end

Anything from the [Out of Scope](#out-of-scope-v01) list — arrays, `for`/`break`/`continue`, structs, etc. — is a candidate for a future v0.2, once v0.1 is solid.

## License

Not yet chosen. Add a `LICENSE` file (MIT or Apache-2.0 are common defaults for small compiler projects) before making the repository public.
