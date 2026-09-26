;;; test-http.el --- Tests for :tools http module (Phase 12.6) -*- lexical-binding: t; -*-

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

(ert-deftest test-http/parse-http-request-block ()
  "Parses standard IntelliJ .http / REST Client request syntax."
  (let ((request-block "### Get User Details
GET https://api.example.com/users/42
Accept: application/json
Authorization: Bearer {{token}}

### Create User
POST https://api.example.com/users
Content-Type: application/json

{
  \"name\": \"Hellmacs Developer\",
  \"email\": \"dev@hellmacs.org\"
}"))
    (with-temp-buffer
      (insert request-block)
      (goto-char (point-min))
      (should (search-forward "### Get User Details" nil t))
      (should (search-forward "GET https://api.example.com/users/42" nil t))
      (should (search-forward "Accept: application/json" nil t))
      (should (search-forward "### Create User" nil t))
      (should (search-forward "POST https://api.example.com/users" nil t)))))

(ert-deftest test-http/keymap-execution ()
  "Verifies key binding for executing HTTP requests under point."
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") 'hellmacs-http-send-request)
    (should (eq (lookup-key map (kbd "C-c C-c")) 'hellmacs-http-send-request))))

(provide 'test-http)
;;; test-http.el ends here
