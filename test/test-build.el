;;; test-build.el --- Tests for the :tools build module -*- lexical-binding: t; -*-

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


;; Run with `bin/hellmacs test'. Builds against real Gradle and Maven are
;; checked by the Phase 6.4 probes (see docs/roadmap.md).

;;; Code:

(require 'ert)
(require 'compile)
(require 'hellmacs-modules)
(require 'hellmacs-ux)                  ; `hellmacs-ux-enable', bound below

(let ((hellmacs-modules (make-hash-table :test #'equal)))
  (hellmacs--enable-modules '(:tools build))
  (hellmacs-module--load '(:tools . build) "autoload.el"))
(hellmacs-forge--add-error-regexps)

(defmacro test-build--with-tree (files &rest body)
  "Run BODY in a temporary directory holding FILES (relative paths)."
  (declare (indent 1))
  `(let* ((root (file-name-as-directory (make-temp-file "hellmacs-test-build" t)))
          (default-directory root))
     (unwind-protect
         (progn
           (dolist (f ,files)
             (let ((path (expand-file-name f root)))
               (make-directory (file-name-directory path) t)
               (with-temp-file path (insert ""))))
           ,@body)
       (delete-directory root t))))

(ert-deftest test-build/detects-tool-and-root ()
  "The wrapper's directory wins over a nearer module build file."
  (test-build--with-tree '("gradlew" "settings.gradle" "app/build.gradle" "app/src/A.java")
    (let ((default-directory (expand-file-name "app/src/" root)))
      (should (equal (hellmacs-forge-build-tool) (list 'gradle root "./gradlew")))))
  (test-build--with-tree '("pom.xml" "src/A.java")
    (let ((default-directory (expand-file-name "src/" root)))
      (should (equal (hellmacs-forge-build-tool) (list 'maven root "mvn")))))
  ;; A wrapper left behind without its build file doesn't make it that build.
  (test-build--with-tree '("gradlew" "pom.xml" "src/A.java")
    (let ((default-directory (expand-file-name "src/" root)))
      (should (equal (hellmacs-forge-build-tool) (list 'maven root "mvn")))))
  (test-build--with-tree '("gradlew" "src/A.java")
    (should-not (hellmacs-forge-build-tool)))
  (test-build--with-tree '("src/A.java")
    (should-not (hellmacs-forge-build-tool))))

(ert-deftest test-build/commands ()
  (test-build--with-tree '("gradlew" "build.gradle.kts")
    (should (equal (hellmacs-forge--command 'build) "./gradlew build --console=plain"))
    (should (equal (hellmacs-forge--command 'test "p.C#m")
                   "./gradlew test --console=plain --tests 'p.C.m'")))
  (test-build--with-tree '("mvnw" "pom.xml")
    (should (equal (hellmacs-forge--command 'build) "./mvnw -B verify"))
    (should (equal (hellmacs-forge--command 'test "p.C#m")
                   "./mvnw -B test -Dtest='p.C#m' -Dsurefire.failIfNoSpecifiedTests=false"))))

(ert-deftest test-build/java-class-and-test-method ()
  (with-temp-buffer
    (setq buffer-file-name "/tmp/GreeterTest.java")
    (insert "package dev.x;\n\nclass GreeterTest {\n    @Test\n    void greets() {\n        assertTrue(true);\n    }\n}\n")
    (should (equal (hellmacs-forge--java-class) "dev.x.GreeterTest"))
    (goto-char (point-min)) (search-forward "assertTrue")
    (should (equal (hellmacs-forge--java-test-method) "greets"))
    (goto-char (point-min))
    (should-not (hellmacs-forge--java-test-method))
    (set-buffer-modified-p nil)))

(defun test-build--parse (output)
  "Parse OUTPUT as compilation output; return (TYPE FILE-BASENAME LINE) per match."
  (with-current-buffer (get-buffer-create " *test-build*")
    (let ((inhibit-read-only t)) (erase-buffer) (insert output))
    (compilation-mode)
    (setq hellmacs-forge--file-cache nil)
    (compilation--ensure-parse (point-max))
    (goto-char (point-min))
    (let (out)
      (while (let ((m (text-property-search-forward 'compilation-message nil (lambda (_ v) v))))
               (when m
                 (let* ((msg (prop-match-value m)) (loc (compilation--message->loc msg)))
                   (push (list (compilation--message->type msg)
                               (file-name-nondirectory (caar (compilation--loc->file-struct loc)))
                               (compilation--loc->line loc))
                         out)))))
      (nreverse out))))

(ert-deftest test-build/error-parsing ()
  "Project frames and test failures resolve; library frames are ignored."
  (test-build--with-tree '("src/test/java/dev/x/BrokenTest.java" "src/main/java/dev/x/Greeter.java")
    ;; Maven/Surefire: a JUnit frame (not in the project) and a project frame.
    (should (equal (test-build--parse
                    "org.opentest4j.AssertionFailedError: nope\n\tat org.junit.jupiter.api.Assertions.assertEquals(Assertions.java:1199)\n\tat dev.x.BrokenTest.fails(BrokenTest.java:16)\n")
                   '((2 "BrokenTest.java" 16))))
    ;; Gradle's test failure line names only the file.
    (should (equal (test-build--parse "BrokenTest > fails() FAILED\n    org.opentest4j.AssertionFailedError at BrokenTest.java:16\n")
                   '((2 "BrokenTest.java" 16))))
    ;; javac, then Gradle's indented repeat of it: an error, then info.
    (let ((path (expand-file-name "src/main/java/dev/x/Greeter.java" root)))
      (should (equal (test-build--parse (format "%s:12: error: bad\n  %s:12: error: bad\n" path path))
                     '((2 "Greeter.java" 12) (0 "Greeter.java" 12)))))))

(ert-deftest test-build/report-messages ()
  (let ((hellmacs-ux-enable t))
    (with-current-buffer (get-buffer-create " *test-build-report*")
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "BrokenTest > fails() FAILED\n\n3 tests completed, 1 failed\n"))
      (compilation-mode)
      (should (equal (hellmacs-forge--test-failures) "1 of 3 tests"))
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "[ERROR] Tests run: 1, Failures: 1, Errors: 0, Skipped: 0 <<< FAILURE! -- in X\n[ERROR] Tests run: 3, Failures: 1, Errors: 1, Skipped: 0\n"))
      (should (equal (hellmacs-forge--test-failures) "2 of 3 tests"))))
  (let ((hellmacs-ux-enable t))
    (should (equal (hellmacs-forge-announce 'tempered 1.25) "[FORGE TEMPERED] Built in 1.2s"))
    (should (equal (hellmacs-forge-announce 'purgatory "A.java:3") "[BYTECODE PURGATORY] A.java:3")))
  (let ((hellmacs-ux-enable nil))
    (should (equal (hellmacs-forge-announce 'damnation "1 of 3 tests") "Tests failed: 1 of 3 tests"))))

(ert-deftest test-build/build-problem-without-a-location ()
  "Failures with no file:line show the build tool's own reason."
  (with-temp-buffer
    (insert "FAILURE: Build failed with an exception.\n\n* What went wrong:\nCould not determine the dependencies of task ':compileKotlin'.\n> Cannot find a Java installation matching: {languageVersion=21}\n\n* Try:\n")
    (should (equal (hellmacs-forge--build-problem)
                   "Cannot find a Java installation matching: {languageVersion=21}")))
  (with-temp-buffer
    (insert "* What went wrong:\nA problem occurred evaluating root project 'x'.\n\n* Try:\n")
    (should (equal (hellmacs-forge--build-problem)
                   "A problem occurred evaluating root project 'x'.")))
  (with-temp-buffer
    (insert "[INFO] BUILD FAILURE\n[ERROR] Failed to execute goal on project demo: Could not resolve dependencies for project a:b:jar:1: no such artifact\n")
    (should (equal (hellmacs-forge--build-problem)
                   "Could not resolve dependencies for project a:b:jar:1: no such artifact")))
  (with-temp-buffer
    (insert "all good\n")
    (should-not (hellmacs-forge--build-problem))))

(provide 'test-build)
;;; test-build.el ends here
