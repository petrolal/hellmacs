;;; init.el --- Your Hellmacs init file -*- lexical-binding: t; -*-

;; Loaded after Hellmacs' core and package manager, but BEFORE any
;; module. Use it to choose which modules load and to set variables
;; that modules read while loading. Everything else belongs in
;; config.el.
;;
;; This file lives in `hellmacs-user-dir' (~/.config/hellmacs/ by
;; default, or $HELLMACSDIR), outside the Hellmacs git checkout, so
;; upgrading Hellmacs never touches it.

;; Modules load in this order. Delete a line to disable that module.
(setq hellmacs-modules
      '(hellmacs-ui
        hellmacs-editor
        hellmacs-keybinds          ; must come before evil/completion
        hellmacs-evil
        hellmacs-completion))

;;; init.el ends here
