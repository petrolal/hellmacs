;;; init.el --- Hellmacs bootstrap -*- lexical-binding: t; -*-

;; This file only orchestrates: it wires `load-path', brings up the
;; package manager, and requires modules in a fixed order. It holds
;; no configuration of its own -- that lives in `core/' (engine
;; internals) and `modules/' (user-facing feature stack).
;;
;; Load order matters and is intentional:
;;   0. core/hellmacs-lib.el       -- macros/helpers (after!, add-hook!, ...), session context
;;   1. core/hellmacs-core.el      -- GC lifecycle, dir isolation, sane defaults
;;   2. core/hellmacs-packages.el  -- Elpaca bootstrap + use-package wiring
;;   3. modules/hellmacs-ui.el         -- theme, frame, mode-line
;;   4. modules/hellmacs-editor.el     -- undo, editing defaults
;;   5. modules/hellmacs-keybinds.el   -- general.el leader framework + which-key
;;      (must precede evil/completion: they bind into the leader map it defines)
;;   6. modules/hellmacs-evil.el       -- modal editing
;;   7. modules/hellmacs-completion.el -- vertico/consult/marginalia/orderless/corfu

;;; Code:

(add-to-list 'load-path hellmacs-core-dir)
(add-to-list 'load-path hellmacs-modules-dir)

(require 'hellmacs-lib)
(hellmacs-context-push 'startup)
(hellmacs-context-push (if noninteractive 'cli 'emacs))

(require 'hellmacs-core)
(require 'hellmacs-packages)

(defvar hellmacs-modules
  '(hellmacs-ui
    hellmacs-editor
    hellmacs-keybinds
    hellmacs-evil
    hellmacs-completion)
  "Modules loaded at startup, in order.
Add/remove entries to change what Hellmacs ships with. Order matters:
see the load-order comment at the top of this file. Modules not on
this list (e.g. `modules/hellmacs-template.el', a scaffold for
writing new ones) are never loaded automatically.")

(defun hellmacs--load-module (module)
  "Require MODULE, reporting a failure without aborting the rest of startup.
One broken module (a typo, a package that failed to install) should
degrade Hellmacs, not brick it."
  (condition-case err
      (with-hellmacs-context 'module
        (require module))
    (error
     (message "Hellmacs: module `%s' failed to load: %s" module (error-message-string err)))))

(mapc #'hellmacs--load-module hellmacs-modules)

(add-hook 'hellmacs-after-init-hook
          (lambda ()
            (message "Hellmacs ready in %.2fs (%d GCs)" hellmacs-init-time gcs-done)))

(provide 'init)
;;; init.el ends here
