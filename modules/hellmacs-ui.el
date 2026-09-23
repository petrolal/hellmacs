;;; hellmacs-ui.el --- Theme, frame, and mode-line defaults -*- lexical-binding: t; -*-

;; Visual defaults only. No keybindings, no editing behavior -- see
;; `hellmacs-editor' and `hellmacs-keybinds' for those.
;;
;; Uses `modus-themes', built into Emacs 28+, instead of pulling in a
;; third-party theme package: it's maintained in lockstep with Emacs
;; itself, is WCAG AA-contrast accessible by default, and keeps
;; Hellmacs' package count down, in keeping with its minimalist goal.

;;; Code:

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

(provide 'hellmacs-ui)
;;; hellmacs-ui.el ends here
