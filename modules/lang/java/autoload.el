;;; lang/java/autoload.el -*- lexical-binding: t; -*-

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


(declare-function dap-java-run-test-method "ext:dap-java")
(declare-function dap-java-run-test-class "ext:dap-java")

;;;###autoload
(defun hellmacs-jvm-test-at-point ()
  "Run the JUnit test method at point (dap-java's runner)."
  (interactive)
  (require 'dap-java)
  (call-interactively #'dap-java-run-test-method))

;;;###autoload
(defun hellmacs-jvm-test-class ()
  "Run every JUnit test in the current class (dap-java's runner)."
  (interactive)
  (require 'dap-java)
  (call-interactively #'dap-java-run-test-class))

(declare-function lsp-java-update-project-configuration "ext:lsp-java")

(defconst hellmacs-jvm-build-files '("pom.xml" "build.gradle" "build.gradle.kts")
  "Files that define a Maven or Gradle project, nearest first.")

;;;###autoload
(defun hellmacs-jvm-update-project-configuration ()
  "Re-import the build file (pom.xml, build.gradle) of the current project.
Works from any file in the project: lsp-java's own command only works
from the build file's buffer. JDTLS also does this by itself when a
build file is saved; this is for changes it missed."
  (interactive)
  (let* ((file (or buffer-file-name (user-error "Not visiting a file")))
         (build (if (member (file-name-nondirectory file) hellmacs-jvm-build-files)
                    file
                  (seq-some (lambda (name)
                              (when-let* ((dir (locate-dominating-file file name)))
                                (expand-file-name name dir)))
                            hellmacs-jvm-build-files))))
    (unless build
      (user-error "No pom.xml or build.gradle above %s" (abbreviate-file-name file)))
    (with-current-buffer (find-file-noselect build)
      (lsp-java-update-project-configuration))
    (message "Re-importing %s" (abbreviate-file-name build))))
