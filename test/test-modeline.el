;;; test-modeline.el --- Tests for :ui modeline -*- lexical-binding: t; -*-

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

;; Run with `bin/hellmacs test'. doom-modeline itself isn't installed
;; in the test environment; the mode-line is checked live, in a GUI, in
;; `emacs -nw' and in a Java buffer (docs/roadmap.md, 9.3).

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'hellmacs-modules)

(let ((hellmacs-modules (make-hash-table :test #'equal))
      (warning-minimum-log-level :emergency))
  (hellmacs--enable-modules '(:ui modeline))
  (hellmacs-module--load '(:ui . modeline) "config.el"))

(defvar doom-modeline-icon)
(defvar doom-modeline-mode)

(defmacro test-modeline--frame (graphic font &rest body)
  "Run BODY as if the frame were GRAPHIC, with a Nerd Font if FONT."
  (declare (indent 2))
  `(cl-letf (((symbol-function 'display-graphic-p) (lambda (&rest _) ,graphic))
             ((symbol-function 'char-displayable-p) (lambda (&rest _) ,font)))
     ,@body))

(ert-deftest test-modeline/icons-per-frame ()
  "Icons in a graphical frame with a Nerd Font; text otherwise."
  (test-modeline--frame t t (should (hellmacs-modeline-icons-p)))
  (test-modeline--frame t nil (should-not (hellmacs-modeline-icons-p)))
  (test-modeline--frame nil t
    (let ((hellmacs-modeline-tty-icons nil)) (should-not (hellmacs-modeline-icons-p)))
    (let ((hellmacs-modeline-tty-icons t)) (should (hellmacs-modeline-icons-p)))))

(ert-deftest test-modeline/icons-follow-the-selected-frame ()
  "`doom-modeline-icon' is set to the frame's answer, and only when it changes."
  (let ((doom-modeline-mode t) (doom-modeline-icon nil) (sets 0))
    (add-variable-watcher 'doom-modeline-icon (lambda (&rest _) (cl-incf sets)))
    (unwind-protect
        (progn
          (test-modeline--frame t t (hellmacs-modeline--update-icons))
          (should (eq doom-modeline-icon t))
          (test-modeline--frame t t (hellmacs-modeline--update-icons))
          (should (= sets 1))           ; unchanged: not set again
          (test-modeline--frame nil t (hellmacs-modeline--update-icons))
          (should (eq doom-modeline-icon nil))
          (should (= sets 2)))
      (dolist (w (get 'doom-modeline-icon 'watchers))
        (remove-variable-watcher 'doom-modeline-icon w)))))

(ert-deftest test-modeline/segments ()
  "The spec's segments, and none of the ones it leaves out."
  (let ((all (apply #'append hellmacs-modeline-segments)))
    (dolist (segment '(buffer-info buffer-position vcs check debug misc-info major-mode))
      (should (memq segment all)))
    (dolist (segment '(minor-modes buffer-encoding word-count lsp indent-info))
      (should-not (memq segment all))))
  (should-not doom-modeline-minor-modes)
  (should-not doom-modeline-buffer-encoding)
  (should-not doom-modeline-lsp)
  (should-not doom-modeline-enable-word-count))

(ert-deftest test-modeline/turned-on-with-the-first-buffer ()
  "Not at startup: doom-modeline loads with the first real buffer."
  (should (memq #'hellmacs-modeline-enable hellmacs-first-buffer-hook))
  (should-not (featurep 'doom-modeline)))

(provide 'test-modeline)
;;; test-modeline.el ends here
