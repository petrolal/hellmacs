;;; lang/clojure/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

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


;; clojure-lsp speaks LSP through lsp-mode, whatever `:tools lsp' is set to.
(unless (modulep! :tools lsp -eglot)
  ;; Shared with lsp-java, kotlin and dap-mode; spinner is also CIDER's.
  ;; Declared up front so Elpaca builds each exactly once (see core/packages.el).
  (package! dash) (package! f) (package! ht) (package! s)
  (package! lv) (package! spinner) (package! markdown-mode)
  (package! lsp-mode :env (("LSP_USE_PLISTS" . "true"))))

(package! clojure-mode)
(package! cider)
(when (modulep! +tree-sitter)
  (package! clojure-ts-mode))
