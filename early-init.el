;;; early-init.el --- Hellmacs early initialization -*- lexical-binding: t; no-byte-compile: t; -*-

;; This file is loaded before `package.el', before `init.el', and
;; before the first frame is created.  Everything here exists to
;; make startup fast and to keep the first frame from flashing
;; stock Emacs chrome before Hellmacs gets a chance to configure it.
;; Nothing in here should depend on a third-party package.

;;; Code:

;;; 1. Directory layout --------------------------------------------
;;
;; Defined here, first, because both the performance tuning below
;; and every file loaded after this one need to know where Hellmacs'
;; disposable (var/) and persistent (etc/) state lives.

(defconst hellmacs-dir
  (file-name-directory (file-truename (or load-file-name buffer-file-name)))
  "Root directory of the Hellmacs distribution.")

(defconst hellmacs-core-dir (expand-file-name "core/" hellmacs-dir)
  "Directory holding Hellmacs engine internals (bootstrap, package manager).")

(defconst hellmacs-modules-dir (expand-file-name "modules/" hellmacs-dir)
  "Directory holding user-facing Hellmacs feature modules.")

(defconst hellmacs-var-dir (expand-file-name "var/" hellmacs-dir)
  "Machine-generated, disposable state: package installs, caches, history.
Safe to delete; Hellmacs recreates whatever it needs on the next start.")

(defconst hellmacs-etc-dir (expand-file-name "etc/" hellmacs-dir)
  "Machine-generated, persistent data: bookmarks and similar user data.
Not safe to delete casually -- unlike `hellmacs-var-dir', losing this
loses actual user state, not just cache.")

(dolist (dir (list hellmacs-var-dir hellmacs-etc-dir))
  (unless (file-directory-p dir)
    (make-directory dir t)))

;;; 2. Startup performance: GC ---------------------------------------
;;
;; Emacs runs a GC check on every allocation, which adds up over the
;; hundreds of `require'/`load' calls a full startup performs. Raise
;; the threshold as high as possible for the duration of boot;
;; `hellmacs-core' restores a bounded runtime value once startup
;; finishes (see `hellmacs--restore-gc-h' there).

(defvar hellmacs--gc-cons-threshold (* 16 1024 1024)
  "GC threshold Hellmacs restores once startup completes.")
(defvar hellmacs--gc-cons-percentage 0.1
  "GC percentage Hellmacs restores once startup completes.")

(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 1.0)

;;; 3. Startup performance: file-name-handler-alist -------------------
;;
;; Consulted on every `require'/`load'/`expand-file-name' call to
;; check for TRAMP, compressed, or encrypted file names. Emptying it
;; during boot skips that check entirely for the hundreds of local,
;; plain-text elisp files Hellmacs loads at startup; the original
;; value is restored immediately after so TRAMP, .gz, and encrypted
;; files keep working for the rest of the session.

(defvar hellmacs--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist hellmacs--file-name-handler-alist)))

;;; 4. package.el: disabled in favor of Elpaca -------------------------
;;
;; Hellmacs bootstraps Elpaca itself (see `hellmacs-packages'). Letting
;; `package.el' also initialize at startup would scan and autoload a
;; redundant, conflicting package system for no benefit.

(setq package-enable-at-startup nil)

;;; 5. Native compilation ----------------------------------------------

(when (featurep 'native-compile)
  ;; Redirect .eln files out of `user-emacs-directory'/eln-cache and
  ;; into var/, so Hellmacs' footprint stays entirely inside its own
  ;; directory and `hellmacs-var-dir' remains the single thing that's
  ;; safe to delete to reset all machine-generated state.
  (when (fboundp 'startup-redirect-eln-cache)
    (startup-redirect-eln-cache (expand-file-name "eln-cache/" hellmacs-var-dir)))
  ;; Compile asynchronously instead of blocking the editor, and don't
  ;; pop up a warnings buffer for every third-party package that trips
  ;; a (usually harmless) native-comp warning during first compile.
  (setq native-comp-async-report-warnings-errors 'silent
        native-comp-jit-compilation t
        native-comp-async-jobs-number
        (max 1 (if (fboundp 'num-processors) (/ (num-processors) 2) 2))))

;;; 6. UI: unset chrome before the first frame is drawn -----------------
;;
;; Setting these as frame parameters (rather than calling
;; `menu-bar-mode' etc. later from `init.el') avoids allocating the
;; widgets in the first place. That is both faster and prevents the
;; "flash" of a fully-chromed default frame before Hellmacs' own
;; config has a chance to run.

(setq default-frame-alist
      (append '((menu-bar-lines . 0)
                (tool-bar-lines . 0)
                (vertical-scroll-bars . nil)
                (horizontal-scroll-bars . nil))
              default-frame-alist))

;; Belt-and-suspenders: also set the minor-mode variables so a later
;; `make-frame' (e.g. a new frame opened mid-session) stays consistent
;; even if something toggles a mode instead of touching frame params.
(setq menu-bar-mode nil
      tool-bar-mode nil
      scroll-bar-mode nil
      tooltip-mode nil)

(setq inhibit-startup-screen t
      inhibit-startup-echo-area-message user-login-name
      initial-scratch-message nil
      inhibit-default-init t
      ;; Resizing the frame to match font metrics on every startup and
      ;; theme load is a measurable, avoidable cost; do it once.
      frame-inhibit-implied-resize t)

;; Site-wide defaults (site-start.el, default.el) almost always either
;; duplicate or actively conflict with a config as opinionated as a
;; full distribution's.
(setq site-run-file nil)

(provide 'early-init)
;;; early-init.el ends here
