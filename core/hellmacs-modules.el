;;; hellmacs-modules.el --- Module system: hellmacs!, modulep!, package! -*- lexical-binding: t; -*-

;; Modeled on Doom Emacs' module system (`doom!', `modulep!',
;; `package!'), minus its v2 compatibility layers.
;;
;; A module is a directory, `modules/<group>/<name>/', written
;; `:group name' (e.g. `modules/completion/vertico/' is
;; `:completion vertico'). Every file in it is optional:
;;
;;   packages.el  `package!' declarations only -- what to install
;;   autoload.el  commands and helpers other files may call
;;   init.el      runs early, before any module's config.el
;;   config.el    the module's actual configuration
;;
;; Your `init.el' enables modules with a `hellmacs!' block:
;;
;;   (hellmacs! :ui theme
;;              :completion vertico (corfu +tab)
;;              :config default)
;;
;; `bin/hellmacs sync' (`hellmacs-sync') reads every enabled module's
;; packages.el, then yours, installs those packages, and records a
;; profile of them (see "Synced profile" below). Startup then:
;;
;;   1. activates the packages from that profile -- or, if it's missing
;;      or out of date, reads the packages.el files and installs and
;;      activates the packages through Elpaca right away
;;   2. loads each module's autoload.el and init.el, in order
;;   3. loads each module's config.el, in order
;;
;; after which `init.el' at the repo root loads your config.el.
;;
;; Modules in `hellmacs-user-dir'/modules/ take precedence over
;; Hellmacs' own, so you can override one by copying it there.

;;; Code:

