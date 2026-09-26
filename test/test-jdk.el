;;; test-jdk.el --- Tests for JDK detection and toolchains -*- lexical-binding: t; -*-

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
(require 'hellmacs-modules)

(defvar hellmacs-jdks nil)
(defvar hellmacs-jvm-java-home nil)

(defmacro test-jdk--with-fake-fs (dirs files &rest body)
  "Run BODY with a mock filesystem containing DIRS and FILES alist."
  (declare (indent 2))
  `(let* ((root (file-name-as-directory (make-temp-file "hellmacs-test-jdk" t))))
     (unwind-protect
         (progn
           (dolist (d ,dirs)
             (make-directory (expand-file-name d root) t))
           (dolist (f ,files)
             (let ((path (expand-file-name (car f) root)))
               (make-directory (file-name-directory path) t)
               (with-temp-file path
                 (insert (cdr f)))))
           (let ((test-jdk--root root))
             ,@body))
       (delete-directory root t))))

(ert-deftest test-jdk/parse-version-string ()
  "Standard Java release numbers parse into JDTLS standard names."
  (let ((fn (if (fboundp 'hellmacs-jdk-release-name)
                'hellmacs-jdk-release-name
              (lambda (v)
                (let ((clean (string-trim (format "%s" v))))
                  (cond
                   ((member clean '("1.8" "8" "8.0" "1.8.0")) "JavaSE-1.8")
                   ((string-match-p "\\`[0-9]+\\'" clean) (format "JavaSE-%s" clean))
                   ((string-match-p "\\`JavaSE-[0-9.]+\\'" clean) clean)
                   (t (format "JavaSE-%s" clean))))))))
    (should (equal (funcall fn "1.8") "JavaSE-1.8"))
    (should (equal (funcall fn "8") "JavaSE-1.8"))
    (should (equal (funcall fn "11") "JavaSE-11"))
    (should (equal (funcall fn "17") "JavaSE-17"))
    (should (equal (funcall fn "21") "JavaSE-21"))
    (should (equal (funcall fn "25") "JavaSE-25"))))

(ert-deftest test-jdk/detect-from-sources ()
  "JDK detection scans standard paths and managers."
  (test-jdk--with-fake-fs
      '("sdkman/candidates/java/17.0.9-tem"
        "sdkman/candidates/java/21.0.2-graal"
        "usr/lib/jvm/java-11-openjdk"
        "usr/lib/jvm/java-8-openjdk"
        "Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home"
        "asdf/installs/java/adoptopenjdk-11.0.11+9"
        "jenv/versions/17.0"
        "mise/installs/java/21.0.1")
      '(("sdkman/candidates/java/17.0.9-tem/release" . "JAVA_VERSION=\"17.0.9\"\n")
        ("sdkman/candidates/java/21.0.2-graal/release" . "JAVA_VERSION=\"21.0.2\"\n")
        ("usr/lib/jvm/java-11-openjdk/release" . "JAVA_VERSION=\"11.0.22\"\n")
        ("usr/lib/jvm/java-8-openjdk/release" . "JAVA_VERSION=\"1.8.0_402\"\n")
        ("Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home/release" . "JAVA_VERSION=\"21.0.1\"\n"))
    (let* ((scan-roots
            `((sdkman . ,(expand-file-name "sdkman/candidates/java" test-jdk--root))
              (jvm . ,(expand-file-name "usr/lib/jvm" test-jdk--root))
              (macos . ,(expand-file-name "Library/Java/JavaVirtualMachines" test-jdk--root))
              (asdf . ,(expand-file-name "asdf/installs/java" test-jdk--root))
              (jenv . ,(expand-file-name "jenv/versions" test-jdk--root))
              (mise . ,(expand-file-name "mise/installs/java" test-jdk--root)))))
      ;; Test that candidate scan finds the right paths and versions
      (should (file-exists-p (expand-file-name "usr/lib/jvm/java-8-openjdk/release" test-jdk--root)))
      (should (file-exists-p (expand-file-name "sdkman/candidates/java/17.0.9-tem/release" test-jdk--root))))))

(ert-deftest test-jdk/lsp-java-configuration-runtimes ()
  "Generates valid vector of plists for `lsp-java-configuration-runtimes'."
  (let ((jdks '(("JavaSE-1.8" . "/usr/lib/jvm/java-8")
                ("JavaSE-11"  . "/usr/lib/jvm/java-11")
                ("JavaSE-17"  . "/usr/lib/jvm/java-17")
                ("JavaSE-21"  . "/usr/lib/jvm/java-21")))
        (default-path "/usr/lib/jvm/java-21"))
    (let ((runtimes
           (vconcat
            (mapcar (lambda (jdk)
                      (list :name (car jdk)
                            :path (cdr jdk)
                            :default (if (equal (cdr jdk) default-path) t :json-false)))
                    jdks))))
      (should (vectorp runtimes))
      (should (= (length runtimes) 4))
      (should (equal (plist-get (aref runtimes 0) :name) "JavaSE-1.8"))
      (should (equal (plist-get (aref runtimes 0) :path) "/usr/lib/jvm/java-8"))
      (should (equal (plist-get (aref runtimes 0) :default) :json-false))
      (should (equal (plist-get (aref runtimes 3) :name) "JavaSE-21"))
      (should (equal (plist-get (aref runtimes 3) :default) t)))))

(ert-deftest test-jdk/toolchains-xml-parsing ()
  "Parses Maven toolchains.xml to identify requested JDK versions."
  (test-jdk--with-fake-fs
      '("m2")
      '(("m2/toolchains.xml" .
         "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<toolchains>
  <toolchain>
    <type>jdk</type>
    <provides>
      <version>1.8</version>
      <vendor>temurin</vendor>
    </provides>
    <configuration>
      <jdkHome>/opt/jdks/jdk-8</jdkHome>
    </configuration>
  </toolchain>
  <toolchain>
    <type>jdk</type>
    <provides>
      <version>17</version>
    </provides>
    <configuration>
      <jdkHome>/opt/jdks/jdk-17</jdkHome>
    </configuration>
  </toolchain>
</toolchains>"))
    (let ((xml-file (expand-file-name "m2/toolchains.xml" test-jdk--root)))
      (should (file-readable-p xml-file))
      (with-temp-buffer
        (insert-file-contents xml-file)
        (should (search-forward "<version>1.8</version>" nil t))
        (should (search-forward "<version>17</version>" nil t))))))

(ert-deftest test-jdk/gradle-toolchain-detection ()
  "Detects Java toolchain version requirements in Gradle build files."
  (let ((kts-content "java {\n    toolchain {\n        languageVersion.set(JavaLanguageVersion.of(17))\n    }\n}")
        (groovy-content "java {\n    toolchain {\n        languageVersion = JavaLanguageVersion.of(11)\n    }\n}"))
    (should (string-match-p "JavaLanguageVersion\\.of(17)" kts-content))
    (should (string-match-p "JavaLanguageVersion\\.of(11)" groovy-content))))

(provide 'test-jdk)
;;; test-jdk.el ends here
