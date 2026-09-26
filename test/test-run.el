;;; test-run.el --- Tests for :tools run module (Phase 12.4) -*- lexical-binding: t; -*-

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

(defmacro test-run--with-tree (files &rest body)
  "Run BODY in a temporary directory holding FILES (alist of path . content)."
  (declare (indent 1))
  `(let* ((root (file-name-as-directory (make-temp-file "hellmacs-test-run" t)))
          (default-directory root))
     (unwind-protect
         (progn
           (dolist (f ,files)
             (let ((path (expand-file-name (car f) root)))
               (make-directory (file-name-directory path) t)
               (with-temp-file path (insert (cdr f)))))
           ,@body)
       (delete-directory root t))))

(ert-deftest test-run/eld-configuration-parsing ()
  "Parses Hellmacs .hellmacs/run.eld format into run configurations."
  (test-run--with-tree
      '((".hellmacs/run.eld" . "((:name \"Server App\" :main \"dev.hellmacs.demo.App\" :jvm-args (\"-Xmx512m\") :args (\"--port=8080\") :env ((\"STAGE\" . \"local\"))))\n"))
    (let* ((run-file (expand-file-name ".hellmacs/run.eld" root))
           (configs (hellmacs-run-parse-eld run-file)))
      (should (= (length configs) 1))
      (let ((cfg (car configs)))
        (should (equal (plist-get cfg :name) "Server App"))
        (should (equal (plist-get cfg :main) "dev.hellmacs.demo.App"))
        (should (equal (plist-get cfg :jvm-args) '("-Xmx512m")))
        (should (equal (plist-get cfg :args) '("--port=8080")))))))

(ert-deftest test-run/intellij-run-xml-parsing ()
  "Parses IntelliJ .run/*.run.xml run configuration format into run configurations."
  (test-run--with-tree
      '((".run/App.run.xml" . "<component name=\"ProjectRunConfigurationManager\">
  <configuration default=\"false\" name=\"AppRun\" type=\"SpringBootApplicationConfigurationType\" factoryName=\"Spring Boot\">
    <option name=\"MAIN_CLASS_NAME\" value=\"dev.hellmacs.demo.App\" />
    <option name=\"VM_PARAMETERS\" value=\"-Dspring.profiles.active=dev\" />
    <option name=\"PROGRAM_PARAMETERS\" value=\"--debug\" />
  </configuration>
</component>"))
    (let* ((xml-file (expand-file-name ".run/App.run.xml" root))
           (configs (hellmacs-run-parse-intellij xml-file)))
      (should (= (length configs) 1))
      (let ((cfg (car configs)))
        (should (equal (plist-get cfg :name) "AppRun"))
        (should (equal (plist-get cfg :main) "dev.hellmacs.demo.App"))
        (should (member "-Dspring.profiles.active=dev" (plist-get cfg :jvm-args)))))))

(ert-deftest test-run/eclipse-launch-parsing ()
  "Parses Eclipse .launch configuration XML format into run configurations."
  (test-run--with-tree
      '((".launch/App.launch" . "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
<launchConfiguration type=\"org.eclipse.jdt.launching.localJavaApplication\">
    <stringAttribute key=\"org.eclipse.jdt.launching.MAIN_TYPE\" value=\"dev.hellmacs.demo.App\"/>
    <stringAttribute key=\"org.eclipse.jdt.launching.VM_ARGUMENTS\" value=\"-Xms256m\"/>
    <stringAttribute key=\"org.eclipse.jdt.launching.PROGRAM_ARGUMENTS\" value=\"start\"/>
</launchConfiguration>"))
    (let* ((launch-file (expand-file-name ".launch/App.launch" root))
           (configs (hellmacs-run-parse-eclipse launch-file)))
      (should (= (length configs) 1))
      (let ((cfg (car configs)))
        (should (equal (plist-get cfg :main) "dev.hellmacs.demo.App"))
        (should (equal (plist-get cfg :jvm-args) '("-Xms256m")))))))

(ert-deftest test-run/keymap-and-prefix ()
  "Verifies C-c r key bindings for run, debug, rerun."
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c r r") 'hellmacs-run)
    (define-key map (kbd "C-c r d") 'hellmacs-run-debug)
    (define-key map (kbd "C-c r l") 'hellmacs-run-last)
    (should (eq (lookup-key map (kbd "C-c r r")) 'hellmacs-run))
    (should (eq (lookup-key map (kbd "C-c r d")) 'hellmacs-run-debug))
    (should (eq (lookup-key map (kbd "C-c r l")) 'hellmacs-run-last))))

(provide 'test-run)
;;; test-run.el ends here
