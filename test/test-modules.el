;;; test-modules.el --- Tests for core/hellmacs-modules.el -*- lexical-binding: t; -*-

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
(require 'hellmacs-modules)

(defmacro test-modules--with-module-dir (spec &rest body)
  "Run BODY with a temporary private module tree ahead of Hellmacs' own.
SPEC is a list of (\"group/name/file.el\" . CONTENTS)."
  (declare (indent 1))
  `(let* ((root (make-temp-file "hellmacs-test-modules" t))
          (hellmacs-module-load-path (list root hellmacs-modules-dir))
          (hellmacs-modules (make-hash-table :test #'equal)))
     (unwind-protect
         (progn
           (pcase-dolist (`(,file . ,contents) ,spec)
             (let ((path (expand-file-name file root)))
               (make-directory (file-name-directory path) t)
               (with-temp-file path (insert contents))))
           ,@body)
       (delete-directory root t))))

(ert-deftest test-modules/hellmacs!-order-flags-depth ()
  (let ((hellmacs-modules (make-hash-table :test #'equal)))
    (hellmacs--enable-modules '(:ui theme :completion vertico (corfu +tab)
                                :config (default :depth -10)))
    (should (equal (hellmacs-module-list)
                   '((:config . default) (:ui . theme)
                     (:completion . vertico) (:completion . corfu))))
    (should (modulep! :completion corfu +tab))
    (should-not (modulep! :completion corfu -tab))
    (should (modulep! :completion vertico -tab))
    (should-not (modulep! :lang java))))

(ert-deftest test-modules/unknown-module-is-skipped ()
  (let ((hellmacs-modules (make-hash-table :test #'equal))
        (warning-minimum-log-level :emergency))
    (hellmacs--enable-modules '(:lang no-such-module :ui theme))
    (should (equal (hellmacs-module-list) '((:ui . theme))))))

(ert-deftest test-modules/private-module-overrides-and-modulep! ()
  "A private module wins over a built-in one; `modulep!' works inside it."
  (defvar test-modules--result nil)
  (test-modules--with-module-dir
      '(("ui/theme/config.el" . "(setq test-modules--result (list :x (modulep! +x) :not-y (modulep! -y)))"))
    (hellmacs--enable-modules '(:ui (theme +x)))
    (should-not (string-prefix-p hellmacs-modules-dir
                                 (hellmacs-module-get '(:ui . theme) :path)))
    (hellmacs-module--load '(:ui . theme) "config.el")
    (should (equal test-modules--result '(:x t :not-y t)))))

(ert-deftest test-modules/package!-declarations ()
  (let ((hellmacs-packages nil)
        (hellmacs--current-module nil))
    (package! a)
    (package! b :recipe (:host github :repo "x/b") :pin "abc")
    (package! which-key :built-in 'prefer)
    (package! c :disable t)
    (package! a :pin "v1")
    (should (equal (hellmacs-package--order 'a (alist-get 'a hellmacs-packages)) '(a :ref "v1")))
    (should (equal (hellmacs-package--order 'b (alist-get 'b hellmacs-packages))
                   '(b :host github :repo "x/b" :ref "abc")))
    (should-not (hellmacs-package--order 'which-key (alist-get 'which-key hellmacs-packages)))
    (should-not (hellmacs-package--order 'c (alist-get 'c hellmacs-packages)))
    (should (equal (plist-get (alist-get 'a hellmacs-packages) :modules) '(:user :user)))))

(ert-deftest test-modules/package!-disable-silences-use-package ()
  (let ((hellmacs-packages nil))
    (package! c :disable t)
    (should-not (macroexpand '(use-package c :demand t)))
    (should (macroexpand '(use-package d :demand t)))))

(ert-deftest test-modules/package!-env ()
  "A literal alist is accepted, and applied unless the package is disabled."
  (let ((hellmacs-packages nil)
        (process-environment (copy-sequence process-environment)))
    (package! envy :env (("HELLMACS_TEST_ENV" . "on")))
    (package! off :disable t :env (("HELLMACS_TEST_OFF" . "on")))
    (hellmacs-packages-apply-env)
    (should (equal (getenv "HELLMACS_TEST_ENV") "on"))
    (should-not (getenv "HELLMACS_TEST_OFF"))))

(ert-deftest test-modules/cli-files-load-once ()
  "Loading every cli.el twice in a session runs each only once."
  (defvar test-modules--cli-loads 0)
  (setq test-modules--cli-loads 0)
  (test-modules--with-module-dir
      '(("tools/probe/cli.el" . "(setq test-modules--cli-loads (1+ test-modules--cli-loads))"))
    (let ((hellmacs--loaded-cli-files nil))
      (hellmacs--enable-modules '(:tools probe))
      (hellmacs-modules-load-cli-files)
      (hellmacs-modules-load-cli-files)
      (should (= test-modules--cli-loads 1)))))

(provide 'test-modules)
;;; test-modules.el ends here
