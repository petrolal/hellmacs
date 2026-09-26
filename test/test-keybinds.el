;;; test-keybinds.el --- Tests for keybinds and leader layout -*- lexical-binding: t; -*-

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
(require 'hellmacs-keybinds)

(ert-deftest test-keybinds/leader-def-basic ()
  "hellmacs-leader-def registers commands under mode-specific-map."
  (let ((mode-specific-map (make-sparse-keymap)))
    (hellmacs-leader-def
      "h h" 'hellmacs-dashboard-open
      "f f" 'find-file)
    (should (eq (keymap-lookup mode-specific-map "h h") 'hellmacs-dashboard-open))
    (should (eq (keymap-lookup mode-specific-map "f f") 'find-file))))

(ert-deftest test-keybinds/leader-def-command-binding ()
  "hellmacs-leader-def binds commands under prefix groups."
  (let ((mode-specific-map (make-sparse-keymap)))
    (hellmacs-leader-def
      "b" "buffer"
      "b b" 'switch-to-buffer
      "b k" 'kill-current-buffer)
    (should (eq (keymap-lookup mode-specific-map "b b") 'switch-to-buffer))
    (should (eq (keymap-lookup mode-specific-map "b k") 'kill-current-buffer))))

(ert-deftest test-keybinds/leader-def-preserves-stock-keys ()
  "hellmacs-leader-def stays within mode-specific-map (C-c prefix)."
  (let ((mode-specific-map (make-sparse-keymap)))
    (hellmacs-leader-def "p p" 'project-switch-project)
    (should (eq (keymap-lookup mode-specific-map "p p") 'project-switch-project))))

(provide 'test-keybinds)
;;; test-keybinds.el ends here
