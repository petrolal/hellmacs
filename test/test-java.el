;;; test-java.el --- Tests for the :lang java module -*- lexical-binding: t; -*-

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


;; Run with `bin/hellmacs test'. These cover the module's own logic; its
;; behavior against a real JDTLS is checked by the Phase 6.2 probes (see
;; docs/roadmap.md).

;;; Code:

(require 'ert)
(require 'hellmacs-modules)
(require 'hellmacs-ux)                  ; `hellmacs-ux-enable', bound below

(defvar hellmacs-jvm--states)           ; defined by the module; bound below
(defvar hellmacs-jvm--import-failures)
(defvar hellmacs-jvm-lombok-jar)
(defvar hellmacs-jvm--default-lombok-jar)
(defvar hellmacs-jvm-lombok-sha256)

(defvar test-java--loaded nil)

(defun test-java--load ()
  "Load :lang java's config.el and autoload.el, once."
  (unless test-java--loaded
    (let ((hellmacs-modules (make-hash-table :test #'equal))
          (warning-minimum-log-level :emergency))
      (hellmacs--enable-modules '(:tools lsp :lang java))
      (hellmacs-module--load '(:lang . java) "autoload.el")
      (hellmacs-module--load '(:lang . java) "config.el"))
    (setq test-java--loaded t)))

(ert-deftest test-java/announce-themed-and-plain ()
  (test-java--load)
  (let ((hellmacs-ux-enable t))
    (should (equal (hellmacs-jvm-announce 'ignited "~/proj")
                   "[FORGE IGNITED] JDTLS bound to ~/proj")))
  (let ((hellmacs-ux-enable nil))
    (should (equal (hellmacs-jvm-announce 'ready "~/proj" 3.04)
                   "~/proj indexed in 3.0s"))))

(ert-deftest test-java/mode-line-states ()
  (test-java--load)
  (let* ((root (make-temp-file "hellmacs-test-java" t))
         (default-directory (file-name-as-directory root))
         (hellmacs-jvm--states (make-hash-table :test #'equal)))
    (unwind-protect
        (cl-letf (((symbol-function 'project-current) #'ignore))
          (should-not (hellmacs-jvm--mode-line))
          (hellmacs-jvm-set-state root 'igniting)
          (should (equal (substring-no-properties (hellmacs-jvm--mode-line)) " JVM:igniting "))
          (hellmacs-jvm-set-state root 'ready)
          (should (eq (get-text-property 1 'face (hellmacs-jvm--mode-line)) 'hellmacs-jvm-ready))
          ;; With or without a trailing slash, it's the same project.
          (should (eq (hellmacs-jvm-state (file-name-as-directory root)) 'ready))
          (should (eq (hellmacs-jvm-state (directory-file-name root)) 'ready))
          (hellmacs-jvm-set-state root nil)
          (should-not (hellmacs-jvm--mode-line)))
      (delete-directory root t))))

(ert-deftest test-java/mode-line-caches-the-project ()
  "Redrawing the mode-line doesn't look up the project again."
  (test-java--load)
  (let* ((root (make-temp-file "hellmacs-test-java" t))
         (hellmacs-jvm--states (make-hash-table :test #'equal))
         (lookups 0))
    (unwind-protect
        (with-temp-buffer
          (setq default-directory (file-name-as-directory root))
          (cl-letf (((symbol-function 'project-current) (lambda (&rest _) (cl-incf lookups) nil)))
            (hellmacs-jvm-set-state root 'ready)
            (dotimes (_ 5) (should (hellmacs-jvm--mode-line)))
            (should (= lookups 1))
            ;; Another directory is looked up again.
            (setq default-directory temporary-file-directory)
            (should-not (hellmacs-jvm--mode-line))
            (should (= lookups 2))))
      (delete-directory root t))))

(ert-deftest test-java/failed-import-is-not-ready ()
  "A failed import says so, and JDTLS's ServiceReady doesn't hide it."
  (test-java--load)
  (let* ((root (make-temp-file "hellmacs-test-java" t))
         (hellmacs-jvm--states (make-hash-table :test #'equal))
         (hellmacs-jvm--import-failures (make-hash-table :test #'equal))
         (hellmacs-ux-enable t)
         (shown nil)
         (toolchain "Sep 23 Synchronize project demo failed due to an error connecting to the Gradle build.
org.gradle...
Caused by: ToolchainProvisioningException: Cannot find a Java installation on your machine (Linux) matching: {languageVersion=17, vendor=any vendor}"))
    (unwind-protect
        (cl-letf (((symbol-function 'message)
                   (lambda (fmt &rest args) (push (apply #'format fmt args) shown))))
          (hellmacs-jvm--note-log root "Some unrelated log line")
          (should-not (hellmacs-jvm-state root))
          (hellmacs-jvm--note-log root toolchain)
          (should (eq (hellmacs-jvm-state root) 'purgatory))
          (should (string-match-p "BYTECODE PURGATORY.*needs a JDK 17" (car shown)))
          ;; Announced once, even if JDTLS repeats itself.
          (hellmacs-jvm--note-log root toolchain)
          (should (= (length shown) 1))
          ;; ServiceReady arrives anyway: still purgatory, no [DAEMON READY].
          (hellmacs-jvm--note-status root "ServiceReady" "ServiceReady")
          (should (eq (hellmacs-jvm-state root) 'purgatory))
          (should (= (length shown) 1))
          ;; After the cause is fixed, an OK project status recovers.
          (hellmacs-jvm--note-status root "ProjectStatus" "OK")
          (should (eq (hellmacs-jvm-state root) 'ready))
          (should (string-match-p "DAEMON READY" (car shown))))
      (delete-directory root t))))

(ert-deftest test-java/update-project-configuration-finds-build-file ()
  "From a source file, the nearest pom.xml or build.gradle is re-imported."
  (test-java--load)
  (let* ((root (make-temp-file "hellmacs-test-java" t))
         (src (expand-file-name "src/main/java/A.java" root))
         called-in)
    (unwind-protect
        (progn
          (make-directory (file-name-directory src) t)
          (with-temp-file src (insert "class A {}"))
          (with-temp-file (expand-file-name "build.gradle" root) (insert ""))
          (cl-letf (((symbol-function 'lsp-java-update-project-configuration)
                     (lambda () (setq called-in (buffer-file-name)))))
            (with-current-buffer (find-file-noselect src)
              (hellmacs-jvm-update-project-configuration)
              (kill-buffer)))
          (should (equal called-in (expand-file-name "build.gradle" root)))
          (when-let* ((b (get-file-buffer (expand-file-name "build.gradle" root)))) (kill-buffer b)))
      (delete-directory root t))))

(defmacro test-java--with-temp-lombok (&rest body)
  "Run BODY with the pinned Lombok jar path inside a temporary directory."
  (declare (indent 0))
  `(let* ((dir (make-temp-file "hellmacs-test-lombok" t))
          (jar (expand-file-name "jvm/lombok-test.jar" dir))
          (hellmacs-jvm-lombok-jar jar)
          (hellmacs-jvm--default-lombok-jar jar))
     (unwind-protect (progn ,@body)
       (delete-directory dir t))))

(ert-deftest test-java/vmargs-lombok-agent ()
  "+lombok adds the jar as a javaagent, but only once it exists."
  (test-java--load)
  (test-java--with-temp-lombok
    (let ((hellmacs-modules (make-hash-table :test #'equal))
          (warning-minimum-log-level :emergency))
      (hellmacs--enable-modules '(:lang (java +lombok)))
      (hellmacs-module--load '(:lang . java) "config.el")
      (should-not (seq-some (lambda (a) (string-prefix-p "-javaagent:" a)) (hellmacs-jvm--vmargs)))
      (make-directory (file-name-directory jar) t)
      (with-temp-file jar (insert "jar"))
      (should (member (concat "-javaagent:" jar) (hellmacs-jvm--vmargs)))
      (should (member "-Xmx2G" (hellmacs-jvm--vmargs)))
      ;; Without the flag, never.
      (hellmacs--enable-modules '(:lang java))
      (hellmacs-module--load '(:lang . java) "config.el")
      (should-not (seq-some (lambda (a) (string-prefix-p "-javaagent:" a)) (hellmacs-jvm--vmargs))))))

(ert-deftest test-java/lombok-download-checksum ()
  "A download is installed only if its SHA-256 matches the pin."
  (require 'hellmacs-sync)
  (let ((hellmacs-modules (make-hash-table :test #'equal)))
    (hellmacs--enable-modules '(:lang (java +lombok)))
    (hellmacs-module--load '(:lang . java) "cli.el"))
  (test-java--with-temp-lombok
    (cl-letf (((symbol-function 'url-copy-file)
               (lambda (_url file &rest _) (with-temp-file file (insert "jar bytes"))))
              ((symbol-function 'hellmacs-sync--log) #'ignore))
      ;; A pin that doesn't match: nothing is installed, no leftovers.
      (let ((hellmacs-jvm-lombok-sha256 "0000"))
        (should-error (hellmacs-jvm-sync-install-lombok))
        (should-not (file-exists-p jar))
        (should-not (file-exists-p (concat jar ".part"))))
      ;; A pin that matches: installed, then left alone.
      (let ((hellmacs-jvm-lombok-sha256 (secure-hash 'sha256 "jar bytes")))
        (hellmacs-jvm-sync-install-lombok)
        (should (file-exists-p jar))
        (should (hellmacs-jvm-lombok-jar-valid-p))
        (cl-letf (((symbol-function 'url-copy-file) (lambda (&rest _) (error "Shouldn't download"))))
          (hellmacs-jvm-sync-install-lombok))))))

(provide 'test-java)
;;; test-java.el ends here
