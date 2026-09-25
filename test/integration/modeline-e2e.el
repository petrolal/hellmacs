;;; modeline-e2e.el --- The :ui modeline in a real Java buffer -*- lexical-binding: t; -*-

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

;; What the Phase 9.3 mode-line draws in a Java buffer: JVM:ready,
;; the flymake counts, JVM:purgatory after a broken build, and no icon
;; glyphs in a terminal. Mode-lines are only drawn in an interactive
;; session (`format-mode-line' returns nothing in batch mode), so this
;; runs in `emacs -nw', inside a terminal or a pty:
;;
;;   HELLMACS_E2E_OUT=/tmp/modeline.log \
;;     script -qec "emacs -nw --init-directory ~/hellmacs \
;;                    -l test/integration/modeline-e2e.el" /dev/null
;;
;; It needs what java-e2e.el needs (a synced profile with :lang java and
;; :tools lsp build), plus :ui modeline. Results go to $HELLMACS_E2E_OUT
;; (else stderr); Emacs exits 1 if a check fails. Run it inside a
;; throwaway XDG_*_HOME/HELLMACSDIR to leave your own setup alone.

;;; Code:

(require 'cl-lib)
(load (expand-file-name "e2e-lib" (file-name-directory (or load-file-name buffer-file-name))) nil t)

;; Results go to $HELLMACS_E2E_OUT, else stderr: stdout is the terminal.
(setq e2e-output #'external-debugging-output)

(defun modeline-e2e--text ()
  "The mode-line of the selected window, as drawn."
  (redisplay t)
  (substring-no-properties (format-mode-line mode-line-format nil (selected-window))))

(defun modeline-e2e--icon-glyphs-p (text)
  "Non-nil if TEXT has a character from the Nerd Font private-use ranges."
  (cl-some (lambda (c) (or (<= #xe000 c #xf8ff) (<= #xf0000 c #x10ffff))) text))

(defun modeline-e2e--run ()
  (let* ((proj (e2e-copy-fixture "java/maven-demo"))
         (src (expand-file-name "src/main/java/dev/hellmacs/demo/" proj))
         ;; Known before the file opens, so lsp-mode doesn't ask whether
         ;; to import the project (that prompt would wait forever).
         (_ (e2e-add-project proj))
         (app (find-file (expand-file-name "App.java" src))))
    (e2e--say "== 9.3 :ui modeline in a Java buffer (%s)" (if (display-graphic-p) "GUI" "terminal"))
    (e2e-check "the Hellmacs mode-line is on in the Java buffer"
      (bound-and-true-p doom-modeline-mode))
    (lsp)
    (e2e-check "it reads JVM:ready once JDTLS is ready"
      (e2e--wait (lambda () (eq (hellmacs-jvm-state proj) 'ready)) 400)
      (string-match-p "JVM:ready" (modeline-e2e--text)))
    (e2e-check "it shows the buffer name and the major mode"
      (let ((text (modeline-e2e--text)))
        (and (string-match-p "App\\.java" text) (string-match-p "Java" text))))
    (unless (display-graphic-p)
      (e2e-check "no icon glyphs in a terminal"
        (not (modeline-e2e--icon-glyphs-p (modeline-e2e--text)))))
    (with-current-buffer (find-file (expand-file-name "Greeter.java" src))
      (lsp)
      (goto-char (point-max)) (re-search-backward "}")
      (insert "int broken = \"s\";\n")
      (e2e-check "the flymake error count appears in the mode-line"
        (e2e--wait (lambda ()
                     (cl-some (lambda (d) (eq (flymake-diagnostic-type d) :error))
                              (flymake-diagnostics)))
                   60)
        (doom-modeline-update-flymake)
        ;; doom-modeline's flymake text: "<icon> errors <icon> warnings <icon> notes".
        (let ((errors (car (seq-filter (lambda (s) (string-match-p "\\`[0-9]+\\'" s))
                                       (split-string doom-modeline--flymake)))))
          (e2e--say "     mode-line: %s" (string-trim (modeline-e2e--text)))
          (and errors (>= (string-to-number errors) 1)
               (string-match-p (regexp-quote errors) (modeline-e2e--text)))))
      (save-buffer)
      (e2e-check "a broken build turns it to JVM:purgatory"
        (e2e--compile-and-wait proj)
        (switch-to-buffer app)
        (delete-other-windows)
        (string-match-p "JVM:purgatory" (modeline-e2e--text))))
    (e2e--say "%s" (if (zerop e2e--failures) "all passed" (format "%d FAILED" e2e--failures)))
    (kill-emacs (if (zerop e2e--failures) 0 1))))

(run-with-idle-timer 1 nil
                     (lambda ()
                       (condition-case err (modeline-e2e--run)
                         (error (e2e--say "ERROR %S" err) (kill-emacs 2)))))

;;; modeline-e2e.el ends here
