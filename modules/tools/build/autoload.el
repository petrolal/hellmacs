;;; tools/build/autoload.el -*- lexical-binding: t; -*-

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


;;; Build tool detection ---------------------------------------------------------

(defconst hellmacs-forge-build-markers
  '(("gradlew" gradle t) ("mvnw" maven t)
    ("settings.gradle" gradle nil) ("settings.gradle.kts" gradle nil)
    ("build.gradle" gradle nil) ("build.gradle.kts" gradle nil)
    ("pom.xml" maven nil))
  "Files that identify a build: (FILE TOOL WRAPPER-P), in order of preference.
A wrapper's directory is the build's root, so a module inside a
multi-module build still builds from the top.")

(defconst hellmacs-forge-build-files
  '((gradle "settings.gradle" "settings.gradle.kts" "build.gradle" "build.gradle.kts")
    (maven "pom.xml"))
  "The files that make a directory the root of a build of each tool.
A wrapper next to none of them (a leftover ./gradlew in a Maven
project) isn't that tool's build.")

(defun hellmacs-forge--build-root-p (root tool)
  "Non-nil if directory ROOT holds a build file of TOOL."
  (seq-some (lambda (file) (file-exists-p (expand-file-name file root)))
            (alist-get tool hellmacs-forge-build-files)))

