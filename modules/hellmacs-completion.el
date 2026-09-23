;;; hellmacs-completion.el --- vertico/consult/marginalia/orderless/corfu -*- lexical-binding: t; -*-

;; Owns the `SPC f' (file), `SPC b' (buffer), and `SPC s' (search)
;; leader groups. Baseline bindings for built-in commands are defined
;; directly below; `consult' then layers richer replacements onto the
;; same groups via its own `:general' block, once it's actually
;; loaded, without this file needing to know consult's internals.

;;; Code:

(which-key-add-key-based-replacements
  "SPC f" "file"
  "SPC b" "buffer"
  "SPC s" "search")

(hellmacs-leader-def
  "f f" '("find file" . find-file)
  "f s" '("save file" . save-buffer)
  "b b" '("switch buffer" . switch-to-buffer)
  "b d" '("kill buffer" . kill-current-buffer))

;;; Minibuffer completion UI -------------------------------------------

(use-package vertico
  :demand t
  :init
  (setq vertico-count 12
        vertico-cycle t)
  :config
  (vertico-mode 1))

(use-package orderless
  :demand t
  :init
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :defer 1
  :config
  (marginalia-mode 1))

(use-package consult
  :general
  (hellmacs-leader-def
    "b b" '("switch buffer" . consult-buffer)
    "f r" '("recent file" . consult-recent-file)
    "s l" '("search line" . consult-line)
    "s g" '("search grep" . consult-ripgrep))
  :init
  (setq consult-narrow-key "<"
        consult-preview-key 'any))

;;; In-buffer completion -------------------------------------------------

(use-package corfu
  :defer 1
  :init
  (setq corfu-auto t
        corfu-auto-delay 0.15
        corfu-auto-prefix 2
        corfu-cycle t
        corfu-preselect 'prompt
        tab-always-indent 'complete)
  :config
  (global-corfu-mode 1)
  (corfu-popupinfo-mode 1))
;; Terminal (non-GUI) Emacs needs the separate `corfu-terminal' package
;; for popups to render; add it as its own `use-package' block if you
;; run Hellmacs in a terminal.

(provide 'hellmacs-completion)
;;; hellmacs-completion.el ends here
