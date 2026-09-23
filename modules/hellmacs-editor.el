;;; hellmacs-editor.el --- Undo system and editing defaults -*- lexical-binding: t; -*-

;; Sensible-defaults editing behavior that isn't tied to modal editing
;; or completion. `hellmacs-evil' wires `undo-fu' as evil's undo
;; backend; this module only installs and configures it.

;;; Code:

(use-package undo-fu
  :defer t
  :init
  (setq undo-fu-allow-undo-in-region t)
  :config
  (setq undo-limit 400000
        undo-strong-limit 3000000
        undo-outer-limit 48000000))

(use-package undo-fu-session
  :defer 1
  :init
  (setq undo-fu-session-directory (expand-file-name "undo-fu-session/" hellmacs-var-dir)
        undo-fu-session-linear t)
  :config
  (global-undo-fu-session-mode 1))

(provide 'hellmacs-editor)
;;; hellmacs-editor.el ends here
