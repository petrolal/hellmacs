;;; hellmacs-core.el --- Core engine: GC lifecycle, dir isolation, sane defaults -*- lexical-binding: t; -*-

;; Everything in `core/' is engine plumbing every Hellmacs install
;; depends on regardless of which feature modules are enabled. This
;; file has no opinions about editing style -- no keybindings, no leader
;; keys, no completion UI, that's `modules/'. It only makes stock
;; Emacs behave sanely and keeps its droppings in Hellmacs' own XDG
;; directories instead of scattering them across `~'.
;;
;; Expects the `hellmacs-*-dir' variables,
;; `hellmacs--gc-cons-threshold' and `hellmacs--gc-cons-percentage' to
;; already be defined -- they're set in `early-init.el', which always
;; loads before this file.

;;; Code:

;;; Startup lifecycle ----------------------------------------------------
;;
;; Hellmacs' notion of "startup finished" is when every package is
;; activated, signalled by `hellmacs--packages-ready-hook'. When packages
;; come from a synced profile (see `hellmacs-sync') that's simply
;; `after-init-hook'. Without one, Elpaca activates them asynchronously
;; and it's `elpaca-after-init-hook' instead. `hellmacs-finalize' runs
;; from there.
;;
;; The `hellmacs-first-*' hooks let modules defer work until the user
;; actually needs it, instead of paying for it during boot. Each runs
;; exactly once, and never before `hellmacs-finalize'.

(defvar hellmacs-after-init-hook nil
  "Run once Hellmacs, its modules and their packages are fully loaded.")

(defvar hellmacs--packages-ready-hook nil
  "Run once every package is activated. Internal; fired by the module system.
Use `hellmacs-after-init-hook' instead.")

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

(add-hook 'hellmacs--packages-ready-hook #'hellmacs-finalize 90)

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

(add-hook 'hellmacs--packages-ready-hook #'hellmacs--restore-gc-h)

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
;; Keep Emacs' and packages' files out of the git checkout and out of
;; `~', split by kind (see the layout comment in `early-init.el').
;;
;; Most packages build their file paths from `user-emacs-directory'
;; (usually via `locate-user-emacs-file'). Pointing it at the cache dir
;; sends all of those there without configuring each package, as Doom
;; does. It's safe to change here: Emacs has already located init.el.
;; Anything that isn't disposable is redirected explicitly below.

(setq user-emacs-directory hellmacs-cache-dir)

(defun hellmacs-state-file (name)
  "Return the absolute path of NAME inside `hellmacs-state-dir'."
  (expand-file-name name hellmacs-state-dir))

(let ((backup-dir    (hellmacs-state-file "backup/"))
      (auto-save-dir (hellmacs-state-file "auto-save/")))
  (with-file-modes #o700
    (make-directory backup-dir t)
    (make-directory auto-save-dir t))
  (setq backup-directory-alist (list (cons "." backup-dir))
        auto-save-file-name-transforms (list (list ".*" auto-save-dir t))
        auto-save-list-file-prefix (expand-file-name ".saves-" auto-save-dir)))

(setq abbrev-file-name            (hellmacs-state-file "abbrev_defs")
      bookmark-default-file       (hellmacs-state-file "bookmarks")
      savehist-file               (hellmacs-state-file "savehist")
      save-place-file             (hellmacs-state-file "save-place")
      recentf-save-file           (hellmacs-state-file "recentf")
      tramp-persistency-file-name (hellmacs-state-file "tramp")
      eshell-directory-name       (hellmacs-state-file "eshell/")
      project-list-file           (hellmacs-state-file "projects")
      transient-history-file      (hellmacs-state-file "transient/history.el")
      transient-levels-file       (hellmacs-state-file "transient/levels.el")
      transient-values-file       (hellmacs-state-file "transient/values.el"))

;; Customize writes are user config, so they go next to the user's
;; init.el and config.el -- unless there is no user dir, in which case
;; they're kept as state instead of creating one behind the user's back.
(setq custom-file
      (if (file-directory-p hellmacs-user-dir)
          (expand-file-name "custom.el" hellmacs-user-dir)
        (hellmacs-state-file "custom.el")))

;; Custom vars/faces may reference installed packages, so load
;; `custom-file' only once every package is activated.
(add-hook 'hellmacs--packages-ready-hook
          (defun hellmacs--load-custom-file-h ()
            (load custom-file 'noerror 'nomessage)))

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
