;;; e2e-lib.el --- Helpers for the integration scripts -*- lexical-binding: t; -*-

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

;; Shared by java-e2e.el and java-parity.el: waiting on JDTLS, reporting
;; checks, and small LSP and compilation helpers. Not a test by itself.

;;; Code:

(require 'cl-lib)

(defvar e2e--failures 0)
(defvar e2e--root (file-name-directory (or load-file-name buffer-file-name))
  "This directory, test/integration/.")

(defvar e2e-output nil
  "Where `e2e--say' prints when $HELLMACS_E2E_OUT isn't set.
A `princ' destination: nil for stdout. A suite running in a terminal,
where stdout is the screen, sets it to `external-debugging-output'.")

(defun e2e--say (fmt &rest args)
  "Report a line: appended to $HELLMACS_E2E_OUT if set, else to `e2e-output'."
  (let ((line (concat (apply #'format fmt args) "\n")))
    (if-let* ((out (getenv "HELLMACS_E2E_OUT")))
        (write-region line nil out 'append 'silent)
      (princ line e2e-output))))

(defun e2e--wait (pred secs)
  "Process output and timers until PRED returns non-nil; nil after SECS seconds."
  (let ((end (+ (float-time) secs)) result)
    (while (and (not (setq result (ignore-errors (funcall pred))))
                (< (float-time) end))
      (accept-process-output nil 0.2))
    result))

(defmacro e2e-check (desc &rest body)
  "Run BODY; report DESC as passed if it returns non-nil, failed otherwise."
  (declare (indent 1))
  `(let ((ok (condition-case err (progn ,@body)
               (error (e2e--say "     %S" err) nil))))
     (unless ok (cl-incf e2e--failures))
     (e2e--say "  %s  %s" (if ok "PASS" "FAIL") ,desc)
     ok))

(defun e2e--position-after (regexp)
  "Move point just after the first REGEXP in the buffer."
  (goto-char (point-min))
  (re-search-forward regexp)
  (point))

(defun e2e--lsp-uri-at-point (method)
  "Return the URIs of METHOD (a location request) at point."
  (let ((res (lsp-request method (lsp--text-document-position-params))))
    ;; A vector of locations (JDTLS), a list of them, or a single one (a plist).
    (mapcar (lambda (loc) (lsp-get loc :uri))
            (cond ((null res) nil)
                  ((vectorp res) (append res nil))
                  ((keywordp (car res)) (list res))
                  (t res)))))

(defun e2e--compile-and-wait (dir)
  "Run the project's build from DIR and return its finish message."
  (let ((default-directory dir) finished)
    (let ((hook (lambda (_buf msg) (setq finished msg))))
      (add-hook 'compilation-finish-functions hook)
      (unwind-protect
          (progn (compile compile-command)
                 (e2e--wait (lambda () finished) 300)
                 finished)
        (remove-hook 'compilation-finish-functions hook)))))

(defvar e2e--skipped 0)

(defmacro e2e-skip (desc why)
  "Report DESC as skipped for WHY."
  `(progn (cl-incf e2e--skipped)
          (e2e--say "  SKIP  %s (%s)" ,desc ,why)))

(provide 'e2e-lib)
;;; e2e-lib.el ends here
