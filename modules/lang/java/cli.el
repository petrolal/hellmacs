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
;; download, and with +lombok, the pinned Lombok jar.

(defconst hellmacs-jvm--module-dir (file-name-directory load-file-name)
  "This module's directory (captured now: `load-file-name' is only set while loading).")

;; Paths and the pinned Lombok release, once, now: after your init.el (so
;; your settings win) and before any sync step runs.
(load (expand-file-name "+paths" hellmacs-jvm--module-dir) nil 'nomessage)

;; +tree-sitter: `bin/hellmacs sync' builds the pinned Java grammar.
(when (modulep! +tree-sitter)
  (hellmacs-treesit-need 'java))

(defvar hellmacs-jvm-install-server-on-sync t
  "Whether `bin/hellmacs sync' installs JDTLS when it's missing.")

(defvar lsp-clients)
(declare-function lsp--client-download-in-progress? "ext:lsp-mode")
(declare-function lsp--server-binary-present? "ext:lsp-mode")
(declare-function lsp-install-server "ext:lsp-mode")

(defun hellmacs-jvm-sync-install-server ()
  "Install JDTLS if it's missing, and wait for it. For `hellmacs-sync-functions'."
  (when hellmacs-jvm-install-server-on-sync
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
          (error "Installing JDTLS failed; see the output above (it needs network access and mvn or a JDK)"))))
    (when (modulep! :tools debugger)
      (hellmacs-jvm-sync-install-java-debug))))

(add-hook 'hellmacs-sync-functions #'hellmacs-jvm-sync-install-server)

;;; Lombok (+lombok) -----------------------------------------------------------

(defun hellmacs-jvm--download-verified (url dest sha256 label)
  "Download URL to DEST, but only keep it if its SHA-256 is SHA256.
LABEL names the file in errors. The jar goes through a .part file, so
JDTLS never sees a bad or half-written one."
  (let ((tmp (concat dest ".part")))
    (make-directory (file-name-directory dest) t)
    (url-copy-file url tmp t)
    (unless (equal (hellmacs-jvm--sha256 tmp) sha256)
      (delete-file tmp)
      (error "%s download from %s failed its SHA-256 check; not installed" label url))
    (rename-file tmp dest t)))

(defun hellmacs-jvm-sync-install-lombok ()
  "Download the pinned Lombok jar if it's missing or corrupt, and check it.
For `hellmacs-sync-functions'. A jar of your own
\(`hellmacs-jvm-lombok-jar') is only checked for existence."
  (cond
   ((hellmacs-jvm-lombok-jar-valid-p)
    (hellmacs-sync--log "Lombok %s is installed"
                        (if (equal hellmacs-jvm-lombok-jar hellmacs-jvm--default-lombok-jar)
                            hellmacs-jvm-lombok-version
                          (abbreviate-file-name hellmacs-jvm-lombok-jar))))
   ((not (equal hellmacs-jvm-lombok-jar hellmacs-jvm--default-lombok-jar))
    (error "+lombok: `hellmacs-jvm-lombok-jar' is %s, which doesn't exist"
           (abbreviate-file-name hellmacs-jvm-lombok-jar)))
   (t
    (hellmacs-sync--log "Downloading Lombok %s..." hellmacs-jvm-lombok-version)
    (hellmacs-jvm--download-verified hellmacs-jvm-lombok-url hellmacs-jvm-lombok-jar
                                     hellmacs-jvm-lombok-sha256 "Lombok")
    (hellmacs-sync--log "Lombok %s installed (SHA-256 verified)" hellmacs-jvm-lombok-version))))

(when (modulep! +lombok)
  (add-hook 'hellmacs-sync-functions #'hellmacs-jvm-sync-install-lombok))

;;; java-debug (:tools debugger) -------------------------------------------------

(defun hellmacs-jvm-sync-install-java-debug ()
  "Replace lsp-java's java-debug bundle with the pinned release, if needed.
Runs after JDTLS's install. It is safe to run every sync: it only
downloads when the bundle isn't the pinned release (also after
`lsp-install-server' reinstalled the old one)."
  (cond
   ((hellmacs-jvm-java-debug-jar-valid-p)
    (hellmacs-sync--log "java-debug %s is installed" hellmacs-jvm-java-debug-version))
   ((not (file-directory-p (file-name-directory hellmacs-jvm-java-debug-jar)))
    (error "JDTLS's bundle directory %s doesn't exist; is JDTLS installed?"
           (abbreviate-file-name (file-name-directory hellmacs-jvm-java-debug-jar))))
   (t
    (hellmacs-sync--log "Installing java-debug %s (the bundled one can't debug on JDK 22+)..."
                        hellmacs-jvm-java-debug-version)
    (hellmacs-jvm--download-verified hellmacs-jvm-java-debug-url hellmacs-jvm-java-debug-jar
                                     hellmacs-jvm-java-debug-sha256 "java-debug")
    (hellmacs-sync--log "java-debug %s installed (SHA-256 verified)" hellmacs-jvm-java-debug-version))))
