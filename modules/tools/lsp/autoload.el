;;; tools/lsp/autoload.el -*- lexical-binding: t; -*-

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


(declare-function cape-capf-buster "ext:cape")
(declare-function cape-file "ext:cape")
(declare-function cape-dabbrev "ext:cape")
(declare-function lsp-completion-at-point "ext:lsp-completion")
(declare-function eglot-completion-at-point "eglot")

(defvar-local hellmacs-lsp--saved-capfs nil
  "`completion-at-point-functions' before the server's were put in.
\(LOCALP . VALUE), or nil when nothing is saved.")

;;;###autoload
(defun hellmacs-lsp--setup-completion-h ()
  "Complete from the language server first, then file names and words.
All of it shows in corfu. With cape (from `:completion corfu'), the
server's candidates are wrapped by `cape-capf-buster', so they're
fetched afresh as the input changes instead of served from a stale
cache; without it, the server's completion is used as is.

Runs from the mode hooks, which also run when the mode turns off: then
the buffer gets back the functions it had before. (The client's own
cleanup can't find the server's function inside the wrapper.)"
  (if (or (bound-and-true-p eglot--managed-mode)
          (bound-and-true-p lsp-completion-mode))
      (let ((server (if (bound-and-true-p eglot--managed-mode)
                        #'eglot-completion-at-point
                      #'lsp-completion-at-point)))
        (unless hellmacs-lsp--saved-capfs
          ;; The client has already added its own function; leave it out.
          ;; A local value of just (t), the client's hook with its function
          ;; taken out, is the global value: nothing of the buffer's own.
          (let ((own (remq server completion-at-point-functions)))
            (setq hellmacs-lsp--saved-capfs
                  (cons (and (local-variable-p 'completion-at-point-functions)
                             (not (equal own '(t))))
                        own))))
        (setq-local completion-at-point-functions
                    (if (fboundp 'cape-capf-buster)
                        (list (cape-capf-buster server) #'cape-file #'cape-dabbrev)
                      (list server))))
    (when-let* ((saved hellmacs-lsp--saved-capfs))
      (if (car saved)
          (setq-local completion-at-point-functions (cdr saved))
        (kill-local-variable 'completion-at-point-functions))
      (setq hellmacs-lsp--saved-capfs nil))))
