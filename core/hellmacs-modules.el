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
;; Startup then runs these steps (see `hellmacs-modules-startup'):
;;
;;   1. read every enabled module's packages.el, then yours
;;   2. install and activate those packages (Elpaca), and wait
;;   3. load each module's autoload.el and init.el, in order
;;   4. load each module's config.el, in order
;;
;; after which `init.el' at the repo root loads your config.el.
;;
;; Modules in `hellmacs-user-dir'/modules/ take precedence over
;; Hellmacs' own, so you can override one by copying it there.
;;
;; Phase 3 of docs/roadmap.md will move steps 1-2 out of startup and
;; into a `hellmacs sync' command; the file layout won't change.

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

(defun hellmacs-modules-install-packages ()
  "Read every packages.el, then install and activate the declared packages.
Blocks until Elpaca has finished, so module config can use them."
  (setq hellmacs-packages nil)
  (dolist (key (hellmacs-module-list))
    (hellmacs-module--load key "packages.el"))
  (hellmacs-load-user-file "packages.el")
  (pcase-dolist (`(,name . ,plist) (reverse hellmacs-packages))
    (when-let* ((order (hellmacs-package--order name plist)))
      (eval `(elpaca ,order) t)))
  (elpaca-wait))

(defun hellmacs-modules-startup ()
  "Install enabled modules' packages, then load the modules.
See the commentary at the top of this file for the order."
  (hellmacs-modules-install-packages)
  (let ((modules (hellmacs-module-list)))
    (dolist (key modules)
      (hellmacs-module--load key "autoload.el")
      (hellmacs-module--load key "init.el"))
    (dolist (key modules)
      (hellmacs-module--load key "config.el"))))

(provide 'hellmacs-modules)
;;; hellmacs-modules.el ends here
