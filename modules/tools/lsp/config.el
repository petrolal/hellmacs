;;; tools/lsp/config.el -*- lexical-binding: t; -*-

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


;; Language-server support: completion, navigation, diagnostics and
;; refactoring from a language server. Language modules (`:lang java',
;; ...) start the server for their buffers; this module only sets up
;; the client.
;;
;; Owns `C-c l' (lsp-mode's own command map: `a a' code action, `r r'
;; rename, `r o' organize imports, `g g'/`g i'/`g r' definition,
;; implementation, references, `= =' format, `w r' restart) and, in
;; LSP buffers only, `C-c !' for diagnostics. Emacs' xref keys work as
;; everywhere: `M-.' definition, `M-?' references, `M-,' back,
;; `C-M-.' search workspace symbols.
;;
;; The client is lsp-mode: lsp-java, dap-mode and the servers' own
;; extensions all build on it. Modules that need it say
;; `(depends-on! :tools lsp)' in their packages.el.

(defvar hellmacs-lsp-read-process-output-max (* 1024 1024)
  "`read-process-output-max' while a language server runs.
Servers send large JSON payloads; lsp-mode recommends 1MB.")

(defun hellmacs-lsp--tune-process-output-h ()
  "Read language-server output in large chunks."
  (setq read-process-output-max hellmacs-lsp-read-process-output-max))

;; Language servers allocate heavily; collect less often (lsp-mode's
;; performance guide). gcmh still collects when Emacs is idle.
(setq gcmh-high-cons-threshold (* 128 1024 1024))

;;; lsp-mode ------------------------------------------------------------------

(defun hellmacs-lsp-mode-used-p ()
  "Non-nil if lsp-mode is in use: declared (packages.el) and not disabled."
  (and (assq 'lsp-mode hellmacs-packages)
       (not (hellmacs-package-disabled-p 'lsp-mode))))

(when (hellmacs-lsp-mode-used-p)
  (use-package lsp-mode
    ;; Loaded in the background after startup, so the first file that
    ;; needs a server doesn't also wait for lsp-mode itself.
    :defer-incrementally (lsp-mode lsp-completion lsp-diagnostics lsp-modeline)
    :commands (lsp lsp-deferred)
    :init
    ;; Must be set before lsp-mode loads: it binds its command map there.
    (setq lsp-keymap-prefix "C-c l")
    :custom
    (lsp-completion-provider :none)         ; plain completion-at-point, shown by corfu
    (lsp-diagnostics-provider :flymake)     ; built-in; no flycheck
    (lsp-log-io nil)
    (lsp-idle-delay 0.5)
    (lsp-keep-workspace-alive nil)
    (lsp-file-watch-threshold 5000)         ; big multi-module builds
    (lsp-headerline-breadcrumb-enable nil)
    (lsp-enable-snippet nil)                ; no yasnippet (yet)
    (lsp-session-file (hellmacs-state-file "lsp-session"))
    :hook
    (lsp-mode . lsp-enable-which-key-integration)
    (lsp-mode . hellmacs-lsp--tune-process-output-h)
    (lsp-completion-mode . hellmacs-lsp--setup-completion-h)
    :bind
    (:map lsp-mode-map
          ("C-c ! n" . flymake-goto-next-error)
          ("C-c ! p" . flymake-goto-prev-error)
          ("C-c ! l" . flymake-show-buffer-diagnostics))))

;; lsp-mode only uses plists if it was *compiled* with LSP_USE_PLISTS
;; set; if the variable says plists but the compiled code expects hash
;; tables, every server response is misread. `lsp-doctor' only checks
;; the variable, so check the compiled accessors themselves.
(when (hellmacs-lsp-mode-used-p)
  (with-eval-after-load 'lsp-protocol
    (when (and (bound-and-true-p lsp-use-plists)
               (fboundp 'lsp:position-line)
               (not (equal (ignore-errors (lsp:position-line '(:line 3 :character 0))) 3)))
      (display-warning
       'hellmacs
       "lsp-mode was compiled without LSP_USE_PLISTS, so it misreads language servers. \
Run `bin/hellmacs sync' to rebuild it."
       :error))))