;;;###autoload
(defun hellmacs-forge-build-tool (&optional dir)
  "Return (TOOL ROOT PROGRAM) for the build containing DIR, or nil.
TOOL is `gradle' or `maven'; ROOT the directory to run it in; PROGRAM
the wrapper (\"./gradlew\") if there is one, else the installed tool."
  (let ((dir (or dir default-directory)))
    (seq-some (pcase-lambda (`(,file ,tool ,wrapper))
                (when-let* ((root (locate-dominating-file dir file)))
                  (when (or (not wrapper) (hellmacs-forge--build-root-p root tool))
                    (list tool (file-name-as-directory (expand-file-name root))
                          (cond (wrapper (concat "./" file))
                                ((eq tool 'gradle) "gradle")
                                (t "mvn"))))))
              hellmacs-forge-build-markers)))

(defun hellmacs-forge--command (task &optional test)
  "Return the shell command for TASK (`build' or `test') in the current build.
TEST narrows `test' to a class (\"pkg.Class\") or method (\"pkg.Class#method\")."
  (pcase-let ((`(,tool ,_root ,program) (or (hellmacs-forge-build-tool)
                                            (user-error "No Gradle or Maven build here"))))
    (pcase (list tool task)
      ('(gradle build) (concat program " build --console=plain"))
      ('(maven build) (concat program " -B verify"))
      ('(gradle test)
       (concat program " test --console=plain"
               (when test (format " --tests '%s'" (string-replace "#" "." test)))))
      ('(maven test)
       (concat program " -B test"
               (when test
                 ;; Surefire wants Class#method (simple class name works
                 ;; too); don't fail modules that have no such test.
                 (format " -Dtest='%s' -Dsurefire.failIfNoSpecifiedTests=false" test)))))))

;;;###autoload
(defun hellmacs-forge-setup-build-h ()
  "Make `compile-command' (and so `C-x p c') the build's own build command."
  (when-let* ((command (ignore-errors (hellmacs-forge--command 'build))))
    (setq-local compile-command command)))

;;; Running builds and tests -----------------------------------------------------

(defun hellmacs-forge--run (command)
  "Run COMMAND with `compile', from the root of the current build."
  (let ((default-directory (nth 1 (hellmacs-forge-build-tool))))
    (compile command)))

(defun hellmacs-forge--java-class ()
  "Return the fully qualified name of the current Java buffer's class."
  (let ((class (file-name-base (or buffer-file-name (user-error "Not visiting a file")))))
    (save-excursion
      (goto-char (point-min))
      (if (re-search-forward "^[ \t]*package[ \t]+\\([a-zA-Z0-9_.]+\\)[ \t]*;" nil t)
          (concat (match-string-no-properties 1) "." class)
        class))))

(defun hellmacs-forge--java-test-method ()
  "Return the name of the test method around point, or nil.
JUnit test methods return void, so the nearest void method above point."
  (save-excursion
    (end-of-line)
    (when (re-search-backward
           (concat "^[ \t]*\\(?:\\(?:public\\|protected\\|private\\|static\\|final\\)[ \t]+\\)*"
                   "void[ \t]+\\([a-zA-Z_$][a-zA-Z0-9_$]*\\)[ \t]*(")
           nil t)
      (match-string-no-properties 1))))

;;;###autoload
(defun hellmacs-forge-build ()
  "Build the current project with its build tool (Gradle or Maven)."
  (interactive)
  (hellmacs-forge--run (hellmacs-forge--command 'build)))

;;;###autoload
(defun hellmacs-forge-test-at-point ()
  "Run the test method at point with the build tool (the whole class if none)."
  (interactive)
  (let ((method (hellmacs-forge--java-test-method)))
    (hellmacs-forge--run (hellmacs-forge--command
                          'test (concat (hellmacs-forge--java-class)
                                        (and method (concat "#" method)))))))

;;;###autoload
(defun hellmacs-forge-test-class ()
  "Run every test in the current class with the build tool."
  (interactive)
  (hellmacs-forge--run (hellmacs-forge--command 'test (hellmacs-forge--java-class))))

;;; Clickable errors and test failures -------------------------------------------
;;
;; Stock Emacs already understands javac (`gnu') and Maven (`maven')
;; errors. What it gets wrong for JVM builds:
;; - stack frames name a file without its directory ("Foo.java:12"),
;;   so it can't find them -- and marks JDK/library frames as errors;
;; - Gradle's test failures ("...Error at FooTest.java:16") likewise;
;; - Gradle repeats compile errors, indented, in its failure summary.
;; These rules resolve file names inside the project, and simply don't
;; match frames whose file isn't there (a FILE function returning nil
;; makes compile.el ignore the match).

(defvar-local hellmacs-forge--file-cache nil
  "Per compilation buffer: file name + package path -> resolved file or `none'.")

(defconst hellmacs-forge--ignored-dirs '("build" "target" "out" ".git" ".gradle" "node_modules")
  "Directories never searched for source files.")

(defun hellmacs-forge--find-source (file &optional package)
  "Find source FILE (a base name) in the project, under PACKAGE's directory.
PACKAGE is dotted (\"dev.hellmacs.demo\"); nil means any directory.
Results are cached per compilation buffer. Returns a path or nil."
  (unless hellmacs-forge--file-cache
    (setq hellmacs-forge--file-cache (make-hash-table :test #'equal)))
  (let* ((suffix (concat (if package (concat (string-replace "." "/" package) "/") "") file))
         (hit (gethash suffix hellmacs-forge--file-cache)))
    (if hit
        (unless (eq hit 'none) hit)
      (let ((found (seq-find
                    (lambda (path) (string-suffix-p (concat "/" suffix) path))
                    (directory-files-recursively
                     default-directory (concat "\\`" (regexp-quote file) "\\'") nil
                     (lambda (dir) (not (member (file-name-nondirectory dir)
                                                hellmacs-forge--ignored-dirs)))))))
        (puthash suffix (or found 'none) hellmacs-forge--file-cache)
        found))))

(defun hellmacs-forge--frame-file ()
  "FILE function for `hellmacs-jvm-frame': the frame's file, if in the project.
Preserves the match data: compile.el reads the line number from it next."
  (let ((package (match-string-no-properties 1))
        (file (match-string-no-properties 2)))
    (save-match-data
      (hellmacs-forge--find-source file (and (not (string-empty-p package))
                                              (string-remove-suffix "." package))))))

(defun hellmacs-forge--basename-file ()
  "FILE function for `hellmacs-gradle-test': the named file, if in the project.
Preserves the match data: compile.el reads the line number from it next."
  (let ((file (match-string-no-properties 1)))
    (save-match-data (hellmacs-forge--find-source file))))

;;;###autoload
(defun hellmacs-forge--add-error-regexps ()
  "Register Hellmacs' JVM error rules with `compile'."
  (dolist (rule
           `((hellmacs-jvm-frame
              ;; "at pkg.Class.method(File.java:12)", optionally "java.base/pkg..."
              ,(concat "^[ \t]+at \\(?:[^ \t\n/(]+/\\)?"
                       "\\(\\(?:[a-zA-Z_$][a-zA-Z0-9_$]*\\.\\)*\\)"   ; 1: package (with dot)
                       "[a-zA-Z_$][a-zA-Z0-9_$]*\\.[^.(\n]+"          ; Class.method
                       "(\\([^():\n]+\\.\\(?:java\\|kt\\|groovy\\|scala\\)\\):\\([0-9]+\\))")
              hellmacs-forge--frame-file 3)
             (hellmacs-gradle-test
              ;; "    org.opentest4j.AssertionFailedError at FooTest.java:16"
              "^[ \t]+[^ \t\n]+ at \\([^ \t\n:/]+\\.\\(?:java\\|kt\\|groovy\\)\\):\\([0-9]+\\)$"
              hellmacs-forge--basename-file 2)
             (hellmacs-gradle-summary
              ;; Gradle's indented repeat of javac errors: info, so M-g n skips it.
              "^[ \t]+\\(/[^:\n]+\\.\\(?:java\\|kt\\)\\):\\([0-9]+\\): \\(?:error\\|warning\\)"
              1 2 nil 0)))
    (setf (alist-get (car rule) compilation-error-regexp-alist-alist) (cdr rule))
    (add-to-list 'compilation-error-regexp-alist (car rule)))
  ;; Stock `java' also matches JVM frames (marking library frames as
  ;; errors); keep only its other job, Valgrind traces.
  (setf (alist-get 'java compilation-error-regexp-alist-alist)
        '("^==[0-9]+== +\\(?:at\\|b\\(y\\)\\).+(\\([^()\n]+\\):\\([0-9]+\\))$" 2 3 nil (1))))

;;; Announcing results -------------------------------------------------------------

(defcustom hellmacs-forge-messages
  '((tempered  success "[FORGE TEMPERED] Built in %.1fs"   "Build finished in %.1fs")
    (purgatory error   "[BYTECODE PURGATORY] %s"           "Build failed: %s")
    (damnation error   "[TEST DAMNATION] %s"               "Tests failed: %s"))
  "Build result messages: (EVENT FACE THEMED PLAIN).
The PLAIN wording is used when `hellmacs-ux-enable' is nil."
  :type '(repeat (list symbol face string string))
  :group 'hellmacs-forge)

(defvar-local hellmacs-forge--started nil
  "When this compilation started (`float-time').")

;;;###autoload
(defun hellmacs-forge--note-start-h (_process)
  "Remember when the compilation in the current buffer started."
  (setq hellmacs-forge--started (float-time)))

(defun hellmacs-forge-announce (event &rest args)
  "Show the message for EVENT (`hellmacs-forge-messages') with ARGS; return it."
  (pcase-let ((`(,face ,themed ,plain) (alist-get event hellmacs-forge-messages)))
    (let ((text (apply #'format (if (bound-and-true-p hellmacs-ux-enable) themed plain) args)))
      (message "%s" (propertize text 'face face))
      text)))

(defun hellmacs-forge--first-error ()
  "Return \"File:LINE\" for the first error in this compilation, or nil."
  (compilation--ensure-parse (point-max))
  (save-excursion
    (goto-char (point-min))
    (when-let* ((match (text-property-search-forward
                        'compilation-message nil
                        (lambda (_ msg) (and msg (= 2 (compilation--message->type msg)))))))
      (let* ((loc (compilation--message->loc (prop-match-value match)))
             (file (caar (compilation--loc->file-struct loc))))
        (format "%s:%s" (file-name-nondirectory file) (compilation--loc->line loc))))))

(defun hellmacs-forge--test-failures ()
  "Return \"F of N tests\" if this output reports failing tests, else nil."
  (save-excursion
    (goto-char (point-max))
    (cond ((re-search-backward "\\([0-9]+\\) tests? completed, \\([0-9]+\\) failed" nil t) ; Gradle
           (format "%s of %s tests" (match-string 2) (match-string 1)))
          ((re-search-backward ;; Maven's final summary line
            "^\\[ERROR\\] Tests run: \\([0-9]+\\), Failures: \\([0-9]+\\), Errors: \\([0-9]+\\)" nil t)
           (format "%d of %s tests"
                   (+ (string-to-number (match-string 2)) (string-to-number (match-string 3)))
                   (match-string 1))))))

(defun hellmacs-forge--build-problem ()
  "Return the build tool's own one-line reason for failing, or nil.
For failures with no source location: a missing toolchain, dependencies
that don't resolve, a plugin error. Gradle names it under \"What went
wrong\", Maven in its \"Failed to execute goal\" line."
  (save-excursion
    (goto-char (point-min))
    (let ((problem
           (cond ((re-search-forward "^\\* What went wrong:\n\\(\\(?:[^\n>].*\n\\)*?\\)> \\(.+\\)$" nil t)
                  (match-string 2))
                 ((re-search-forward "^\\* What went wrong:\n\\(.+\\)$" nil t)
                  (match-string 1))
                 ((re-search-forward "^\\[ERROR\\] Failed to execute goal .*on project [^ :]+: \\(.+\\)$" nil t)
                  (match-string 1)))))
      (when problem
        (truncate-string-to-width (string-trim problem) 110 nil nil t)))))

;;;###autoload
(defun hellmacs-forge--report-h (buffer status)
  "Announce how the build in BUFFER ended (STATUS from `compile').
For `compilation-finish-functions'. Only real compilations, not grep."
  (with-current-buffer buffer
    (when (eq major-mode 'compilation-mode)
      (let ((ok (string-prefix-p "finished" status))
            (elapsed (if hellmacs-forge--started (- (float-time) hellmacs-forge--started) 0.0)))
        (if ok
            (hellmacs-forge-announce 'tempered elapsed)
          (let ((where (hellmacs-forge--first-error)))
            (if-let* ((tests (hellmacs-forge--test-failures)))
                (hellmacs-forge-announce 'damnation (if where (format "%s (%s)" tests where) tests))
              (hellmacs-forge-announce 'purgatory (or where (hellmacs-forge--build-problem)
                                                      (string-trim status))))))
        ;; A Java project's mode-line: JVM:purgatory until the next good build.
        (when (fboundp 'hellmacs-jvm-set-state)
          (if (not ok)
              (hellmacs-jvm-set-state default-directory 'purgatory)
            (when (eq (hellmacs-jvm-state default-directory) 'purgatory)
              (hellmacs-jvm-set-state default-directory 'ready))))))))
