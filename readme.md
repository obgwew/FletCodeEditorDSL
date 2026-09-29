# flet-code-editor-dsl

> A real Flutter code editor exposed as a [Flet](https://flet.dev) control, with a small Python DSL for defining syntax-highlighting rules and bracket/quote pair matching.

![Python](https://img.shields.io/badge/python-%3E%3D3.10-blue)
![Flet](https://img.shields.io/badge/flet-%3E%3D0.80-informational)
![Version](https://img.shields.io/badge/version-0.1.0-green)
![License](https://img.shields.io/badge/license-Apache%202.0-blue)

---

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Requirements](#requirements)
4. [Installation](#installation)
   - [Install directly from GitHub with pip](#option-1-install-directly-from-github-with-pip)
   - [Use in a Flet app (`pyproject.toml`)](#option-2-declare-it-as-a-dependency-in-your-flet-app)
   - [Pin to a branch, tag or commit](#pinning-a-version)
   - [Local / editable install](#option-3-local-editable-install)
5. [Quick Start](#quick-start)
6. [API Reference](#api-reference)
   - [`CodeEditor`](#codeeditor)
   - [`rule()`](#rule)
   - [`group()`](#group)
   - [`pair()`](#pair)
   - [`rules_json()` and `pairs_json()`](#rules_json-and-pairs_json)
7. [How the Highlighting Engine Works](#how-the-highlighting-engine-works)
8. [Controlling the Editor at Runtime](#controlling-the-editor-at-runtime)
9. [Complete Example](#complete-example)
10. [Building Your App](#building-your-app)
11. [Project Structure](#project-structure)
12. [Known Limitations](#known-limitations)
13. [Troubleshooting](#troubleshooting)
14. [Contributing](#contributing)
15. [License](#license)

---

## Overview

`flet-code-editor-dsl` is a Flet extension that embeds a multi-line code editor built on Flutter's `TextField`. Instead of shipping a fixed set of language grammars, it provides a compact **DSL** (domain-specific language) in Python that lets you describe exactly how text should be colored:

- **Rules** — regular expressions mapped to colors, with optional context conditions (`before`, `after`, `ignore_if`).
- **Pairs** — matching delimiters (brackets, quotes, tags) with distinct colors for matched and unmatched occurrences.
- **Strict mode** — any text not covered by a rule can be flagged as an error.

This makes it well suited for custom languages, configuration formats, templating syntaxes, and educational tools.

## Features

- Native Flutter rendering through the Flet extension mechanism.
- Declarative highlighting rules defined entirely from Python.
- Context-aware matching using look-behind (`before`), look-ahead (`after`) and exclusion (`ignore_if`) patterns.
- Grouped rules: several patterns sharing a single color.
- Bracket and quote pair matching, including nesting and unmatched-delimiter detection.
- Strict mode that paints unrecognized text with an error color.
- Configurable font family, font size and background color.
- `on_change` event for reading the current text.
- Inherits standard layout properties from `ft.LayoutControl` (`width`, `height`, `expand`, `margin`, etc.).

## Requirements

| Component | Version |
|-----------|---------|
| Python    | `>= 3.10` |
| Flet      | `>= 0.80` (the Flutter side depends on `flet: ^0.80.0`) |
| Dart SDK  | `>= 3.0.0 < 4.0.0` |
| Flutter   | `>= 3.10.0` |
| Git       | Required for installing from GitHub |

> **Note:** Because this package contains a Flutter extension, it only takes effect when your app is packaged with `flet build` (or run with a Flet client that includes the extension). See [Building Your App](#building-your-app).

---

## Installation

### Option 1: Install directly from GitHub with pip

```bash
pip install "git+https://github.com/obgwew/flet-code-editor-dsl.git"
```

Or, using the explicit direct-reference form:

```bash
pip install "flet-code-editor-dsl @ git+https://github.com/obgwew/flet-code-editor-dsl.git"
```

### Option 2: Declare it as a dependency in your Flet app

Add the package to the `dependencies` of your app's `pyproject.toml`:

```toml
[project]
name = "my-flet-app"
version = "0.1.0"
requires-python = ">=3.10"
dependencies = [
  "flet",
  "flet-code-editor-dsl @ git+https://github.com/obgwew/flet-code-editor-dsl.git",
]
```

Then install and run as usual:

```bash
pip install -e .
flet run
```

If you use a `requirements.txt` instead:

```text
flet
git+https://github.com/obgwew/flet-code-editor-dsl.git
```

### Pinning a version

Append `@<ref>` to the URL, where `<ref>` is a branch, tag, or commit hash:

```bash
# Branch
pip install "git+https://github.com/obgwew/flet-code-editor-dsl.git@main"

# Tag
pip install "git+https://github.com/obgwew/flet-code-editor-dsl.git@v0.1.0"

# Commit
pip install "git+https://github.com/obgwew/flet-code-editor-dsl.git@<commit-sha>"
```

Pinning to a tag or commit is strongly recommended for reproducible builds.

### Option 3: Local editable install

```bash
git clone https://github.com/obgwew/flet-code-editor-dsl.git
cd flet-code-editor-dsl
pip install -e .
```

### Verifying the installation

```bash
python -c "import flet_code_editor_dsl as m; print(m.__all__)"
```

Expected output:

```text
['CodeEditor', 'rule', 'group', 'pair', 'rules_json', 'pairs_json']
```

---

## Quick Start

```python
import flet as ft
import flet_code_editor_dsl as ce


def main(page: ft.Page):
    page.title = "Code Editor"

    editor = ce.CodeEditor(
        value="let x = (1 + 2)",
        rules=ce.rules_json([
            ce.group(["let", "if", "else"], color="#C586C0"),   # keywords
            ce.rule(r"\d+", color="#B5CEA8"),                    # numbers
        ]),
        pairs=ce.pairs_json([
            ce.pair("(", ")", color="#FFD700"),
        ]),
        default_color="#D4D4D4",
        background_color="#1E1E1E",
        expand=True,
    )

    page.add(editor)


ft.run(main)
```

> On Flet versions that still use the older entry point, replace `ft.run(main)` with `ft.app(main)`.

---

## API Reference

All public names are importable from the top-level package:

```python
from flet_code_editor_dsl import CodeEditor, rule, group, pair, rules_json, pairs_json
```

### `CodeEditor`

```python
@ft.control("flet_code_editor_dsl")
class CodeEditor(ft.LayoutControl): ...
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `value` | `str` | `""` | The text shown in the editor. Setting it from Python replaces the editor content. |
| `rules` | `str` (JSON) | `"[]"` | Highlighting rules. Build it with `rules_json([...])`. |
| `pairs` | `str` (JSON) | `"[]"` | Delimiter pairs. Build it with `pairs_json([...])`. |
| `default_color` | `str` | `"#000000"` | Color for text not matched by any rule (when `strict` is `False`). |
| `strict` | `bool` | `False` | If `True`, unmatched text is painted with `error_color` instead of `default_color`. |
| `error_color` | `str` | `"#FF0000"` | Color used for unrecognized text in strict mode. |
| `background_color` | `ft.ColorValue \| None` | `None` | Editor background. When `None`, the Flutter side falls back to `#202124`. |
| `font_family` | `str` | `"monospace"` | Font family used by the editor. |
| `font_size` | `float` | `14.0` | Font size in logical pixels. |
| `on_change` | `ft.ControlEventHandler \| None` | `None` | Called whenever the text changes. The new text is available as `e.data`. |

In addition, all `ft.LayoutControl` properties (such as `width`, `height`, `expand`, `margin`, `visible`, `opacity`) are supported.

> **Tip:** The default `default_color` is black (`#000000`) while the default background is dark. Always set `default_color` explicitly (for example `"#D4D4D4"`) when using a dark theme.

#### Color format

Colors are strings in one of these forms:

| Format | Example | Meaning |
|--------|---------|---------|
| `#RRGGBB` | `#FF8800` | Opaque color (alpha `FF` is added automatically). |
| `#AARRGGBB` | `#80FF8800` | Color with explicit alpha channel. |

Invalid values fall back to a default color instead of raising an error.

---

### `rule()`

Creates a single highlighting rule.

```python
rule(
    form: str,
    color: str,
    before: Optional[str] = None,
    after: Optional[str] = None,
    ignore_if: Optional[str] = None,
) -> dict
```

| Parameter | Description |
|-----------|-------------|
| `form` | Regular expression that selects the text to color. |
| `color` | Color applied to every match. |
| `before` | Regex that must match **immediately before** the match (it is anchored to the end of the preceding text). If it does not match, the occurrence is skipped. |
| `after` | Regex that must match **immediately after** the match (anchored to the start of the following text). |
| `ignore_if` | Regex tested at the **start of the match**. If it matches, the occurrence is skipped. |

```python
# Highlight identifiers that directly follow "def "
ce.rule(r"[A-Za-z_]\w*", color="#DCDCAA", before=r"def\s+")

# Highlight names followed by "(" as function calls
ce.rule(r"[A-Za-z_]\w*", color="#DCDCAA", after=r"\(")

# Highlight words, but skip the keyword "let"
ce.rule(r"[A-Za-z_]\w*", color="#9CDCFE", ignore_if=r"let\b")
```

### `group()`

Creates a rule that applies **one color to several patterns**. The patterns are combined into a single alternation.

```python
group(
    forms: list[str],
    color: str,
    before: Optional[str] = None,
    after: Optional[str] = None,
    ignore_if: Optional[str] = None,
) -> dict
```

```python
ce.group([r"\bif\b", r"\belse\b", r"\bwhile\b", r"\breturn\b"], color="#C586C0")
```

### `pair()`

Defines a pair of delimiters that are matched against each other.

```python
pair(
    open: str,
    close: str,
    color: Optional[str] = None,
    unmatched_color: str = "#FF0000",
) -> dict
```

| Parameter | Description |
|-----------|-------------|
| `open` | Opening delimiter (a **literal string**, not a regex). |
| `close` | Closing delimiter (a literal string). |
| `color` | Color for correctly matched delimiters. If `None`, matched delimiters keep the color assigned by rules. |
| `unmatched_color` | Color for delimiters that have no partner. Defaults to red. |

Behavior:

- When `open != close` (e.g. `(` and `)`), delimiters are matched using a stack, so nesting is supported. An unmatched closer, or an opener left on the stack, is painted with `unmatched_color`.
- When `open == close` (e.g. `"` and `"`), occurrences are counted in order. If the total count is odd, the **last** one is treated as unmatched.

```python
ce.pair("(", ")", color="#FFD700")
ce.pair("[", "]", color="#DA70D6")
ce.pair("{", "}", color="#179FFF")
ce.pair('"', '"', color="#CE9178", unmatched_color="#FF5555")
```

### `rules_json()` and `pairs_json()`

Serialize a list of rules or pairs into the compact JSON string expected by `CodeEditor.rules` and `CodeEditor.pairs`.

```python
rules_json(rules: Iterable[dict]) -> str
pairs_json(pairs: Iterable[dict]) -> str
```

```python
editor.rules = ce.rules_json([ce.rule(r"\d+", "#B5CEA8")])
editor.pairs = ce.pairs_json([ce.pair("(", ")", "#FFD700")])
```

---

## How the Highlighting Engine Works

Understanding the evaluation order helps you write predictable rules.

1. **Rule pass** — Rules are applied in the order they appear in the list. Each match paints its characters with the rule's color. **Later rules override earlier ones** where matches overlap.
2. **Context checks** — For every match, `before`, `after` and `ignore_if` are evaluated. If a check fails, that match is ignored.
3. **Fallback pass** — Characters not covered by any rule receive `default_color`, or `error_color` if `strict=True`.
4. **Pair pass** — Pair matching runs last and **overrides** the colors of delimiter characters. This ensures unmatched delimiters are always visible.

**Practical consequences**

- Put general rules first (identifiers, words) and specific rules last (keywords, literals).
- Regular expressions use the **Dart `RegExp`** engine (ECMAScript-style), not Python's `re`. Most common syntax is identical, but avoid Python-only constructs such as `(?P<name>...)` — use `(?<name>...)` instead.
- Patterns that fail to compile are silently skipped, so test new patterns incrementally.
- Use raw strings (`r"..."`) in Python to avoid double escaping.

---

## Controlling the Editor at Runtime

### Reading the text

```python
def on_change(e: ft.ControlEvent):
    print("Current text:", e.data)

editor = ce.CodeEditor(on_change=on_change)
```

### Setting the text

```python
editor.value = "new content"
editor.update()
```

### Updating rules or pairs dynamically

```python
editor.rules = ce.rules_json([
    ce.rule(r"\bTODO\b", "#FFCC00"),
])
editor.update()
```

### Switching strict mode

```python
editor.strict = True
editor.error_color = "#FF5555"
editor.update()
```

### Changing appearance

```python
editor.font_size = 16
editor.font_family = "Courier New"
editor.background_color = "#0D1117"
editor.update()
```

### Layout

```python
ce.CodeEditor(width=600, height=400)   # fixed size
ce.CodeEditor(expand=True)             # fill available space
```

---

## Complete Example

A live-validating editor for a tiny expression language. Keywords, numbers, strings and comments are colored, brackets are matched, and anything unrecognized is flagged as an error.

```python
import flet as ft
import flet_code_editor_dsl as ce

SAMPLE = '''\
# Example program
let total = (price * 3) + 12
if (total > 100) {
    print("expensive")
} else {
    print("cheap")
}
'''

RULES = ce.rules_json([
    # Identifiers (general rule first)
    ce.rule(r"[A-Za-z_]\w*", "#9CDCFE"),

    # Function calls: a name followed by "("
    ce.rule(r"[A-Za-z_]\w*", "#DCDCAA", after=r"\("),

    # Keywords
    ce.group([r"\blet\b", r"\bif\b", r"\belse\b"], "#C586C0"),

    # Numbers
    ce.rule(r"\b\d+(?:\.\d+)?\b", "#B5CEA8"),

    # Operators and whitespace (so strict mode does not flag them)
    ce.group([r"[+\-*/=<>!]+", r"\s+", r"[(){}\[\],;]"], "#D4D4D4"),

    # Strings
    ce.rule(r'"[^"\n]*"', "#CE9178"),

    # Comments (last, so they override everything on the line)
    ce.rule(r"#.*", "#6A9955"),
])

PAIRS = ce.pairs_json([
    ce.pair("(", ")", color="#FFD700"),
    ce.pair("{", "}", color="#179FFF"),
    ce.pair("[", "]", color="#DA70D6"),
])


def main(page: ft.Page):
    page.title = "flet-code-editor-dsl demo"
    page.theme_mode = ft.ThemeMode.DARK

    status = ft.Text("Characters: %d" % len(SAMPLE))

    def on_change(e: ft.ControlEvent):
        status.value = "Characters: %d" % len(e.data or "")
        status.update()

    def toggle_strict(e: ft.ControlEvent):
        editor.strict = e.control.value
        editor.update()

    editor = ce.CodeEditor(
        value=SAMPLE,
        rules=RULES,
        pairs=PAIRS,
        default_color="#D4D4D4",
        strict=False,
        error_color="#F44747",
        background_color="#1E1E1E",
        font_family="monospace",
        font_size=15,
        expand=True,
        on_change=on_change,
    )

    page.add(
        ft.Row([ft.Switch(label="Strict mode", on_change=toggle_strict), status]),
        editor,
    )


ft.run(main)
```

---

## Building Your App

Flutter extensions are compiled into the Flet client, so you must build a custom client for your target platform. Make sure the package is listed in your app's `pyproject.toml` dependencies (see [Installation](#option-2-declare-it-as-a-dependency-in-your-flet-app)), then run:

```bash
# Desktop
flet build windows
flet build macos
flet build linux

# Mobile
flet build apk
flet build ipa

# Web
flet build web
```

`flet build` detects the Flutter package bundled inside `flutter/flet_code_editor_dsl/` and adds it to the generated Flutter project automatically. A working Flutter SDK is required; Flet will download one if it is missing.

---

## Project Structure

```text
flet-code-editor-dsl/
├── pyproject.toml
└── src/
    ├── flet_code_editor_dsl/
    │   └── __init__.py                     # Python API: CodeEditor + DSL helpers
    └── flutter/
        ├── __init__.py
        └── flet_code_editor_dsl/
            ├── __init__.py
            ├── pubspec.yaml                # Flutter package definition
            └── lib/
                ├── flet_code_editor_dsl.dart
                └── src/
                    ├── extension.dart      # Registers the control with Flet
                    └── code_editor.dart    # Editor widget + highlighting engine
```

| File | Responsibility |
|------|----------------|
| `src/flet_code_editor_dsl/__init__.py` | Declares `CodeEditor` and the `rule` / `group` / `pair` helpers. |
| `.../lib/src/extension.dart` | Maps the control type `flet_code_editor_dsl` to the Flutter widget. |
| `.../lib/src/code_editor.dart` | Custom `TextEditingController` that builds colored `TextSpan`s from rules and pairs. |
| `pyproject.toml` | Packaging metadata; includes `pubspec.yaml` and `lib/**/*` as package data. |

---

## Known Limitations

- **No language awareness in pairs.** Delimiters inside strings or comments are still matched. Use `ignore_if` or rule ordering to reduce false positives, or avoid pairing characters that appear inside literals.
- **Highlighting is recomputed on each rebuild.** Very large documents with many rules may reduce typing performance.
- **Plain text editing only.** Line numbers, code folding, auto-indent and autocompletion are not included.
- **Dart regex semantics.** Patterns must be valid for Dart's `RegExp`; invalid patterns are ignored without an error message.
- **Client rebuild required.** As with all Flet extensions, the control is not available in the stock Flet client.
- **Minimum height.** The editor shows at least 12 lines.

## Troubleshooting

| Symptom | Likely cause and fix |
|---------|----------------------|
| The editor does not appear, or an "unknown control" error is shown | The app is running with a stock Flet client. Build with `flet build`, or ensure the extension is registered in your custom client. |
| Text is hard to see | `default_color` defaults to black while the background is dark. Set `default_color` (for example `#D4D4D4`) or change `background_color`. |
| A rule has no effect | Its regex may be invalid for Dart, or a later rule overrides it. Simplify the pattern and check rule order. |
| Everything is red | `strict=True` is set and some text is not covered by any rule. Add rules for whitespace, operators and punctuation, or disable strict mode. |
| `pip install` from GitHub fails | Confirm Git is installed, the URL is correct, and (for private repositories) that you are authenticated via SSH or a personal access token. |
| Changes made from Python are not visible | Call `editor.update()` after modifying a property. |

For private repositories, authenticate with a token:

```bash
pip install "git+https://<TOKEN>@github.com/obgwew/flet-code-editor-dsl.git"
```

## Contributing

Contributions are welcome.

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/my-feature`.
3. Commit your changes with clear messages.
4. Push the branch and open a Pull Request describing the change and its motivation.

Please open an issue first for larger changes or new features so the design can be discussed.

## License

This project is licensed under the **Apache License, Version 2.0**. See the [LICENSE](LICENSE) file for the full text.

```text
Copyright 2026 obgwew

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

By contributing to this repository, you agree that your contributions will be licensed under the same Apache 2.0 license.