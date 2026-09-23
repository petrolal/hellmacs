;;; hellmacs-evil.el --- Modal editing: evil-mode + evil-collection -*- lexical-binding: t; -*-

;; Owns the `SPC w' (window) leader group: `evil-window-map' is
;; evil's own concept, so it belongs here rather than in
;; `hellmacs-keybinds', which only owns the leader framework itself.

;;; Code:

(use-package evil
  :ensure (:wait t) ; evil-collection below depends on it being fully loaded first
  :demand t
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil    ; evil-collection provides its own, more complete bindings
        evil-want-C-u-scroll t
        evil-want-C-i-jump nil
        evil-undo-system 'undo-fu
        evil-respect-visual-line-mode t
        evil-search-module 'evil-search
        evil-symbol-word-search t)
  :config
  (evil-mode 1)
  (hellmacs-leader-def
    "w" '("window" . evil-window-map)))

(use-package evil-collection
  :after evil
  :demand t
  :init
  (setq evil-collection-setup-minibuffer t)
  :config
  (evil-collection-init))

(provide 'hellmacs-evil)
;;; hellmacs-evil.el ends here
