;;; config/default/autoload.el -*- lexical-binding: t; -*-

;; Commands behind the `C-c h' (Hellmacs) group.

;;;###autoload
(defun hellmacs-reload ()
  "Reload Hellmacs' init file, and with it your init.el and config.el."
  (interactive)
  (with-hellmacs-context 'reload
    (load-file (expand-file-name "init.el" hellmacs-dir))))

;;;###autoload
(defun hellmacs-visit-dir ()
  "Open a Dired buffer at the Hellmacs install directory."
  (interactive)
  (dired hellmacs-dir))

;;;###autoload
(defun hellmacs-init-user-dir ()
  "Create `hellmacs-user-dir' with starter init.el, packages.el and config.el.
Existing files are never overwritten."
  (interactive)
  (make-directory hellmacs-user-dir t)
  (dolist (name '("init.el" "packages.el" "config.el"))
    (let ((file (expand-file-name name hellmacs-user-dir)))
      (unless (file-exists-p file)
        (copy-file (expand-file-name (concat "static/" (file-name-base name) ".example.el")
                                     hellmacs-dir)
                   file))))
  ;; `custom-file' was put in the state dir because there was no user
  ;; dir at startup; from now on it belongs here.
  (setq custom-file (expand-file-name "custom.el" hellmacs-user-dir))
  (message "Hellmacs user config is in %s" (abbreviate-file-name hellmacs-user-dir)))

;;;###autoload
(defun hellmacs-visit-user-dir ()
  "Open a Dired buffer at your Hellmacs config (`hellmacs-user-dir').
Offers to create it with starter files if it doesn't exist yet."
  (interactive)
  (unless (file-directory-p hellmacs-user-dir)
    (if (y-or-n-p (format "%s doesn't exist. Create it? "
                          (abbreviate-file-name hellmacs-user-dir)))
        (hellmacs-init-user-dir)
      (user-error "No user config directory")))
  (dired hellmacs-user-dir))

;;;###autoload
(defun hellmacs-list-modules ()
  "Display the enabled Hellmacs modules, in load order, with their flags."
  (interactive)
  (message "Hellmacs modules: %s"
           (mapconcat (lambda (key)
                        (string-join
                         (mapcar #'symbol-name
                                 (append (list (car key) (cdr key))
                                         (hellmacs-module-get key :flags)))
                         " "))
                      (hellmacs-module-list)
                      ", ")))
