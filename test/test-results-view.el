;;; test-results-view.el --- Tests for test results UI (Phase 12.5) -*- lexical-binding: t; -*-

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

(defmacro test-results--with-tree (files &rest body)
  "Run BODY in a temporary directory holding FILES (alist of path . content)."
  (declare (indent 1))
  `(let* ((root (file-name-as-directory (make-temp-file "hellmacs-test-results" t)))
          (default-directory root))
     (unwind-protect
         (progn
           (dolist (f ,files)
             (let ((path (expand-file-name (car f) root)))
               (make-directory (file-name-directory path) t)
               (with-temp-file path (insert (cdr f)))))
           ,@body)
       (delete-directory root t))))

(ert-deftest test-results/parse-junit-xml ()
  "Parses Maven surefire / Gradle JUnit XML test result reports."
  (test-results--with-tree
      '(("target/surefire-reports/TEST-com.example.AppTest.xml" .
         "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<testsuite name=\"com.example.AppTest\" time=\"0.125\" tests=\"3\" errors=\"0\" skipped=\"0\" failures=\"1\">
  <testcase name=\"testPass\" classname=\"com.example.AppTest\" time=\"0.010\"/>
  <testcase name=\"testFail\" classname=\"com.example.AppTest\" time=\"0.050\">
    <failure message=\"expected 42 but got 41\" type=\"org.junit.ComparisonFailure\">
      org.junit.ComparisonFailure: expected 42 but got 41
      at com.example.AppTest.testFail(AppTest.java:25)
    </failure>
  </testcase>
  <testcase name=\"testPassTwo\" classname=\"com.example.AppTest\" time=\"0.005\"/>
</testsuite>"))
    (let* ((xml-file (expand-file-name "target/surefire-reports/TEST-com.example.AppTest.xml" root))
           (suite (hellmacs-test-results-parse-junit-xml xml-file)))
      (should (equal (plist-get suite :suite) "com.example.AppTest"))
      (should (= (plist-get suite :total) 3))
      (should (= (plist-get suite :failures) 1))
      (let ((cases (plist-get suite :cases)))
        (should (= (length cases) 3))
        (let ((failed (cl-find-if (lambda (c) (plist-get c :failure)) cases)))
          (should failed)
          (should (equal (plist-get failed :name) "testFail"))
          (should (string-match-p "expected 42" (plist-get failed :failure))))))))

(ert-deftest test-results/locate-report-files ()
  "Finds test report XMLs across Maven target and Gradle build directories."
  (test-results--with-tree
      '(("target/surefire-reports/TEST-A.xml" . "<testsuite name=\"A\"/>")
        ("target/failsafe-reports/TEST-IT.xml" . "<testsuite name=\"IT\"/>")
        ("build/test-results/test/TEST-B.xml" . "<testsuite name=\"B\"/>"))
    (let ((reports (hellmacs-test-results-find-reports root)))
      (should (= (length reports) 3)))))

(ert-deftest test-results/tabulated-list-keybindings ()
  "Verifies keymap definitions for test results navigation and rerun."
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") 'hellmacs-test-results-jump)
    (define-key map (kbd "r") 'hellmacs-test-results-rerun-at-point)
    (define-key map (kbd "f") 'hellmacs-test-results-rerun-failures)
    (define-key map (kbd "g") 'hellmacs-test-results-refresh)
    (should (eq (lookup-key map (kbd "RET")) 'hellmacs-test-results-jump))
    (should (eq (lookup-key map (kbd "r")) 'hellmacs-test-results-rerun-at-point))
    (should (eq (lookup-key map (kbd "f")) 'hellmacs-test-results-rerun-failures))
    (should (eq (lookup-key map (kbd "g")) 'hellmacs-test-results-refresh))))

(provide 'test-results-view)
;;; test-results-view.el ends here
