;;; <group>/<name>/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; What this module installs. Declarations only -- no configuration,
;; no side effects: this file is read before anything is installed.
;; See `package!' for the options (:recipe, :pin, :built-in, :disable).
;; Changes here take effect after `bin/hellmacs sync'.

(package! example-package)

;; Only needed with the module's +extra flag:
(when (modulep! +extra)
  (package! example-extra))
