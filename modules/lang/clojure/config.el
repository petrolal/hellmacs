;;; lang/clojure/config.el -*- lexical-binding: t; -*-

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


;; Clojure: CIDER for the REPL, clojure-lsp (over lsp-mode) for code
;; intelligence. Flags:
;;   +tree-sitter  Use `clojure-ts-mode' (`bin/hellmacs sync' builds the
;;                 pinned Clojure grammar)
;;
;; CIDER keeps its own standard keys, which are the ones its manual uses:
;;   C-c M-j  jack in (start a REPL for the project)     C-c M-c  connect to one
;;   C-c C-k  load the buffer      C-c C-e / C-x C-e  evaluate the form before point
;;   C-M-x    evaluate the top-level form      C-c C-t t  run the test at point
;;   C-c C-z  switch to the REPL   M-. / M-,   jump to a definition and back
;;   C-c C-d d  documentation      C-c C-q  quit the REPL
;; Nothing is rebound. `C-c h r' (the Crucible) reloads the buffer into
;; the connected REPL. Code intelligence -- rename, references, code
;; actions, diagnostics -- is `:tools lsp' (`C-c l', `C-c ! n').
;;
;; The clojure-lsp binary is installed by `bin/hellmacs sync' (a pinned
;; release, checked by SHA-256) into the data directory; a clojure-lsp on
;; your PATH is used instead. A REPL needs the Clojure CLI, Leiningen or
;; Babashka on the PATH (`bin/hellmacs doctor' checks).

(load (expand-file-name "+paths" (file-name-directory load-file-name)) nil 'nomessage)

(unless (modulep! :tools lsp)
  (display-warning 'hellmacs ":lang clojure needs :tools lsp for its keys, completion and tuning; add it to your hellmacs! block"))

(when (modulep! +tree-sitter)
  ;; clojure-ts-mode installs grammars itself, at first use, into the
  ;; cache; Hellmacs builds them (pinned) on sync instead.
  (setq clojure-ts-ensure-grammars nil)
  ;; Without them the mode fails or loses highlighting: stay on
  ;; clojure-mode and say why.
  (if (seq-every-p #'hellmacs-treesit-current-p
                   '(clojure markdown-inline regex))
      (dolist (remap '((clojure-mode . clojure-ts-mode)
                       (clojurescript-mode . clojure-ts-clojurescript-mode)
                       (clojurec-mode . clojure-ts-clojurec-mode)))
        (add-to-list 'major-mode-remap-alist remap))
    (display-warning 'hellmacs "+tree-sitter: the Clojure grammars aren't built yet; run `bin/hellmacs sync'")))

;;; CIDER ------------------------------------------------------------------------------

;; Loaded in the background after startup, with what it needs, so the
;; first `C-c M-j' doesn't wait for it.
(use-package cider
  :defer-incrementally (spinner queue sesman parseedn clojure-mode)
  :commands (cider-jack-in cider-jack-in-clj cider-jack-in-cljs cider-connect cider-connect-clj)
  :custom
  (cider-repl-history-file (hellmacs-state-file "cider-history"))
  (cider-repl-display-help-banner nil)     ; the banner repeats what the manual says
  (cider-repl-pop-to-buffer-on-connect 'display-only) ; show the REPL, keep focus in the code
  (cider-prefer-local-resources t)         ; don't fetch source over TRAMP when a local copy exists
  (cider-save-file-on-load t)              ; save before C-c C-k, without asking
  (cider-show-error-buffer 'except-in-repl))

(use-package clojure-mode
  :custom
  (clojure-toplevel-inside-comment-form t)) ; C-M-x evaluates inside (comment ...)

;;; clojure-lsp -------------------------------------------------------------------------

;; clojure-mode and CIDER already indent and format Clojure, and CIDER
;; completes from the live REPL; keep the language server to what only it
;; does. (lsp-mode's capf and CIDER's both join `completion-at-point-functions'.)
(defun hellmacs-clojure--lsp-h ()
  "Start clojure-lsp for this buffer, leaving indentation to Clojure mode."
  (setq-local lsp-enable-indentation nil
              lsp-enable-on-type-formatting nil)
  (lsp-deferred))

(dolist (hook '(clojure-mode-hook clojurec-mode-hook clojurescript-mode-hook
                clojure-ts-mode-hook clojure-ts-clojurec-mode-hook
                clojure-ts-clojurescript-mode-hook))
  (add-hook hook #'hellmacs-clojure--lsp-h))

;;; Status: echo-area announcements --------------------------------------------------
;;
;; clojure-lsp reports its start-up as one `$/progress' (begin, reports,
;; end): the end means the project is analysed. If it can't build the
;; classpath (a dependency that doesn't resolve, no `clojure' on the PATH)
;; it asks to show a warning instead. The messages are in
;; core/hellmacs-lsp-status.el.

(require 'hellmacs-lsp-status)

(defun hellmacs-clojure-state (root)
  "The state of clojure-lsp for project ROOT: igniting, ready, failed or nil."
  (hellmacs-lsp-status-state 'clojure-lsp root))

(defun hellmacs-clojure--failure-reason (message)
  "A short reason from clojure-lsp's classpath-failure MESSAGE."
  (if (string-match "^Error: \\(.+\\)$" message)
      (match-string 1 message)
    "the classpath lookup failed (run `clojure -Spath' in the project to see why)"))

(defun hellmacs-clojure--note-notification (root method params)
  "React to clojure-lsp's notification METHOD with PARAMS for project ROOT."
  (when (and (equal method "$/progress")
             (equal (hellmacs-lsp-status-get (hellmacs-lsp-status-get params :value) :kind) "end"))
    (hellmacs-lsp-status-ready 'clojure-lsp root)))

(defun hellmacs-clojure--note-request (root method params)
  "React to clojure-lsp's request METHOD with PARAMS for project ROOT."
  (when (equal method "window/showMessageRequest")
    (let ((message (or (hellmacs-lsp-status-get params :message) "")))
      (when (string-match-p "classpath lookup failed" message)
        (hellmacs-lsp-status-fail 'clojure-lsp root (hellmacs-clojure--failure-reason message))))))

(defun hellmacs-clojure--ignited-h ()
  "For `lsp-after-initialize-hook'."
  (when (and lsp--cur-workspace (hellmacs-lsp-status-workspace-p lsp--cur-workspace 'clojure-lsp))
    (hellmacs-lsp-status-ignite 'clojure-lsp "clojure-lsp" (lsp--workspace-root lsp--cur-workspace))))

(defun hellmacs-clojure--notification-a (workspace notification)
  "Before lsp-mode handles NOTIFICATION from a clojure-lsp WORKSPACE."
  (when (hellmacs-lsp-status-workspace-p workspace 'clojure-lsp)
    (hellmacs-clojure--note-notification (lsp--workspace-root workspace)
                                         (lsp-get notification :method)
                                         (lsp-get notification :params))))

(defun hellmacs-clojure--request-a (workspace request)
  "Before lsp-mode handles REQUEST from a clojure-lsp WORKSPACE."
  (when (hellmacs-lsp-status-workspace-p workspace 'clojure-lsp)
    (hellmacs-clojure--note-request (lsp--workspace-root workspace)
                                    (lsp-get request :method)
                                    (lsp-get request :params))))

(defun hellmacs-clojure--forget-h (workspace)
  "For `lsp-after-uninitialized-functions': the server for WORKSPACE exited."
  (when (hellmacs-lsp-status-workspace-p workspace 'clojure-lsp)
    (hellmacs-lsp-status-forget 'clojure-lsp (lsp--workspace-root workspace))))

(with-eval-after-load 'lsp-mode
  (add-hook 'lsp-after-initialize-hook #'hellmacs-clojure--ignited-h)
  (add-hook 'lsp-after-uninitialized-functions #'hellmacs-clojure--forget-h)
  (advice-add 'lsp--on-notification :before #'hellmacs-clojure--notification-a)
  (advice-add 'lsp--on-request :before #'hellmacs-clojure--request-a))
