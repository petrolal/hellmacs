;;; init.el --- Your Hellmacs init file -*- lexical-binding: t; -*-

;; Loaded after Hellmacs' core, but BEFORE any module. Use it to choose
;; which modules load (the `hellmacs!' block) and to set variables that
;; modules read while loading. Everything else belongs in config.el.
;;
;; This file lives in `hellmacs-user-dir' (~/.config/hellmacs/ by
;; default, or $HELLMACSDIR), outside the Hellmacs git checkout, so
;; upgrading Hellmacs never touches it. Without it, Hellmacs uses the
;; `hellmacs!' block below (it reads this very file from static/).
;;
;; After changing this block, run `bin/hellmacs sync' (or `C-c h s').
;;
;; Modules load in the order listed. Comment a line out to disable a
;; module; +flags turn on optional behavior, documented at the top of
;; each module's config.el (modules/<group>/<name>/config.el).

(hellmacs! :ui
           theme              ; modus-themes, line numbers, mode-line bits

           :editor
           undo               ; persistent undo history (undo-fu-session)

           :completion
           vertico            ; minibuffer completion + consult commands
           corfu              ; in-buffer completion popup (+tab: TAB completes)

           :config
           default)           ; C-c leader groups: h, q, w; which-key

;;; init.el ends here
