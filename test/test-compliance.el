;;; test-compliance.el --- Tests for SBOM and license reporting (Phase 12.9) -*- lexical-binding: t; -*-

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
(require 'cl-lib)

(ert-deftest test-compliance/cyclonedx-sbom-structure ()
  "Generates valid CycloneDX SBOM JSON representation."
  (let ((sbom (hellmacs-compliance-cyclonedx-sbom)))
    (should (equal (cdr (assq 'bomFormat sbom)) "CycloneDX"))
    (should (equal (cdr (assq 'specVersion sbom)) "1.5"))
    (should (vectorp (cdr (assq 'components sbom))))))

(ert-deftest test-compliance/license-reporting ()
  "Verifies license summary aggregation across installed packages."
  (let ((report (hellmacs-compliance-collect-licenses)))
    (should (listp report))
    (should (cl-every (lambda (entry) (stringp (cdr entry))) report))))

(provide 'test-compliance)
;;; test-compliance.el ends here
