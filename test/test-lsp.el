;;; test-lsp.el --- Tests for :tools lsp -*- lexical-binding: t; no-byte-compile: t; -*-

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

(let ((hellmacs-modules (make-hash-table :test #'equal)))
  (hellmacs--enable-modules '(:tools lsp))
  (hellmacs-module--load '(:tools . lsp) "autoload.el"))

(defvar lsp-completion-mode)
(defvar eglot--managed-mode)

(defun test-lsp--capf () nil)

(ert-deftest test-lsp/completion-is-given-back-when-the-server-goes ()
  "Turning the client off restores the buffer's own completion functions."
  (dolist (mode '(lsp-completion-mode eglot--managed-mode))
    (let ((server (if (eq mode 'lsp-completion-mode)
                      'lsp-completion-at-point
                    'eglot-completion-at-point)))
      ;; A buffer with functions of its own, then one with only the global ones.
      (dolist (local '(t nil))
        (with-temp-buffer
          (when local
            (setq-local completion-at-point-functions (list #'test-lsp--capf t)))
          (let ((before completion-at-point-functions))
            ;; The client adds its function, then runs its mode hook.
            (set (make-local-variable mode) t)
            (add-hook 'completion-at-point-functions server nil t)
            (hellmacs-lsp--setup-completion-h)
            (should (memq server (flatten-tree completion-at-point-functions)))
            (should-not (memq 'test-lsp--capf completion-at-point-functions))
            ;; The client turns off: its cleanup can't find its function
            ;; when cape wraps it, so the hook puts things back.
            (set mode nil)
            (remove-hook 'completion-at-point-functions server t)
            (hellmacs-lsp--setup-completion-h)
            (should (equal completion-at-point-functions before))
            (should (eq (local-variable-p 'completion-at-point-functions) local))))))))

(defvar lsp-keymap-prefix)

(ert-deftest test-lsp/lsp-mode-configured-whenever-used ()
  "lsp-mode gets Hellmacs' settings whenever a module uses it, +eglot or not."
  (pcase-dolist (`(,spec ,configured)
                 '(((:tools lsp) t)
                   ((:tools (lsp +eglot)) nil)          ; eglot only
                   ((:tools (lsp +eglot) :lang java) t) ; java runs on lsp-mode anyway
                   ((:tools (lsp +eglot) :lang kotlin) t)
                   ((:tools (lsp +eglot) :lang clojure) t)))
    (let ((hellmacs-modules (make-hash-table :test #'equal))
          (hellmacs-packages nil)
          (lsp-keymap-prefix "s-l")               ; lsp-mode's own default
          (warning-minimum-log-level :emergency))
      (hellmacs--enable-modules spec)
      (hellmacs-modules-read-packages)
      (hellmacs-module--load '(:tools . lsp) "config.el")
      (should (eq (hellmacs-lsp-mode-used-p) (and configured t)))
      (should (equal lsp-keymap-prefix (if configured "C-c l" "s-l"))))))

(provide 'test-lsp)
;;; test-lsp.el ends here
