;;; config/default/config.el -*- lexical-binding: t; -*-

;; Hellmacs' default keybindings and the groups with no natural owning
;; feature module: `C-c h' (Hellmacs), `C-c q' (quit) and `C-c w'
;; (built-in window commands). Feature modules fill their own groups,
;; e.g. `:completion vertico' owns `C-c f', `C-c b' and `C-c s'.

(use-package which-key
  :defer 1
  :init
  (setq which-key-idle-delay 0.4
        which-key-sort-order 'which-key-key-order-alpha
        which-key-add-column-padding 1)
  :config
  (which-key-mode 1))

;;; C-c h, C-c q -----------------------------------------------------------

(hellmacs-leader-def
  "h"   "hellmacs"
  "h r" '("reload config" . hellmacs-reload)
  "h v" '("visit hellmacs dir" . hellmacs-visit-dir)
  "h u" '("visit user config" . hellmacs-visit-user-dir)
  "h m" '("list modules" . hellmacs-list-modules)
  "h s" '("sync packages" . hellmacs-sync)
  "q"   "quit"
  "q q" '("quit emacs" . save-buffers-kill-terminal)
  "q r" '("restart emacs" . restart-emacs))

;;; C-c w -- windows -----------------------------------------------------------
;;
;; Built-in commands only. The defaults (`C-x 2', `C-x 3', `C-x 0',
;; `C-x 1', `C-x o') still work; this group gathers them in one place
;; and adds directional movement and window-layout undo.

(add-hook 'hellmacs-first-input-hook #'winner-mode)

(hellmacs-leader-def
  "w"   "window"
  "w s" '("split below" . split-window-below)
  "w v" '("split right" . split-window-right)
  "w d" '("delete window" . delete-window)
  "w m" '("maximize (delete others)" . delete-other-windows)
  "w o" '("other window" . other-window)
  "w =" '("balance windows" . balance-windows)
  "w b" '("window left" . windmove-left)
  "w f" '("window right" . windmove-right)
  "w p" '("window up" . windmove-up)
  "w n" '("window down" . windmove-down)
  "w u" '("undo layout" . winner-undo)
  "w r" '("redo layout" . winner-redo))
