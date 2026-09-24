;;; startup-bench.el --- Measure one interactive Hellmacs startup -*- lexical-binding: t; -*-

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

;; The startup budget of Phase 9 (docs/roadmap.md). Loaded into an
;; interactive session, after init:
;;
;;   emacs -nw --init-directory ~/hellmacs -l test/integration/startup-bench.el
;;   emacs     --init-directory ~/hellmacs -l test/integration/startup-bench.el
;;
;; (the first inside a terminal or a pty, e.g. `script -qc'). Once the
;; first frame is drawn it appends one line to $HELLMACS_BENCH_OUT (or
;; prints it to stderr) and exits:
;;
;;   tty 0.052s 3gc 61.2MB warnings=0
;;
;; the frame type, `hellmacs-init-time', `gcs-done', the resident set
;; size, and how many entries *Warnings* holds. Any warning is also
;; written out, since a clean start is part of the budget.

;;; Code:

(defun startup-bench--rss-mb ()
  "Resident set size of this Emacs, in MB, from /proc (nil elsewhere)."
  (let ((file (format "/proc/%d/status" (emacs-pid))))
    (when (file-readable-p file)
      (with-temp-buffer
        (insert-file-contents file)
        (when (re-search-forward "^VmRSS:\\s-+\\([0-9]+\\) kB" nil t)
          (/ (string-to-number (match-string 1)) 1024.0))))))

(defun startup-bench--warnings ()
  "The text of *Warnings*, or nil when nothing was warned about."
  (when-let* ((buffer (get-buffer "*Warnings*")))
    (with-current-buffer buffer
      (let ((text (string-trim (buffer-string))))
        (unless (string-empty-p text) text)))))

(defun startup-bench--report ()
  "Write the measurement and exit."
  (let* ((warnings (startup-bench--warnings))
         (line (format "%s %.3fs %dgc %.1fMB warnings=%d\n"
                       (if (display-graphic-p) "gui" "tty")
                       (or hellmacs-init-time -1) gcs-done
                       (or (startup-bench--rss-mb) -1)
                       (if warnings (length (split-string warnings "\n" t)) 0)))
         (out (getenv "HELLMACS_BENCH_OUT")))
    (when warnings
      (setq line (concat line warnings "\n")))
    (if out
        (write-region line nil out 'append 'silent)
      (princ line #'external-debugging-output))
    (kill-emacs 0)))

;; After the first redisplay, so the frame and the startup buffer count.
(run-with-idle-timer 0.5 nil #'startup-bench--report)

;;; startup-bench.el ends here
