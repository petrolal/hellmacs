;;; core/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Packages Hellmacs' core declares for every configuration, read before
;; any module's packages.el (as Doom's lisp/packages.el is).
;;
;; `compat' is a dependency of most modern packages (vertico, consult,
;; corfu, marginalia, orderless, ...). Declaring it here, up front,
;; makes Elpaca build it once as a top-level package. Left to be
;; discovered as a dependency, several packages queue it at the same
;; moment on a fresh install, Elpaca starts building it twice, the
;; second build fails, and the packages waiting on it never finish.
(package! compat)
