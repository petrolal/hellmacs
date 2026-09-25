# Module System Specification & API Contracts

## 1. Module Definition Contract

A module is declared at path `modules/<group>/<name>/` (or `~/.config/hellmacs/modules/<group>/<name>/`).

### File Contract Schema
```
modules/<group>/<name>/
├── packages.el   # [EVALUATED AT SYNC TIME] Declarations: (package! ...), (depends-on! ...), (hellmacs-treesit! ...)
├── init.el       # [BOOT PHASE 1] Evaluated before any config.el is loaded
├── config.el     # [BOOT PHASE 2] Evaluated during interactive boot (use-package forms)
├── autoload.el   # [ON-DEMAND] Evaluated into global autoload table at sync time
├── cli.el        # [CLI EXTENSION] Extends `bin/hellmacs` subcommands
└── doctor.el     # [HEALTH CHECK] Hooks into `bin/hellmacs doctor`
```

---

## 2. Core Macros API Reference

### `(hellmacs! ...)`
Declares the enabled module set and their active flags in user's `init.el`.
* **Signature**: `(hellmacs! &rest GROUPS-AND-MODULES)`
* **Example**:
  ```elisp
  (hellmacs! :ui theme (dashboard +ascii)
             :completion (corfu +tab) vertico
             :tools lsp (debugger +dap)
             :lang (java +lombok +tree-sitter))
  ```

### `(modulep! ...)`
Queries module activation state and flag predicates.
* **Signatures**:
  * `(modulep! +FLAG)`: Tests if `+FLAG` is active in current module context.
  * `(modulep! :GROUP NAME)`: Tests if module `:GROUP NAME` is active globally.
  * `(modulep! :GROUP NAME +FLAG)`: Tests if flag `+FLAG` is enabled on `:GROUP NAME`.

### `(package! NAME &rest PLIST)`
Declares a package requirement inside a `packages.el` file.
* **Keyword Parameters**:
  * `:pin STRING`: Fixed commit hash to enforce reproducibility.
  * `:recipe PLIST`: Elpaca recipe overrides.
  * `:disable BOOLEAN`: Suppresses package installation and activation.
  * `:built-in SYMBOL`: Indicates package availability in GNU Emacs core (`'prefer`).

### `(depends-on! :GROUP NAME &rest FLAGS)`
Declares, inside a `packages.el`, that the current module needs another module (flags as in `modulep!`).
* Checked once: at startup, by `bin/hellmacs sync`, and by `bin/hellmacs doctor` (under the module). Modules never check for each other by hand.
* The dependency's `packages.el` is read before the dependent's, so shared packages (the lsp-mode stack) are declared first.
* Every module that runs a language server declares `(depends-on! :tools lsp)`; the lsp-mode stack is declared only in `:tools lsp`.

### `(hellmacs-treesit! :grammars GRAMMARS :remap REMAP)`
Declares, inside a `packages.el` and under the module's `+tree-sitter` flag, the tree-sitter grammars the module needs and the modes they enable.
* `GRAMMARS`: `((LANGUAGE URL LABEL COMMIT [DIRECTORY]) ...)`; the COMMIT is what gets fetched. `hellmacs-treesit-sources` (user) overrides a pin.
* `REMAP`: `((MODE . TS-MODE) ...)`, added to `major-mode-remap-alist` at startup once every grammar is built; otherwise a warning says to sync.
* `sync` builds the grammars and `doctor` checks them; modules don't repeat this in cli.el, config.el or doctor.el.

### Buffer-local hooks a language module sets
Core and `:tools` modules never name a language; each `:lang` module sets these in its mode hooks:
* `hellmacs-reload-function` (core): what `C-c h r` (the Crucible) does in the buffer. Java: hot-swap into a debug session. Clojure: load into the REPL.
* `hellmacs-forge-test-class-function` / `hellmacs-forge-test-method-function` (`:tools build`): the test class and the test method at point, for `hellmacs-forge-test-at-point`. The class defaults to package + file name.
* Language server status: `(hellmacs-lsp-status-register SERVER :label ... :on-log ... :on-notification ... :on-request ...)` (core).

---

## 3. Precedence & Override Rules

1. **User Module Override**: A module located at `~/.config/hellmacs/modules/<group>/<name>/` completely overrides `hellmacs/modules/<group>/<name>/`.
2. **Declaration Evaluation Order**:
   - `core/packages.el` $\rightarrow$ Module `packages.el` (in `hellmacs!` order) $\rightarrow$ User `~/.config/hellmacs/packages.el`.
3. **Configuration Execution Order**:
   - `core/` $\rightarrow$ Module `init.el` $\rightarrow$ Module `config.el` $\rightarrow$ User `config.el`.
