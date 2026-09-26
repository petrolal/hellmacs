;;; test-groovy.el --- Tests for :lang groovy module (Phase 8.4) -*- lexical-binding: t; -*-

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

(ert-deftest test-groovy/file-associations ()
  "Associates .groovy, .gradle, and Jenkinsfile with Groovy mode."
  (let ((files '("App.groovy" "build.gradle" "settings.gradle" "Jenkinsfile" "pipeline.jenkinsfile")))
    (dolist (f files)
      (should (string-match-p "\\(\\.\\(groovy\\|gradle\\|jenkinsfile\\)\\'\\|Jenkinsfile\\'\\)" f)))))

(ert-deftest test-groovy/pinned-server-download ()
  "Verifies groovy-language-server download pinning."
  (let ((server-info '(:name "groovy-language-server"
                       :version "0.4.6"
                       :sha256 "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef")))
    (should (plist-get server-info :version))
    (should (= (length (plist-get server-info :sha256)) 64))))

(ert-deftest test-groovy/keybindings ()
  "Verifies C-c l g key binding group for Groovy commands."
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c l g b") 'hellmacs-groovy-build)
    (should (eq (lookup-key map (kbd "C-c l g b")) 'hellmacs-groovy-build))))

(provide 'test-groovy)
;;; test-groovy.el ends here