(require 'use-package)

;;; Variables --------------------------------------------------------------

(defvar hellmacs-module-load-path
  (list (expand-file-name "modules/" hellmacs-user-dir)
        hellmacs-modules-dir)
  "Directories searched for modules, highest priority first.
Each contains <group>/<name>/ module directories.")

(defvar hellmacs-modules (make-hash-table :test #'equal)
  "Enabled modules: a table of (GROUP . NAME) -> plist.
The plist holds :path, :flags, :depth and :index. Populated by
`hellmacs!'; use `hellmacs-module-list' for load order.")

(defvar hellmacs-packages nil
  "Declared packages: an alist of (NAME . PLIST), filled in by `package!'.")

(defvar hellmacs--current-module nil
  "The (GROUP . NAME) of the module whose files are being loaded.
Used by `modulep!' and `package!' to know which module they're in.")

(defvar hellmacs--initial-load-path) ; set in early-init.el

;;; Enabling modules: hellmacs! ------------------------------------------

(defun hellmacs-module-locate-path (group name)
  "Return the directory of module GROUP NAME, or nil if it doesn't exist."
  (let ((rel (format "%s/%s/" (substring (symbol-name group) 1) name)))
    (seq-some (lambda (dir)
                (let ((path (expand-file-name rel dir)))
                  (and (file-directory-p path) path)))
              hellmacs-module-load-path)))

(defun hellmacs-module-enable (group name &optional flags depth)
  "Enable module GROUP NAME with FLAGS (a list of +symbols) at DEPTH.
Modules load in ascending DEPTH (default 0), then in the order they
were enabled. Returns nil (and warns) if the module doesn't exist."
  (if-let* ((path (hellmacs-module-locate-path group name)))
      (puthash (cons group name)
               (list :path path
                     :flags flags
                     :depth (or depth 0)
                     :index (hash-table-count hellmacs-modules))
               hellmacs-modules)
    (display-warning 'hellmacs (format "Unknown module %s %s, skipped" group name))
    nil))

(defmacro hellmacs! (&rest modules)
  "Enable MODULES, in order. Use it once, in your init.el.

MODULES is a list of groups (keywords), each followed by the modules
in that group. A module is a symbol, or a list whose first element is
the module name, followed by +flags and an optional `:depth N':

  (hellmacs! :ui theme
             :editor undo
             :completion vertico (corfu +tab)
             :config (default :depth -10))

See `modulep!' for testing modules and flags from code."
  `(hellmacs--enable-modules ',modules))

(defun hellmacs--enable-modules (spec)
  "Enable every module in SPEC, the argument list of `hellmacs!'."
  (clrhash hellmacs-modules)
  (let (group)
    (dolist (item spec)
      (cond ((keywordp item)
             (setq group item))
            ((null group)
             (user-error "hellmacs!: module `%s' comes before any :group" item))
            ((symbolp item)
             (hellmacs-module-enable group item))
            ((consp item)
             (let ((name (car item)) flags depth (rest (cdr item)))
               (while rest
                 (let ((x (pop rest)))
                   (if (eq x :depth)
                       (setq depth (pop rest))
                     (push x flags))))
               (hellmacs-module-enable group name (nreverse flags) depth)))))))

(defun hellmacs-module-list ()
  "Return the keys of enabled modules, in load order."
  (let (keys)
    (maphash (lambda (k _) (push k keys)) hellmacs-modules)
    (sort keys (lambda (a b)
                 (let ((pa (gethash a hellmacs-modules))
                       (pb (gethash b hellmacs-modules)))
                   (if (= (plist-get pa :depth) (plist-get pb :depth))
                       (< (plist-get pa :index) (plist-get pb :index))
                     (< (plist-get pa :depth) (plist-get pb :depth))))))))

(defun hellmacs-module-get (key prop)
  "Return PROP of the enabled module KEY, a (GROUP . NAME) cons."
  (plist-get (gethash key hellmacs-modules) prop))

;;; Querying modules: modulep! ---------------------------------------------

(defun hellmacs-module-p (group name &optional flags)
  "Return non-nil if module GROUP NAME is enabled with all FLAGS.
A flag written -foo means +foo must NOT be enabled."
  (when-let* ((plist (gethash (cons group name) hellmacs-modules)))
    (let ((enabled (plist-get plist :flags)))
      (seq-every-p
       (lambda (flag)
         (let ((s (symbol-name flag)))
           (if (string-prefix-p "-" s)
               (not (memq (intern (concat "+" (substring s 1))) enabled))
             (memq flag enabled))))
       flags))))

(defmacro modulep! (&rest args)
  "Return non-nil if a module (and optionally its flags) is enabled.

  (modulep! :completion corfu)        ; is the module enabled?
  (modulep! :completion corfu +tab)   ; ...with the +tab flag?
  (modulep! :completion corfu -tab)   ; ...without it?

Inside a module's own files, the group and name can be left out:

  (modulep! +tab)"
  (let ((key (if (keywordp (car args))
                 (cons (pop args) (pop args))
               (or hellmacs--current-module
                   (error "modulep!: no module given, and not inside a module")))))
    `(hellmacs-module-p ',(car key) ',(cdr key) ',args)))

;;; Declaring packages: package! -------------------------------------------

(defmacro package! (name &rest plist)
  "Declare that package NAME should be installed. Use it in packages.el.

This only records the declaration; installing happens later, all at
once. Configure the package separately, with `use-package' in a
config.el. PLIST accepts:

  :recipe PLIST   an Elpaca recipe (:host github :repo \"user/repo\" ...)
                  for packages not on (M)ELPA, or to change its source
  :pin REF        a commit, tag or branch to install
  :built-in BOOL  don't install; Emacs provides it. \\='prefer means
                  install only if this Emacs doesn't have it built in
  :disable BOOL   don't install it, and ignore every `use-package'
                  block for it (to switch off a module's package from
                  your own packages.el)

A later declaration of the same package is merged over an earlier
one, so your packages.el (read last) can change a module's."
  (declare (indent defun))
  ;; A literal recipe like (:host github ...) must not be evaluated as
  ;; a function call; other values (e.g. \='prefer) are evaluated.
  (let ((recipe (plist-get plist :recipe)))
    (when (keywordp (car-safe recipe))
      (setq plist (plist-put (copy-sequence plist) :recipe `',recipe))))
  `(hellmacs-package-declare ',name (list ,@plist)))

(defun hellmacs-package-declare (name plist)
  "Record PLIST for package NAME in `hellmacs-packages'. See `package!'."
  (let* ((old (alist-get name hellmacs-packages))
         (new (copy-sequence old)))
    (cl-loop for (k v) on plist by #'cddr
             do (setq new (plist-put new k v)))
    (setq new (plist-put new :modules
                         (append (plist-get old :modules)
                                 (list (or hellmacs--current-module :user)))))
    (setf (alist-get name hellmacs-packages) new)
    name))

(defun hellmacs-package-built-in-p (name)
  "Return non-nil if package NAME ships with this Emacs."
  (locate-library (symbol-name name) nil hellmacs--initial-load-path))

(defun hellmacs-package-disabled-p (name)
  "Return non-nil if package NAME was declared with `:disable'."
  (plist-get (alist-get name hellmacs-packages) :disable))

(defun hellmacs-package--order (name plist)
  "Return the Elpaca order for package NAME with `package!' PLIST, or nil.
Nil means the package shouldn't be installed."
  (let ((built-in (plist-get plist :built-in)))
    (unless (or (plist-get plist :disable)
                (eq built-in t)
                (and (eq built-in 'prefer) (hellmacs-package-built-in-p name)))
      (let ((recipe (copy-sequence (plist-get plist :recipe))))
        (when-let* ((pin (plist-get plist :pin)))
          (setq recipe (plist-put recipe :ref pin)))
        (if recipe (cons name recipe) name)))))

;; `:disable' also has to silence the package's configuration, which
;; lives in some module's `use-package' block, so the block would
;; otherwise try to load a package that was never installed.
(defun hellmacs--use-package-disabled-a (fn name &rest args)
  "Expand to nothing if package NAME was disabled with `package!'."
  (unless (hellmacs-package-disabled-p name)
    (apply fn name args)))
(advice-add 'use-package :around #'hellmacs--use-package-disabled-a)

;;; Loading ----------------------------------------------------------------

(defun hellmacs-load-user-file (name)
  "Load NAME from `hellmacs-user-dir', if it exists.
Errors are reported as warnings instead of aborting startup, so a typo
in your config leaves you with a working editor to fix it in."
  (let ((file (expand-file-name name hellmacs-user-dir)))
    (when (file-exists-p file)
      (condition-case-unless-debug err
          (load file nil 'nomessage 'nosuffix)
        (error
         (display-warning
          'hellmacs (format "Error loading %s: %s"
                            (abbreviate-file-name file) (error-message-string err))
          :error))))))

(defun hellmacs-module--load (key file)
  "Load FILE from module KEY's directory, if it exists.
Errors warn instead of aborting startup: one broken module should
degrade Hellmacs, not brick it."
  (let ((path (expand-file-name file (hellmacs-module-get key :path))))
    (when (file-exists-p path)
      (let ((hellmacs--current-module key))
        (with-hellmacs-context 'module
          (condition-case-unless-debug err
              (load path nil 'nomessage 'nosuffix)
            (error
             (display-warning
              'hellmacs (format "Module %s %s: error in %s: %s"
                                (car key) (cdr key) file (error-message-string err))
              :error))))))))

(defun hellmacs-modules-read-config ()
  "Enable modules from the user's init.el (its `hellmacs!' block).
Without a user init.el, or without a `hellmacs!' call in it, the
defaults in static/init.example.el apply."
  (hellmacs--enable-modules nil)
  (hellmacs-load-user-file "init.el")
  (when (zerop (hash-table-count hellmacs-modules))
    (load (expand-file-name "static/init.example.el" hellmacs-dir) nil 'nomessage 'nosuffix)))

(defun hellmacs-modules-read-packages ()
  "Read core/packages.el, every enabled module's packages.el, then the user's.
Fills `hellmacs-packages'."
  (setq hellmacs-packages nil)
  (let ((hellmacs--current-module :core))
    (load (expand-file-name "packages.el" hellmacs-core-dir) nil 'nomessage 'nosuffix))
  (dolist (key (hellmacs-module-list))
    (hellmacs-module--load key "packages.el"))
  (hellmacs-load-user-file "packages.el"))

(defvar hellmacs-lock-file (expand-file-name "packages.lock.eld" hellmacs-user-dir)
  "Exact commits of every installed package, written by `bin/hellmacs lock'.
When it exists, packages are installed at these commits instead of the
latest ones, so a config can be reproduced on another machine. It sits
next to your config so you can version it together. `bin/hellmacs
upgrade' rewrites it after updating.")

(defun hellmacs-modules-install-packages (&optional ignore-lock)
  "Read every packages.el, then install and activate the declared packages.
Loads Elpaca, and blocks until it has finished, so module config can
use the packages. Uses `hellmacs-lock-file' unless IGNORE-LOCK."
  (hellmacs-packages-bootstrap)
  (defvar elpaca-lock-file)
  (setq elpaca-lock-file (and (not ignore-lock)
                              (file-exists-p hellmacs-lock-file)
                              hellmacs-lock-file))
  (hellmacs-modules-read-packages)
  (pcase-dolist (`(,name . ,plist) (reverse hellmacs-packages))
    (when-let* ((order (hellmacs-package--order name plist)))
      (eval `(elpaca ,order) t)))
  (hellmacs--elpaca-wait))

(defvar hellmacs-elpaca-stall-timeout 30
  "Seconds of no progress, with only blocked packages left, before giving up.")

(defun hellmacs--elpaca-wait ()
  "Like `elpaca-wait', but give up if Elpaca stops making progress.
Elpaca can leave packages blocked forever on a dependency whose build
failed (see core/packages.el), and `elpaca-wait' then never returns.
A watchdog notices when every unfinished package has been blocked,
unchanged, for `hellmacs-elpaca-stall-timeout' seconds, and interrupts
the wait; Elpaca then marks those packages failed."
  (let* ((last nil)
         (since (float-time))
         (watchdog
          (run-with-timer
           5 5
           (lambda ()
             (let* ((statuses (mapcar (lambda (q) (elpaca<-status (cdr q))) (elpaca--queued)))
                    (pending (seq-remove (lambda (s) (memq s '(finished failed))) statuses)))
               (cond ((not (equal statuses last))
                      (setq last statuses since (float-time)))
                     ((and pending
                           (seq-every-p (lambda (s) (eq s 'blocked)) pending)
                           (> (- (float-time) since) hellmacs-elpaca-stall-timeout))
                      (display-warning
                       'hellmacs
                       (format "Elpaca stalled with %d package(s) blocked; giving up on them. \
Running the sync again usually finishes the job." (length pending)))
                      ;; Picked up by `elpaca-wait''s loop as a keyboard quit,
                      ;; which fails the unfinished packages and returns.
                      (setq quit-flag t))))))))
    (unwind-protect
        ;; Failing a package signals; callers check statuses afterwards
        ;; (see `hellmacs-sync'), which reports every failure, not just one.
        (condition-case nil (elpaca-wait)
          (elpaca-build-error nil))
      (cancel-timer watchdog))))

;;; Synced profile ---------------------------------------------------------
;;
;; `hellmacs-sync' (bin/hellmacs sync) installs every declared package,
;; then records what startup needs in a profile: the packages' build
;; directories and autoload files, in dependency order, plus loaddefs
;; generated from modules' autoload.el files. A startup that finds an
;; up-to-date profile just replays it, without loading Elpaca or reading
;; any packages.el.
;;
;; The profile is out of date when the enabled modules or their flags
;; change, when any packages.el or autoload.el involved changes, when a
;; recorded build directory disappears, or when Emacs is upgraded. Then
;; startup falls back to installing/activating live through Elpaca, and
;; warns that a sync is due.

(defvar hellmacs-profile-dir (expand-file-name "profiles/default/" hellmacs-data-dir)
  "Where `hellmacs-sync' writes the generated profile.")

(defun hellmacs-profile-file (name)
  "Return the path of file NAME in `hellmacs-profile-dir'."
  (expand-file-name name hellmacs-profile-dir))

(defun hellmacs-profile--modules ()
  "Describe the enabled modules for staleness checks: key, flags, path."
  (mapcar (lambda (key)
            (list key (hellmacs-module-get key :flags) (hellmacs-module-get key :path)))
          (hellmacs-module-list)))

(defun hellmacs-profile--inputs ()
  "Return the files a profile depends on, each paired with its mtime.
The mtime is nil for files that don't exist, so creating one counts
as a change too."
  (mapcar (lambda (file)
            (cons file (when-let* ((attrs (file-attributes file)))
                         (float-time (file-attribute-modification-time attrs)))))
          (cl-list* (expand-file-name "packages.el" hellmacs-core-dir)
                    (expand-file-name "packages.el" hellmacs-user-dir)
                    (cl-loop for key in (hellmacs-module-list)
                             for dir = (hellmacs-module-get key :path)
                             collect (expand-file-name "packages.el" dir)
                             collect (expand-file-name "autoload.el" dir)))))

(defun hellmacs-profile--stale-reason (profile)
  "Return why PROFILE doesn't match the current config, or nil if it does."
  (cond ((not (equal (plist-get profile :emacs-version) emacs-version))
         (format "Emacs changed from %s to %s" (plist-get profile :emacs-version) emacs-version))
        ((not (equal (plist-get profile :modules) (hellmacs-profile--modules)))
         "the enabled modules changed")
        ((not (equal (plist-get profile :inputs) (hellmacs-profile--inputs)))
         (let ((changed (seq-difference (hellmacs-profile--inputs) (plist-get profile :inputs))))
           (format "%s changed" (abbreviate-file-name (car (car changed))))))
        ((seq-find (lambda (dir) (not (file-directory-p dir))) (plist-get profile :load-path))
         "an installed package is missing")))

(defun hellmacs-profile-read ()
  "Return the synced profile's data, or nil if it's missing or unreadable."
  (let ((file (hellmacs-profile-file "profile.eld")))
    (when (file-exists-p file)
      (with-temp-buffer
        (insert-file-contents file)
        (ignore-errors (read (current-buffer)))))))

(defun hellmacs-profile-activate ()
  "Activate packages from the synced profile, if it is up to date.
Return non-nil on success. On failure, say why (unless there's no
profile at all) and return nil; the caller activates live instead."
  (let* ((file (hellmacs-profile-file "profile.eld"))
         (profile (hellmacs-profile-read))
         (reason (if profile
                     (hellmacs-profile--stale-reason profile)
                   (unless (file-exists-p file) 'none))))
    (cond ((null profile)
           (unless (eq reason 'none)
             (display-warning 'hellmacs "The synced profile is unreadable; run `bin/hellmacs sync'."))
           nil)
          (reason
           (display-warning
            'hellmacs
            (format "Your config changed since the last sync (%s). \
Packages were activated directly, which is slower and may install \
packages now. Run `bin/hellmacs sync' to fix." reason))
           nil)
          (t
           (setq hellmacs-packages (plist-get profile :packages))
           (dolist (dir (reverse (plist-get profile :load-path)))
             (add-to-list 'load-path dir))
           (dolist (file (plist-get profile :autoloads))
             (load file 'noerror 'nomessage 'nosuffix))
           (load (hellmacs-profile-file "module-autoloads.el") 'noerror 'nomessage 'nosuffix)
           t))))

;;; Startup ----------------------------------------------------------------

(defun hellmacs--run-packages-ready-h ()
  "Run `hellmacs--packages-ready-hook'."
  (run-hooks 'hellmacs--packages-ready-hook))

(defun hellmacs-modules-startup ()
  "Activate enabled modules' packages, then load the modules.
Uses the synced profile when it is up to date; otherwise installs and
activates packages through Elpaca. See the commentary at the top of
this file for the order."
  (let ((synced (hellmacs-profile-activate)))
    (if synced
        (add-hook 'after-init-hook #'hellmacs--run-packages-ready-h 90)
      (hellmacs-modules-install-packages)
      (add-hook 'elpaca-after-init-hook #'hellmacs--run-packages-ready-h))
    (let ((modules (hellmacs-module-list)))
      (dolist (key modules)
        ;; A synced profile has these as autoloads already.
        (unless synced
          (hellmacs-module--load key "autoload.el"))
        (hellmacs-module--load key "init.el"))
      (dolist (key modules)
        (hellmacs-module--load key "config.el")))))

(autoload 'hellmacs-sync "hellmacs-sync"
  "Install every declared package, then write the synced profile." t)

(provide 'hellmacs-modules)
;;; hellmacs-modules.el ends here
