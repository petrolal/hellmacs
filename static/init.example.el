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
           theme              ; the Hellmacs theme, line numbers, current line

           :editor
           undo               ; persistent undo history (undo-fu-session)

           :completion
           vertico            ; minibuffer completion + consult commands
           corfu              ; in-buffer completion popup (+tab: TAB completes)

           :tools
           ;;build            ; build/test with Gradle or Maven (C-x p c), clickable errors
           ;;debugger         ; debug via dap-mode, C-c d (Java: breakpoints, tests, hot swap)
           ;;lsp              ; code intelligence via lsp-mode, C-c l (+eglot: eglot instead)

           :lang
           ;;(java +lombok)   ; Java via JDTLS: needs :tools lsp and a JDK 21+ (+tree-sitter)

           :config
           default)           ; C-c leader groups: h, q, w; which-key

;; Look and feel (all optional):
;; (setq hellmacs-theme 'modus-vivendi)   ; another theme; nil loads none
;; (setq hellmacs-splash-enable nil)      ; start on *scratch*, not the Altar
;; (setq hellmacs-ux-enable nil)          ; stock quit prompt and error messages

;;; init.el ends here
