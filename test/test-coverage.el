;;; test-coverage.el --- Tests for JaCoCo code coverage (Phase 12.5) -*- lexical-binding: t; -*-

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
(require 'cl-lib)

(defmacro test-cov--with-tree (files &rest body)
  "Run BODY in a temporary directory holding FILES (alist of path . content)."
  (declare (indent 1))
  `(let* ((root (file-name-as-directory (make-temp-file "hellmacs-test-cov" t)))
          (default-directory root))
     (unwind-protect
         (progn
           (dolist (f ,files)
             (let ((path (expand-file-name (car f) root)))
               (make-directory (file-name-directory path) t)
               (with-temp-file path (insert (cdr f)))))
           ,@body)
       (delete-directory root t))))

(ert-deftest test-coverage/parse-jacoco-xml ()
  "Parses JaCoCo XML coverage report into per-line coverage statuses."
  (test-cov--with-tree
      '(("target/site/jacoco/jacoco.xml" .
         "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
<!DOCTYPE report PUBLIC \"-//JACOCO//DTD Report 1.1//EN\" \"report.dtd\">
<report name=\"demo\">
  <package name=\"com/example\">
    <sourcefile name=\"App.java\">
      <line nr=\"5\" mi=\"0\" ci=\"1\" mb=\"0\" cb=\"0\"/>
      <line nr=\"6\" mi=\"1\" ci=\"0\" mb=\"0\" cb=\"0\"/>
      <line nr=\"7\" mi=\"0\" ci=\"1\" mb=\"1\" cb=\"1\"/>
    </sourcefile>
  </package>
</report>"))
    (let* ((xml-file (expand-file-name "target/site/jacoco/jacoco.xml" root))
           (cov-data (hellmacs-coverage-parse-jacoco-xml xml-file)))
      (should (assoc "com/example/App.java" cov-data))
      (let ((file-lines (cdr (assoc "com/example/App.java" cov-data))))
        ;; Line 5: covered
        (should (eq (alist-get 5 file-lines) 'covered))
        ;; Line 6: missed
        (should (eq (alist-get 6 file-lines) 'missed))
        ;; Line 7: partial
        (should (eq (alist-get 7 file-lines) 'partial))))))

(ert-deftest test-coverage/locate-jacoco-files ()
  "Finds JaCoCo XML reports in Maven target and Gradle build locations."
  (test-cov--with-tree
      '(("target/site/jacoco/jacoco.xml" . "<report name=\"maven\"/>")
        ("build/reports/jacoco/test/jacocoTestReport.xml" . "<report name=\"gradle\"/>"))
    (let ((reports (hellmacs-coverage-find-reports root)))
      (should (= (length reports) 2)))))

(provide 'test-coverage)
;;; test-coverage.el ends here
