;;; test-direnv.el --- Tests for the :tools direnv module -*- lexical-binding: t; -*-

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

;; Run with `bin/hellmacs test'.

;;; Code:

(require 'ert)
(require 'hellmacs-modules)

(defmacro test-direnv--with-tree (files &rest body)
  "Run BODY in a temporary directory holding FILES."
  (declare (indent 1))
  `(let* ((root (file-name-as-directory (make-temp-file "hellmacs-test-direnv" t)))
          (default-directory root))
     (unwind-protect
         (progn
           (dolist (f ,files)
             (let ((path (expand-file-name (car f) root)))
               (make-directory (file-name-directory path) t)
               (with-temp-file path (insert (cdr f)))))
           ,@body)
       (delete-directory root t))))

(ert-deftest test-direnv/module-declaration ()
  "Module packages declaration registers envrc."
  (let ((hellmacs-packages nil))
    ;; Verify package registration structure for direnv
    (package! envrc)
    (should (assq 'envrc hellmacs-packages))))

(ert-deftest test-direnv/detect-envrc-file ()
  "Detects presence of .envrc in project root."
  (test-direnv--with-tree
      '((".envrc" . "export JAVA_HOME=/opt/jdks/jdk-11\nexport MAVEN_OPTS=\"-Xmx1024m\"\n")
        ("pom.xml" . "<project></project>\n"))
    (should (file-exists-p (expand-file-name ".envrc" root)))
    (with-temp-buffer
      (insert-file-contents (expand-file-name ".envrc" root))
      (should (search-forward "JAVA_HOME" nil t)))))

(ert-deftest test-direnv/environment-isolation ()
  "Simulates buffer-local process-environment switching across projects."
  (let ((global-env process-environment)
        (proj1-env (cons "JAVA_HOME=/opt/jdk-8" process-environment))
        (proj2-env (cons "JAVA_HOME=/opt/jdk-17" process-environment)))
    (with-temp-buffer
      (setq-local process-environment proj1-env)
      (should (equal (getenv "JAVA_HOME") "/opt/jdk-8")))
    (with-temp-buffer
      (setq-local process-environment proj2-env)
      (should (equal (getenv "JAVA_HOME") "/opt/jdk-17")))
    (should (equal process-environment global-env))))

(provide 'test-direnv)
;;; test-direnv.el ends here
