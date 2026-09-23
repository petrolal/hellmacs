;;; lang/kotlin/config.el -*- lexical-binding: t; -*-

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


;; Kotlin, through kotlin-language-server (fwcd's, over lsp-mode). Flags:
;;   +tree-sitter  Use `kotlin-ts-mode' (`bin/hellmacs sync' builds the
;;                 pinned Kotlin grammar)
;;
;; The server is unpacked by `bin/hellmacs sync' (a pinned release, checked
;; by SHA-256) into the data directory. It runs on JAVA_HOME's JDK, like
;; the Gradle build. Completion, navigation, diagnostics, rename and code
;; actions come from `:tools lsp' (`C-c l', `M-.', `C-c ! n'); this module
;; adds `C-c l k' in Kotlin buffers:
;;   b build the project (Gradle, wrapper first)
;;   t run the test at point (with backticked names)    T the test class
;; Both need `:tools build', which also makes compile errors clickable
;; (`e: file:///...Foo.kt:12:5' lines) and shows `[BYTECODE PURGATORY]' when
;; a build fails.

(load (expand-file-name "+paths" (file-name-directory load-file-name)) nil 'nomessage)

(unless (modulep! :tools lsp)
  (display-warning 'hellmacs ":lang kotlin needs :tools lsp for its keys, completion and tuning; add it to your hellmacs! block"))

(when (modulep! +tree-sitter)
  ;; Without the grammar kotlin-ts-mode fails on every file: stay on
  ;; kotlin-mode and say why.
  (if (file-exists-p (hellmacs-treesit-library 'kotlin))
      (add-to-list 'major-mode-remap-alist '(kotlin-mode . kotlin-ts-mode))
    (display-warning 'hellmacs "+tree-sitter: the Kotlin grammar isn't built yet; run `bin/hellmacs sync'")))

;;; Server settings --------------------------------------------------------------

(defvar hellmacs-kotlin-jvm-target "21"
  "The JVM target the server assumes for Kotlin code. Match your projects.")

;; Set before lsp-kotlin loads (a defcustom keeps a value that's already set).
(setq lsp-kotlin-compiler-jvm-target hellmacs-kotlin-jvm-target
      lsp-kotlin-debug-adapter-enabled nil) ; the debugger is Java's (:tools debugger)

;; lsp-mode finds this before anything on the PATH; it's the pinned release.
(setq lsp-clients-kotlin-server-executable hellmacs-kotlin-ls-executable)

;; The server is a JVM program whose heap is otherwise uncapped (a quarter
;; of RAM): 2.6GB on a real Spring project. The launcher script reads its
;; options from KOTLIN_LANGUAGE_SERVER_OPTS; one you set yourself wins.
(defvar hellmacs-kotlin-vmargs '("-Xmx2G" "-Xms128m")
  "JVM options for kotlin-language-server (unless KOTLIN_LANGUAGE_SERVER_OPTS is set).")

(unless (getenv "KOTLIN_LANGUAGE_SERVER_OPTS")
  (setenv "KOTLIN_LANGUAGE_SERVER_OPTS" (string-join hellmacs-kotlin-vmargs " ")))

(dolist (hook '(kotlin-mode-hook kotlin-ts-mode-hook))
  (add-hook hook #'lsp-deferred))

;; `C-x p c' proposes the project's own Gradle build (:tools build).
(when (modulep! :tools build)
  (dolist (hook '(kotlin-mode-hook kotlin-ts-mode-hook))
    (add-hook hook #'hellmacs-forge-setup-build-h)))

;;; Status: echo-area announcements --------------------------------------------------
;;
;; kotlin-language-server has no "ready" notification, so its log is the
;; signal: a Gradle task failing means the project didn't import, and the
;; full symbol index being built means search and navigation work. Same
;; wording as :lang java's messages, plain when `hellmacs-ux-enable' is nil.

(defcustom hellmacs-kotlin-messages
  '((ignited hellmacs-jvm-busy   "[FORGE IGNITED] Kotlin server bound to %s" "Kotlin server started for %s")
    (ready   hellmacs-jvm-ready  "[DAEMON READY] %s indexed in %.1fs"        "%s indexed in %.1fs")
    (failed  hellmacs-jvm-failed "[BYTECODE PURGATORY] %s failed to import: %s" "%s failed to import: %s"))
  "Status messages: (EVENT FACE THEMED PLAIN)."
  :type '(repeat (list symbol face string string))
  :group 'hellmacs)

(defvar hellmacs-kotlin--sessions (make-hash-table :test #'equal)
  "Project root -> (STATE . SINCE), STATE one of igniting, ready or failed.")

(defun hellmacs-kotlin-announce (event &rest args)
  "Show the message for EVENT (see `hellmacs-kotlin-messages') formatted with ARGS."
  (pcase-let ((`(,face ,themed ,plain) (alist-get event hellmacs-kotlin-messages)))
    (let ((text (apply #'format (if (bound-and-true-p hellmacs-ux-enable) themed plain) args)))
      (message "%s" (propertize text 'face face))
      text)))

(defun hellmacs-kotlin--key (root)
  (directory-file-name (file-truename root)))

(defun hellmacs-kotlin-state (root)
  "The recorded state of project ROOT (igniting, ready or failed), or nil."
  (car (gethash (hellmacs-kotlin--key root) hellmacs-kotlin--sessions)))

(defun hellmacs-kotlin--set-state (root state)
  (puthash (hellmacs-kotlin--key root)
           (cons state (or (cdr (gethash (hellmacs-kotlin--key root) hellmacs-kotlin--sessions))
                           (float-time)))
           hellmacs-kotlin--sessions))

(defun hellmacs-kotlin--ignite (root)
  "Note that a server just started for ROOT."
  (puthash (hellmacs-kotlin--key root) (cons 'igniting (float-time)) hellmacs-kotlin--sessions)
  (hellmacs-kotlin-announce 'ignited (abbreviate-file-name root)))

(defun hellmacs-kotlin--note-log (root message)
  "React to the server's log MESSAGE for project ROOT."
  (let ((state (hellmacs-kotlin-state root)))
    (cond
     ((and (not (eq state 'failed))
           (string-match "Gradle task failed: \\(.*\\)" message))
      (let ((reason (string-trim (replace-regexp-in-string
                                  "file://" "" (match-string 1 message)))))
        (hellmacs-kotlin--set-state root 'failed)
        (hellmacs-kotlin-announce 'failed (abbreviate-file-name root)
                                  (truncate-string-to-width reason 110 nil nil t))))
     ((and (eq state 'igniting)
           (string-match-p "Updated full symbol index in" message))
      (let ((since (cdr (gethash (hellmacs-kotlin--key root) hellmacs-kotlin--sessions))))
        (hellmacs-kotlin--set-state root 'ready)
        (hellmacs-kotlin-announce 'ready (abbreviate-file-name root)
                                  (- (float-time) (or since (float-time)))))))))

(defun hellmacs-kotlin--kotlin-workspace-p (workspace)
  (eq (lsp--client-server-id (lsp--workspace-client workspace)) 'kotlin-ls))

(defun hellmacs-kotlin--ignited-h ()
  "For `lsp-after-initialize-hook'."
  (when (and lsp--cur-workspace (hellmacs-kotlin--kotlin-workspace-p lsp--cur-workspace))
    (hellmacs-kotlin--ignite (lsp--workspace-root lsp--cur-workspace))))

(defun hellmacs-kotlin--log-a (workspace params)
  "Before lsp-mode shows a log message (PARAMS) from a Kotlin WORKSPACE."
  (when (hellmacs-kotlin--kotlin-workspace-p workspace)
    (hellmacs-kotlin--note-log (lsp--workspace-root workspace) (lsp-get params :message))))

(defun hellmacs-kotlin--forget-h (workspace)
  "For `lsp-after-uninitialized-functions': the server for WORKSPACE exited."
  (when (hellmacs-kotlin--kotlin-workspace-p workspace)
    (remhash (hellmacs-kotlin--key (lsp--workspace-root workspace)) hellmacs-kotlin--sessions)))

(with-eval-after-load 'lsp-mode
  (add-hook 'lsp-after-initialize-hook #'hellmacs-kotlin--ignited-h)
  (add-hook 'lsp-after-uninitialized-functions #'hellmacs-kotlin--forget-h)
  (advice-add 'lsp--window-log-message :before #'hellmacs-kotlin--log-a))

;;; Keys: C-c l k --------------------------------------------------------------------

(when (modulep! :tools build)
  (defvar-keymap hellmacs-kotlin-map
    :doc "Kotlin commands, on `C-c l k' in Kotlin buffers."
    "b" (cons "build project" #'hellmacs-forge-build)
    "t" (cons "run test at point" #'hellmacs-forge-test-at-point)
    "T" (cons "run test class" #'hellmacs-forge-test-class))

  ;; In the Kotlin modes' own maps: lsp-mode's `C-c l' map (a minor-mode
  ;; map, looked up first) has no `k', so the full key falls through.
  (with-eval-after-load 'kotlin-mode
    (keymap-set kotlin-mode-map "C-c l k" (cons "kotlin" hellmacs-kotlin-map)))
  (with-eval-after-load 'kotlin-ts-mode
    (keymap-set kotlin-ts-mode-map "C-c l k" (cons "kotlin" hellmacs-kotlin-map))))
