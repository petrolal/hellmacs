;;; test-ux.el --- Tests for core/hellmacs-ux.el -*- lexical-binding: t; -*-

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
(require 'hellmacs-ux)

(ert-deftest test-ux/routine-error-classification ()
  "Distinguishes routine user signals from unexpected fatal errors."
  (should (hellmacs-ux--routine-error-p '(user-error "Cannot find file")))
  (should (hellmacs-ux--routine-error-p '(quit)))
  (should (hellmacs-ux--routine-error-p '(beginning-of-buffer)))
  (should (hellmacs-ux--routine-error-p '(end-of-buffer)))
  (should (hellmacs-ux--routine-error-p '(buffer-read-only)))
  (should-not (hellmacs-ux--routine-error-p '(void-variable foo)))
  (should-not (hellmacs-ux--routine-error-p '(void-function bar)))
  (should-not (hellmacs-ux--routine-error-p '(error "Null pointer in JDTLS backend"))))

(ert-deftest test-ux/kill-prompt ()
  "Confirm kill emacs uses the Hellmacs thematic prompt."
  (should (equal hellmacs-ux-kill-prompt "Extinguish the forge and return to the void? ")))

(ert-deftest test-ux/format-fatality ()
  "Formats unhandled errors with the fatality prefix."
  (let ((hellmacs-ux-enable t))
    (should (string-match-p "\\[CRITICAL FATALITY\\]"
                            (format "[CRITICAL FATALITY]: %s" "Symbol's value as variable is void")))))

(provide 'test-ux)
;;; test-ux.el ends here
