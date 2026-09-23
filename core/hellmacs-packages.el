;;; hellmacs-packages.el --- Package manager bootstrap -*- lexical-binding: t; -*-

;; Hellmacs uses Elpaca (https://github.com/progfolio/elpaca) rather
;; than straight.el.  Both give reproducible, git-based installs
;; instead of package.el's tarball snapshots, but Elpaca installs
;; packages asynchronously/in parallel, which matters directly for
;; Hellmacs' startup-time goals, and its `elpaca-use-package-mode'
;; integration keeps every module's `use-package' block declarative
;; with no separate recipe step. straight.el remains the better
;; choice if you need its build-caching across machines or its
;; longer track record; Elpaca is the better choice for a
;; startup-performance-first, single-machine distribution, which is
;; Hellmacs' goal.
;;
;; The bootstrap block below is Elpaca's official installer (see its
;; README's "Installer" section), adapted only to redirect Elpaca's
;; own directory into `hellmacs-data-dir' instead of
;; `user-emacs-directory' (the git checkout).
;; Do not hand-edit it piecemeal; replace the whole block from
;; upstream when updating Elpaca's installer version.

;;; Code:

(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory (expand-file-name "elpaca/" hellmacs-data-dir))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-sources-directory (expand-file-name "sources/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                               :ref nil :depth 1 :inherit ignore
                               :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                               :build (:not elpaca-activate)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-sources-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                   ,@(when-let* ((depth (plist-get order :depth)))
                                                       (list (format "--depth=%d" depth) "--no-single-branch"))
                                                   ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;;; use-package integration --------------------------------------------

;; Installing and configuring are separate, as in Doom: modules declare
;; what to install with `package!' in their packages.el (see
;; `hellmacs-modules'), and configure it with `use-package' in their
;; config.el. So `use-package' doesn't install anything by default.
;; `elpaca-use-package-mode' is still enabled, so an explicit `:ensure t'
;; in your own config.el installs through Elpaca rather than package.el.
(elpaca elpaca-use-package
  (elpaca-use-package-mode)
  ;; Modules should never eagerly load a package just by mentioning it.
  ;; Every `use-package' block opts into loading explicitly via
  ;; `:demand t', `:defer t' + `:hook'/`:bind'/`:commands', or
  ;; autoloading -- never by omission.
  (setq use-package-always-defer t
        use-package-always-ensure nil
        use-package-expand-minimally t))

;; Block until Elpaca + elpaca-use-package are installed and activated,
;; before the module system and any `use-package' block run.
(elpaca-wait)

(provide 'hellmacs-packages)
;;; hellmacs-packages.el ends here
