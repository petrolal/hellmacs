;;; ui/theme/config.el -*- lexical-binding: t; -*-

;; Visual defaults only: theme, cursor, mode-line, line numbers.
;;
;; Uses `modus-themes', built into Emacs 28+, instead of pulling in a
;; third-party theme package: it's maintained in lockstep with Emacs
;; itself, is WCAG AA-contrast accessible by default, and keeps
;; Hellmacs' package count down.

(use-package emacs
  :ensure nil
  :init
  (setq-default cursor-type 'bar)
  :config
  (column-number-mode 1)
  (size-indication-mode 1)
  ;; Line numbers only where they're actually useful for navigation.
  (add-hook 'prog-mode-hook #'display-line-numbers-mode))

;; `modus-themes' ships with Emacs 28+ as theme files under
;; `etc/themes/' (found via `custom-theme-load-path'), not as a
;; library on `load-path' -- so `load-theme' works directly, but a
;; `use-package'-style `require' of it does not. Setting its options
;; still works ahead of time since they're plain `defcustom's.
(setq modus-themes-italic-constructs t
      modus-themes-bold-constructs nil
      modus-themes-mixed-fonts t)
(load-theme 'modus-operandi :no-confirm)
