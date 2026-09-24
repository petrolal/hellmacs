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

5. **Testing Invariant**:
   * After any change to core engine or modules, ALWAYS run `./bin/hellmacs test` and `./bin/hellmacs doctor` to verify 100% test pass rate.
   * Maintain the sub-0.12s startup speed budget.
