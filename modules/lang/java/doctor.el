;;; lang/java/doctor.el -*- lexical-binding: t; no-byte-compile: t; -*-

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


;; Checked by `bin/hellmacs doctor'.

(load (expand-file-name "+paths" (file-name-directory load-file-name)) nil 'nomessage)

(defun hellmacs-jvm--doctor-java-major (java)
  "Return the major version of the JDK whose java binary is JAVA, or nil."
  (with-temp-buffer
    (when (ignore-errors (zerop (call-process java nil t nil "-version")))
      (goto-char (point-min))
      (when (re-search-forward "version \"\\([0-9]+\\)\\(?:\\.\\([0-9]+\\)\\)?" nil t)
        (let ((major (string-to-number (match-string 1))))
          ;; Java 8 and older call themselves 1.8, 1.7...
          (if (= major 1) (string-to-number (match-string 2)) major))))))

(let* ((home (getenv "JAVA_HOME"))
       (java (if home (expand-file-name "bin/java" home) (executable-find "java")))
       (major (and java (file-executable-p java) (hellmacs-jvm--doctor-java-major java))))
  (cond ((null major)
         (hellmacs-doctor-error "No JDK found (set JAVA_HOME or put java on the PATH); JDTLS needs 21+"))
        ((< major 21)
         (hellmacs-doctor-error "JDK %d at %s is too old to run JDTLS (needs 21+); set `hellmacs-jvm-java-home'"
                                major (abbreviate-file-name java)))
        (t (hellmacs-doctor-ok "JDK %d for JDTLS: %s" major (abbreviate-file-name java))))
  (unless home
    (hellmacs-doctor-info "JAVA_HOME isn't set; using java from the PATH")))

(hellmacs-doctor-executable "gradle" "Gradle projects without a ./gradlew wrapper")
(hellmacs-doctor-executable "mvn" "Maven projects without a ./mvnw wrapper, and installing JDTLS faster" nil "--version")

(if (file-directory-p (expand-file-name "eclipse.jdt.ls/plugins/" lsp-server-install-dir))
    (hellmacs-doctor-ok "JDTLS installed in %s" (abbreviate-file-name lsp-server-install-dir))
  (hellmacs-doctor-warn "JDTLS isn't installed yet; `bin/hellmacs sync' installs it (or the first Java file does)"))
(if (file-exists-p dap-java-test-runner)
    (hellmacs-doctor-ok "JUnit test runner installed")
  (hellmacs-doctor-warn "The JUnit test runner isn't installed yet; `bin/hellmacs sync' installs it with JDTLS"))

(when (modulep! +lombok)
  (cond ((hellmacs-jvm-lombok-jar-valid-p)
         (hellmacs-doctor-ok "Lombok: %s" (abbreviate-file-name hellmacs-jvm-lombok-jar)))
        ((file-exists-p hellmacs-jvm-lombok-jar)
         (hellmacs-doctor-error "Lombok jar %s fails its SHA-256 check; `bin/hellmacs sync' downloads it again"
                                (abbreviate-file-name hellmacs-jvm-lombok-jar)))
        (t
         (hellmacs-doctor-error "+lombok is on but Lombok isn't installed; run `bin/hellmacs sync'"))))
