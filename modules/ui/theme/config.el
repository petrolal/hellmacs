;;; ui/theme/config.el -*- lexical-binding: t; -*-

;; Visual defaults only: theme, cursor, mode-line, line numbers.
;;
;; The theme is Hellmacs' own (themes/hellmacs-theme.el): obsidian
;; black, brimstone red, amber and toxic green, with no dependencies.
;; Set `hellmacs-theme' in your init.el to use another one -- e.g.
;; `modus-vivendi', built into Emacs -- or nil to load none.

(defvar hellmacs-theme 'hellmacs
  "Theme loaded at startup by the `:ui theme' module, or nil for none.")

(add-to-list 'custom-theme-load-path (expand-file-name "themes/" hellmacs-dir))

(use-package emacs
  :ensure nil
  :init
  (setq-default cursor-type 'bar)
  :config
  (column-number-mode 1)
  (size-indication-mode 1)
  ;; Line numbers only where they're actually useful for navigation.
  (add-hook 'prog-mode-hook #'display-line-numbers-mode))

;; The current line is highlighted where you edit (Charcoal Iron in
;; the Hellmacs theme).
(add-hook 'prog-mode-hook #'hl-line-mode)
(add-hook 'text-mode-hook #'hl-line-mode)

(when hellmacs-theme
  ;; Themes stack; start from none, so no other theme's faces show
  ;; through where this one leaves a face unset.
  (mapc #'disable-theme custom-enabled-themes)
  (load-theme hellmacs-theme :no-confirm))
