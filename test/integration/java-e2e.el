;;; java-e2e.el --- End-to-end check of the Java modules -*- lexical-binding: t; -*-

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

;; Drives the real modules against a real JDTLS, java-debug and Git: the
;; Phase 6.2-6.6 checks. Unlike `bin/hellmacs test' it needs a synced
;; profile with every Java module on, a JDK 21+, and network access on
;; the first run (Maven or Gradle fetch the fixture's dependencies).
;;
;;   bin/hellmacs install     # with :tools build debugger lsp magit and
;;                            # (:lang java +lombok) in your init.el
;;   HELLMACS_E2E_FIXTURE=maven-demo \
;;     emacs --batch -l early-init.el -l init.el \
;;           -l test/integration/java-e2e.el
;;
;; HELLMACS_E2E_FIXTURE is maven-demo (default) or gradle-demo. The
;; fixture is copied to a temporary directory first, so it stays clean.
;; Run it inside a throwaway XDG_*_HOME/HELLMACSDIR to leave your own
;; setup alone. Exits 1 if any check fails.

;;; Code:

(require 'cl-lib)

(defvar e2e--failures 0)
(defvar e2e--root (file-name-directory (or load-file-name buffer-file-name)))
(defvar e2e--fixture (or (getenv "HELLMACS_E2E_FIXTURE") "maven-demo"))

(defun e2e--say (fmt &rest args)
  (princ (concat (apply #'format fmt args) "\n")))

(defun e2e--wait (pred secs)
  "Process output and timers until PRED returns non-nil; nil after SECS seconds."
  (let ((end (+ (float-time) secs)) result)
    (while (and (not (setq result (ignore-errors (funcall pred))))
                (< (float-time) end))
      (accept-process-output nil 0.2))
    result))

(defmacro e2e-check (desc &rest body)
  "Run BODY; report DESC as passed if it returns non-nil, failed otherwise."
  (declare (indent 1))
  `(let ((ok (condition-case err (progn ,@body)
               (error (e2e--say "     %S" err) nil))))
     (unless ok (cl-incf e2e--failures))
     (e2e--say "  %s  %s" (if ok "PASS" "FAIL") ,desc)
     ok))

