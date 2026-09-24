;;; hellmacs-lsp-status.el --- Status messages for language servers -*- lexical-binding: t; -*-

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

;; The `[FORGE IGNITED]' / `[DAEMON READY]' / `[BYTECODE PURGATORY]' messages
;; for a language server that has no notification of its own for them:
;; `:lang kotlin' and `:lang clojure' watch their server's traffic for the
;; signals it does send, and report them through here. The state is kept
;; per server and project, so two servers in one project don't mix. (JDTLS
;; has its own, with a mode-line segment, in `:lang java'.)
;;
;; Wording follows `hellmacs-ux-enable': themed, or plain.

;;; Code:

(defface hellmacs-jvm-busy '((t (:inherit warning)))
  "Face for a language server that is starting or importing a project."
  :group 'hellmacs)

(defface hellmacs-jvm-ready '((t (:inherit success)))
  "Face for a language server that is ready."
  :group 'hellmacs)

(defface hellmacs-jvm-failed '((t (:inherit error)))
  "Face for a server that died, or a project that failed to import or build."
  :group 'hellmacs)

(defcustom hellmacs-lsp-status-messages
  '((ignited hellmacs-jvm-busy   "[FORGE IGNITED] %s bound to %s"          "%s started for %s")
    (ready   hellmacs-jvm-ready  "[DAEMON READY] %s indexed in %.1fs"      "%s indexed in %.1fs")
    (failed  hellmacs-jvm-failed "[BYTECODE PURGATORY] %s failed to import: %s" "%s failed to import: %s"))
  "Status messages: (EVENT FACE THEMED PLAIN). `ignited' takes the server's
name and the project; `ready' the project and seconds; `failed' the
project and the reason."
  :type '(repeat (list symbol face string string))
  :group 'hellmacs)

(defvar hellmacs-lsp-status--sessions (make-hash-table :test #'equal)
  "(SERVER . PROJECT-ROOT) -> (STATE . SINCE), STATE igniting, ready or failed.")

(defun hellmacs-lsp-status-get (object key)
  "Return KEY (a keyword, like :method) from a protocol OBJECT.
lsp-mode gives plists when built with LSP_USE_PLISTS (Hellmacs does that),
and hash tables otherwise; this reads either."
  (if (hash-table-p object)
      (gethash (substring (symbol-name key) 1) object)
    (plist-get object key)))

(defun hellmacs-lsp-status-workspace-p (workspace server)
  "Non-nil if lsp-mode WORKSPACE belongs to SERVER (a server id, like `jdtls')."
  (eq (lsp--client-server-id (lsp--workspace-client workspace)) server))

(defun hellmacs-lsp-status--key (server root)
  (cons server (directory-file-name (file-truename root))))

(defun hellmacs-lsp-status-state (server root)
  "The state of SERVER (a symbol) for project ROOT: igniting, ready, failed or nil."
  (car (gethash (hellmacs-lsp-status--key server root) hellmacs-lsp-status--sessions)))

(defun hellmacs-lsp-status--set (key state)
  "Record STATE for session KEY, keeping the time the server started."
  (puthash key (cons state (or (cdr (gethash key hellmacs-lsp-status--sessions)) (float-time)))
           hellmacs-lsp-status--sessions))

(defun hellmacs-lsp-status-announce (event &rest args)
  "Show the message for EVENT (see `hellmacs-lsp-status-messages') formatted with ARGS.
Returns the text."
  (apply #'hellmacs-announce hellmacs-lsp-status-messages event args))

(defun hellmacs-lsp-status-ignite (server label root)
  "SERVER (shown as LABEL, like \"Kotlin server\") just started for project ROOT."
  (puthash (hellmacs-lsp-status--key server root) (cons 'igniting (float-time))
           hellmacs-lsp-status--sessions)
  (hellmacs-lsp-status-announce 'ignited label (abbreviate-file-name root)))

(defun hellmacs-lsp-status-ready (server root)
  "SERVER finished indexing project ROOT. Only counts right after it started."
  (let* ((key (hellmacs-lsp-status--key server root))
         (session (gethash key hellmacs-lsp-status--sessions)))
    (when (eq (car session) 'igniting)
      (hellmacs-lsp-status--set key 'ready)
      (hellmacs-lsp-status-announce 'ready (abbreviate-file-name root)
                                    (- (float-time) (cdr session))))))

(defun hellmacs-lsp-status-fail (server root reason)
  "SERVER couldn't import project ROOT, for REASON. Announced once per start."
  (let ((key (hellmacs-lsp-status--key server root)))
    (unless (eq (car (gethash key hellmacs-lsp-status--sessions)) 'failed)
      (hellmacs-lsp-status--set key 'failed)
      (hellmacs-lsp-status-announce 'failed (abbreviate-file-name root)
                                    (truncate-string-to-width (string-trim reason) 110 nil nil t)))))

(defun hellmacs-lsp-status-forget (server root)
  "SERVER's process for ROOT exited."
  (remhash (hellmacs-lsp-status--key server root) hellmacs-lsp-status--sessions))

(provide 'hellmacs-lsp-status)
;;; hellmacs-lsp-status.el ends here
