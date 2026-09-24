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
;;   +lombok       Load Lombok into JDTLS (a pinned jar that `bin/hellmacs
;;                 sync' downloads and checks), so the getters, builders,
;;                 ... Lombok generates resolve instead of showing as errors.
;;   +tree-sitter  Use `java-ts-mode' (`bin/hellmacs sync' builds the pinned grammar)
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
  ;; The grammar is built by `bin/hellmacs sync'; without it, java-ts-mode
  ;; would fail on every file, so stay on java-mode and say why.
  (if (hellmacs-treesit-current-p 'java)
      (add-to-list 'major-mode-remap-alist '(java-mode . java-ts-mode))
    (display-warning 'hellmacs "+tree-sitter: the Java grammar isn't built yet; run `bin/hellmacs sync'")))

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
    (banished  hellmacs-jvm-failed "[DAEMON BANISHED] JDTLS for %s exited" "JDTLS for %s exited")
    (import-failed hellmacs-jvm-failed "[BYTECODE PURGATORY] %s failed to import: %s"
                   "%s failed to import: %s"))
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

(defvar-local hellmacs-jvm--key-cache nil
  "(ID . KEY): this buffer's `hellmacs-jvm--states' key, and what it came from.
ID is the JDTLS workspace root once there is one, else `default-directory'.")

(defun hellmacs-jvm--buffer-key ()
  "The current buffer's `hellmacs-jvm--states' key, cached.
The mode-line asks on nearly every redisplay, and finding the project
and its true name reads the disk; that's only redone when the buffer
gets its JDTLS workspace, or moves to another directory."
  (let* ((workspace (car (bound-and-true-p lsp--buffer-workspaces)))
         (ws-root (and workspace (lsp--workspace-root workspace)))
         (id (or ws-root default-directory)))
    (unless (equal id (car hellmacs-jvm--key-cache))
      (setq hellmacs-jvm--key-cache
            (cons id (hellmacs-jvm--key (or ws-root (hellmacs-jvm--root))))))
    (cdr hellmacs-jvm--key-cache)))

