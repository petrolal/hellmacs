;;; hellmacs-packages.el --- Package management settings -*- lexical-binding: t; -*-

;; Hellmacs uses Elpaca (https://github.com/progfolio/elpaca), not
;; package.el or straight.el. Both Elpaca and straight.el give
;; reproducible, git-based installs instead of package.el's tarball
;; snapshots, but Elpaca installs in parallel and its
;; `elpaca-use-package-mode' integration is simple.
;;
;; Elpaca itself is only loaded when something has to be installed or
;; built: by `hellmacs-sync', or at a startup that has no up-to-date
;; synced profile (see `hellmacs-modules-startup'). A synced startup
;; just adds the recorded build directories to `load-path' and loads
;; their autoloads -- no package manager involved.

;;; Code:

(defvar elpaca-directory (expand-file-name "elpaca/" hellmacs-data-dir))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-sources-directory (expand-file-name "sources/" elpaca-directory))

(defun hellmacs-packages-bootstrap ()
  "Load Elpaca, installing it first if needed. Safe to call repeatedly."
  (require 'hellmacs-elpaca))

;;; use-package ------------------------------------------------------------

;; Installing and configuring are separate, as in Doom: modules declare
;; what to install with `package!' in their packages.el (see
;; `hellmacs-modules'), and configure it with `use-package' in their
;; config.el. So `use-package' doesn't install anything by default.
(require 'use-package)

;; Modules should never eagerly load a package just by mentioning it.
;; Every `use-package' block opts into loading explicitly via
;; `:demand t', `:defer t' + `:hook'/`:bind'/`:commands', or
;; autoloading -- never by omission.
(setq use-package-always-defer t
      use-package-always-ensure nil
      use-package-expand-minimally t)

;; An explicit `:ensure' only works when Elpaca is loaded (where
;; `elpaca-use-package-mode' takes it over). On a synced startup it
;; would otherwise fall through to package.el, so point it here.
(setq use-package-ensure-function #'hellmacs--use-package-ensure)

(defun hellmacs--use-package-ensure (name args _state &optional _no-refresh)
  "Warn that `:ensure' ARGS for NAME are ignored; `package!' replaces it."
  (when (car args)
    (display-warning
     'hellmacs
     (format "`use-package %s :ensure' is ignored. Declare it with `(package! %s)' \
in packages.el, then run `bin/hellmacs sync'." name name))))

(provide 'hellmacs-packages)
;;; hellmacs-packages.el ends here
