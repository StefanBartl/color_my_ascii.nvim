# Guides

Long-form manuals for individual features — one file each, written as a
walkthrough rather than a catalogue entry.

These predate the themed catalogue in [`../FEATURES/`](../FEATURES/) and were
the material it was written from. They live here rather than inside that folder
because they are not theme files: each one is a manual *about* a single
feature, and a parser reading `##` headings as features counted the seven of
them as 102 separate features instead of seven.

| Guide | Covers |
| --- | --- |
| [group-configuration.md](group-configuration.md) | Character groups — defining them, the matching order, and the overrides that beat them |
| [keyword-configuration.md](keyword-configuration.md) | Keyword highlighting: exact words, patterns, and per-language sets |
| [function-detection.md](function-detection.md) | How a function name is recognized inside a fence, and how to tune it |
| [bracket-highlighting.md](bracket-highlighting.md) | Bracket pairs, nesting depth, and the colors per level |
| [inline-code.md](inline-code.md) | Backtick spans inside prose, outside any fence |
| [custom-colors.md](custom-colors.md) | Building a palette by hand instead of taking a scheme |
| [custom-highlights.md](custom-highlights.md) | Per-character and per-pattern overrides on top of everything else |

> **Cross-references, repaired 2026-09-04.** Several of these pointed at files
> from an older layout that no longer exist (`./language-detection.md`,
> `../groups/operators.md`, `../color-schemes.md`, `../performance.md`). Each
> now points at the document that took the subject over — detection at
> [`../FEATURES/LANGUAGES.md`](../FEATURES/LANGUAGES.md), schemes at
> [`../schemes.md`](../schemes.md), performance at
> [`../troubleshooting.md`](../troubleshooting.md).
