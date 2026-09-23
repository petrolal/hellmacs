;;; init.el --- Hellmacs bootstrap -*- lexical-binding: t; -*-

;; This file only orchestrates: it wires `load-path', brings up the
;; package manager, and loads modules and the user's config in a fixed
;; order. It holds no configuration of its own -- that lives in
;; `core/' (engine internals), `modules/' (user-facing feature stack)
;; and `hellmacs-user-dir' (your config, outside this repo).
;;
;; Load order matters and is intentional:
;;   0. core/hellmacs-lib.el       -- macros/helpers (after!, add-hook!, ...), session context
;;   1. core/hellmacs-core.el      -- lifecycle hooks, GC, dir isolation, sane defaults
;;   2. core/hellmacs-packages.el  -- Elpaca bootstrap + use-package wiring
;;   3. $HELLMACSDIR/init.el       -- user: choose modules, set early variables
;;   4. modules/hellmacs-ui.el         -- theme, frame, mode-line
;;   5. modules/hellmacs-editor.el     -- undo, editing defaults
;;   6. modules/hellmacs-keybinds.el   -- general.el leader framework + which-key
;;      (must precede evil/completion: they bind into the leader map it defines)
;;   7. modules/hellmacs-evil.el       -- modal editing
;;   8. modules/hellmacs-completion.el -- vertico/consult/marginalia/orderless/corfu
;;   9. $HELLMACSDIR/config.el     -- user: everything else
;;  10. `custom-file', once Elpaca has activated every package

;;; Code:

(add-to-list 'load-path hellmacs-core-dir)
(add-to-list 'load-path hellmacs-modules-dir)

(require 'hellmacs-lib)
(hellmacs-context-push 'startup)
(hellmacs-context-push (if noninteractive 'cli 'emacs))

(require 'hellmacs-core)
(require 'hellmacs-packages)

(defun hellmacs-load-user-file (name)
  "Load NAME from `hellmacs-user-dir', if it exists.
Errors are reported as warnings instead of aborting startup, so a typo
in your config leaves you with a working editor to fix it in."
  (let ((file (expand-file-name name hellmacs-user-dir)))
    (when (file-exists-p file)
      (condition-case-unless-debug err
          (load file nil 'nomessage 'nosuffix)
        (error
         (display-warning
          'hellmacs (format "Error loading %s: %s"
                            (abbreviate-file-name file) (error-message-string err))
          :error))))))

(defvar hellmacs-modules
  '(hellmacs-ui
    hellmacs-editor
    hellmacs-keybinds
    hellmacs-evil
    hellmacs-completion)
  "Modules loaded at startup, in order.
Change it from your own init.el (see `hellmacs-user-dir'), which is
loaded before any module. Order matters:
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

(hellmacs-load-user-file "init.el")
(mapc #'hellmacs--load-module hellmacs-modules)
(hellmacs-load-user-file "config.el")

(add-hook 'hellmacs-after-init-hook
          (lambda ()
            (message "Hellmacs ready in %.2fs (%d GCs)" hellmacs-init-time gcs-done)))

(provide 'init)
;;; init.el ends here
