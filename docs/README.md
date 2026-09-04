# color_my_ascii.nvim documentation

What is here, and which question each page answers. [The README](../README.md) is the
short version of all of it; `:help color_my_ascii` is the same ground offline.

## Getting it running

| Page | Answers |
| --- | --- |
| [QUICKSTART.md](QUICKSTART.md) | Installation with lazy.nvim and packer.nvim, the first coloured block, and the handful of settings most people change first |
| [configuration.md](configuration.md) | Every option `setup()` takes, with its default: the treesitter overlay, colour schemes, custom highlights, fence-line and fence-content painting, and ASCII in code comments |
| [troubleshooting.md](troubleshooting.md) | Nothing is coloured, the wrong language was detected, characters shift while typing — and what the plugin costs on a large buffer |

## Using it

| Page | Answers |
| --- | --- |
| [WORKFLOW.md](WORKFLOW.md) | How the pieces combine day to day: which of the two fence spellings to use, when treesitter decides a block boundary and when the heuristic does, and which `:Fence` subcommand fits the task |
| [commands.md](commands.md) | Every `:ColorMyAscii` route and every `:Fence` action, with arguments |
| [BINDINGS.md](BINDINGS.md) | Every command, keymap, autocommand and highlight group this plugin installs, in one compact table |
| [languages.md](languages.md) | The 31 built-in languages, which fence tags reach them, and how to add one without a fork |
| [schemes.md](schemes.md) | The built-in colour schemes, how to modify one, and how to write your own |
| [api.md](api.md) | The two public APIs: fenced-block detection, and reading the applied highlighting back out as data |

## Why it is the way it is

| Page | Answers |
| --- | --- |
| [FEATURES/](FEATURES/README.md) | The feature catalogue, grouped by theme — painting, languages, fences, schemes, tools |
| [guides/](guides/README.md) | One long-form manual per feature: character groups, keywords, function detection, brackets, inline code, custom colours, custom highlights. The material the catalogue was written from |
| [contributing.md](contributing.md) | The dev setup (stylua, luacheck, CI), and what adding a language or a character group actually touches |
| [CHANGELOG.md](CHANGELOG.md) | What changed between versions, and the migration notes for the changes that need them |

## Not here

**The fixture.** [`TESTS/FIXTURE.md`](../TESTS/FIXTURE.md) is a markdown file that
exercises every feature at once, with [`TESTS/FIXTURE-CONFIG.md`](../TESTS/FIXTURE-CONFIG.md)
to turn them all on. It lives with the specs because it is one — the manual half,
for the things a headless run cannot see.

**The roadmap and the feature log.** What is not built yet, and when each shipped
feature landed, answer a question the author has rather than one a reader of this
plugin has. `git log` has the second one either way. Both live outside the repository.

**`docs/map/`.** `:DocMap` builds a browsable module map there. It is generated and
gitignored, so it is not in the checkout — run it when you want it.
