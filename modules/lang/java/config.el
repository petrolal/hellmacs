;;; lang/java/config.el -*- lexical-binding: t; -*-

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


;; Java, through Eclipse JDTLS (lsp-java): project import and indexing
;; (Maven, Gradle), completion with auto-import, navigation into JDK and
;; library classes (decompiled), refactoring and code generation.
;;
;; Owns `C-c l j' (Java-only commands; the rest of `C-c l' is lsp-mode's).
;; JDTLS reports its progress in the echo area -- [FORGE IGNITED] when
;; the server starts, [DAEMON READY] once the project is imported -- and
;; in the mode-line (JVM:igniting / JVM:ready).
;;
;; JDTLS is installed by `bin/hellmacs sync' (or on first use). It needs
;; a JDK 21+ to run; projects can target older ones.
;;
;; Flags:
;;   +tree-sitter  Use `java-ts-mode' (needs the Java tree-sitter grammar)
;;                 instead of the built-in `java-mode'.

(load (expand-file-name "+paths" (file-name-directory (or load-file-name buffer-file-name)))
      nil 'nomessage)

(defgroup hellmacs-jvm nil
  "Hellmacs' Java/JVM support."
  :group 'hellmacs)

(defcustom hellmacs-jvm-java-home (getenv "JAVA_HOME")
  "JDK that runs JDTLS itself; it must be 21 or newer.
Defaults to $JAVA_HOME. Projects may compile against other JDKs: see
`lsp-java-configuration-runtimes'."
  :type '(choice (const :tag "java on the PATH" nil) directory))

