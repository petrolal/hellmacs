# Configuration & Module System

Hellmacs uses a modular architecture inspired by Doom Emacs, but modernized for pure Emacs workflows and asynchronous package management via [Elpaca](https://github.com/progfolio/elpaca).

---

## User Configuration Files

Your personal configuration lives in `~/.config/hellmacs/` (or `$HELLMACSDIR`):

```
~/.config/hellmacs/
├── init.el          # Module declarations via (hellmacs! ...)
├── packages.el      # Extra packages declared via (package! ...)
├── config.el        # Custom Elisp configuration loaded after modules
└── custom.el        # Automatically written by Emacs customize system
```

---

## Enabling and Disabling Modules (`init.el`)

The `(hellmacs! ...)` block in `~/.config/hellmacs/init.el` dictates which modules are loaded at boot.

### Syntax
```elisp
(hellmacs! :ui
           theme              ; Hellmacs Inferno theme
           dashboard          ; The Altar startup screen
           modeline           ; Custom lightweight mode-line

           :editor
           undo               ; Persistent undo history (undo-fu-session)

           :completion
           (corfu +tab)       ; In-buffer completion popup with TAB completion
           vertico            ; Minibuffer completion (Consult + Marginalia + Orderless)

           :tools
           build              ; Gradle & Maven compilation
           debugger           ; DAP mode for JVM debugging
           lsp                ; Language Server Protocol (lsp-mode)
           magit              ; Git interface

           :lang
           (java +lombok +tree-sitter) ; Java with JDTLS, Lombok and Tree-sitter
           (kotlin +tree-sitter)       ; Kotlin with kotlin-language-server
           (clojure +tree-sitter)      ; Clojure with CIDER and clojure-lsp

           :config
           default)           ; Default keybindings & which-key
```

### Module Flags (`+flag`)
Modules support granular flags:
* `(corfu +tab)`: Enables TAB to complete when nothing is indented.
* `(java +lombok)`: Downloads and attaches Lombok javaagent to JDTLS.
* `(java +tree-sitter)`: Activates `java-ts-mode` instead of classic `java-mode`.

---

## Declaring Additional Packages (`packages.el`)

To install third-party packages that are not part of Hellmacs modules, declare them in `~/.config/hellmacs/packages.el` using the `package!` macro:

```elisp
;; Install from MELPA / GNU ELPA
(package! yaml-mode)
(package! restclient)

;; Install from a specific Git repository
(package! example-pkg
  :recipe (:host github :repo "username/example-pkg"))

;; Pin a package to a specific commit
(package! another-pkg
  :pin "abcdef1234567890")

;; Disable a package included by a built-in module
(package! unwanted-pkg :disable t)
```

After modifying `init.el` or `packages.el`, always run:
```sh
bin/hellmacs sync
```
*(or press `C-c h s` inside Emacs).*

---

## Personal Elisp (`config.el`)

`~/.config/hellmacs/config.el` runs after all modules have loaded. Use standard `use-package`, `after!`, and `setq`:

```elisp
;; Customize variables
(setq display-line-numbers-type 'relative)

;; Configure packages
(after! lsp-mode
  (setq lsp-lens-enable t))

;; Custom keybindings
(keymap-global-set "C-c o" #'my-custom-command)
```

---

## Creating Private Custom Modules

You can create private modules that override or extend Hellmacs modules:
1. Create a directory in `~/.config/hellmacs/modules/<category>/<name>/` (e.g. `~/.config/hellmacs/modules/lang/rust/`).
2. Add any of the following optional files:
   * `packages.el`: Package declarations (`package! ...`).
   * `config.el`: Main configuration (`use-package ...`).
   * `autoload.el`: Functions to autoload on demand.
   * `init.el`: Early configuration run before `config.el`.
   * `doctor.el`: Health checks for `bin/hellmacs doctor`.
3. Enable `:category name` in your `init.el` and run `bin/hellmacs sync`.

---

## Multiple Profiles

Hellmacs supports isolated configuration profiles (e.g. for work and personal setups):

```sh
# Sync and manage a specific profile
bin/hellmacs --profile work sync
bin/hellmacs --profile work doctor

# Start Emacs with a specific profile
emacs --profile work
```

Each profile maintains completely isolated configs (`~/.config/hellmacs-work`), packages (`~/.local/share/hellmacs-work`), caches, and state directories.
