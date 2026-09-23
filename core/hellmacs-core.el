;;; hellmacs-core.el --- Core engine: GC lifecycle, dir isolation, sane defaults -*- lexical-binding: t; -*-

;; Everything in `core/' is engine plumbing every Hellmacs install
;; depends on regardless of which feature modules are enabled. This
;; file has no opinions about editing style -- no evil, no leader
;; keys, no completion UI, that's `modules/'. It only makes stock
;; Emacs behave sanely and keeps its droppings inside `hellmacs-dir'
;; instead of scattering them across `~'.
;;
;; Expects `hellmacs-dir', `hellmacs-var-dir', `hellmacs-etc-dir',
;; `hellmacs--gc-cons-threshold' and `hellmacs--gc-cons-percentage' to
;; already be defined -- they're set in `early-init.el', which always
;; loads before this file.

;;; Code:

;;; Startup lifecycle ----------------------------------------------------
;;
;; Elpaca activates packages asynchronously, so `after-init-hook' fires
;; before modules' packages are actually usable. Hellmacs' own notion of
;; "startup finished" is therefore `elpaca-after-init-hook', which is
;; where `hellmacs-finalize' runs.
;;
;; The `hellmacs-first-*' hooks let modules defer work until the user
;; actually needs it, instead of paying for it during boot. Each runs
;; exactly once, and never before `hellmacs-finalize'.

(defvar hellmacs-after-init-hook nil
  "Run once Hellmacs, its modules and their packages are fully loaded.")

(defvar hellmacs-first-input-hook nil
  "Run once, before the first interactive command after startup.")

(defvar hellmacs-first-file-hook nil
  "Run once, when the first file is opened after startup.")

(defvar hellmacs-first-buffer-hook nil
  "Run once, when the first real buffer is displayed after startup.
*scratch*, *Messages* and other `special-mode' buffers don't count.")

