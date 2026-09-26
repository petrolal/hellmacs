# AI Agent Context Primer & Operational Invariants

> **IMPORTANT**: AI Agents, LLM assistants, and automated tools working on this codebase must ingest and follow the directives below.

---

## 1. Persona & Codebase Context

* **Project**: Hellmacs (Enterprise JVM Emacs Distribution).
* **Language/Stack**: Emacs Lisp (lexical-binding: t), Bash, Java/Kotlin/Clojure toolchains, Tree-sitter C grammars.
* **Core Philosophy**: Stock Emacs keybindings (NEVER assume Evil/Vim bindings), JVM-first priority, pure XDG state isolation, sub-0.12s startup budget.

---

## 2. Inviolable Directives for AI Agents

1. **The 40-Year Purist Guarantee (No Modal / Evil Keybindings)**:
   * All keybinding proposals and bindings MUST use standard GNU Emacs conventions (`C-c`, `C-x`, `M-x`, `M-.`, `C-s`, `dired`, etc.).
   * Never introduce Vim/Evil modal states or single-letter key hijackings that break lifelong Emacs muscle memory.
   * Hellmacs leader shortcuts belong strictly under `C-c` (`C-c h`, `C-c f`, `C-c b`, `C-c s`, `C-c d`, `C-c l`, `C-c w`, `C-c q`).

2. **Preserve Vanilla Discoverability & GNU Standards**:
   * Preserve all built-in GNU Emacs help mechanisms (`C-h t` tutorial, `C-h i` Info manual, `C-h r`, `C-h f`, `C-h v`, `C-h k`).
   * New documentation and help features must integrate cleanly with the Info manual subsystem (`docs/hellmacs.texi`).

3. **Preserve XDG Directory Isolation**:
   * Never hardcode paths to `~/.emacs.d` or write runtime state to `$HOME`.
   * Use `hellmacs-state-file`, `hellmacs-cache-dir`, and `hellmacs-data-dir`.

4. **Package Declarations**:
   * Do not use raw `package-install` or `straight-use-package`.
   * Declare dependencies via `(package! <name>)` in `packages.el` and let `bin/hellmacs sync` / Elpaca manage them.

5. **Strict Test-Driven Development (TDD) Invariant**:
   * **Write Tests First**: For every new phase, feature, or bugfix, write failing ERT unit and integration tests *before* writing the production code (RED).
   * Tests must assert against the target function APIs, data contracts, and behaviors directly without placeholder/mock self-implementations in the test body.
   * Next, implement the minimal production code to satisfy the tests (GREEN).
   * Refactor, byte-compile, and verify that `./bin/hellmacs test` and `./bin/hellmacs doctor` pass completely.
   * Maintain the sub-0.12s startup speed budget.

6. **Work Order & Progress Tracking**:
   * Pick up roadmap work in the order given by [`work-order.md`](work-order.md) (the first unchecked item in the lowest step), unless the user asks for something else.
   * When you finish and verify an item, tick it there (`- [x]`, with the date and a short note) and tick the matching checkbox in `docs/roadmap.md`. Mark partial work `- [/]` and say what's left.
