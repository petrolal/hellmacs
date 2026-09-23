;;; completion/vertico/config.el -*- lexical-binding: t; -*-

;; Minibuffer completion: vertico (UI), orderless (matching),
;; marginalia (annotations), consult (commands).
;;
;; Owns the `C-c f' (file), `C-c b' (buffer), and `C-c s' (search)
;; leader groups. The groups bind built-in commands; `consult' then
;; remaps those built-ins -- and their default keys, like `C-x b' and
;; `M-y' -- to its richer versions. Emacs muscle memory keeps working,
;; it just gets previews and better completion.

(hellmacs-leader-def
  "f"   "file"
  "f f" '("find file" . find-file)
  "f s" '("save file" . save-buffer)
  "f R" '("rename file" . rename-visited-file)
  "b"   "buffer"
  "b b" '("switch buffer" . switch-to-buffer)
  "b d" '("kill buffer" . kill-current-buffer)
  "b r" '("revert buffer" . revert-buffer-quick)
  "s"   "search"
  "s s" '("isearch" . isearch-forward)
  "s o" '("occur" . occur))

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
  ;; consult is big; load it while idle so the first C-x b is instant.
  :defer-incrementally t
  :bind
  (;; Replace default commands everywhere they're bound -- `C-x b',
   ;; `C-c b b', `M-y', `M-g g', ... -- rather than inventing new keys.
   ([remap switch-to-buffer]              . consult-buffer)
   ([remap switch-to-buffer-other-window] . consult-buffer-other-window)
   ([remap project-switch-to-buffer]      . consult-project-buffer)
   ([remap yank-pop]                      . consult-yank-pop)
   ([remap goto-line]                     . consult-goto-line)
   ([remap imenu]                         . consult-imenu)
   ([remap bookmark-jump]                 . consult-bookmark)
   ;; `M-s' is Emacs' own search prefix; these keys are free in it.
   ("M-s l" . consult-line)
   ("M-s r" . consult-ripgrep)
   ("M-s f" . consult-find))
  :init
  (setq consult-narrow-key "<"
        consult-preview-key 'any)
  (hellmacs-leader-def
    "f r" '("recent file" . consult-recent-file)
    "s l" '("search line" . consult-line)
    "s g" '("search grep" . consult-ripgrep)
    "s f" '("find file by name" . consult-find)
    "s i" '("jump to symbol" . consult-imenu)))
