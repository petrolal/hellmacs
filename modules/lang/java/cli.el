;;; lang/java/cli.el -*- lexical-binding: t; -*-

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


;; Extends bin/hellmacs: `sync' also installs JDTLS (with its java-debug
;; bundle and JUnit runner), so the first Java file doesn't wait for a
;; download.

(defconst hellmacs-jvm--module-dir (file-name-directory load-file-name)
  "This module's directory (captured now: `load-file-name' is only set while loading).")

(defvar hellmacs-jvm-install-server-on-sync t
  "Whether `bin/hellmacs sync' installs JDTLS when it's missing.")

(defvar lsp-clients)
(declare-function lsp--client-download-in-progress? "ext:lsp-mode")
(declare-function lsp--server-binary-present? "ext:lsp-mode")
(declare-function lsp-install-server "ext:lsp-mode")

(defun hellmacs-jvm-sync-install-server ()
  "Install JDTLS if it's missing, and wait for it. For `hellmacs-sync-functions'."
  (when hellmacs-jvm-install-server-on-sync
    (load (expand-file-name "+paths" hellmacs-jvm--module-dir) nil 'nomessage)
    (require 'lsp-mode)
    (require 'lsp-java)
    (require 'dap-java nil t)          ; so the test runner is installed too
    (let ((client (gethash 'jdtls lsp-clients)))
      (if (lsp--server-binary-present? client)
          (hellmacs-sync--log "JDTLS is installed")
        (hellmacs-sync--log "Installing JDTLS, java-debug and the JUnit runner (a few minutes the first time)...")
        (lsp-install-server nil 'jdtls)
        ;; lsp-mode installs asynchronously; wait for it to finish.
        (while (lsp--client-download-in-progress? client)
          (accept-process-output nil 1))
        (if (lsp--server-binary-present? client)
            (hellmacs-sync--log "JDTLS installed in %s" (abbreviate-file-name lsp-server-install-dir))
          (error "Installing JDTLS failed; see the output above (it needs network access and mvn or a JDK)"))))))

(add-hook 'hellmacs-sync-functions #'hellmacs-jvm-sync-install-server)
