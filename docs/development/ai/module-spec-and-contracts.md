# Module System Specification & API Contracts

## 1. Module Definition Contract

A module is declared at path `modules/<group>/<name>/` (or `~/.config/hellmacs/modules/<group>/<name>/`).

### File Contract Schema
```
modules/<group>/<name>/
├── packages.el   # [EVALUATED AT SYNC TIME] Declares dependencies via (package! ...)
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

---

## 3. Precedence & Override Rules

1. **User Module Override**: A module located at `~/.config/hellmacs/modules/<group>/<name>/` completely overrides `hellmacs/modules/<group>/<name>/`.
2. **Declaration Evaluation Order**:
   - `core/packages.el` $\rightarrow$ Module `packages.el` (in `hellmacs!` order) $\rightarrow$ User `~/.config/hellmacs/packages.el`.
3. **Configuration Execution Order**:
   - `core/` $\rightarrow$ Module `init.el` $\rightarrow$ Module `config.el` $\rightarrow$ User `config.el`.
