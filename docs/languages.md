# Supported Languages

The plugin includes predefined keyword definitions for 31 languages, plus
standard markdown fence-tag detection for each.

## Table of content

  - [Language Table](#language-table)
  - [Standard Fence Tag Support](#standard-fence-tag-support)

---

## Language Table

| Language | Unique Keywords | Example |
|----------|----------------|---------|
| C | `restrict`, `_Bool`, `_Complex` | `int`, `void`, `char` |
| C++ | `class`, `namespace`, `template` | `virtual`, `override`, `nullptr` |
| C# | `foreach`, `delegate`, `sealed` | `class`, `async`, `await` |
| Lua | `then`, `elseif`, `end` | `function`, `local`, `nil` |
| Go | `func`, `chan`, `defer` | `go`, `:=`, `<-` |
| Rust | `fn`, `mut`, `impl` | `trait`, `match`, `loop` |
| TypeScript | `interface`, `namespace` | `async`, `await`, `Promise` |
| JavaScript | `console`, `NaN`, `globalThis` | `function`, `async`, `await` |
| Python | `def`, `elif`, `pass` | `lambda`, `self`, `yield` |
| Bash | `fi`, `esac`, `done` | `if`, `then`, `else` |
| Zig | `comptime`, `errdefer` | `anytype`, `unreachable` |
| LLVM IR | `getelementptr`, `phi` | `alloca`, `icmp`, `zext` |
| Vimscript | `endif`, `endfunction`, `nnoremap` | `augroup`, `echom`, `setlocal` |
| Java | `implements`, `throws`, `synchronized` | `class`, `public`, `static` |
| PHP | `echo`, `require_once`, `isset` | `function`, `class`, `foreach` |
| Ruby | `elsif`, `unless`, `attr_accessor` | `def`, `end`, `module` |
| Kotlin | `fun`, `companion`, `suspend` | `val`, `var`, `class` |
| Swift | `guard`, `fileprivate`, `deinit` | `func`, `var`, `let` |
| Scala | `trait`, `implicit`, `object` | `def`, `val`, `case` |
| Dart | `mixin`, `covariant`, `late` | `void`, `class`, `async` |
| Elixir | `defmodule`, `defp`, `defmacro` | `def`, `do`, `end` |
| Haskell | `newtype`, `deriving`, `Maybe` | `data`, `type`, `where` |
| Perl | `bless`, `wantarray`, `qw` | `my`, `sub`, `if` |
| R | `sapply`, `lapply`, `ifelse` | `function`, `TRUE`, `FALSE` |
| Clojure | `defn`, `recur`, `deref` | `let`, `fn`, `def` |
| Groovy | `println`, `findAll`, `GString` | `def`, `class`, `closure` |
| PowerShell | `param`, `trap` | `function`, `foreach`, `try` |
| SQL | `SELECT`, `INSERT`, `JOIN` | `WHERE`, `FROM`, `UPDATE` |
| JSON | *(none - explicit tag only)* | `true`, `false`, `null` |
| HTML | `DOCTYPE`, `textarea`, `thead` | `div`, `span`, `class` |
| CSS | `keyframes`, `rgba`, `important` | `display`, `flex`, `color` |

---

## Standard Fence Tag Support

Blocks with a standard markdown fence language tag are automatically
highlighted when that tag is listed in `fence_language_map` - this includes
**every language above under its common tag(s)** by default (e.g. ` ```go `,
` ```js `/` ```javascript `, ` ```py `/` ```python `, ` ```rb `/` ```ruby `, ...),
not just the `ascii`-prefixed formats:

````markdown
```vim
function! MyFunc()
  ┌──────────────────────────┐
  │  nnoremap <leader>w :w<CR>│
  └──────────────────────────┘
endfunction
```
````

See [config/DEFAULTS.lua](../lua/color_my_ascii/config/DEFAULTS.lua) for the
full default map (aliases like `sh`/`py`/`ts`/`rs`/`kt`/`cs` included). Add or
override entries in your own setup:

````lua
require('color_my_ascii').setup({
  fence_language_map = {
    myasciitag = 'python',  -- add a custom tag on top of the defaults
  },
})
````

Additional languages can be easily added (see [Contributing](contributing.md)).

---

## See Also

- [../README.md](../README.md) — project overview and quickstart
- [Configuration](configuration.md) — full `setup()` reference
- [Contributing](contributing.md) — how to add a new language