(defun e2e--copy-fixture ()
  "Copy the chosen fixture to a temporary directory; return its path."
  (let* ((src (expand-file-name (concat "../fixtures/java/" e2e--fixture) e2e--root))
         (dst (expand-file-name e2e--fixture (make-temp-file "hellmacs-e2e" t))))
    (copy-directory src dst nil t t)
    (dolist (d '("build" "target" ".gradle" ".settings"))
      (let ((dir (expand-file-name d dst)))
        (when (file-directory-p dir) (delete-directory dir t))))
    dst))

(defun e2e--position-after (regexp)
  "Move point just after the first REGEXP in the buffer."
  (goto-char (point-min))
  (re-search-forward regexp)
  (point))

(defun e2e--lsp-uri-at-point (method)
  "Return the URIs of METHOD (a location request) at point."
  (let ((res (lsp-request method (lsp--text-document-position-params))))
    (mapcar (lambda (loc) (lsp-get loc :uri))
            (if (and res (not (vectorp res)) (not (listp res))) (list res) (append res nil)))))

(defun e2e--compile-and-wait (dir)
  "Run the project's build from DIR and return its finish message."
  (let ((default-directory dir) finished)
    (let ((hook (lambda (_buf msg) (setq finished msg))))
      (add-hook 'compilation-finish-functions hook)
      (unwind-protect
          (progn (compile compile-command)
                 (e2e--wait (lambda () finished) 300)
                 finished)
        (remove-hook 'compilation-finish-functions hook)))))

(defun e2e--java-checks (proj)
  (let* ((src (expand-file-name "src/main/java/dev/hellmacs/demo/" proj))
         (app (expand-file-name "App.java" src))
         (greeter (expand-file-name "Greeter.java" src))
         (test (expand-file-name "src/test/java/dev/hellmacs/demo/GreeterTest.java" proj))
         (app-buf (find-file-noselect app)))
    (switch-to-buffer app-buf)

    (e2e--say "\n== 6.2 :lang java (%s)" e2e--fixture)
    (e2e-check "java-mode starts JDTLS (lsp) and reports it ready"
      ;; lsp-mode asks whether to import a new project's root; this is
      ;; the answer "yes" (it's remembered in the session file).
      (lsp-workspace-folders-add proj)
      (lsp)
      (e2e--wait (lambda () (eq (hellmacs-jvm-state proj) 'ready)) 400))
    ;; `format-mode-line' renders nothing in batch mode, so evaluate the
    ;; registered segment itself, in the Java buffer.
    (e2e-check "mode-line segment is registered and reads JVM:ready"
      (let ((entry (assq 'hellmacs-jvm-mode-line-mode mode-line-misc-info)))
        (with-current-buffer app-buf
          (and entry hellmacs-jvm-mode-line-mode
               (string-match-p "JVM:ready" (eval (cadr (cadr entry)) t))))))
    (e2e-check "go to definition: greeter.greet -> Greeter.java"
      (e2e--position-after "greeter\\.gr")
      (cl-some (lambda (u) (string-suffix-p "Greeter.java" u))
               (e2e--lsp-uri-at-point "textDocument/definition")))
    (e2e-check "completion after `greeter.' offers greet"
      (e2e--position-after "greeter\\.")
      (let* ((res (lsp-request "textDocument/completion" (lsp--text-document-position-params)))
             (items (append (if (lsp-get res :items) (lsp-get res :items) res) nil)))
        (cl-some (lambda (i) (string-prefix-p "greet" (lsp-get i :label))) items)))

    (e2e--say "\n== 6.3 +lombok")
    (e2e-check "JDTLS runs with the Lombok javaagent"
      (cl-some (lambda (a) (string-match-p "lombok" a)) lsp-java-vmargs))
    (e2e-check "Lombok's generated person.getName() has no error in App.java"
      (e2e--wait (lambda () (flymake-running-backends)) 30)
      (accept-process-output nil 5)
      (null (cl-remove-if-not (lambda (d) (eq (flymake-diagnostic-type d) :error))
                              (flymake-diagnostics))))
    (e2e-check "definition of getName resolves (generated member)"
      (e2e--position-after "person\\.get")
      (e2e--lsp-uri-at-point "textDocument/definition"))

    (e2e--say "\n== 6.2 diagnostics")
    (with-current-buffer (find-file-noselect greeter)
      (switch-to-buffer (current-buffer))
      (lsp)                             ; `lsp-deferred' waits for a redisplay
      (goto-char (point-max)) (re-search-backward "}")
      (insert "int broken = \"s\";\n")
      (e2e-check "a type error shows up as a flymake error"
        (e2e--wait (lambda ()
                     (cl-some (lambda (d) (eq (flymake-diagnostic-type d) :error))
                              (flymake-diagnostics)))
                   60))
      (set-buffer-modified-p nil)
      (revert-buffer t t t))

    (e2e--say "\n== 6.4 :tools build")
    (with-current-buffer app-buf
      (e2e-check "compile-command is the project's wrapper"
        (string-match-p "\\./\\(mvnw\\|gradlew\\)" compile-command))
      (e2e-check "a good build says FORGE TEMPERED and JVM:ready"
        (let ((msg (e2e--compile-and-wait proj)))
          (and msg (string-match-p "finished" msg)
               (eq (hellmacs-jvm-state proj) 'ready)))))
    (with-current-buffer (find-file-noselect greeter)
      (goto-char (point-max)) (re-search-backward "}")
      (insert "int broken = \"s\";\n")
      (save-buffer)
      (e2e-check "a broken build sets JVM:purgatory"
        (e2e--compile-and-wait proj)
        (eq (hellmacs-jvm-state proj) 'purgatory))
      (e2e-check "M-g n lands on the error in Greeter.java"
        (next-error)
        (string-suffix-p "Greeter.java"
                         (or (buffer-file-name (window-buffer (selected-window))) "")))
      (goto-char (point-min))
      (re-search-forward "int broken = \"s\";\n")
      (replace-match "")
      (save-buffer))
    (with-current-buffer app-buf
      (e2e-check "the fixed build brings JVM:ready back"
        (e2e--compile-and-wait proj)
        (eq (hellmacs-jvm-state proj) 'ready)))
    (with-current-buffer (find-file-noselect test)
      (e2e-check "the test at point runs and passes"
        (e2e--position-after "@Test")
        (forward-line 1)
        (hellmacs-forge-test-at-point)
        (e2e--wait (lambda () (not (get-buffer-process (compilation-find-buffer)))) 300)
        (with-current-buffer (compilation-find-buffer)
          (save-excursion (goto-char (point-min))
                          (re-search-forward "BUILD SUCCESS" nil t)))))

    (e2e--say "\n== 6.5 :tools debugger")
    (switch-to-buffer app-buf)
    (goto-char (point-min)) (search-forward "String greeting") (beginning-of-line)
    (let ((line (line-number-at-pos)))
      (dap-breakpoint-add)
      (e2e-check "a launch stops at the breakpoint"
        (call-interactively #'dap-java-debug)
        (e2e--wait (lambda () (let ((s (dap--cur-session)))
                                (and s (dap--debug-session-active-frame s))))
                   120)
        (= line (gethash "line" (dap--debug-session-active-frame (dap--cur-session)))))
      (cl-flet ((evaluate (expr)
                  (let* ((s (dap--cur-session)) result)
                    (dap--send-message
                     (dap--make-request "evaluate"
                                        (list :expression expr :context "repl"
                                              :frameId (gethash "id" (dap--debug-session-active-frame s))))
                     (lambda (resp) (setq result (gethash "result" (gethash "body" resp))))
                     s)
                    (e2e--wait (lambda () result) 30)
                    result)))
        (e2e-check "locals evaluate: greeter.greet(\"Eval\")"
          (string-match-p "Hello, Eval, from Hellmacs" (evaluate "greeter.greet(\"Eval\")")))
        (e2e-check "hot swap keeps the session and reports through C-c h r"
          (hellmacs-debug-hot-swap) t))
      (e2e-check "C-c d c continues to the end of the program"
        (call-interactively #'hellmacs-debug-continue)
        (e2e--wait (lambda () (not (dap--session-running (dap--cur-session)))) 60)
        t)
      (dap-breakpoint-delete-all))))

(defun e2e--magit-checks ()
  (e2e--say "\n== 6.6 :tools magit")
  (let* ((repo (expand-file-name (locate-dominating-file e2e--root ".git")))
         (scratch (expand-file-name "clone" (make-temp-file "hellmacs-e2e-git" t))))
    (e2e-check "C-x g, C-x M-g and C-c M-g are bound, Magit not loaded yet"
      (and (eq (key-binding (kbd "C-x g")) 'magit-status)
           (eq (key-binding (kbd "C-x M-g")) 'magit-dispatch)
           (eq (key-binding (kbd "C-c M-g")) 'magit-file-dispatch)
           (not (featurep 'magit))))
    (e2e-check "status opens on this repository"
      (let ((default-directory repo))
        (call-interactively (key-binding (kbd "C-x g")))
        (and (derived-mode-p 'magit-status-mode)
             (save-excursion (goto-char (point-min)) (re-search-forward "Recent commits" nil t)))))
    (e2e-check "log lists commits"
      (let ((default-directory repo))
        (magit-log-current nil nil)
        (with-current-buffer (magit-get-mode-buffer 'magit-log-mode)
          (> (count-lines (point-min) (point-max)) 1))))
    (e2e-check "blame marks chunks"
      (with-current-buffer (find-file-noselect (expand-file-name "init.el" repo))
        (magit-blame-addition nil)
        (e2e--wait (lambda () (cl-some (lambda (o) (overlay-get o 'magit-blame-chunk))
                                       (overlays-in (point-min) (point-max))))
                   30)))
    (let ((default-directory "/"))
      (unless (zerop (call-process "git" nil nil nil "clone" "-q" repo scratch))
        (error "Couldn't clone %s" repo))
      (call-process "git" nil nil nil "-C" scratch "config" "user.email" "e2e@example.invalid")
      (call-process "git" nil nil nil "-C" scratch "config" "user.name" "e2e"))
    (e2e-check "stage and commit on a scratch clone"
      (let ((default-directory (file-name-as-directory scratch)))
        (with-temp-file (expand-file-name "probe.txt" scratch) (insert "hello\n"))
        (magit-stage-files (list (expand-file-name "probe.txt" scratch)))
        (magit-run-git "commit" "-m" "e2e: commit through magit")
        (and (equal (magit-git-string "log" "-1" "--format=%s") "e2e: commit through magit")
             (null (magit-git-lines "status" "--porcelain")))))
    (delete-directory (file-name-directory scratch) t)))

(let ((proj (e2e--copy-fixture)))
  (e2e--say "Hellmacs Java end-to-end, fixture %s in %s" e2e--fixture proj)
  (e2e--java-checks proj)
  (e2e--magit-checks))

(e2e--say "\n%s" (if (zerop e2e--failures) "ALL PASSED" (format "%d FAILED" e2e--failures)))
(kill-emacs (if (zerop e2e--failures) 0 1))

;;; java-e2e.el ends here
