;;; hellmacs-template.el --- Template for new Hellmacs modules -*- lexical-binding: t; -*-

;; This file is a SCAFFOLD, not a real module: it is intentionally
;; left off of `hellmacs-modules' in `init.el' and is never loaded
;; automatically. Copy it to `modules/hellmacs-<name>.el' as the
;; starting point for a new module, then add the new file's symbol
;; (`hellmacs-<name>') to `hellmacs-modules' in `init.el' to enable it.
;;
;; Naming and structure conventions demonstrated here, followed by
;; every module in `modules/':
;;
;;   - File name and `provide' symbol are both `hellmacs-<name>',
;;     matching exactly -- this is what makes `(require 'hellmacs-foo)'
;;     in `init.el' find `modules/hellmacs-foo.el' on `load-path'.
;;   - A one-line file header (like this one's first line) plus a
;;     short comment block explaining what leader-key group (if any)
;;     the module owns and why. See `hellmacs-keybinds.el' or
;;     `hellmacs-completion.el' for real examples.
;;   - Package installation and configuration go through `use-package'
;;     with `:defer' (or `:demand t' only when genuinely required
;;     immediately, e.g. `vertico' so the first minibuffer uses it). Never load
;;     a package just by mentioning it.
;;   - Keybindings follow Emacs conventions (see "Keybinding policy"
;;     in docs/roadmap.md): never rebind a default key to something
;;     else. Improve a default command with `[remap ...]' in `:bind',
;;     or add a `C-c' leader binding with `hellmacs-leader-def'.
;;   - Leader keybindings belong to exactly one module -- the one that
;;     "owns" that feature. Don't duplicate a binding across modules;
;;     layer onto an existing group from the owning module instead
;;     (see how `hellmacs-completion' fills its own `C-c f'/`C-c b'
;;     groups from `consult').
;;   - End with `(provide 'hellmacs-<name>)' and the closing comment.

;;; Code:

;; A package this module needs. `:defer t' is the default (see
;; `use-package-always-defer' in `core/hellmacs-packages.el'), so this
;; loads lazily via the `:hook'/`:bind'/`:commands' trigger below
;; rather than at startup.
(use-package example-package
  :init
  ;; Settings read *before* the package loads (safe to set unconditionally,
  ;; cheap, no side effects on Emacs internals).
  (setq example-package-some-option t)
  ;; A leader binding (`C-c x x'). The command is autoloaded, so
  ;; pressing the key loads the package.
  (hellmacs-leader-def
    "x"   "example"
    "x x" '("example command" . example-package-command))
  :hook
  ;; Load lazily, the first time `some-mode' turns on.
  (some-mode . example-package-mode)
  :bind
  ;; Make a default key smarter instead of adding a new one.
  ([remap some-builtin-command] . example-package-better-command)
  :config
  ;; Runs once, after the package actually loads. Settings here may
  ;; depend on the package's own internals (faces, keymaps, etc.).
  (example-package-setup))

(provide 'hellmacs-template)
;;; hellmacs-template.el ends here
