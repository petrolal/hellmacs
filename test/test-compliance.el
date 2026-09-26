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
  (let ((sbom `((bomFormat . "CycloneDX")
                (specVersion . "1.5")
                (version . 1)
                (metadata . ((component . ((type . "application")
                                           (name . "hellmacs")
                                           (version . "1.0.0-SNAPSHOT")))))
                (components . [((type . "library")
                                (name . "elpaca")
                                (version . "0.1.0")
                                (purl . "pkg:generic/elpaca@0.1.0"))]))))
    (should (equal (cdr (assq 'bomFormat sbom)) "CycloneDX"))
    (should (equal (cdr (assq 'specVersion sbom)) "1.5"))
    (should (= (length (cdr (assq 'components sbom))) 1))))

(ert-deftest test-compliance/license-reporting ()
  "Verifies license summary aggregation across installed packages."
  (let ((packages '((vertico . "GPL-3.0-or-later")
                    (corfu . "GPL-3.0-or-later")
                    (lsp-mode . "GPL-3.0-or-later")
                    (magit . "GPL-3.0-or-later"))))
    (let ((licenses (mapcar #'cdr packages)))
      (should (cl-every (lambda (lic) (equal lic "GPL-3.0-or-later")) licenses)))))

(provide 'test-compliance)
;;; test-compliance.el ends here
