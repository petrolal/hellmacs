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
    (should (hellmacs-treesit-current-p 'fake))
    ;; Nothing but the library and its commit marker is left.
    (should (equal (sort (directory-files hellmacs-treesit-dir nil "\\`[^.]") #'string<)
                   (sort (list (file-name-nondirectory (hellmacs-treesit-library 'fake))
                               (file-name-nondirectory (hellmacs-treesit--marker 'fake)))
                         #'string<)))
    ;; A library built from another commit (an older pin) isn't current.
    (with-temp-file (hellmacs-treesit--marker 'fake) (insert "0000\n"))
    (should-not (hellmacs-treesit-current-p 'fake))
    (delete-file (hellmacs-treesit--marker 'fake))
    (should-not (hellmacs-treesit-current-p 'fake))))

(ert-deftest test-treesit/builds-a-grammar-in-a-subdirectory ()
  "A DIRECTORY entry compiles that subdirectory's src/, as markdown-inline needs."
  (skip-unless (and (executable-find "git") (executable-find "cc")))
  (let* ((root (make-temp-file "hellmacs-test-treesit" t))
         (repo (expand-file-name "mono" root))
         (hellmacs-treesit-dir (expand-file-name "out/" root)))
    (unwind-protect
        (progn
          (make-directory (expand-file-name "inner/src" repo) t)
          (with-temp-file (expand-file-name "inner/src/parser.c" repo)
            (insert "const void *tree_sitter_fake(void) { return 0; }\n"))
          (test-treesit--git repo "init" "-q")
          (test-treesit--git repo "add" ".")
          (test-treesit--git repo "commit" "-q" "-m" "x")
          (let ((hellmacs-treesit-sources
                 (list (list 'fake (concat "file://" repo) "main"
                             (test-treesit--git repo "rev-parse" "HEAD") "inner"))))
            (hellmacs-treesit-install 'fake)
            (should (file-exists-p (hellmacs-treesit-library 'fake)))))
      (delete-directory root t))))

(ert-deftest test-treesit/refuses-a-commit-that-is-not-there ()
  "A pin the source can't supply installs nothing."
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
  ;; Every shipped grammar names a label and a full commit.
  (dolist (entry hellmacs-treesit-default-sources)
    (should (string-prefix-p "https://" (nth 1 entry)))
    (should (nth 2 entry))
    (should (string-match-p "\\`[0-9a-f]\\{40\\}\\'" (nth 3 entry)))
    (should (or (null (nth 4 entry)) (stringp (nth 4 entry)))))
  ;; clojure-ts-mode's three grammars are all known.
  (dolist (lang '(clojure markdown-inline regex))
    (should (assq lang hellmacs-treesit-default-sources)))
  (should-error (hellmacs-treesit-install 'no-such-language)))

(provide 'test-treesit)
;;; test-treesit.el ends here
