;;; hellmacs-keybinds.el --- Leader-key framework -*- lexical-binding: t; -*-

;; Hellmacs uses Emacs' default keybindings -- no evil, no modal
;; editing (see "Keybinding policy" in docs/roadmap.md). Its own
;; commands live under `C-c', the prefix Emacs reserves for users,
;; laid out like Doom's non-evil leader: `C-c h' Hellmacs, `C-c f'
;; file, `C-c b' buffer, `C-c s' search, `C-c w' window, `C-c q' quit.
;;
;; This file owns the framework (`hellmacs-leader-def') and the
;; groups with no natural owning feature module: `C-c h', `C-c q' and
;; `C-c w' (built-in window commands). Feature modules populate their
;; own groups (`hellmacs-completion' owns `C-c f', `C-c b', `C-c s');
;; this file must load before them. See the load-order comment in
;; `init.el'.
;;
;; No keybinding package is needed: Emacs 29's `keymap-set' covers
;; everything once there are no evil states to juggle.

;;; Code:

(defun hellmacs-leader-def (&rest bindings)
  "Bind BINDINGS, alternating KEY DEF pairs, under the `C-c' leader.

KEY is relative to `C-c', in `keymap-set' syntax (\"f f\" means
`C-c f f'). DEF is one of:
  - a command
  - (DESCRIPTION . COMMAND), to also give which-key a label
  - a string, to label KEY as a prefix group (\"file\" for `C-c f')

  (hellmacs-leader-def
    \"f\"   \"file\"
    \"f r\" \='(\"recent file\" . consult-recent-file))

Bindings go into `mode-specific-map', the keymap Emacs itself puts on
`C-c', so bindings made there by the user or by other packages keep
working alongside Hellmacs'."
  (while bindings
    (let ((key (pop bindings))
          (def (pop bindings)))
      (keymap-set mode-specific-map key
                  (if (stringp def)
                      ;; (LABEL . KEYMAP) is still a prefix to Emacs, and
                      ;; which-key displays LABEL for it.
                      (let ((map (keymap-lookup mode-specific-map key)))
                        (cons def (if (keymapp map) map (make-sparse-keymap))))
                    def)))))

(use-package which-key
  :defer 1
  :init
  (setq which-key-idle-delay 0.4
        which-key-sort-order 'which-key-key-order-alpha
        which-key-add-column-padding 1)
  :config
  (which-key-mode 1))

;;; C-c h -- hellmacs meta/help group --------------------------------------

(defun hellmacs-reload ()
  "Reload Hellmacs' init file, and with it your init.el and config.el."
  (interactive)
  (with-hellmacs-context 'reload
    (load-file (expand-file-name "init.el" hellmacs-dir))))

(defun hellmacs-visit-dir ()
  "Open a Dired buffer at the Hellmacs install directory."
  (interactive)
  (dired hellmacs-dir))

(defun hellmacs-init-user-dir ()
  "Create `hellmacs-user-dir' with starter init.el and config.el files.
Existing files are never overwritten."
  (interactive)
  (make-directory hellmacs-user-dir t)
  (dolist (name '("init.el" "config.el"))
    (let ((file (expand-file-name name hellmacs-user-dir)))
      (unless (file-exists-p file)
        (copy-file (expand-file-name (concat "static/" (file-name-base name) ".example.el")
                                     hellmacs-dir)
                   file))))
  ;; `custom-file' was put in the state dir because there was no user
  ;; dir at startup; from now on it belongs here.
  (setq custom-file (expand-file-name "custom.el" hellmacs-user-dir))
  (message "Hellmacs user config is in %s" (abbreviate-file-name hellmacs-user-dir)))

(defun hellmacs-visit-user-dir ()
  "Open a Dired buffer at your Hellmacs config (`hellmacs-user-dir').
Offers to create it with starter files if it doesn't exist yet."
  (interactive)
  (unless (file-directory-p hellmacs-user-dir)
    (if (y-or-n-p (format "%s doesn't exist. Create it? "
                          (abbreviate-file-name hellmacs-user-dir)))
        (hellmacs-init-user-dir)
      (user-error "No user config directory")))
  (dired hellmacs-user-dir))

(defun hellmacs-list-modules ()
  "Display the list of currently enabled Hellmacs modules."
  (interactive)
  (message "Hellmacs modules: %s"
           (mapconcat #'symbol-name hellmacs-modules ", ")))

(hellmacs-leader-def
  "h"   "hellmacs"
  "h r" '("reload config" . hellmacs-reload)
  "h v" '("visit hellmacs dir" . hellmacs-visit-dir)
  "h u" '("visit user config" . hellmacs-visit-user-dir)
  "h m" '("list modules" . hellmacs-list-modules)
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

(provide 'hellmacs-keybinds)
;;; hellmacs-keybinds.el ends here
