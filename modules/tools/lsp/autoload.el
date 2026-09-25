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


;;;###autoload
(defvar-local hellmacs-lsp--added-dabbrev nil
  "Non-nil if `hellmacs-lsp--setup-completion-h' added `cape-dabbrev' here.")

;;;###autoload
(defun hellmacs-lsp--setup-completion-h ()
  "In a buffer with a language server, fall back to words from open buffers.
The server's completion comes first (lsp-mode puts it there), then the
buffer's own functions and file names (`:completion corfu'), then words
(`cape-dabbrev'); all of it shows in corfu. The server's function itself
is cache-busted once, globally (see config.el). Runs from
`lsp-completion-mode-hook', which also runs when the mode turns off:
then the fallback goes again, unless the buffer had it already."
  (cond ((not (fboundp 'cape-dabbrev)))
        ((bound-and-true-p lsp-completion-mode)
         (unless (memq #'cape-dabbrev completion-at-point-functions)
           (add-hook 'completion-at-point-functions #'cape-dabbrev 90 t)
           (setq hellmacs-lsp--added-dabbrev t)))
        (hellmacs-lsp--added-dabbrev
         (remove-hook 'completion-at-point-functions #'cape-dabbrev t)
         (setq hellmacs-lsp--added-dabbrev nil))))