(defun hellmacs--real-buffer-p ()
  "Return non-nil if the current buffer counts for `hellmacs-first-buffer-hook'."
  (not (or (minibufferp)
           (member (buffer-name) '("*scratch*" "*Messages*"))
           (derived-mode-p 'special-mode))))

(hellmacs-run-hook-on 'hellmacs-first-input-hook '(pre-command-hook))
(hellmacs-run-hook-on 'hellmacs-first-file-hook
                      '(find-file-hook dired-initial-position-hook))
(hellmacs-run-hook-on 'hellmacs-first-buffer-hook
                      '(find-file-hook window-buffer-change-functions)
                      #'hellmacs--real-buffer-p)

(defun hellmacs-finalize ()
  "Mark the end of startup and run `hellmacs-after-init-hook'."
  (when (hellmacs-context-p 'startup)
    (setq hellmacs-init-time
          (float-time (time-subtract (current-time) before-init-time)))
    ;; Files passed on the command line were opened before startup
    ;; finished, so their triggers were ignored; catch up now.
    (when (seq-some #'buffer-file-name (buffer-list))
      (hellmacs-run-hooks 'hellmacs-first-file-hook 'hellmacs-first-buffer-hook)
      (setq hellmacs-first-file-hook nil
            hellmacs-first-buffer-hook nil))
    (hellmacs-run-hooks 'hellmacs-after-init-hook)
    (hellmacs-context-pop 'startup)))

(add-hook 'elpaca-after-init-hook #'hellmacs-finalize 90)

;;; GC lifecycle -------------------------------------------------------
;;
;; `early-init.el' maxed out `gc-cons-threshold' to get through boot
;; without collection pauses. Left unbounded permanently, though, GC
;; pauses get *worse* during editing -- a huge collection lands
;; mid-keystroke instead of being spread out. Restore a generous but
;; bounded value once startup finishes, then only collect while Emacs
;; is idle so pauses stay invisible to typing.

(defun hellmacs--restore-gc-h ()
  "Restore a bounded GC threshold after startup finishes."
  (setq gc-cons-threshold hellmacs--gc-cons-threshold
        gc-cons-percentage hellmacs--gc-cons-percentage))

(add-hook 'elpaca-after-init-hook #'hellmacs--restore-gc-h)

(defvar hellmacs--idle-gc-timer
  (run-with-idle-timer 15 t (lambda () (garbage-collect)))
  "Collect garbage after 15s of idle time instead of on the allocation
that happens to cross the threshold -- so collection never lands
mid-keystroke or mid-scroll.")

;; The minibuffer is the other place users perceive GC pauses acutely
;; (an autocomplete candidate list stuttering as they type). Suspend
;; collection entirely for the duration of minibuffer input.
(add-hook! 'minibuffer-setup-hook
  (defun hellmacs--defer-gc-h ()
    (setq gc-cons-threshold most-positive-fixnum)))
(add-hook! 'minibuffer-exit-hook
  (defun hellmacs--restore-gc-threshold-h ()
    (setq gc-cons-threshold hellmacs--gc-cons-threshold)))

;;; Directory isolation --------------------------------------------------
;;
;; Hand-rolled equivalent of what `no-littering' provides: redirect
;; every built-in feature that wants to write state to disk into
;; `hellmacs-var-dir' (disposable) or `hellmacs-etc-dir' (persistent),
;; instead of scattering dotfiles across `user-emacs-directory'.

(make-directory (expand-file-name "backup/" hellmacs-var-dir) t)
(make-directory (expand-file-name "auto-save/" hellmacs-var-dir) t)

(setq custom-file (expand-file-name "custom.el" hellmacs-var-dir)
      backup-directory-alist (list (cons "." (expand-file-name "backup/" hellmacs-var-dir)))
      auto-save-file-name-transforms (list (list ".*" (expand-file-name "auto-save/" hellmacs-var-dir) t))
      auto-save-list-file-prefix (expand-file-name "auto-save/.saves-" hellmacs-var-dir)
      bookmark-default-file (expand-file-name "bookmarks" hellmacs-etc-dir)
      savehist-file (expand-file-name "savehist" hellmacs-var-dir)
      save-place-file (expand-file-name "save-place" hellmacs-var-dir)
      recentf-save-file (expand-file-name "recentf" hellmacs-var-dir)
      tramp-persistency-file-name (expand-file-name "tramp" hellmacs-var-dir)
      eshell-directory-name (expand-file-name "eshell/" hellmacs-var-dir)
      transient-history-file (expand-file-name "transient/history.el" hellmacs-var-dir)
      transient-levels-file (expand-file-name "transient/levels.el" hellmacs-var-dir)
      transient-values-file (expand-file-name "transient/values.el" hellmacs-var-dir))

;; Custom vars/faces may reference packages Elpaca installs, so load
;; `custom-file' only after Elpaca has activated everything queued in
;; `init.el' -- not eagerly here. See Elpaca's install notes.
(add-hook 'elpaca-after-init-hook
          (lambda () (load custom-file 'noerror 'nomessage)))

;; None of these are needed until the user actually does something, so
;; start them lazily instead of paying their file IO at boot.
(add-hook 'hellmacs-first-input-hook #'savehist-mode)
(add-hook 'hellmacs-first-file-hook #'recentf-mode)
(add-hook 'hellmacs-first-file-hook #'save-place-mode)

;;; Sane global defaults --------------------------------------------------

(setq-default indent-tabs-mode nil
              tab-width 4
              fill-column 80
              truncate-lines t
              cursor-in-non-selected-windows nil)

(setq ring-bell-function #'ignore
      visible-bell nil
      use-short-answers t            ; Emacs 28+: y/n instead of yes/no
      confirm-kill-emacs #'y-or-n-p
      create-lockfiles nil           ; TRAMP/CI mostly; local editing rarely needs them
      load-prefer-newer t
      sentence-end-double-space nil
      require-final-newline t
      help-window-select t           ; jump straight into *Help* buffers
      delete-by-moving-to-trash t
      large-file-warning-threshold (* 50 1024 1024))

(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)
(delete-selection-mode 1)
(electric-pair-mode 1)
(show-paren-mode 1)

(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(prefer-coding-system 'utf-8)

(provide 'hellmacs-core)
;;; hellmacs-core.el ends here
