;;; hellmacs-keybinds.el --- Leader-key framework -*- lexical-binding: t; -*-

;; Establishes the SPC-leader keybinding framework every other module
;; binds into. This file owns only the framework itself and the
;; "hellmacs meta" (`SPC h') and "quit" (`SPC q') groups -- genuine
;; engine-level concerns with no natural owning feature module.
;; Feature modules (`hellmacs-evil', `hellmacs-completion', ...) each
;; own and populate their own leader groups (`SPC w', `SPC f', `SPC
;; b', ...); this file must load before them so `hellmacs-leader-def'
;; exists when they do. See the load-order comment in `init.el'.
;;
;; Binding style: leaves use which-key's keymap-based replacement --
;; `(cons "description" definition)' -- rather than general.el's
;; `:which-key' extended keyword, which general's own README
;; recommends against for anything this simple. Bare group prefixes
;; (no command of their own, e.g. `SPC f') are labeled with
;; `which-key-add-key-based-replacements' instead, since there's no
;; definition to attach a cons replacement to.

;;; Code:

(use-package general
  :ensure (:wait t) ; block until installed: later modules use `hellmacs-leader-def' in their own :config
  :demand t
  :config
  (general-auto-unbind-keys) ; don't require pre-unbinding a prefix key before rebinding it as one

  (general-create-definer hellmacs-leader-def
    :states '(normal visual motion insert emacs)
    :keymaps 'override
    :prefix "SPC"
    :non-normal-prefix "M-SPC")

  (hellmacs-leader-def
    "SPC" '("M-x" . execute-extended-command)
    ":"   '("eval expression" . eval-expression)))

(use-package which-key
  :defer 1
  :init
  (setq which-key-idle-delay 0.4
        which-key-sort-order 'which-key-key-order-alpha
        which-key-add-column-padding 1)
  :config
  (which-key-mode 1)
  (which-key-add-key-based-replacements
    "SPC h" "hellmacs"
    "SPC q" "quit"))

;;; SPC h -- hellmacs meta/help group ------------------------------------

(defun hellmacs-reload ()
  "Reload the Hellmacs init file."
  (interactive)
  (with-hellmacs-context 'reload
    (load-file (expand-file-name "init.el" hellmacs-dir))))

(defun hellmacs-visit-dir ()
  "Open a Dired buffer at the Hellmacs install directory."
  (interactive)
  (dired hellmacs-dir))

(defun hellmacs-list-modules ()
  "Display the list of currently enabled Hellmacs modules."
  (interactive)
  (message "Hellmacs modules: %s"
           (mapconcat #'symbol-name hellmacs-modules ", ")))

(hellmacs-leader-def
  "h r" '("reload config" . hellmacs-reload)
  "h v" '("visit hellmacs dir" . hellmacs-visit-dir)
  "h m" '("list modules" . hellmacs-list-modules)
  "q q" '("quit emacs" . save-buffers-kill-terminal))

(provide 'hellmacs-keybinds)
;;; hellmacs-keybinds.el ends here
