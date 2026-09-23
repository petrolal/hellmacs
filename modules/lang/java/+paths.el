;;; lang/java/+paths.el -*- lexical-binding: t; -*-

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


;; Where JDTLS, its workspace and the debugger's test runner live. Loaded
;; by config.el at startup and by cli.el in bin/hellmacs, before
;; lsp-java: `lsp-java-server-install-dir' is computed from
;; `lsp-server-install-dir' when lsp-java loads.

;; JDTLS and its bundles: data (reinstallable, needed to run).
(setq lsp-server-install-dir (expand-file-name "lsp/" hellmacs-data-dir))

;; JDTLS's workspace and project index: regenerable, but only by
;; reimporting every project, so data rather than disposable cache.
(setq lsp-java-workspace-dir (expand-file-name "jvm/workspace/" hellmacs-data-dir)
      lsp-java-workspace-cache-dir (expand-file-name "jvm/workspace/.cache/" hellmacs-data-dir))

;; dap-java's JUnit runner, installed next to JDTLS by `lsp-install-server'.
;; Its default is under `user-emacs-directory', Hellmacs' disposable cache.
(setq dap-java-test-runner
      (expand-file-name "eclipse.jdt.ls/test-runner/junit-platform-console-standalone.jar"
                        lsp-server-install-dir))
