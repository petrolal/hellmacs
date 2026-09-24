;;; ui/modeline/doctor.el -*- lexical-binding: t; no-byte-compile: t; -*-

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


;; Checked by `bin/hellmacs doctor'. Hellmacs never installs fonts, so a
;; missing Nerd Font is reported with the command that installs one.

(let ((families (and (executable-find "fc-list")
                     (ignore-errors
                       (process-lines "fc-list" ":charset=f07b" "family")))))
  (cond ((not (executable-find "fc-list"))
         (hellmacs-doctor-info "fc-list not found; can't tell whether a Nerd Font is installed"))
        (families
         (hellmacs-doctor-ok "Nerd Font glyphs: %s" (car (split-string (car families) ","))))
        (t
         (hellmacs-doctor-warn "No Nerd Font installed: the mode-line shows text instead of icons. Install one with M-x nerd-icons-install-fonts (into ~/.local/share/fonts), or from your distribution"))))
