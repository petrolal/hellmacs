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


(defvar hellmacs-jvm-install-server-on-sync t
  "Whether `bin/hellmacs sync' installs JDTLS when it's missing.")

(defun hellmacs-jvm--install-jdtls ()
  "Install the pinned JDTLS into `hellmacs-jvm-jdtls-dir', replacing what's there.
Downloaded and checked (`hellmacs-sync-download-verified'), unpacked next
to the install (the same file system, so it moves into place whole), and
only then swapped in; the marker is written last. Whatever else lived in
the directory (java-debug, the test runner) is installed again after."
  (unless (executable-find "tar") (error "tar is needed to install JDTLS"))
  (let* ((dir (directory-file-name hellmacs-jvm-jdtls-dir))
         (stage (progn (make-directory (file-name-directory dir) t)
                       (make-temp-file (concat dir "-stage") t)))
         (tarball (expand-file-name "jdtls.tar.gz" stage))
         (server (expand-file-name "server" stage)))
    (unwind-protect
        (progn
          (hellmacs-sync-download-verified hellmacs-jvm-jdtls-url tarball
                                           hellmacs-jvm-jdtls-sha256 "JDTLS")
          (make-directory server)
          (with-temp-buffer
            (unless (zerop (call-process "tar" nil t nil "-xzf" tarball "-C" server))
              (error "Unpacking JDTLS failed: %s" (buffer-string))))
          (make-directory (expand-file-name "bundles" server)) ; java-debug goes here
          (when (file-directory-p dir) (delete-directory dir t))
          (rename-file server dir)
          (with-temp-file (hellmacs-jvm--jdtls-marker) (insert hellmacs-jvm-jdtls-sha256 "\n")))
      (delete-directory stage t))))

(defun hellmacs-jvm-sync-install-server ()
  "Install the pinned JDTLS and JUnit runner if they aren't. For `hellmacs-sync-functions'."
  (when hellmacs-jvm-install-server-on-sync
    (if (hellmacs-jvm-jdtls-installed-p)
        (hellmacs-sync--log "JDTLS %s is installed" hellmacs-jvm-jdtls-version)
      (hellmacs-sync--log "Downloading JDTLS %s (49MB)..." hellmacs-jvm-jdtls-version)
      (hellmacs-jvm--install-jdtls)
      (hellmacs-sync--log "JDTLS %s installed (SHA-256 verified)" hellmacs-jvm-jdtls-version))
    (unless (hellmacs-jvm-junit-runner-valid-p)
      (hellmacs-sync-download-verified hellmacs-jvm-junit-runner-url dap-java-test-runner
                                       hellmacs-jvm-junit-runner-sha256 "The JUnit runner")
      (hellmacs-sync--log "JUnit runner %s installed (SHA-256 verified)"
                          hellmacs-jvm-junit-runner-version))
    (when (modulep! :tools debugger)
      (hellmacs-jvm-sync-install-java-debug))))

(add-hook 'hellmacs-sync-functions #'hellmacs-jvm-sync-install-server)

;;; Lombok (+lombok) -----------------------------------------------------------

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
    (hellmacs-sync-download-verified hellmacs-jvm-lombok-url hellmacs-jvm-lombok-jar
                                     hellmacs-jvm-lombok-sha256 "Lombok")
    (hellmacs-sync--log "Lombok %s installed (SHA-256 verified)" hellmacs-jvm-lombok-version))))

(when (modulep! +lombok)
  (add-hook 'hellmacs-sync-functions #'hellmacs-jvm-sync-install-lombok))

;;; java-debug (:tools debugger) -------------------------------------------------

(defun hellmacs-jvm-sync-install-java-debug ()
  "Install the pinned java-debug bundle into JDTLS, if it isn't there.
Runs after JDTLS's install. It is safe to run every sync: it only
downloads when the bundle isn't the pinned release."
  (cond
   ((hellmacs-jvm-java-debug-jar-valid-p)
    (hellmacs-sync--log "java-debug %s is installed" hellmacs-jvm-java-debug-version))
   ((not (file-directory-p (file-name-directory hellmacs-jvm-java-debug-jar)))
    (error "JDTLS's bundle directory %s doesn't exist; is JDTLS installed?"
           (abbreviate-file-name (file-name-directory hellmacs-jvm-java-debug-jar))))
   (t
    (hellmacs-sync--log "Installing java-debug %s..."
                        hellmacs-jvm-java-debug-version)
    (hellmacs-sync-download-verified hellmacs-jvm-java-debug-url hellmacs-jvm-java-debug-jar
                                     hellmacs-jvm-java-debug-sha256 "java-debug")
    (hellmacs-sync--log "java-debug %s installed (SHA-256 verified)" hellmacs-jvm-java-debug-version))))
