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

(defvar hellmacs-lsp-status--sessions)  ; defined by core; bound below
(defvar hellmacs-lsp-status--servers)
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

(ert-deftest test-java/registered-with-its-wording ()
  (test-java--load)
  (should (plist-get (alist-get 'jdtls hellmacs-lsp-status--servers) :on-log))
  (let ((hellmacs-ux-enable t))
    (should (equal (hellmacs-lsp-status-announce 'ignited "JDTLS" "~/proj")
                   "[FORGE IGNITED] JDTLS bound to ~/proj")))
  (let ((hellmacs-ux-enable nil))
    (should (equal (hellmacs-lsp-status-announce 'ready "~/proj" 3.04)
                   "~/proj indexed in 3.0s"))))

(ert-deftest test-java/failed-import-is-not-ready ()
  "A failed import says so, and JDTLS's ServiceReady doesn't hide it."
  (test-java--load)
  (let* ((root (make-temp-file "hellmacs-test-java" t))
         (hellmacs-lsp-status--sessions (make-hash-table :test #'equal))
         (hellmacs-ux-enable t)
         (shown nil)
         (toolchain "Sep 23 Synchronize project demo failed due to an error connecting to the Gradle build.
org.gradle...
Caused by: ToolchainProvisioningException: Cannot find a Java installation on your machine (Linux) matching: {languageVersion=17, vendor=any vendor}"))
    (unwind-protect
        (cl-letf (((symbol-function 'message)
                   (lambda (fmt &rest args) (push (apply #'format fmt args) shown))))
          (hellmacs-lsp-status-ignite 'jdtls root)
          (setq shown nil)
          (hellmacs-jvm--note-log root "Some unrelated log line")
          (should (eq (hellmacs-jvm-state root) 'igniting))
          ;; Not ready while importing, whatever the project status says.
          (hellmacs-jvm--note-notification root "language/status" '(:type "ProjectStatus" :message "OK"))
          (should (eq (hellmacs-jvm-state root) 'igniting))
          (hellmacs-jvm--note-log root toolchain)
          (should (eq (hellmacs-jvm-state root) 'failed))
          (should (string-match-p "BYTECODE PURGATORY.*needs a JDK 17" (car shown)))
          ;; Announced once, even if JDTLS repeats itself.
          (hellmacs-jvm--note-log root toolchain)
          (should (= (length shown) 1))
          ;; ServiceReady arrives anyway: still failed, no [DAEMON READY].
          (hellmacs-jvm--note-notification root "language/status" '(:type "ServiceReady" :message "ServiceReady"))
          (should (eq (hellmacs-jvm-state root) 'failed))
          (should (= (length shown) 1))
          ;; After the cause is fixed, an OK project status recovers.
          (hellmacs-jvm--note-notification root "language/status" '(:type "ProjectStatus" :message "OK"))
          (should (eq (hellmacs-jvm-state root) 'ready))
          (should (string-match-p "DAEMON READY" (car shown))))
      (delete-directory root t))))

(ert-deftest test-java/service-ready-means-ready ()
  (test-java--load)
  (let* ((root (make-temp-file "hellmacs-test-java" t))
         (hellmacs-lsp-status--sessions (make-hash-table :test #'equal)))
    (unwind-protect
        (cl-letf (((symbol-function 'message) #'ignore))
          (hellmacs-lsp-status-ignite 'jdtls root)
          (hellmacs-jvm--note-notification root "language/progressReport" '(:status "Importing"))
          (should (eq (hellmacs-jvm-state root) 'igniting))
          (hellmacs-jvm--note-notification root "language/status" '(:type "ServiceReady" :message "ServiceReady"))
          (should (eq (hellmacs-jvm-state root) 'ready)))
      (delete-directory root t))))

(ert-deftest test-java/test-method ()
  "The nearest void method above point is the test at point."
  (test-java--load)
  (with-temp-buffer
    (insert "package dev.x;\n\nclass GreeterTest {\n    @Test\n    void greets() {\n        assertTrue(true);\n    }\n}\n")
    (goto-char (point-min)) (search-forward "assertTrue")
    (should (equal (hellmacs-jvm-test-method) "greets"))
    (goto-char (point-min))
    (should-not (hellmacs-jvm-test-method))))

(ert-deftest test-java/reload-hot-swaps-debug-sessions ()
  "`C-c h r' in Java hot-swaps into a debug session, and only then."
  (test-java--load)
  (let (swapped)
    (cl-letf (((symbol-function 'hellmacs-debug-hot-swap) (lambda () (setq swapped t)))
              ((symbol-function 'dap--cur-session) #'ignore))
      (should-error (hellmacs-jvm-reload) :type 'user-error)
      (should-not swapped)
      (cl-letf (((symbol-function 'dap--cur-session) (lambda () 'session)))
        (hellmacs-jvm-reload))
      (should swapped))))

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
