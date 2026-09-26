;;; test-sync.el --- Tests for core/hellmacs-sync.el -*- lexical-binding: t; -*-

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
(require 'hellmacs-sync)
(or (require 'loaddefs-gen nil t)
    (require 'autoload nil t))

(ert-deftest test-sync/make-autoload-defun ()
  "Generates autoload form for defun declarations."
  (let* ((form '(defun my-custom-cmd () "Docstring" (interactive) nil))
         (file "/tmp/test-autoload.el")
         (al (hellmacs-sync--make-autoload form file)))
    (should (eq (car al) 'autoload))
    (should (equal (cadr al) ''my-custom-cmd))
    (should (equal (nth 2 al) file))
    (should (equal (nth 4 al) t))))

(ert-deftest test-sync/make-autoload-defmacro ()
  "Generates autoload form for defmacro declarations."
  (let* ((form '(defmacro my-custom-macro (x) "Macro doc" `(+ 1 ,x)))
         (file "/tmp/test-autoload.el")
         (al (hellmacs-sync--make-autoload form file)))
    (should (eq (car al) 'autoload))
    (should (equal (cadr al) ''my-custom-macro))
    (should (equal (nth 2 al) file))))

(ert-deftest test-sync/profile-paths ()
  "Profile and compiled directories are properly anchored to data directory."
  (should (string-prefix-p hellmacs-data-dir hellmacs-profile-dir))
  (should (string-prefix-p hellmacs-profile-dir hellmacs-compiled-dir)))

(provide 'test-sync)
;;; test-sync.el ends here
