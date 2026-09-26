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
(require 'xml)

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
  "Parses JaCoCo XML coverage report and extracts line coverage counts."
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
    (let ((xml-file (expand-file-name "target/site/jacoco/jacoco.xml" root)))
      (should (file-readable-p xml-file))
      (let* ((parsed (with-temp-buffer
                       (insert-file-contents xml-file)
                       (xml-parse-region (point-min) (point-max))))
             (report (car parsed))
             (pkg (car (xml-get-children report 'package)))
             (sf (car (xml-get-children pkg 'sourcefile)))
             (lines (xml-get-children sf 'line)))
        (should (= (length lines) 3))
        ;; Line 5: covered (ci > 0, mi == 0)
        (let ((l5 (xml-node-attributes (nth 0 lines))))
          (should (equal (cdr (assq 'nr l5)) "5"))
          (should (equal (cdr (assq 'ci l5)) "1"))
          (should (equal (cdr (assq 'mi l5)) "0")))
        ;; Line 6: missed (ci == 0, mi > 0)
        (let ((l6 (xml-node-attributes (nth 1 lines))))
          (should (equal (cdr (assq 'nr l6)) "6"))
          (should (equal (cdr (assq 'ci l6)) "0"))
          (should (equal (cdr (assq 'mi l6)) "1")))
        ;; Line 7: partly covered (mb > 0, cb > 0)
        (let ((l7 (xml-node-attributes (nth 2 lines))))
          (should (equal (cdr (assq 'nr l7)) "7"))
          (should (equal (cdr (assq 'cb l7)) "1"))
          (should (equal (cdr (assq 'mb l7)) "1")))))))

(ert-deftest test-coverage/locate-jacoco-files ()
  "Finds JaCoCo XML reports in Maven target and Gradle build locations."
  (test-cov--with-tree
      '(("target/site/jacoco/jacoco.xml" . "<report name=\"maven\"/>")
        ("build/reports/jacoco/test/jacocoTestReport.xml" . "<report name=\"gradle\"/>"))
    (let ((maven-cov (expand-file-name "target/site/jacoco/jacoco.xml" root))
          (gradle-cov (expand-file-name "build/reports/jacoco/test/jacocoTestReport.xml" root)))
      (should (file-exists-p maven-cov))
      (should (file-exists-p gradle-cov)))))

(provide 'test-coverage)
;;; test-coverage.el ends here