(defun hellmacs-jvm--mode-line ()
  "Mode-line text for the current Java buffer's project."
  (when-let* ((state (car (gethash (hellmacs-jvm--buffer-key) hellmacs-jvm--states))))
    ;; Spaced on both sides: lsp-mode's own entries (the code-action
    ;; count and lightbulb, lsp-java's progress) follow with no space.
    (concat " "
            (pcase state
              ('igniting  (propertize "JVM:igniting" 'face 'hellmacs-jvm-busy))
              ('ready     (propertize "JVM:ready" 'face 'hellmacs-jvm-ready))
              ('purgatory (propertize "JVM:purgatory" 'face 'hellmacs-jvm-failed)))
            " ")))

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
      (remhash (hellmacs-jvm--key root) hellmacs-jvm--import-failures)
      (hellmacs-jvm-set-state root 'igniting)
      (hellmacs-jvm-announce 'ignited (abbreviate-file-name root)))))

(defvar hellmacs-jvm--import-failures (make-hash-table :test #'equal)
  "Project root -> why JDTLS couldn't import it, until an import succeeds.")

(defun hellmacs-jvm--import-failure-reason (message)
  "A short reason for the import failure described by log MESSAGE."
  (cond ((string-match "Cannot find a Java installation[^\n]*languageVersion=\\([0-9]+\\)" message)
         (format "the build needs a JDK %s that Gradle can't find (install it, then C-c l j u)"
                 (match-string 1 message)))
        ((string-match-p "Gradle" message) "the Gradle sync failed (see the *lsp-log* buffer)")
        ((string-match-p "Maven" message) "the Maven import failed (see the *lsp-log* buffer)")
        (t "see the *lsp-log* buffer")))

(defun hellmacs-jvm--note-log (root message)
  "React to JDTLS log MESSAGE for project ROOT: a failed import is announced.
JDTLS goes on to say ServiceReady even then, but nothing works."
  (when (and (string-match-p "\\`[^\n]*Synchronize project .* failed" message)
             (not (gethash (hellmacs-jvm--key root) hellmacs-jvm--import-failures)))
    (let ((reason (hellmacs-jvm--import-failure-reason message)))
      (puthash (hellmacs-jvm--key root) reason hellmacs-jvm--import-failures)
      (hellmacs-jvm-set-state root 'purgatory)
      (hellmacs-jvm-announce 'import-failed (abbreviate-file-name root) reason))))

(defun hellmacs-jvm--note-status (root type message)
  "React to a JDTLS status of TYPE and MESSAGE for project ROOT.
ServiceReady means ready, unless the import failed; a later
ProjectStatus OK (after fixing the cause) means it recovered."
  (let ((failed (gethash (hellmacs-jvm--key root) hellmacs-jvm--import-failures)))
    (when (or (and (equal type "ServiceReady") (not failed))
              (and (equal type "ProjectStatus") (equal message "OK") failed))
      (remhash (hellmacs-jvm--key root) hellmacs-jvm--import-failures)
      (let ((since (cdr (gethash (hellmacs-jvm--key root) hellmacs-jvm--states))))
        (hellmacs-jvm-set-state root 'ready)
        (hellmacs-jvm-announce 'ready (abbreviate-file-name root)
                               (if since (- (float-time) since) 0.0))))))

(defun hellmacs-jvm--status-a (workspace params)
  "After lsp-java handles a JDTLS status (PARAMS), note when it's ready."
  (hellmacs-jvm--note-status (lsp--workspace-root workspace)
                             (lsp:java-status-type params) (lsp:java-status-message params)))

(defun hellmacs-jvm--log-a (workspace params)
  "Before lsp-mode shows a JDTLS log message (PARAMS), look for import failures."
  (when (hellmacs-jvm--jdtls-workspace-p workspace)
    (hellmacs-jvm--note-log (lsp--workspace-root workspace) (lsp-get params :message))))

(defun hellmacs-jvm--banished-h (workspace)
  "Note that a JDTLS server exited. For `lsp-after-uninitialized-functions'."
  (when (hellmacs-jvm--jdtls-workspace-p workspace)
    (let ((root (lsp--workspace-root workspace)))
      (hellmacs-jvm-set-state root nil)
      (hellmacs-jvm-announce 'banished (abbreviate-file-name root)))))

;;; lsp-java -------------------------------------------------------------------

(defconst hellmacs-jvm--base-vmargs
  '("-XX:+UseParallelGC" "-XX:GCTimeRatio=4" "-XX:AdaptiveSizePolicyWeight=90"
    "-Dsun.zip.disableMemoryMapping=true" "-Xmx2G" "-Xms256m")
  "JVM arguments for JDTLS: lsp-java's defaults, with twice the heap (1GB
is tight for real multi-module projects).")

(defun hellmacs-jvm--vmargs ()
  "Return the JVM arguments JDTLS starts with.
With +lombok, Lombok is loaded as a javaagent, so JDTLS sees the code
Lombok generates (getters, builders, ...). Only its existence is
checked here; `bin/hellmacs sync' and doctor verify its checksum."
  (append hellmacs-jvm--base-vmargs
          (when (modulep! +lombok)
            (if (file-exists-p hellmacs-jvm-lombok-jar)
                (list (concat "-javaagent:" hellmacs-jvm-lombok-jar))
              (display-warning
               'hellmacs "+lombok: the Lombok jar isn't installed; run `bin/hellmacs sync'")
              nil))))

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
  (lsp-java-vmargs (hellmacs-jvm--vmargs))
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
  (advice-add 'lsp-java--language-status-callback :after #'hellmacs-jvm--status-a)
  ;; ...and a failed import only shows up in its log messages.
  (advice-add 'lsp--window-log-message :before #'hellmacs-jvm--log-a))

;; `C-x p c' proposes the project's own Gradle/Maven build (:tools build).
(when (modulep! :tools build)
  (add-hook 'java-mode-hook #'hellmacs-forge-setup-build-h)
  (add-hook 'java-ts-mode-hook #'hellmacs-forge-setup-build-h))

;; Debugging (:tools debugger): dap-java, shipped with lsp-java, loads with it.
(when (modulep! :tools debugger)
  (with-eval-after-load 'dap-java
    (setq dap-java-java-command (if hellmacs-jvm-java-home
                                    (expand-file-name "bin/java" hellmacs-jvm-java-home)
                                  "java")
          ;; JDTLS already builds on save; don't ask before every launch.
          dap-java-build 'always)
    ;; For a JVM started with -agentlib:jdwp=transport=dt_socket,server=y,address=5005
    (dap-register-debug-template "Java Attach (localhost:5005)"
                                 (list :type "java" :request "attach"
                                       :hostName "localhost" :port 5005))))

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
