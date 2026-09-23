;;; init.el --- Hellmacs bootstrap -*- lexical-binding: t; -*-

;; This file only orchestrates: it wires `load-path', brings up the
;; package manager, and loads modules and the user's config in a fixed
;; order. It holds no configuration of its own -- that lives in
;; `core/' (engine internals), `modules/<group>/<name>/' (user-facing
;; features) and `hellmacs-user-dir' (your config, outside this repo).
;;
;; Load order matters and is intentional:
;;   1. core/hellmacs-lib.el       -- macros/helpers (after!, add-hook!, ...), session context
;;   2. core/hellmacs-core.el      -- lifecycle hooks, GC, dir isolation, sane defaults
;;   3. core/hellmacs-packages.el  -- use-package settings (Elpaca itself loads on demand)
;;   4. core/hellmacs-keybinds.el  -- the C-c leader (`hellmacs-leader-def')
;;   5. core/hellmacs-modules.el   -- module system: `hellmacs!', `modulep!', `package!'
;;   6. $HELLMACSDIR/init.el       -- user: `hellmacs!' block choosing modules
;;                                    (static/init.example.el if there isn't one)
;;   7. packages: activated from the profile `bin/hellmacs sync' wrote --
;;      or, if it's missing or out of date, every packages.el is read and
;;      Elpaca installs/activates the packages before going on
;;   8. every enabled module's autoload.el + init.el, in `hellmacs!' order
;;   9. every enabled module's config.el, in `hellmacs!' order
;;  10. $HELLMACSDIR/config.el     -- user: everything else
;;  11. `custom-file', once every package is activated

;;; Code:

;; `--init-directory', `keymap-set' and `defvar-keymap' are all 29.1+.
(when (< emacs-major-version 29)
  (error "Hellmacs needs Emacs 29.1 or newer; this is %s" emacs-version))

(add-to-list 'load-path hellmacs-core-dir)

(require 'hellmacs-lib)
(hellmacs-context-push 'startup)
(hellmacs-context-push (if noninteractive 'cli 'emacs))

(require 'hellmacs-core)
(require 'hellmacs-packages)

(require 'hellmacs-keybinds)
(require 'hellmacs-modules)

;; Your init.el chooses modules with `hellmacs!'. Without one (or if it
;; doesn't call `hellmacs!'), the starter file's defaults apply, so
;; there's a single definition of Hellmacs' default module set.
(hellmacs-modules-read-config)

(hellmacs-modules-startup)
(hellmacs-load-user-file "config.el")

(add-hook 'hellmacs-after-init-hook
          (lambda ()
            (message "Hellmacs%s ready in %.2fs (%d GCs)"
                     (if hellmacs-profile (format " [%s]" hellmacs-profile) "")
                     hellmacs-init-time gcs-done)))

(provide 'init)
;;; init.el ends here
