;;; editor/undo/config.el -*- lexical-binding: t; -*-

;; Undo is Emacs' own: `C-/' undoes, `C-?' (`undo-redo') redoes, and
;; `undo' in an active region undoes only within it.
;; `undo-fu-session' adds what Emacs lacks: undo history that survives
;; closing a file or restarting Emacs.

(setq undo-limit 400000
      undo-strong-limit 3000000
      undo-outer-limit 48000000)

(use-package undo-fu-session
  :defer 1
  :init
  (setq undo-fu-session-directory (hellmacs-state-file "undo-fu-session/")
        undo-fu-session-linear t)
  :config
  (global-undo-fu-session-mode 1))
