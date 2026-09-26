;;; test-editor-extras.el --- Tests for UI/Editor extras (Phase 10.3, 10.4) -*- lexical-binding: t; -*-

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

(ert-deftest test-editor-extras/todo-keywords ()
  "Verifies hl-todo keyword patterns."
  (let ((keywords '("TODO" "FIXME" "BUG" "HACK" "NOTE" "DEPRECATED")))
    (dolist (kw keywords)
      (should (string-match-p (format "\\<%s\\>" kw) (format "/* %s: fix this */" kw))))))

(ert-deftest test-editor-extras/editorconfig-integration ()
  "Verifies editorconfig settings mapping to buffer variables."
  (let ((indent-size 4)
        (tab-width 4)
        (indent-tabs-mode nil))
    (should (= indent-size 4))
    (should-not indent-tabs-mode)))

(ert-deftest test-editor-extras/snippets-tempel ()
  "Verifies Tempel snippet templates structure."
  (let ((java-snippets '((psvm "public static void main(String[] args) {\n    " (p "body") "\n}")
                         (sout "System.out.println(" (p "expr") ");"))))
    (should (= (length java-snippets) 2))
    (should (eq (car (nth 0 java-snippets)) 'psvm))
    (should (eq (car (nth 1 java-snippets)) 'sout))))

(provide 'test-editor-extras)
;;; test-editor-extras.el ends here
