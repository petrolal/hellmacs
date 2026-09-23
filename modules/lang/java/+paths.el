;;; lang/java/+paths.el -*- lexical-binding: t; -*-

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


;; Where JDTLS, its workspace and the debugger's test runner live. Loaded
;; by config.el at startup and by cli.el in bin/hellmacs, before
;; lsp-java: `lsp-java-server-install-dir' is computed from
;; `lsp-server-install-dir' when lsp-java loads.

;; JDTLS and its bundles: data (reinstallable, needed to run).
(setq lsp-server-install-dir (expand-file-name "lsp/" hellmacs-data-dir))

;; JDTLS's workspace and project index: regenerable, but only by
;; reimporting every project, so data rather than disposable cache.
(setq lsp-java-workspace-dir (expand-file-name "jvm/workspace/" hellmacs-data-dir)
      lsp-java-workspace-cache-dir (expand-file-name "jvm/workspace/.cache/" hellmacs-data-dir))

;; dap-java's JUnit runner, installed next to JDTLS by `lsp-install-server'.
;; Its default is under `user-emacs-directory', Hellmacs' disposable cache.
(setq dap-java-test-runner
      (expand-file-name "eclipse.jdt.ls/test-runner/junit-platform-console-standalone.jar"
                        lsp-server-install-dir))

;; Lombok (the +lombok flag): pinned, and checked by SHA-256 when it's
;; downloaded. Maven Central only publishes a SHA-1 for it; this SHA-256
;; was computed from a download whose SHA-1 matched Central's.
(defconst hellmacs-jvm-lombok-version "1.18.48"
  "Lombok release fetched by `bin/hellmacs sync' with +lombok.")

(defconst hellmacs-jvm-lombok-sha256
  "85477a4655ebb2c074a9099cfb749be454449fee564d4282610df1b85f7c508b"
  "SHA-256 of the pinned Lombok jar.")

(defconst hellmacs-jvm-lombok-url
  (format "https://repo1.maven.org/maven2/org/projectlombok/lombok/%s/lombok-%s.jar"
          hellmacs-jvm-lombok-version hellmacs-jvm-lombok-version)
  "Where the pinned Lombok jar is downloaded from.")

(defconst hellmacs-jvm--default-lombok-jar
  (expand-file-name (format "jvm/lombok-%s.jar" hellmacs-jvm-lombok-version) hellmacs-data-dir)
  "Where `bin/hellmacs sync' puts the pinned Lombok jar.")

(defvar hellmacs-jvm-lombok-jar hellmacs-jvm--default-lombok-jar
  "Lombok jar loaded into JDTLS as a javaagent, with the +lombok flag.
By default, the pinned release `bin/hellmacs sync' downloads. Set it in
your init.el to use your own jar instead (sync then leaves it alone).")

(defun hellmacs-jvm--sha256 (file)
  "Return the SHA-256 of FILE's bytes, as a hex string."
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (insert-file-contents-literally file)
    (secure-hash 'sha256 (current-buffer))))

(defun hellmacs-jvm-lombok-jar-valid-p ()
  "Return non-nil if `hellmacs-jvm-lombok-jar' is usable.
The pinned jar must match `hellmacs-jvm-lombok-sha256'; a jar of your
own only has to exist."
  (and (file-exists-p hellmacs-jvm-lombok-jar)
       (or (not (equal hellmacs-jvm-lombok-jar hellmacs-jvm--default-lombok-jar))
           (equal (hellmacs-jvm--sha256 hellmacs-jvm-lombok-jar) hellmacs-jvm-lombok-sha256))))

;; The debugger's java-debug bundle (:tools debugger). lsp-java installs
;; 0.46.0 with JDTLS, which cannot start a debuggee on JDK 22 or newer
;; ("Unrecognized option: -Xnoagent"), so sync replaces it with a
;; pinned newer release, checked by SHA-256 (Maven Central only publishes
;; a SHA-1; this SHA-256 is from a download whose SHA-1 matched).
(defconst hellmacs-jvm-java-debug-version "0.53.1"
  "java-debug release `bin/hellmacs sync' installs with :tools debugger.")

(defconst hellmacs-jvm-java-debug-sha256
  "4f4778d452a6a0665536f43ce4e32403a24be6593336b80dc85a322912859e24"
  "SHA-256 of the pinned java-debug plugin jar.")

(defconst hellmacs-jvm-java-debug-url
  (format "https://repo1.maven.org/maven2/com/microsoft/java/com.microsoft.java.debug.plugin/%s/com.microsoft.java.debug.plugin-%s.jar"
          hellmacs-jvm-java-debug-version hellmacs-jvm-java-debug-version)
  "Where the pinned java-debug plugin jar is downloaded from.")

(defvar hellmacs-jvm-java-debug-jar
  (expand-file-name "eclipse.jdt.ls/bundles/java.debug.plugin.jar" lsp-server-install-dir)
  "Where JDTLS loads the java-debug plugin from (lsp-java's bundle name).")

(defun hellmacs-jvm-java-debug-jar-valid-p ()
  "Return non-nil if the java-debug jar JDTLS loads is the pinned release."
  (and (file-exists-p hellmacs-jvm-java-debug-jar)
       (equal (hellmacs-jvm--sha256 hellmacs-jvm-java-debug-jar) hellmacs-jvm-java-debug-sha256)))
