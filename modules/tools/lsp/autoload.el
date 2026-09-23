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

;;;###autoload
(defun hellmacs-lsp--setup-completion-h ()
  "Complete from the language server first, then file names and words.
All of it shows in corfu. With cape (from `:completion corfu'), the
server's candidates are wrapped by `cape-capf-buster', so they're
fetched afresh as the input changes instead of served from a stale
cache; without it, the server's completion is used as is."
  (let ((server (if (bound-and-true-p eglot--managed-mode)
                    #'eglot-completion-at-point
                  #'lsp-completion-at-point)))
    (setq-local completion-at-point-functions
                (if (fboundp 'cape-capf-buster)
                    (list (cape-capf-buster server) #'cape-file #'cape-dabbrev)
                  (list server)))))
