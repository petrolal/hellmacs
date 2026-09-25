;;; hellmacs-sync.el --- Install packages and write the synced profile -*- lexical-binding: t; -*-

;; Copyright (C) 2026 petrolal <petrolalucas@gmail.com>
;;
;; Author: petrolal <petrolalucas@gmail.com>
;; URL: https://github.com/petrolal/hellmacs
;; License: GPL-3.0-or-later
;;
;; This file is part of Hellmacs.
;;
;; Hellmacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; Hellmacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;; `hellmacs-sync' is the equivalent of `doom sync'. Run it (usually as
;; `bin/hellmacs sync') whenever you change your `hellmacs!' block, a
;; packages.el, or a module's autoload.el. It:
;;
;;   1. reads your init.el's `hellmacs!' block and every packages.el
;;   2. installs and builds anything missing, through Elpaca
;;   3. writes a profile (see "Synced profile" in hellmacs-modules.el)
;;      so that startup can activate packages without Elpaca
;;
;; Startup notices when the profile is out of date and falls back to
;; activating packages live, so forgetting to sync slows startup down
;; but never breaks it.
;;
;; Not loaded at startup; `bin/hellmacs' (core/hellmacs-cli.el) and
;; `M-x hellmacs-sync' load it.

;;; Code:

(require 'hellmacs-lib)
(require 'hellmacs-core)
(require 'hellmacs-packages)
(require 'hellmacs-keybinds)
(require 'hellmacs-modules)
(require 'hellmacs-treesit)

(defvar hellmacs-sync-functions nil
  "Functions run, in order, at the end of every `hellmacs-sync'.
Called with no arguments after packages are installed and the profile
is written. A module's cli.el adds to it, e.g. to download a tool the
module needs. An error fails the sync.")

;; Registered first, so a module's own sync steps (which may want a
;; grammar) come after it. What to build was declared by the modules'
;; cli.el files, all loaded by the time this runs.
(add-hook 'hellmacs-sync-functions #'hellmacs-treesit-sync -90)

(defun hellmacs-sync--log (format-string &rest args)
  "Report progress: FORMAT-STRING with ARGS, on stdout in batch mode."
  (let ((msg (apply #'format format-string args)))
    (if noninteractive
        (princ (concat msg "\n"))
      (message "Hellmacs sync: %s" msg))))

(defun hellmacs-sync-download-verified (url dest sha256 label)
  "Download URL to DEST, but only keep it if its SHA-256 is SHA256.
LABEL names the file in errors. It goes through a .part file, so
nothing ever sees a bad or half-written download. For a module's sync
step that fetches a pinned tool."
  (let ((tmp (concat dest ".part")))
    (make-directory (file-name-directory dest) t)
    (unwind-protect
        (progn
          (url-copy-file url tmp t)
          (unless (equal (hellmacs-file-sha256 tmp) sha256)
            (error "%s download from %s failed its SHA-256 check; not installed" label url))
          (rename-file tmp dest t))
      ;; Only left if the download failed, or failed its check.
      (when (file-exists-p tmp)
        (delete-file tmp)))))

(defun hellmacs-sync-install-zip (label url sha256 dir marker install-fn)
  "Install LABEL from the zip at URL, pinned by SHA256, into DIR.
The download is checked (`hellmacs-sync-download-verified') and unpacked
into a temporary directory; INSTALL-FN is called with that directory to
move what it needs into place. MARKER then records SHA256 (see
`hellmacs-marker-current-p'). Nothing is left behind on failure."
  (unless (executable-find "unzip")
    (error "unzip is needed to install %s" label))
  (let ((zip (expand-file-name (concat (file-name-base url) ".zip") dir))
        (stage (make-temp-file "hellmacs-unzip" t)))
    (unwind-protect
        (progn
          (hellmacs-sync-download-verified url zip sha256 label)
          (with-temp-buffer
            (unless (zerop (call-process "unzip" nil t nil "-q" "-o" zip "-d" stage))
              (error "Unpacking %s failed: %s" label (buffer-string))))
          (funcall install-fn stage)
          (with-temp-file marker (insert sha256 "\n")))
      (delete-directory stage t)
      (when (file-exists-p zip) (delete-file zip)))))

(defun hellmacs-sync--packages ()
  "Return the installed Elpaca records for every declared package.
Includes their dependencies, with each package after the packages it
depends on, so autoloads load in a safe order."
  (let (seen ordered)
    (cl-labels ((visit (id)
                  (unless (memq id seen)
                    (push id seen)
                    (when-let* ((e (elpaca-get id)))
                      (dolist (dep (elpaca--dependencies e))
                        (visit (car dep)))
                      (push e ordered)))))
      (pcase-dolist (`(,name . ,plist) (reverse hellmacs-packages))
        (when (hellmacs-package--order name plist)
          (visit name))))
    (nreverse ordered)))

(defun hellmacs-sync--autoloads-file (e)
  "Return the autoloads file Elpaca generated for package record E, or nil.
Follows the recipe's :autoloads, as `elpaca-activate' does."
  (let* ((recipe (elpaca<-recipe e))
         (member (plist-member recipe :autoloads))
         (key (if member (cadr member) t))
         (file (and key
                    (expand-file-name (if (stringp key) key
                                        (concat (elpaca<-package e) "-autoloads.el"))
                                      (elpaca<-build-dir e)))))
    (and file (file-exists-p file) file)))

(defun hellmacs-sync--make-autoload (form file)
  "Return the `autoload' form for definition FORM from FILE, or nil.
The function doing this was `make-autoload' until Emacs 30, and is
`loaddefs-generate--make-autoload' since. (`loaddefs-generate' itself
writes file names relative to its output file, which doesn't suit a
profile living outside the checkout.)"
  (funcall (if (fboundp 'loaddefs-generate--make-autoload)
               #'loaddefs-generate--make-autoload
             'make-autoload)
           form file))

(defun hellmacs-sync--module-autoloads ()
  "Return autoload forms for every `;;;###autoload' in modules' autoload.el.
A cookie before a definition yields an `autoload' form; before any
other form, the form itself is kept, as in Emacs' own loaddefs."
  (require 'loaddefs-gen)
  (let (forms)
    (dolist (key (hellmacs-module-list))
      (let ((file (expand-file-name "autoload.el" (hellmacs-module-get key :path))))
        (when (file-exists-p file)
          (with-temp-buffer
            (insert-file-contents file)
            (emacs-lisp-mode)
            (goto-char (point-min))
            (while (re-search-forward "^;;;###autoload[ \t]*$" nil t)
              (let ((form (read (current-buffer))))
                (push (or (hellmacs-sync--make-autoload form (file-name-sans-extension file))
                          form)
                      forms)))))))
    (nreverse forms)))

(defun hellmacs-sync--write (file header data)
  "Write DATA (a list of forms) to FILE, after the comment HEADER."
  (make-directory (file-name-directory file) t)
  (with-temp-file file
    (let ((print-length nil) (print-level nil) (print-circle nil)
          (print-escape-newlines t) (print-quoted t))
      (insert header "\n")
      (dolist (form data)
        (prin1 form (current-buffer))
        (insert "\n")))))

(defun hellmacs-sync--write-profile ()
  "Write the profile for the current modules and installed packages."
  (let* ((packages (hellmacs-sync--packages))
         (stamp (format ";; Generated by `hellmacs-sync' on %s; don't edit."
                        (format-time-string "%F %T"))))
    (hellmacs-sync--write
     (hellmacs-profile-file "module-autoloads.el")
     (concat ";;; module-autoloads.el -*- lexical-binding: t; no-byte-compile: t -*-\n" stamp)
     (hellmacs-sync--module-autoloads))
    ;; Written last: its presence means the rest of the profile is complete.
    (hellmacs-sync--write
     (hellmacs-profile-file "profile.eld")
     (concat ";; -*- mode: lisp-data -*-\n" stamp)
     (list (list :emacs-version emacs-version
                 :modules (hellmacs-profile--modules)
                 :inputs (hellmacs-profile--inputs)
                 :packages hellmacs-packages
                 :dependencies hellmacs-module-dependencies
                 :treesit hellmacs-treesit-declarations
                 :load-path (mapcar #'elpaca<-build-dir packages)
                 :autoloads (delq nil (mapcar #'hellmacs-sync--autoloads-file packages)))))
    packages))

(defun hellmacs-sync--discard-empty-checkout (dir)
  "Delete DIR if it holds only a .git directory; return non-nil if it did.
A treeless clone whose checkout is cut short by the network is left
like this, and Elpaca takes it for a finished clone, so a second sync
would fail the same way. Removing it lets that sync clone again."
  (when (and (file-directory-p dir)
             (equal (directory-files dir nil directory-files-no-dot-files-regexp) '(".git")))
    (delete-directory dir t)
    t))

(defun hellmacs-sync--check-failures ()
  "Signal an error naming every declared package Elpaca didn't finish."
  (let ((failed (cl-loop for (name . plist) in hellmacs-packages
                         for e = (and (hellmacs-package--order name plist) (elpaca-get name))
                         when (and e (not (eq (elpaca<-status e) 'finished)))
                         do (hellmacs-sync--discard-empty-checkout (elpaca<-source-dir e))
                         and collect name)))
    (when failed
      (error "These packages failed to install: %s. Run the sync again; \
if they keep failing, see M-x elpaca-log in Emacs"
             (mapconcat #'symbol-name failed ", ")))))

;;;###autoload
(defun hellmacs-sync ()
  "Install every declared package, then write the synced profile.
Run it after changing your `hellmacs!' block, a packages.el, or a
module's autoload.el. Signals an error if a package fails to install."
  (interactive)
  ;; In a running session, packages may already be loaded from a synced
  ;; profile; tell Elpaca startup is over, so it doesn't warn about them.
  (when after-init-time
    (defvar elpaca-after-init-time)
    (setq elpaca-after-init-time (or (bound-and-true-p elpaca-after-init-time)
                                     after-init-time)))
  (hellmacs-sync--log "Reading modules and packages...")
  (hellmacs-modules-read-config)
  (hellmacs-modules-load-cli-files)
  (hellmacs-sync--log "Modules: %s"
                      (mapconcat (lambda (m) (format "%s %s" (car (car m)) (cdr (car m))))
                                 (hellmacs-profile--modules) ", "))
  (hellmacs-sync--log "Installing and building packages (this can take a while)...")
  (hellmacs-modules-install-packages)
  (hellmacs-modules-check-dependencies)
  (hellmacs-sync--check-failures)
  (let ((packages (hellmacs-sync--write-profile)))
    (hellmacs-sync--log "Synced %d packages; profile written to %s"
                        (length packages) (abbreviate-file-name hellmacs-profile-dir))
    (run-hooks 'hellmacs-sync-functions)
    (unless noninteractive
      (hellmacs-sync--log "done. Restart Emacs to start from the new profile."))))

(provide 'hellmacs-sync)
;;; hellmacs-sync.el ends here
