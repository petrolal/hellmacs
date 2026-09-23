;;; tools/lsp/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

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


;; lsp-mode by default; eglot (built into Emacs) with +eglot.

(if (modulep! +eglot)
    (package! eglot :built-in 'prefer)
  ;; Shared by lsp-mode, lsp-java, dap-mode and lsp-treemacs: declared up
  ;; front so Elpaca builds each exactly once (see core/packages.el).
  (package! dash) (package! f) (package! ht) (package! s)
  (package! lv) (package! spinner) (package! markdown-mode)
  ;; lsp-mode is much faster with plists instead of hash tables, but only
  ;; if it's compiled that way: LSP_USE_PLISTS must be set at build time.
  (package! lsp-mode :env (("LSP_USE_PLISTS" . "true"))))
