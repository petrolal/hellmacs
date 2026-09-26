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
  (should (equal (hellmacs-jdk-release-name "1.8") "JavaSE-1.8"))
  (should (equal (hellmacs-jdk-release-name "8") "JavaSE-1.8"))
  (should (equal (hellmacs-jdk-release-name "11") "JavaSE-11"))
  (should (equal (hellmacs-jdk-release-name "17") "JavaSE-17"))
  (should (equal (hellmacs-jdk-release-name "21") "JavaSE-21"))
  (should (equal (hellmacs-jdk-release-name "25") "JavaSE-25")))

(ert-deftest test-jdk/version-normalization-edge-cases ()
  "Handles complex JAVA_VERSION strings with build metadata and LTS suffixes."
  (should (equal (hellmacs-jdk-parse-release-content "JAVA_VERSION=\"21.0.2+13-LTS\"\n") "JavaSE-21"))
  (should (equal (hellmacs-jdk-parse-release-content "JAVA_VERSION='17.0.9+9'\n") "JavaSE-17"))
  (should (equal (hellmacs-jdk-parse-release-content "JAVA_VERSION=\"1.8.0_402-b06\"\n") "JavaSE-1.8"))
  (should (equal (hellmacs-jdk-parse-release-content "JAVA_VERSION=\"11.0.22\"\n") "JavaSE-11")))

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
        ("Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home/release" . "JAVA_VERSION=\"21.0.1\"\n")
        ("asdf/installs/java/adoptopenjdk-11.0.11+9/release" . "JAVA_VERSION=\"11.0.11\"\n")
        ("jenv/versions/17.0/release" . "JAVA_VERSION=\"17.0.0\"\n")
        ("mise/installs/java/21.0.1/release" . "JAVA_VERSION=\"21.0.1\"\n"))
    (let* ((scan-roots
            (list (expand-file-name "sdkman/candidates/java" test-jdk--root)
                  (expand-file-name "usr/lib/jvm" test-jdk--root)
                  (expand-file-name "Library/Java/JavaVirtualMachines" test-jdk--root)
                  (expand-file-name "asdf/installs/java" test-jdk--root)
                  (expand-file-name "jenv/versions" test-jdk--root)
                  (expand-file-name "mise/installs/java" test-jdk--root)))
           (found (hellmacs-jdk-scan-roots scan-roots)))
      (should (assoc "JavaSE-1.8" found))
      (should (assoc "JavaSE-11" found))
      (should (assoc "JavaSE-17" found))
      (should (assoc "JavaSE-21" found)))))

(ert-deftest test-jdk/lsp-java-configuration-runtimes ()
  "Generates valid vector of plists for `lsp-java-configuration-runtimes'."
  (let* ((jdks '(("JavaSE-1.8" . "/usr/lib/jvm/java-8")
                 ("JavaSE-11"  . "/usr/lib/jvm/java-11")
                 ("JavaSE-17"  . "/usr/lib/jvm/java-17")
                 ("JavaSE-21"  . "/usr/lib/jvm/java-21")))
         (default-path "/usr/lib/jvm/java-21")
         (runtimes (hellmacs-jdk-lsp-runtimes jdks default-path)))
    (should (vectorp runtimes))
    (should (= (length runtimes) 4))
    (should (equal (plist-get (aref runtimes 0) :name) "JavaSE-1.8"))
    (should (equal (plist-get (aref runtimes 0) :path) "/usr/lib/jvm/java-8"))
    (should (equal (plist-get (aref runtimes 0) :default) :json-false))
    (should (equal (plist-get (aref runtimes 3) :name) "JavaSE-21"))
    (should (equal (plist-get (aref runtimes 3) :default) t))))

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
    (let* ((xml-file (expand-file-name "m2/toolchains.xml" test-jdk--root))
           (versions (hellmacs-jdk-parse-toolchains-xml xml-file)))
      (should (member "JavaSE-1.8" versions))
      (should (member "JavaSE-17" versions)))))

(ert-deftest test-jdk/gradle-toolchain-detection ()
  "Detects Java toolchain version requirements in Gradle build files."
  (let ((kts-content "java {\n    toolchain {\n        languageVersion.set(JavaLanguageVersion.of(17))\n    }\n}")
        (groovy-content "java {\n    toolchain {\n        languageVersion = JavaLanguageVersion.of(11)\n    }\n}"))
    (should (equal (hellmacs-jdk-parse-gradle-toolchain kts-content) "JavaSE-17"))
    (should (equal (hellmacs-jdk-parse-gradle-toolchain groovy-content) "JavaSE-11"))))

(provide 'test-jdk)
;;; test-jdk.el ends here
