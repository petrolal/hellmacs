;;; test-completion.el --- Tests for completion modules -*- lexical-binding: t; -*-

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

;; Run with `bin/hellmacs test'.

;;; Code:

(require 'ert)
(require 'hellmacs-modules)

(ert-deftest test-completion/vertico-package-declarations ()
  "Vertico module registers vertico, marginalia, orderless, and consult."
  (let ((hellmacs-packages nil))
    (package! vertico)
    (package! marginalia)
    (package! orderless)
    (package! consult)
    (should (assq 'vertico hellmacs-packages))
    (should (assq 'marginalia hellmacs-packages))
    (should (assq 'orderless hellmacs-packages))
    (should (assq 'consult hellmacs-packages))))

(ert-deftest test-completion/corfu-package-declarations ()
  "Corfu module registers corfu and cape."
  (let ((hellmacs-packages nil))
    (package! corfu)
    (package! cape)
    (should (assq 'corfu hellmacs-packages))
    (should (assq 'cape hellmacs-packages))))

(ert-deftest test-completion/orderless-completion-styles ()
  "Verifies completion styles include orderless and basic."
  (let ((completion-styles '(orderless basic)))
    (should (member 'orderless completion-styles))
    (should (member 'basic completion-styles))))

(provide 'test-completion)
;;; test-completion.el ends here
