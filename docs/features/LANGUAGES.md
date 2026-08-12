# Languages

Keyword-level highlighting for 31 built-in programming languages, how the
plugin decides which one applies to a given block, and how to add your own
without forking the plugin.

## Built-in language keyword sets

31 predefined languages ship as `languages/*.lua` files, each a `{ words,
unique_words?, hl }` definition: C, C++, C#, Lua, Go, Rust, TypeScript,
JavaScript, Python, Bash, Zig, LLVM IR, Vimscript, Java, PHP, Ruby, Kotlin,
Swift, Scala, Dart, Elixir, Haskell, Perl, R, Clojure, Groovy, PowerShell,
SQL, JSON, HTML, CSS. `words` are highlighted whenever the language is
active for a block; `unique_words` are the subset used to drive automatic
detection (below).

- **Module:** `languages/*.lua`
- **Config:** `opts.enable_keywords` (default `true`)

## Automatic language detection

When a block has no explicit language marker, the plugin counts
`unique_words` matches per language and picks the best match once it clears
`language_detection_threshold` — lower is more lenient, higher is stricter.
Priority order: explicit marker (`` ```ascii-c ``, a standard fence tag in
`fence_language_map`) beats heuristic detection, which beats the fallback of
the buffer's own filetype.

- **Config:** `opts.enable_language_detection` (default `true`), `opts.language_detection_threshold` (default `2`)

## Standard fence-tag support

Every built-in language is recognized under its common markdown fence tag(s)
by default — not just the `` ```ascii-<lang> `` form — so a plain `` ```go ``,
`` ```js ``/`` ```javascript ``, `` ```py ``/`` ```python ``, etc. block is
highlighted automatically. Add your own tag (or override a default one) via
`fence_language_map`.

- **Config:** `opts.fence_language_map` (see `config/DEFAULTS.lua` for the full default map, including aliases like `sh`/`ts`/`rs`/`kt`/`cs`)

## Custom language definitions

`config.languages` is the extension point for adding a language from
`setup()` — same `{ words, unique_words?, hl }` shape as the built-in files,
no `languages/*.lua` file needed. A name reused from a built-in language
(e.g. `lua`) replaces that language's entry wholesale, not a field-by-field
merge; a malformed entry (missing `words`/`hl`) is skipped with a warning
instead of breaking keyword-lookup construction for the rest. Calling
`setup()` again — e.g. from a keymap after editing a `languages` entry —
re-highlights every already-open, plugin-managed buffer immediately, so an
added or edited language takes effect without touching the buffer or
restarting Neovim. There is no file-watcher for an external language
definition file; re-running `setup()` is the whole reload mechanism.

- **Module:** `config/init.lua` (`merge_user_languages`)
- **Config:** `opts.languages`
- **Tests:** `TESTS/config_languages_spec.lua`
