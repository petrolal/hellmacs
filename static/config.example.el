;;; config.el --- Your Hellmacs config -*- lexical-binding: t; -*-

;; Loaded after every module. Put your own settings, keybindings and
;; extra packages here. Packages may still be installing when this
;; runs, so configure them with `after!' or `use-package' rather than
;; calling their functions directly.
;;
;; Hellmacs' helper macros are available: `after!', `add-hook!',
;; `setq-hook!', `defadvice!' and `cmd!' (see core/hellmacs-lib.el).

;; Settings for a built-in feature:
;; (setq fill-column 100)

;; Per-mode settings:
;; (setq-hook! 'java-ts-mode-hook tab-width 4 fill-column 120)

;; Configure a package once it has loaded:
;; (after! consult
;;   (setq consult-preview-key "M-."))

;; Your own keys under the C-c leader (C-c g g here):
;; (hellmacs-leader-def
;;   "g"   "git"
;;   "g g" '("status" . magit-status))

;; Install and configure an extra package:
;; (use-package magit
;;   :bind ("C-x g" . magit-status))

;;; config.el ends here
