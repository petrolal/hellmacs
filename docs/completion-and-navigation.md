# Completion & Code Intelligence

Hellmacs provides a modern, blazing-fast completion stack using modular built-ins and minimalist modern packages.

---

## 1. In-Buffer Autocomplete ([Corfu](https://github.com/minad/corfu) & [Cape](https://github.com/minad/cape))

Configured in [`modules/completion/corfu/`](file:///home/petrolal/hellmacs/modules/completion/corfu/config.el).

* **Automatic Completion Popups**: As you type (after 2 characters and 0.15s delay), a floating child frame appears with completion candidates.
* **Documentation Hover (`corfu-popupinfo`)**: Automatically displays Javadoc, signatures, and markdown documentation next to the selected candidate.
* **TAB Completion**: With `(corfu +tab)` in your `init.el`, `TAB` triggers and cycles through completions. Stock Emacs `C-M-i` (`complete-at-point`) is always available.
* **Cape Fallback Extensions**: Provides fallback completion sources for file paths and open buffers.

---

## 2. Minibuffer Completion ([Vertico](https://github.com/minad/vertico) + [Consult](https://github.com/minad/consult) + [Orderless](https://github.com/oantolin/orderless))

Configured in [`modules/completion/vertico/`](file:///home/petrolal/hellmacs/modules/completion/vertico/config.el).

* **Vertical Minibuffer**: Clean, vertical list UI for finding files, buffers, commands, and project symbols.
* **Orderless Matching**: Search with space-separated tokens in any order (e.g. `user contr test` matches `UserControllerTest.java`).
* **Marginalia Annotations**: Adds rich metadata to minibuffer lists (file sizes, docstrings, keybindings, timestamps).

### Minibuffer Navigation Shortcuts
| Key | Command | Description |
|---|---|---|
| `C-c f f` / `C-x C-f` | `find-file` | Open or find a file |
| `C-c f r` | `consult-recent-file` | Search recently opened files |
| `C-c b b` / `C-x b` | `consult-buffer` | Switch buffer with previews |
| `C-c s s` | `consult-line` | Interactive search for lines in current buffer |
| `C-c s p` / `C-c h f` | `consult-ripgrep` | Blazing-fast regex search across the entire project |
| `C-c s i` | `consult-imenu` | Jump to functions/methods/symbols in current buffer |

---

## 3. LSP Semantic Intelligence & Navigation

Configured in [`modules/tools/lsp/`](file:///home/petrolal/hellmacs/modules/tools/lsp/config.el).

### Code Navigation
| Key | Action | Description |
|---|---|---|
| `M-.` | Go to Definition | Jump to symbol definition (decompiles bytecode for 3rd-party JARs) |
| `M-?` | Find References | List all usages across the workspace |
| `M-,` | Pop Tag / Back | Jump back to where you were before `M-.` |
| `C-M-.` | Workspace Symbols | Search classes, methods, and symbols across the entire project |
| `C-c l g d` | Type Definition | Jump to the declaration of the type |
| `C-c l g i` | Implementation | Jump to interface implementations |

### Refactoring & Code Actions
| Key | Action | Description |
|---|---|---|
| `C-c l a a` | Code Actions | Quick fixes, generate methods, missing imports, etc. |
| `C-c l r r` | Rename | Semantic, workspace-wide symbol rename |
| `C-c l r o` | Organize Imports | Optimize and clean up unused imports |
| `C-c l = =` | Format Buffer | Format according to project / language server formatter |

### Diagnostics & Errors
* Real-time errors and warnings are highlighted in the buffer.
* `C-c ! n`: Jump to next diagnostic error/warning.
* `C-c ! p`: Jump to previous diagnostic error/warning.
* `C-c ! l`: List all diagnostics in a project/buffer summary.