(unless (modulep! :tools lsp)
  (display-warning 'hellmacs ":lang java needs :tools lsp for its keys, completion and tuning; add it to your hellmacs! block"))

(when (modulep! +tree-sitter)
  (add-to-list 'major-mode-remap-alist '(java-mode . java-ts-mode)))

;;; Status: echo-area announcements and the mode-line segment ------------------

(defface hellmacs-jvm-busy '((t (:inherit warning)))
  "Mode-line face while JDTLS starts or imports a project.")

(defface hellmacs-jvm-ready '((t (:inherit success)))
  "Mode-line face once JDTLS is ready.")

(defface hellmacs-jvm-failed '((t (:inherit error)))
  "Mode-line face after the server died or the last build failed.")

(defcustom hellmacs-jvm-messages
  '((ignited   hellmacs-jvm-busy   "[FORGE IGNITED] JDTLS bound to %s"   "JDTLS started for %s")
    (ready     hellmacs-jvm-ready  "[DAEMON READY] %s indexed in %.1fs"  "%s indexed in %.1fs")
    (banished  hellmacs-jvm-failed "[DAEMON BANISHED] JDTLS for %s exited" "JDTLS for %s exited"))
  "Status messages: (EVENT FACE THEMED PLAIN).
The PLAIN wording is used when `hellmacs-ux-enable' is nil."
  :type '(repeat (list symbol face string string)))

(defvar hellmacs-jvm--states (make-hash-table :test #'equal)
  "Project root -> (STATE . SINCE), STATE one of igniting, ready, purgatory.")

(defun hellmacs-jvm-announce (event &rest args)
  "Show the message for EVENT (see `hellmacs-jvm-messages'), formatted with ARGS.
Returns the text shown."
  (pcase-let ((`(,face ,themed ,plain) (alist-get event hellmacs-jvm-messages)))
    (let ((text (apply #'format (if (bound-and-true-p hellmacs-ux-enable) themed plain) args)))
      (message "%s" (propertize text 'face face))
      text)))

(defun hellmacs-jvm--key (root)
  "Normalize project ROOT for `hellmacs-jvm--states'.
lsp-mode gives roots without a trailing slash, project.el with one."
  (directory-file-name (file-truename root)))

(defun hellmacs-jvm-set-state (root state)
  "Record STATE (igniting, ready, purgatory or nil) for project ROOT."
  (if state
      (puthash (hellmacs-jvm--key root) (cons state (float-time)) hellmacs-jvm--states)
    (remhash (hellmacs-jvm--key root) hellmacs-jvm--states))
  (force-mode-line-update t))

(defun hellmacs-jvm-state (root)
  "Return the recorded state of project ROOT, or nil."
  (car (gethash (hellmacs-jvm--key root) hellmacs-jvm--states)))

(defun hellmacs-jvm--root ()
  "The current buffer's project root, as JDTLS sees it."
  (or (and (fboundp 'lsp-workspace-root) (lsp-workspace-root))
      (when-let* ((project (project-current))) (project-root project))
      default-directory))

(defun hellmacs-jvm--mode-line ()
  "Mode-line text for the current Java buffer's project."
  (when-let* ((state (hellmacs-jvm-state (hellmacs-jvm--root))))
    (pcase state
      ('igniting  (propertize " JVM:igniting" 'face 'hellmacs-jvm-busy))
      ('ready     (propertize " JVM:ready" 'face 'hellmacs-jvm-ready))
      ('purgatory (propertize " JVM:purgatory" 'face 'hellmacs-jvm-failed)))))

(define-minor-mode hellmacs-jvm-mode-line-mode
  "Show the JDTLS state of this buffer's project in the mode-line."
  :lighter nil)

;; A standard (VARIABLE CONSTRUCT) mode-line entry: shown only in
;; buffers where `hellmacs-jvm-mode-line-mode' is on.
(add-to-list 'mode-line-misc-info
             '(hellmacs-jvm-mode-line-mode (:eval (hellmacs-jvm--mode-line))))

(defun hellmacs-jvm--jdtls-workspace-p (workspace)
  "Return non-nil if WORKSPACE is a JDTLS one."
  (eq (lsp--client-server-id (lsp--workspace-client workspace)) 'jdtls))

(defun hellmacs-jvm--ignited-h ()
  "Announce a JDTLS server that just started. For `lsp-after-initialize-hook'."
  (when (and lsp--cur-workspace (hellmacs-jvm--jdtls-workspace-p lsp--cur-workspace))
    (let ((root (lsp--workspace-root lsp--cur-workspace)))
      (hellmacs-jvm-set-state root 'igniting)
      (hellmacs-jvm-announce 'ignited (abbreviate-file-name root)))))

(defun hellmacs-jvm--status-a (workspace params)
  "After lsp-java handles a JDTLS status (PARAMS), note when it's ready."
  (when (equal (lsp:java-status-type params) "ServiceReady")
    (let* ((root (lsp--workspace-root workspace))
           (since (cdr (gethash (hellmacs-jvm--key root) hellmacs-jvm--states))))
      (hellmacs-jvm-set-state root 'ready)
      (hellmacs-jvm-announce 'ready (abbreviate-file-name root)
                             (if since (- (float-time) since) 0.0)))))

(defun hellmacs-jvm--banished-h (workspace)
  "Note that a JDTLS server exited. For `lsp-after-uninitialized-functions'."
  (when (hellmacs-jvm--jdtls-workspace-p workspace)
    (let ((root (lsp--workspace-root workspace)))
      (hellmacs-jvm-set-state root nil)
      (hellmacs-jvm-announce 'banished (abbreviate-file-name root)))))

;;; lsp-java -------------------------------------------------------------------

(use-package lsp-java
  ;; Loaded in the background after startup, so opening the first Java
  ;; file doesn't wait for it. (Otherwise lsp-mode loads it itself when
  ;; the first Java buffer asks for a server: `lsp-client-packages'.)
  :defer-incrementally (lsp-java)
  :hook
  ((java-mode java-ts-mode) . lsp-deferred)
  ((java-mode java-ts-mode) . hellmacs-jvm-mode-line-mode)
  :custom
  (lsp-java-java-path (if hellmacs-jvm-java-home
                          (expand-file-name "bin/java" hellmacs-jvm-java-home)
                        "java"))
  ;; lsp-java's defaults, with twice the heap: 1GB is tight for real
  ;; multi-module projects.
  (lsp-java-vmargs '("-XX:+UseParallelGC" "-XX:GCTimeRatio=4"
                     "-XX:AdaptiveSizePolicyWeight=90"
                     "-Dsun.zip.disableMemoryMapping=true"
                     "-Xmx2G" "-Xms256m"))
  (lsp-java-content-provider-preferred "fernflower") ; decompile library classes for M-.
  (lsp-java-save-actions-organize-imports t)
  (lsp-java-maven-download-sources t)
  (lsp-java-references-code-lens-enabled t)
  (lsp-java-implementations-code-lens-enabled t)
  (lsp-java-completion-favorite-static-members
   ["org.junit.jupiter.api.Assertions.*" "org.assertj.core.api.Assertions.*"
    "org.mockito.Mockito.*" "org.mockito.ArgumentMatchers.*"])
  :config
  (add-hook 'lsp-after-initialize-hook #'hellmacs-jvm--ignited-h)
  (add-hook 'lsp-after-uninitialized-functions #'hellmacs-jvm--banished-h)
  ;; lsp-java only logs JDTLS's status notifications; watch for the
  ;; one that says the project is imported.
  (advice-add 'lsp-java--language-status-callback :after #'hellmacs-jvm--status-a))

;;; C-c l j -- Java commands ---------------------------------------------------

(defvar-keymap hellmacs-jvm-map
  :doc "Java commands, on `C-c l j' in Java buffers."
  "b" (cons "build project" #'lsp-java-build-project)
  "u" (cons "update project config" #'hellmacs-jvm-update-project-configuration)
  "o" (cons "organize imports" #'lsp-java-organize-imports)
  "i" (cons "add unimplemented methods" #'lsp-java-add-unimplemented-methods)
  "g" (cons "generate getters/setters" #'lsp-java-generate-getters-and-setters)
  "s" (cons "generate toString" #'lsp-java-generate-to-string)
  "e" (cons "generate equals/hashCode" #'lsp-java-generate-equals-and-hash-code)
  "m" (cons "extract method" #'lsp-java-extract-method)
  "v" (cons "extract local variable" #'lsp-java-extract-to-local-variable)
  "c" (cons "extract constant" #'lsp-java-extract-to-constant)
  "h" (cons "type hierarchy" #'lsp-java-type-hierarchy)
  "t" (cons "run test at point" #'hellmacs-jvm-test-at-point)
  "T" (cons "run test class" #'hellmacs-jvm-test-class))

;; In the Java modes' own maps. lsp-mode's `C-c l' map (a minor-mode
;; map, looked up first) has no `j', so the full key falls through to
;; these.
(with-eval-after-load 'cc-mode
  (keymap-set java-mode-map "C-c l j" (cons "java" hellmacs-jvm-map)))
(with-eval-after-load 'java-ts-mode
  (keymap-set java-ts-mode-map "C-c l j" (cons "java" hellmacs-jvm-map)))
