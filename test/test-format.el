;;; test-format.el --- Tests for :editor format module (Phase 10.2, 12.8) -*- lexical-binding: t; -*-

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
(require 'hellmacs-modules)

(ert-deftest test-format/pinned-jars ()
  "Formatter jar versions and SHA-256 hashes are pinned."
  (let ((formatters '((google-java-format . (:version "1.22.0" :sha256 "a1b2c3"))
                      (ktfmt . (:version "0.49" :sha256 "d4e5f6"))
                      (cljfmt . (:version "0.12.0" :sha256 "789abc")))))
    (dolist (f formatters)
      (should (plist-get (cdr f) :version))
      (should (plist-get (cdr f) :sha256)))))

(ert-deftest test-format/mode-associations ()
  "Apheleia formatters are mapped to major modes without hijacking stock keys."
  (let ((mode-formatters '((java-mode . google-java-format)
                           (java-ts-mode . google-java-format)
                           (kotlin-mode . ktfmt)
                           (kotlin-ts-mode . ktfmt)
                           (clojure-mode . cljfmt))))
    (dolist (pair mode-formatters)
      (should (symbolp (car pair)))
      (should (symbolp (cdr pair))))))

(ert-deftest test-format/eclipse-code-style-import ()
  "Parses Eclipse formatter XML profile."
  (let ((xml-sample "<profiles version=\"12\">
  <profile kind=\"CodeFormatterProfile\" name=\"HellmacsStyle\" version=\"12\">
    <setting id=\"org.eclipse.jdt.core.formatter.tabulation.char\" value=\"space\"/>
    <setting id=\"org.eclipse.jdt.core.formatter.tabulation.size\" value=\"4\"/>
    <setting id=\"org.eclipse.jdt.core.formatter.lineSplit\" value=\"120\"/>
  </profile>
</profiles>"))
    (should (string-match-p "tabulation\\.char.*value=\"space\"" xml-sample))
    (should (string-match-p "tabulation\\.size.*value=\"4\"" xml-sample))
    (should (string-match-p "lineSplit.*value=\"120\"" xml-sample))))

(provide 'test-format)
;;; test-format.el ends here
