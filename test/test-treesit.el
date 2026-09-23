;;; test-debugger.el --- Tests for the :tools debugger module -*- lexical-binding: t; -*-

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


;; Run with `bin/hellmacs test'. The pin and build logic runs against a
;; tiny local git repository; real grammars are checked by the Phase 8.1
;; probes (see docs/roadmap.md).

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'hellmacs-treesit)

(defun test-treesit--git (dir &rest args)
  (with-temp-buffer
    (let ((default-directory (file-name-as-directory dir)))
      (unless (zerop (apply #'call-process "git" nil t nil
                            "-c" "user.name=t" "-c" "user.email=t@example.invalid" args))
        (error "git %s: %s" args (buffer-string)))
      (string-trim (buffer-string)))))

(defun test-treesit--fake-grammar (root)
  "Make a git repo under ROOT with a compilable src/parser.c, tagged v1.
Returns (URL TAG COMMIT)."
  (let ((repo (expand-file-name "fake-grammar" root)))
    (make-directory (expand-file-name "src" repo) t)
    (with-temp-file (expand-file-name "src/parser.c" repo)
      (insert "const void *tree_sitter_fake(void) { return 0; }\n"))
    (test-treesit--git repo "init" "-q")
    (test-treesit--git repo "add" ".")
    (test-treesit--git repo "commit" "-q" "-m" "grammar")
    (test-treesit--git repo "tag" "v1")
    (list (concat "file://" repo) "v1" (test-treesit--git repo "rev-parse" "HEAD"))))

(defmacro test-treesit--with-fake (&rest body)
  "Run BODY with `fake' pinned in `hellmacs-treesit-sources' and a temp install dir."
  (declare (indent 0))
  `(progn
     (skip-unless (and (executable-find "git") (executable-find "cc")))
     (let* ((root (make-temp-file "hellmacs-test-treesit" t))
            (source (test-treesit--fake-grammar root))
            (hellmacs-treesit-dir (expand-file-name "out/" root))
            (hellmacs-treesit-sources (list (cons 'fake source))))
       (unwind-protect (progn ,@body)
         (delete-directory root t)))))

(ert-deftest test-treesit/builds-the-pinned-commit ()
  (test-treesit--with-fake
    (should-not (file-exists-p (hellmacs-treesit-library 'fake)))
    (hellmacs-treesit-install 'fake)
    (should (file-exists-p (hellmacs-treesit-library 'fake)))
    ;; Nothing but the library is left in the install directory.
    (should (equal (directory-files hellmacs-treesit-dir nil "\\`[^.]")
                   (list (file-name-nondirectory (hellmacs-treesit-library 'fake)))))))

(ert-deftest test-treesit/refuses-a-moved-tag ()
  "A tag that no longer points at the pinned commit installs nothing."
  (test-treesit--with-fake
    (setcar (nthcdr 2 (cdr (assq 'fake hellmacs-treesit-sources)))
            "0000000000000000000000000000000000000000")
    (should-error (hellmacs-treesit-install 'fake))
    (should-not (file-exists-p (hellmacs-treesit-library 'fake)))
    (should-not (and (file-directory-p hellmacs-treesit-dir)
                     (directory-files hellmacs-treesit-dir nil "\\`[^.]")))))

(ert-deftest test-treesit/sources-and-needs ()
  (let ((hellmacs-treesit-wanted nil))
    (hellmacs-treesit-need 'kotlin)
    (hellmacs-treesit-need 'kotlin)
    (hellmacs-treesit-need 'java)
    (should (equal hellmacs-treesit-wanted '(java kotlin))))
  ;; Every shipped grammar names a tag and a full commit.
  (dolist (entry hellmacs-treesit-default-sources)
    (should (string-prefix-p "https://" (nth 1 entry)))
    (should (nth 2 entry))
    (should (string-match-p "\\`[0-9a-f]\\{40\\}\\'" (nth 3 entry))))
  (should-error (hellmacs-treesit-install 'no-such-language)))

(provide 'test-treesit)
;;; test-treesit.el ends here
