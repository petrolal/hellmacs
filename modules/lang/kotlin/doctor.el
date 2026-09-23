;;; lang/kotlin/doctor.el -*- lexical-binding: t; no-byte-compile: t; -*-

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


;; Checked by `bin/hellmacs doctor'.

(load (expand-file-name "+paths" (file-name-directory load-file-name)) nil 'nomessage)

(unless (modulep! :tools lsp)
  (hellmacs-doctor-warn ":lang kotlin needs :tools lsp for completion, keys and tuning; add it to your hellmacs! block"))
(when (modulep! :tools lsp +eglot)
  (hellmacs-doctor-warn "kotlin-language-server is used through lsp-mode, even with :tools lsp +eglot"))

;; The server is a JVM program: it runs on JAVA_HOME's java, else the PATH's.
(let* ((home (getenv "JAVA_HOME"))
       (java (if home (expand-file-name "bin/java" home) (executable-find "java"))))
  (if (not (and java (file-executable-p java)))
      (hellmacs-doctor-error "No JDK found (set JAVA_HOME or put java on the PATH); kotlin-language-server needs 11+")
    (hellmacs-doctor-ok "JDK for the server: %s" (abbreviate-file-name java))))

(hellmacs-doctor-executable "unzip" "installing kotlin-language-server")
(hellmacs-doctor-executable "kotlinc" "compiling Kotlin outside Gradle (projects build with Gradle)" nil "-version")

(cond ((hellmacs-kotlin-ls-installed-p)
       (hellmacs-doctor-ok "kotlin-language-server %s installed in %s" hellmacs-kotlin-ls-version
                           (abbreviate-file-name hellmacs-kotlin-ls-dir)))
      ((file-exists-p hellmacs-kotlin-ls-executable)
       (hellmacs-doctor-error "The installed kotlin-language-server isn't the pinned %s; `bin/hellmacs sync' replaces it"
                              hellmacs-kotlin-ls-version))
      (t
       (hellmacs-doctor-warn "kotlin-language-server isn't installed yet; `bin/hellmacs sync' installs it (or the first Kotlin file does, unpinned)")))

(when (modulep! +tree-sitter)
  (hellmacs-doctor-treesit 'kotlin))
