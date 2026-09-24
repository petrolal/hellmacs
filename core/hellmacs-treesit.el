;;; hellmacs-treesit.el --- Pinned tree-sitter grammars -*- lexical-binding: t; -*-

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

;; Modules that offer a `+tree-sitter' flag (`:lang java', `:lang kotlin',
;; `:lang clojure') need a compiled grammar per language. Emacs can build
;; them itself (`treesit-install-language-grammar'), but it prompts, puts
;; them under `user-emacs-directory', and follows a branch or tag that can
;; move. This does the same job the Hellmacs way:
;;
;;   - Each grammar is pinned to one commit, fetched by its hash (the tag
;;     or branch it came from is only a label); anything else is refused.
;;   - Grammars are built by `bin/hellmacs sync' (never at startup) into
;;     `hellmacs-treesit-dir' under the data directory, and found through
;;     `treesit-extra-load-path'.
;;   - A module says what it needs with `hellmacs-treesit-need', from its
;;     cli.el and only when its `+tree-sitter' flag is on.
;;
;; Building needs git and a C compiler (and a C++ one for grammars with a
;; C++ scanner); `bin/hellmacs doctor' checks for them.

;;; Code:

(require 'cl-lib)
(require 'hellmacs-lib)
(require 'hellmacs-core)

(defconst hellmacs-treesit-default-sources
  '((java    "https://github.com/tree-sitter/tree-sitter-java"   "v0.23.5"
             "94703d5a6bed02b98e438d7cad1136c01a60ba2c")
    ;; Not the last tag (0.3.8, 2024): kotlin-ts-mode's font-lock rules follow
    ;; the grammar's main branch, and 0.3.8 makes it drop string and constant
    ;; highlighting. This is main on 2026-08-02.
    (kotlin  "https://github.com/fwcd/tree-sitter-kotlin"        "main 2026-08-02"
             "1852ea17b7f60fb3f9d84e0b1555d56b46b39fb1")
    ;; clojure-ts-mode 0.6 wants this newer Clojure grammar (not the last
    ;; release, v0.0.13), and two more for docstrings and regex literals.
    (clojure "https://github.com/sogaiu/tree-sitter-clojure"     "unstable-20250526"
             "69070d2e4563f8f58c7f57b0c8e093a08d7a5814")
    (markdown-inline "https://github.com/tree-sitter-grammars/tree-sitter-markdown" "v0.5.2"
                     "aca7767daa8bbe3daddafc312c34be88383c828b" "tree-sitter-markdown-inline")
    (regex   "https://github.com/tree-sitter/tree-sitter-regex"  "v0.24.3"
             "4470c59041416e8a2a9fa343595ca28ed91f38b8"))
  "The grammars Hellmacs knows: (LANGUAGE URL LABEL COMMIT [DIRECTORY]).
LABEL only says what the commit is (a release tag, or a branch and date);
the COMMIT is what gets fetched. DIRECTORY, when the grammar isn't at the
top of the repository, is the subdirectory holding its src/. All are tree-sitter ABI 14 or 15, which
Emacs 29 through 31 load.")

(defvar hellmacs-treesit-sources hellmacs-treesit-default-sources
  "Grammar sources, as `hellmacs-treesit-default-sources'. Set it in your
init.el to pin a different release.")

(defvar hellmacs-treesit-dir (expand-file-name "treesit/" hellmacs-data-dir)
  "Where compiled grammars live (data: reinstallable, but needed to run).")

(defvar hellmacs-treesit-wanted nil
  "Languages the enabled modules need, added by `hellmacs-treesit-need'.")

(defvar treesit-extra-load-path)

