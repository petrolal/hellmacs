;;; test-core.el --- Tests for core/hellmacs-core.el and -packages.el -*- lexical-binding: t; -*-

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

;; Run with `bin/hellmacs test'.

;;; Code:

(require 'ert)
(require 'hellmacs-core)
(require 'hellmacs-packages)

(defmacro test-core--with-features (features &rest body)
  "Run BODY with each of FEATURES loadable from a temporary directory."
  (declare (indent 1))
  `(let* ((dir (make-temp-file "hellmacs-test-features" t))
          (load-path (cons dir load-path)))
     (unwind-protect
         (progn
           (dolist (f ,features)
             (with-temp-file (expand-file-name (format "%s.el" f) dir)
               (insert (format "(provide '%s)\n" f))))
           ,@body)
       (delete-directory dir t))))

(ert-deftest test-core/incremental-loading ()
  "Queued in order without duplicates, loaded one per call."
  (test-core--with-features '(test-core-feat-a test-core-feat-b)
    (let ((hellmacs-incremental-packages nil))
      (hellmacs-load-incrementally '(test-core-feat-a test-core-feat-b test-core-feat-a))
      (should (equal hellmacs-incremental-packages '(test-core-feat-a test-core-feat-b)))
      (cl-letf (((symbol-function 'run-with-idle-timer) #'ignore))
        (hellmacs--load-next-incrementally)
        (should (featurep 'test-core-feat-a))
        (should-not (featurep 'test-core-feat-b))
        (hellmacs--load-next-incrementally))
      (should (featurep 'test-core-feat-b))
      (should-not hellmacs-incremental-packages))))

(ert-deftest test-core/incremental-skips-loaded ()
  (let ((hellmacs-incremental-packages nil))
    (hellmacs-load-incrementally '(hellmacs-lib))
    (should-not hellmacs-incremental-packages)))

(ert-deftest test-core/use-package-defer-incrementally ()
  (should (string-match-p "hellmacs-load-incrementally '(foo)"
                          (format "%S" (macroexpand-all '(use-package foo :defer-incrementally t)))))
  (should (string-match-p "hellmacs-load-incrementally '(clojure-mode sesman cider)"
                          (format "%S" (macroexpand-all
                                        '(use-package cider :defer-incrementally (clojure-mode sesman)))))))

(ert-deftest test-core/sync-discards-only-empty-checkouts ()
  "A failed clone that left just .git is removed; a real checkout is kept."
  (require 'hellmacs-sync)
  (let* ((root (make-temp-file "hellmacs-test-src" t))
         (empty (expand-file-name "empty" root))
         (full (expand-file-name "full" root)))
    (unwind-protect
        (progn
          (make-directory (expand-file-name ".git" empty) t)
          (make-directory (expand-file-name ".git" full) t)
          (with-temp-file (expand-file-name "pkg.el" full) (insert ";; pkg"))
          (should (hellmacs-sync--discard-empty-checkout empty))
          (should-not (file-exists-p empty))
          (should-not (hellmacs-sync--discard-empty-checkout full))
          (should (file-exists-p (expand-file-name "pkg.el" full)))
          (should-not (hellmacs-sync--discard-empty-checkout (expand-file-name "missing" root))))
      (delete-directory root t))))

(provide 'test-core)
;;; test-core.el ends here
