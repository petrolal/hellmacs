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