;; Emacs finds grammars here from now on, whether or not any is installed.
(when (fboundp 'treesit-available-p)
  (add-to-list 'treesit-extra-load-path hellmacs-treesit-dir))

(defun hellmacs-treesit-need (lang)
  "Record that a module needs the grammar for LANG (a symbol) installed."
  (cl-pushnew lang hellmacs-treesit-wanted))

(defun hellmacs-treesit--source (lang)
  "The (URL LABEL COMMIT [DIRECTORY]) for LANG, or an error if it isn't known."
  (or (cdr (assq lang hellmacs-treesit-sources))
      (error "No tree-sitter grammar source for `%s'; see `hellmacs-treesit-sources'" lang)))

(defun hellmacs-treesit-library (lang)
  "The path of LANG's compiled grammar."
  (expand-file-name (format "libtree-sitter-%s%s" lang (car dynamic-library-suffixes))
                    hellmacs-treesit-dir))

(defun hellmacs-treesit--marker (lang)
  "The file recording the commit LANG's grammar was built from."
  (concat (hellmacs-treesit-library lang) ".commit"))

(defun hellmacs-treesit-current-p (lang)
  "Non-nil if LANG's library exists and was built from the pinned commit.
A library left by an older pin (or by Emacs' own installer) isn't current."
  (and (file-exists-p (hellmacs-treesit-library lang))
       (hellmacs-marker-current-p (hellmacs-treesit--marker lang)
                                  (nth 2 (hellmacs-treesit--source lang)))))

(defun hellmacs-treesit-installed-p (lang)
  "Non-nil if LANG's grammar is built from the pinned commit and loads."
  (and (hellmacs-treesit-current-p lang)
       (fboundp 'treesit-language-available-p)
       (treesit-language-available-p lang)))

(defun hellmacs-treesit--run (dir program &rest args)
  "Run PROGRAM with ARGS in DIR; return its output, or signal an error."
  (with-temp-buffer
    (let ((default-directory (file-name-as-directory dir)))
      (unless (zerop (apply #'call-process program nil t nil args))
        (error "`%s %s' failed: %s" program (string-join args " ")
               (string-trim (buffer-string))))
      (string-trim (buffer-string)))))

(defun hellmacs-treesit--compiler (&rest names)
  "The first of NAMES found on the PATH, or an error."
  (or (seq-some #'executable-find names)
      (error "No C compiler found (looked for %s); grammars are built from C sources"
             (string-join names ", "))))

(defun hellmacs-treesit--build (src out)
  "Compile the grammar in SRC's src/ directory into the library OUT."
  (let* ((srcdir (expand-file-name "src/" src))
         (cc (hellmacs-treesit--compiler "cc" "gcc" "clang"))
         (c++ (seq-some #'executable-find '("c++" "g++" "clang++")))
         (cpp-scanner (file-exists-p (expand-file-name "scanner.cc" srcdir)))
         (objects nil))
    (unless (file-exists-p (expand-file-name "parser.c" srcdir))
      (error "%s has no src/parser.c" src))
    (dolist (file '("parser.c" "scanner.c" "scanner.cc"))
      (when (file-exists-p (expand-file-name file srcdir))
        (let ((obj (concat file ".o")))
          (hellmacs-treesit--run srcdir (if (string-suffix-p ".cc" file)
                                            (or c++ (error "A C++ compiler is needed for %s" file))
                                          cc)
                                 "-fPIC" "-O2" "-I." "-c" file "-o" obj)
          (push obj objects))))
    (make-directory (file-name-directory out) t)
    (let ((tmp (concat out ".part")))
      (apply #'hellmacs-treesit--run srcdir (if cpp-scanner c++ cc)
             "-shared" "-o" tmp (nreverse objects))
      (rename-file tmp out t))))

(defun hellmacs-treesit-install (lang)
  "Build LANG's pinned grammar into `hellmacs-treesit-dir'.
Fetches exactly the pinned commit (refusing anything else), compiles it
in a temporary directory, and only then puts the library in place."
  (pcase-let* ((`(,url ,_label ,commit ,directory) (hellmacs-treesit--source lang))
               (tmp (make-temp-file "hellmacs-treesit" t)))
    (unless (executable-find "git") (error "git is needed to fetch tree-sitter grammars"))
    (unwind-protect
        (let ((src (expand-file-name (format "tree-sitter-%s" lang) tmp)))
          (make-directory src t)
          (hellmacs-treesit--run src "git" "init" "--quiet")
          (hellmacs-treesit--run src "git" "remote" "add" "origin" url)
          (hellmacs-treesit--run src "git" "fetch" "--quiet" "--depth" "1" "origin" commit)
          (hellmacs-treesit--run src "git" "checkout" "--quiet" "FETCH_HEAD")
          (let ((head (hellmacs-treesit--run src "git" "rev-parse" "HEAD")))
            (unless (equal head commit)
              (error "Grammar `%s' fetched %s, not the pinned %s; not installed" lang head commit)))
          (hellmacs-treesit--build (if directory (expand-file-name directory src) src)
                                   (hellmacs-treesit-library lang))
          ;; Written last: without it the library isn't taken for current.
          (with-temp-file (hellmacs-treesit--marker lang) (insert commit "\n")))
      (delete-directory tmp t))))

(defun hellmacs-treesit-ensure (lang)
  "Make sure LANG's grammar is installed, building it if it isn't.
Returns non-nil when it is available afterwards."
  (unless (hellmacs-treesit-current-p lang)
    (hellmacs-treesit-install lang))
  (hellmacs-treesit-installed-p lang))

(declare-function hellmacs-sync--log "hellmacs-sync")

(defun hellmacs-treesit-sync ()
  "Build the grammars the enabled modules asked for. For `hellmacs-sync-functions'."
  (dolist (lang (reverse hellmacs-treesit-wanted))
    (if (hellmacs-treesit-installed-p lang)
        (hellmacs-sync--log "tree-sitter %s grammar is installed" lang)
      (hellmacs-sync--log "Building the tree-sitter %s grammar..." lang)
      (unless (hellmacs-treesit-ensure lang)
        (error "The %s grammar was built but Emacs can't load it (%s)"
               lang (abbreviate-file-name (hellmacs-treesit-library lang))))
      (hellmacs-sync--log "tree-sitter %s grammar installed (commit pinned)" lang))))

(provide 'hellmacs-treesit)
;;; hellmacs-treesit.el ends here
