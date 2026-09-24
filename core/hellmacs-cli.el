;;; hellmacs-cli.el --- The bin/hellmacs command-line tool -*- lexical-binding: t; -*-

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

;; `bin/hellmacs' runs Emacs in batch mode, loads early-init.el and this
;; file, and calls `hellmacs-cli-main' with the command-line arguments.
;; Each command is a `hellmacs-cli-COMMAND' function; see `hellmacs-cli-help'.
;;
;; Commands print plain text on stdout and exit 0 on success, 1 on failure.

;;; Code:

(require 'hellmacs-sync)

;;; Output ---------------------------------------------------------------------

(defun hellmacs-cli--say (format-string &rest args)
  "Print FORMAT-STRING with ARGS, and a newline, on stdout."
  (princ (concat (apply #'format format-string args) "\n")))

(defvar hellmacs-cli--problems 0
  "How many `error'-level results `hellmacs-cli--check' printed.")

(defun hellmacs-cli--check (level format-string &rest args)
  "Print a check result. LEVEL is `ok', `warn', `error' or `info'."
  (when (eq level 'error) (cl-incf hellmacs-cli--problems))
  (hellmacs-cli--say "  %s %s"
                     (pcase level ('ok "✓") ('warn "!") ('error "✗") (_ "·"))
                     (apply #'format format-string args)))

(defun hellmacs-cli--run (program &rest args)
  "Run PROGRAM with ARGS; return (EXIT-CODE . OUTPUT), OUTPUT trimmed."
  (with-temp-buffer
    (let ((code (condition-case nil
                    (apply #'call-process program nil t nil args)
                  (file-missing 127))))
      (cons code (string-trim (buffer-string))))))

;;; sync -----------------------------------------------------------------------

(defun hellmacs-cli-sync (&rest _)
  "Install/build every declared package and write the profile."
  (hellmacs-sync))

;;; install --------------------------------------------------------------------

(defun hellmacs-cli-install (&rest args)
  "First-time setup: create the user config, sync, optionally save the env.
ARGS may contain --env (also run `env') and --no-config (don't create
the user config directory)."
  (hellmacs-cli--say "Setting up Hellmacs in %s" (abbreviate-file-name hellmacs-dir))
  (unless (member "--no-config" args)
    (let ((existed (file-directory-p hellmacs-user-dir)))
      (hellmacs-init-user-dir)
      (hellmacs-cli--say "%s your config in %s"
                         (if existed "Kept" "Created")
                         (abbreviate-file-name hellmacs-user-dir))))
  (hellmacs-sync)
  (when (member "--env" args)
    (hellmacs-cli-env))
  (hellmacs-cli--say "")
  (hellmacs-cli-doctor)
  (hellmacs-cli--say "\nDone. Start Emacs with:  emacs --init-directory %s"
                     (abbreviate-file-name (directory-file-name hellmacs-dir))))

;;; env ------------------------------------------------------------------------

(defvar hellmacs-env-deny
  '("^DBUS_SESSION_BUS_ADDRESS$" "^GPG_AGENT_INFO$" "^\\(SSH\\|GPG\\)_TTY$"
    "^SSH_\\(AUTH_SOCK\\|AGENT_PID\\|CLIENT\\|CONNECTION\\)$"
    "^DISPLAY$" "^WAYLAND_DISPLAY$" "^XAUTHORITY$" "^XDG_SESSION_\\|^XDG_VTNR$"
    "^TERM$" "^TERM_PROGRAM" "^COLORTERM$" "^COLUMNS$" "^LINES$"
    "^INSIDE_EMACS$" "^EMACS" "^TMUX" "^STY$" "^WINDOWID$"
    "^PWD$" "^OLDPWD$" "^SHLVL$" "^_$" "^HOME$" "^R_SESSION_TMPDIR$"
    ;; Which Hellmacs config the command ran on: saved, it would send any
    ;; bin/hellmacs run from inside Emacs to that one.
    "^HELLMACS_PROFILE$" "^HELLMACSDIR$")
  "Regexps of variables `bin/hellmacs env' never saves.
They describe the terminal or session the command ran in, not your
shell setup, and would be wrong -- or harmful -- inside Emacs later.")

(defun hellmacs-cli-env (&rest args)
  "Save the current shell environment for Emacs to load at startup.
With --clear in ARGS, delete the saved environment instead."
  (if (member "--clear" args)
      (progn
        (when (file-exists-p hellmacs-env-file)
          (delete-file hellmacs-env-file))
        (hellmacs-cli--say "Removed the saved environment (%s)"
                           (abbreviate-file-name hellmacs-env-file)))
    (let ((vars (seq-remove
                 (lambda (entry)
                   (let ((name (car (split-string entry "="))))
                     (seq-some (lambda (re) (string-match-p re name)) hellmacs-env-deny)))
                 ;; `initial-environment' is what bin/hellmacs was run with,
                 ;; before Emacs (or early-init.el) changed anything.
                 initial-environment)))
      (make-directory (file-name-directory hellmacs-env-file) t)
      (with-temp-file hellmacs-env-file
        (insert ";; -*- mode: lisp-data -*-\n"
                ";; Saved by `bin/hellmacs env' on " (format-time-string "%F %T")
                ". Re-run it after changing your shell's environment.\n")
        (let ((print-escape-newlines t))
          (prin1 (sort vars #'string<) (current-buffer)))
        (insert "\n"))
      (hellmacs-cli--say "Saved %d environment variables to %s (PATH has %d entries)"
                         (length vars) (abbreviate-file-name hellmacs-env-file)
                         (length (parse-colon-path (getenv "PATH")))))))

;;; lock -----------------------------------------------------------------------

(defun hellmacs-cli--write-lock ()
  "Write `hellmacs-lock-file' for every package Elpaca has queued."
  (defvar elpaca-lock-file-functions)
  (let ((elpaca-lock-file-functions nil)) ; lock everything, not just init-time orders
    (make-directory (file-name-directory hellmacs-lock-file) t)
    (elpaca-write-lock-file hellmacs-lock-file))
  (hellmacs-cli--say "Locked %d packages in %s"
                     (length (elpaca--queued)) (abbreviate-file-name hellmacs-lock-file)))

(defun hellmacs-cli-lock (&rest _)
  "Sync, then record the exact commit of every installed package."
  (hellmacs-sync)
  (hellmacs-cli--write-lock))

;;; upgrade --------------------------------------------------------------------

(defun hellmacs-cli--upgrade-hellmacs ()
  "Pull Hellmacs itself with git, when that's safe."
  (let ((git (lambda (&rest args) (apply #'hellmacs-cli--run "git" "-C" hellmacs-dir args))))
    (cond
     ((not (zerop (car (funcall git "rev-parse" "--git-dir"))))
      (hellmacs-cli--say "Hellmacs isn't a git checkout; skipping its update.") nil)
     ((not (string-empty-p (cdr (funcall git "status" "--porcelain" "--untracked-files=no"))))
      (hellmacs-cli--say "Hellmacs has uncommitted changes; skipping its update.") nil)
     ((not (zerop (car (funcall git "rev-parse" "--abbrev-ref" "@{upstream}"))))
      (hellmacs-cli--say "Hellmacs' branch has no upstream to pull from; skipping its update.") nil)
     (t
      (let ((before (cdr (funcall git "rev-parse" "HEAD")))
            (pull (funcall git "pull" "--ff-only")))
        (unless (zerop (car pull))
          (error "git pull failed in %s:\n%s" hellmacs-dir (cdr pull)))
        (let ((after (cdr (funcall git "rev-parse" "HEAD"))))
          (hellmacs-cli--say (if (equal before after)
                                 "Hellmacs is already up to date."
                               (format "Updated Hellmacs %s -> %s"
                                       (substring before 0 7) (substring after 0 7))))))))))

(defun hellmacs-cli--reattach (e)
  "Put package E's git checkout back on its branch, if it's detached.
Installing at an exact commit (from the lock file) leaves the checkout
on a detached HEAD, which has no upstream to update from."
  (let* ((dir (elpaca<-source-dir e))
         (git (lambda (&rest args) (apply #'hellmacs-cli--run "git" "-C" dir args))))
    (when (and (file-directory-p dir)
               (zerop (car (funcall git "rev-parse" "--git-dir")))
               (not (zerop (car (funcall git "symbolic-ref" "-q" "HEAD")))))
      (let ((branch (or (plist-get (elpaca<-recipe e) :branch)
                        (let ((head (funcall git "symbolic-ref" "--short" "refs/remotes/origin/HEAD")))
                          (and (zerop (car head))
                               (string-remove-prefix "origin/" (cdr head)))))))
        (unless (and branch (zerop (car (funcall git "checkout" "-q" branch))))
          (hellmacs-cli--say "  ! couldn't find the branch of %s; leaving it at its current commit"
                             (elpaca<-id e)))))))

(defun hellmacs-cli-upgrade-self (&rest _)
  "Update Hellmacs itself with git. Run by `bin/hellmacs upgrade' first,
so the package update that follows runs the new code."
  (hellmacs-cli--upgrade-hellmacs))

(defun hellmacs-cli-upgrade (&rest _)
  "Update every unpinned package, then re-sync.
`bin/hellmacs upgrade' runs `upgrade-self' before this, unless given
--packages. Rewrites the lock file if you have one."
  (let ((locked (file-exists-p hellmacs-lock-file)))
    (hellmacs-sync--log "Reading modules and packages...")
    (hellmacs-modules-read-config)
    ;; Install from the lock first, so upgrading starts from what's locked.
    (hellmacs-modules-install-packages)
    (let ((pinned (cl-loop for (name . plist) in hellmacs-packages
                           when (plist-get plist :pin) collect name))
          (ids (mapcar #'car (elpaca--queued))))
      (hellmacs-sync--log "Updating %d packages%s..."
                          (- (length ids) (length pinned))
                          (if pinned (format " (%d pinned, skipped)" (length pinned)) ""))
      (dolist (id ids)
        (unless (memq id pinned)
          (hellmacs-cli--reattach (elpaca-get id))
          (elpaca-merge id 'fetch)))
      (elpaca-process-queues)
      (hellmacs--elpaca-wait))
    (hellmacs-sync--check-failures)
    (hellmacs-sync--log "Synced %d packages" (length (hellmacs-sync--write-profile)))
    (when locked
      (hellmacs-cli--write-lock))))

;;; gc -------------------------------------------------------------------------

(defun hellmacs-cli-gc (&rest args)
  "Delete installed packages nothing declares any more.
With -n or --dry-run in ARGS, only list them."
  (let ((dry-run (or (member "-n" args) (member "--dry-run" args))))
    (hellmacs-sync)
    (let* ((keep (cl-loop for (_ . e) in (elpaca--queued)
                          collect (file-name-as-directory (elpaca<-build-dir e))
                          collect (file-name-as-directory (elpaca<-source-dir e))))
           (orphans (cl-loop for root in (list elpaca-builds-directory elpaca-sources-directory)
                             when (file-directory-p root)
                             append (cl-loop for dir in (directory-files root t "\\`[^.]")
                                             for d = (file-name-as-directory dir)
                                             when (and (file-directory-p d) (not (member d keep)))
                                             collect d))))
      (if (null orphans)
          (hellmacs-cli--say "Nothing to clean up.")
        (dolist (dir orphans)
          (hellmacs-cli--say "%s %s" (if dry-run "Would delete" "Deleting")
                             (abbreviate-file-name (directory-file-name dir)))
          (unless dry-run
            (delete-directory dir 'recursive)))
        (hellmacs-cli--say "%s %d orphaned package directories."
                           (if dry-run "Found" "Deleted") (length orphans))))))

;;; test -----------------------------------------------------------------------

(defun hellmacs-cli-test (&rest args)
  "Run Hellmacs' test suites (test/test-*.el) with ERT, then exit.
ARGS, if any, is an ERT selector regexp: only matching tests run.
bin/hellmacs points every Hellmacs directory at a temporary one first."
  (require 'ert)
  (let ((dir (expand-file-name "test/" hellmacs-dir)))
    (add-to-list 'load-path dir)
    (dolist (file (directory-files dir t "\\`test-.*\\.el\\'"))
      (load file nil 'nomessage))
    ;; Exits Emacs itself, with a failing status if any test failed.
    (ert-run-tests-batch-and-exit (if args (car args) t))))

;;; doctor ---------------------------------------------------------------------

(defun hellmacs-cli--version (program &rest args)
  "Return the first line PROGRAM prints for ARGS, or nil if it isn't installed."
  (when (executable-find program)
    (car (split-string (cdr (apply #'hellmacs-cli--run program args)) "\n"))))

;; The API a module's doctor.el uses.

(defun hellmacs-doctor-ok (format-string &rest args)
  "Report a passing check (FORMAT-STRING, ARGS) from a module's doctor.el."
  (apply #'hellmacs-cli--check 'ok format-string args))

(defun hellmacs-doctor-info (format-string &rest args)
  "Report a neutral fact (FORMAT-STRING, ARGS) from a module's doctor.el."
  (apply #'hellmacs-cli--check 'info format-string args))

(defun hellmacs-doctor-warn (format-string &rest args)
  "Report something optional that's missing (FORMAT-STRING, ARGS)."
  (apply #'hellmacs-cli--check 'warn format-string args))

(defun hellmacs-doctor-error (format-string &rest args)
  "Report a problem that breaks the module (FORMAT-STRING, ARGS).
Makes `bin/hellmacs doctor' exit with a failure."
  (apply #'hellmacs-cli--check 'error format-string args))

(defun hellmacs-doctor-executable (program why &optional required &rest version-args)
  "Check that PROGRAM is on the PATH; WHY says what it's needed for.
If found, show its version (running it with VERSION-ARGS) or its path.
If missing, warn -- or report an error if REQUIRED is non-nil.
Returns PROGRAM's path, or nil."
  (if-let* ((path (executable-find program)))
      (progn (hellmacs-doctor-ok "%s: %s" program
                                 (or (and version-args (apply #'hellmacs-cli--version program version-args))
                                     (abbreviate-file-name path)))
             path)
    (funcall (if required #'hellmacs-doctor-error #'hellmacs-doctor-warn)
             "%s not found -- %s" program why)
    nil))

;; Hellmacs never installs fonts (it writes only to its own directories),
;; so a missing Nerd Font is reported with the command that installs one.
(defun hellmacs-doctor-nerd-font (consequence)
  "Check that a Nerd Font is installed; CONSEQUENCE says what happens without."
  (if (not (executable-find "fc-list"))
      (hellmacs-doctor-info "fc-list not found; can't tell whether a Nerd Font is installed")
    (if-let* ((families (ignore-errors
                          (process-lines "fc-list" ":charset=f07b" "family"))))
        (hellmacs-doctor-ok "Nerd Font glyphs: %s" (car (split-string (car families) ",")))
      (hellmacs-doctor-warn "No Nerd Font installed: %s. Install one with M-x nerd-icons-install-fonts (into ~/.local/share/fonts), or from your distribution"
                            consequence))))

(defun hellmacs-doctor-treesit (lang)
  "Check what building and loading LANG's tree-sitter grammar needs.
For a module's doctor.el when its +tree-sitter flag is on."
  (if (not (and (fboundp 'treesit-available-p) (treesit-available-p)))
      (hellmacs-doctor-error "This Emacs has no tree-sitter support, which +tree-sitter needs")
    (if (hellmacs-treesit-installed-p lang)
        (hellmacs-doctor-ok "tree-sitter %s grammar: %s" lang
                            (abbreviate-file-name (hellmacs-treesit-library lang)))
      (if (file-exists-p (hellmacs-treesit-library lang))
          (hellmacs-doctor-warn "The tree-sitter %s grammar isn't the pinned commit; `bin/hellmacs sync' rebuilds it" lang)
        (hellmacs-doctor-warn "The tree-sitter %s grammar isn't built yet; `bin/hellmacs sync' builds it" lang))
      (unless (executable-find "git")
        (hellmacs-doctor-error "git is needed to fetch the %s grammar" lang))
      (unless (seq-some #'executable-find '("cc" "gcc" "clang"))
        (hellmacs-doctor-error "No C compiler (cc, gcc or clang) to build the %s grammar" lang)))))

(defun hellmacs-cli-doctor (&rest _)
  "Check Emacs, required and optional tools, and the state of the config."
  (setq hellmacs-cli--problems 0)
  (hellmacs-cli--say "Emacs")
  (if (version< emacs-version "29.1")
      (hellmacs-cli--check 'error "Emacs %s is too old; Hellmacs needs 29.1+" emacs-version)
    (hellmacs-cli--check 'ok "Emacs %s" emacs-version))
  (when (string-match-p "\\.[5-9][0-9]\\'" emacs-version)
    (hellmacs-cli--check 'warn "This is a development build of Emacs; expect breakage"))
  (if (and (fboundp 'native-comp-available-p) (native-comp-available-p))
      (hellmacs-cli--check 'ok "Native compilation available")
    (hellmacs-cli--check 'info "No native compilation (optional; makes packages faster)"))

  (hellmacs-cli--say "\nRequired tools")
  (if-let* ((git (hellmacs-cli--version "git" "--version")))
      (hellmacs-cli--check 'ok "%s" git)
    (hellmacs-cli--check 'error "git not found; it's needed to install packages"))

  ;; Each enabled module checks its own requirements (doctor.el).
  ;; `hellmacs-cli-main' has read the config already.
  (dolist (key (hellmacs-module-list))
    (let ((file (expand-file-name "doctor.el" (hellmacs-module-get key :path))))
      (when (file-exists-p file)
        (hellmacs-cli--say "\nModule %s %s" (car key) (cdr key))
        (hellmacs-module--load key "doctor.el"))))

  (hellmacs-cli--say "\nConfiguration")
  (hellmacs-cli--check 'info "Profile: %s" (or hellmacs-profile "default"))
  (if (file-directory-p hellmacs-user-dir)
      (hellmacs-cli--check 'ok "Your config: %s" (abbreviate-file-name hellmacs-user-dir))
    (hellmacs-cli--check 'info "No user config yet (%s); using the defaults. `bin/hellmacs install' creates one"
                         (abbreviate-file-name hellmacs-user-dir)))
  (hellmacs-cli--check 'info "Modules: %s"
                       (mapconcat (lambda (k) (format "%s %s" (car k) (cdr k)))
                                  (hellmacs-module-list) ", "))
  (let ((profile (hellmacs-profile-read)))
    (cond ((null profile)
           (hellmacs-cli--check 'error "Not synced yet; run `bin/hellmacs sync'"))
          ((hellmacs-profile--stale-reason profile)
           (hellmacs-cli--check 'error "Out of sync (%s); run `bin/hellmacs sync'"
                                (hellmacs-profile--stale-reason profile)))
          (t (hellmacs-cli--check 'ok "Synced: %d packages" (length (plist-get profile :load-path))))))
  (if (file-exists-p hellmacs-lock-file)
      (hellmacs-cli--check 'ok "Packages locked (%s)" (abbreviate-file-name hellmacs-lock-file))
    (hellmacs-cli--check 'info "Packages not locked; `bin/hellmacs lock' pins their exact versions"))
  (if (file-exists-p hellmacs-env-file)
      (hellmacs-cli--check 'ok "Shell environment saved on %s"
                           (format-time-string "%F" (file-attribute-modification-time
                                                     (file-attributes hellmacs-env-file))))
    (hellmacs-cli--check 'info "No saved shell environment; run `bin/hellmacs env' if Emacs can't find your tools"))
  (dolist (legacy '("var/" "etc/"))
    (let ((dir (expand-file-name legacy hellmacs-dir)))
      (when (file-directory-p dir)
        (hellmacs-cli--check 'warn "%s is left over from an older Hellmacs; nothing uses it, safe to delete"
                             (abbreviate-file-name dir)))))

  (hellmacs-cli--say "")
  (if (zerop hellmacs-cli--problems)
      (hellmacs-cli--say "No problems found.")
    ;; `hellmacs-cli-main' turns these into a failing exit code.
    (hellmacs-cli--say "%d problem(s) found." hellmacs-cli--problems)))

;;; help & dispatch ------------------------------------------------------------

(defun hellmacs-cli-help (&rest _)
  "Print usage."
  (hellmacs-cli--say "\
Usage: bin/hellmacs [--profile NAME] COMMAND [OPTIONS]

--profile NAME (or HELLMACS_PROFILE=NAME) acts on a named profile: a
separate config (~/.config/hellmacs-NAME) with its own packages. Start
Emacs on it with `emacs --init-directory DIR --profile NAME'.

Commands:
  install [--env] [--no-config]
             First-time setup: create your config (~/.config/hellmacs), sync,
             optionally save your shell environment, then run doctor.
  sync       Install/build every package your modules and packages.el declare,
             and write the profile Emacs starts from. Run it after changing
             your hellmacs! block, a packages.el or a module's autoload.el.
  upgrade [--packages]
             Update Hellmacs (git pull) and every unpinned package, then sync.
             --packages: only update packages.
  lock       Record the exact commit of every package in
             ~/.config/hellmacs/packages.lock.eld; later syncs install those.
  gc [-n]    Delete installed packages nothing declares any more.
             -n, --dry-run: only list them.
  env [--clear]
             Save your shell's environment (PATH, JAVA_HOME, ...) for Emacs to
             load at startup; --clear removes it.
  doctor     Check Emacs, tools and your config for problems.
  test [REGEXP]
             Run Hellmacs' own test suites (only tests matching REGEXP),
             in temporary directories.
  help       Show this help.

Environment: EMACS (Emacs binary), HELLMACSDIR (your config dir),
XDG_DATA_HOME, XDG_CACHE_HOME, XDG_STATE_HOME."))

(defun hellmacs-cli-main ()
  "Run the bin/hellmacs command in `command-line-args-left', then exit."
  (let* ((args (delete "--" (copy-sequence command-line-args-left)))
         (command (pcase (car args)
                    ((or 'nil "-h" "--help") "help")
                    (c c)))
         fn)
    (setq command-line-args-left nil)
    ;; early-init.el tuned these for an interactive boot, which a batch
    ;; session never finishes, so they'd never be restored.
    (setq file-name-handler-alist hellmacs--file-name-handler-alist
          gc-cons-threshold (* 128 1024 1024)
          gc-cons-percentage 0.1)
    (hellmacs-context-push 'cli)
    ;; Enabled modules may add commands and sync steps (their cli.el).
    (hellmacs-modules-read-config)
    (hellmacs-modules-load-cli-files)
    (setq fn (intern-soft (concat "hellmacs-cli-" command)))
    (unless (and fn (fboundp fn) (not (string-prefix-p "-" command)))
      (hellmacs-cli--say "bin/hellmacs: unknown command `%s'\n" command)
      (hellmacs-cli-help)
      (kill-emacs 1))
    (condition-case err
        (progn (apply fn (cdr args))
               (kill-emacs (if (zerop hellmacs-cli--problems) 0 1)))
      (error
       (hellmacs-cli--say "Error: %s" (error-message-string err))
       (kill-emacs 1)))))

(provide 'hellmacs-cli)
;;; hellmacs-cli.el ends here
