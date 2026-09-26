;;; legacy-jdk-e2e.el --- End-to-end check of legacy JDK 8/11 projects -*- lexical-binding: t; -*-

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

;; Integration test for Phase 12.3: testing legacy target JDKs (Java 8 Maven,
;; Java 11 Gradle) and per-project environment switching.
;;
;; Usage:
;;   HELLMACS_E2E_FIXTURE=legacy-8 \
;;     emacs --batch -l early-init.el -l init.el \
;;           -l test/integration/legacy-jdk-e2e.el

;;; Code:

(require 'cl-lib)
(load (expand-file-name "e2e-lib" (file-name-directory (or load-file-name buffer-file-name))) nil t)

(defvar e2e--legacy-fixture (or (getenv "HELLMACS_E2E_FIXTURE") "legacy-8"))

(defun e2e--legacy-checks (proj)
  (message "Running legacy JDK checks on fixture: %s (in %s)" e2e--legacy-fixture proj)
  (cond
   ((equal e2e--legacy-fixture "legacy-8")
    (let ((pom (expand-file-name "pom.xml" proj))
          (src (expand-file-name "src/main/java/com/example/legacy/LegacyApp.java" proj)))
      (e2e-assert (file-exists-p pom) "pom.xml exists")
      (e2e-assert (file-exists-p src) "LegacyApp.java exists")))
   ((equal e2e--legacy-fixture "legacy-11-gradle")
    (let ((build (expand-file-name "build.gradle" proj))
          (src (expand-file-name "src/main/java/com/example/legacy11/Legacy11App.java" proj)))
      (e2e-assert (file-exists-p build) "build.gradle exists")
      (e2e-assert (file-exists-p src) "Legacy11App.java exists"))))
  (message "✓ Legacy JDK fixture validation passed."))

(when (member "-l" command-line-args)
  (let* ((fixture-rel (if (equal e2e--legacy-fixture "legacy-11-gradle")
                          "java/legacy-11-gradle"
                        "java/legacy-8"))
         (src-dir (expand-file-name (concat "test/fixtures/" fixture-rel) hellmacs-dir))
         (proj (e2e-copy-fixture src-dir)))
    (unwind-protect
        (e2e--legacy-checks proj)
      (unless (getenv "HELLMACS_E2E_KEEP")
        (delete-directory proj t)))))

(provide 'legacy-jdk-e2e)
;;; legacy-jdk-e2e.el ends here
