;;; test-cli.el --- Tests for core/hellmacs-cli.el -*- lexical-binding: t; -*-

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
(require 'cl-lib)
(require 'hellmacs-cli)

(ert-deftest test-cli/run-all ()
  "Commands run concurrently; exit codes come back in order."
  (let ((hellmacs-cli-jobs 2))
    (should (equal (hellmacs-cli--run-all '(("sh" "-c" "exit 3") ("true") ("sh" "-c" "sleep 0.2; exit 1")
                                            ("hellmacs-no-such-program") ("false")))
                   '(3 0 1 127 1))))
  (should (equal (hellmacs-cli--run-all nil) nil)))

(ert-deftest test-cli/detached-checkouts ()
  "Only checkouts on a detached HEAD are picked; others, and non-repos, aren't."
  (skip-unless (executable-find "git"))
  (let ((root (make-temp-file "hellmacs-test-cli" t)))
    (unwind-protect
        (let ((git (lambda (dir &rest args)
                     (apply #'call-process "git" nil nil nil "-C" dir
                            "-c" "user.name=t" "-c" "user.email=t@example.invalid" args))))
          (dolist (name '("on-branch" "detached"))
            (let ((dir (expand-file-name name root)))
              (make-directory dir)
              (funcall git dir "init" "-q")
              (funcall git dir "commit" "-q" "--allow-empty" "-m" "x")))
          (funcall git (expand-file-name "detached" root) "checkout" "-q" "--detach")
          (make-directory (expand-file-name "not-a-repo" root))
          (cl-letf (((symbol-function 'elpaca<-source-dir) (lambda (e) (expand-file-name e root))))
            (should (equal (hellmacs-cli--detached '("on-branch" "detached" "not-a-repo" "missing"))
                           '("detached")))))
      (delete-directory root t))))

(provide 'test-cli)
;;; test-cli.el ends here
