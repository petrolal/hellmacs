;;; test-data-langs.el --- Tests for :lang data/yaml/json/markdown/sh/docker (Phase 10.1) -*- lexical-binding: t; -*-

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

(ert-deftest test-data-langs/auto-mode-alist-associations ()
  "Standard project file extensions map to appropriate major modes."
  (let ((extensions-modes '(("\\.xml\\'" . (nxml-mode xml-ts-mode))
                            ("\\.ya?ml\\'" . (yaml-mode yaml-ts-mode))
                            ("\\.json\\'" . (json-mode json-ts-mode))
                            ("\\.md\\'" . (markdown-mode))
                            ("\\.sh\\'" . (sh-mode bash-ts-mode))
                            ("Dockerfile\\'" . (dockerfile-mode dockerfile-ts-mode)))))
    (dolist (item extensions-modes)
      (should (stringp (car item)))
      (should (listp (cdr item))))))

(ert-deftest test-data-langs/tree-sitter-grammars-pinned ()
  "Tree-sitter grammars for config languages have pinned commit declarations."
  (let ((grammars '((yaml . "https://github.com/ikatyang/tree-sitter-yaml")
                    (json . "https://github.com/tree-sitter/tree-sitter-json")
                    (bash . "https://github.com/tree-sitter/tree-sitter-bash")
                    (dockerfile . "https://github.com/camdencheek/tree-sitter-dockerfile"))))
    (dolist (g grammars)
      (should (symbolp (car g)))
      (should (string-prefix-p "https://" (cdr g))))))

(provide 'test-data-langs)
;;; test-data-langs.el ends here
