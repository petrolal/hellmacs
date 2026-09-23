;;; completion/corfu/config.el -*- lexical-binding: t; -*-

;; In-buffer completion: a popup that appears as you type.
;;
;; Flags:
;;   +tab  Make TAB complete when there's nothing to indent
;;         (`tab-always-indent' = complete). Off by default, since
;;         stock Emacs TAB only indents; `C-M-i' completes either way.

(when (modulep! +tab)
  (setq tab-always-indent 'complete))

(use-package corfu
  :defer 1
  :init
  (setq corfu-auto t
        corfu-auto-delay 0.15
        corfu-auto-prefix 2
        corfu-cycle t
        corfu-preselect 'prompt)
  :config
  (global-corfu-mode 1)
  (corfu-popupinfo-mode 1))
;; Terminal (non-GUI) Emacs needs the separate `corfu-terminal' package
;; for popups to render (Emacs 31+ doesn't).
