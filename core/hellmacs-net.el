;;; hellmacs-net.el --- Proxies, corporate CAs and mirrors -*- lexical-binding: t; -*-

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

;; Every connection Hellmacs itself makes, set up for a corporate network.
;; In your init.el:
;;
;;   (setq hellmacs-proxy "http://proxy.corp.example:3128")  ; nil: $HTTPS_PROXY, $HTTP_PROXY
;;   (setq hellmacs-no-proxy '("localhost" ".corp.example"))  ; nil: $NO_PROXY
;;   (setq hellmacs-ca-bundle "~/certs/corp-root-ca.pem")     ; your company's root CA
;;   (setq hellmacs-mirrors                                  ; upstream prefix -> mirror prefix
;;         '(("https://github.com/" . "https://git.corp.example/github/")
;;           ("https://repo1.maven.org/maven2/" . "https://artifactory.corp.example/maven-central/")))
;;
;; The proxy and the CA apply to all of Emacs (url.el and GnuTLS): a proxy
;; is how the network works, and trusting one more CA takes nothing away.
;; Mirrors apply only while Hellmacs itself fetches (`with-hellmacs-network':
;; sync, upgrade, package and server installs), to url.el and to git; they
;; never touch your own repositories. Downloads stay pinned by SHA-256, so a
;; mirror can't serve a different file.
;;
;; Git gets its settings through GIT_CONFIG_* variables (git 2.31+), so the
;; git processes Elpaca starts inherit them: the proxy, a CA bundle (git
;; replaces its trusted CAs with the file it's given, so it gets the system's
;; and yours combined), and each mirror as a `url.<mirror>.insteadOf' rule.

;;; Code:

(require 'cl-lib)
(require 'seq)
(require 'subr-x)
(require 'hellmacs-lib)

(defvar url-proxy-services)
(defvar gnutls-trustfiles)

(defvar hellmacs-proxy nil
  "The HTTP(S) proxy, as a URL (\"http://proxy.corp.example:3128\").
nil uses $HTTPS_PROXY or $HTTP_PROXY, as `bin/hellmacs env' saved them.")

(defvar hellmacs-no-proxy nil
  "Hosts reached without `hellmacs-proxy': names, or \".domain\" suffixes.
nil uses $NO_PROXY.")

(defvar hellmacs-ca-bundle nil
  "A PEM file with your company's root CA(s), trusted on top of the system's.")

(defvar hellmacs-mirrors nil
  "Alist of (UPSTREAM-PREFIX . MIRROR-PREFIX), for Hellmacs' own fetches.
A URL starting with UPSTREAM-PREFIX is fetched from MIRROR-PREFIX
instead, with the rest of the URL kept. One table covers Artifactory's
and Nexus' GitHub, Maven and generic remote repositories.")

;;; The settings in effect ------------------------------------------------------

(defun hellmacs-net-proxy ()
  "The proxy URL in use: `hellmacs-proxy', else the environment's, or nil."
  (or hellmacs-proxy
      (seq-some (lambda (var)
                  (let ((value (getenv var)))
                    (and value (not (string-empty-p value)) value)))
                '("HTTPS_PROXY" "https_proxy" "HTTP_PROXY" "http_proxy"))))

(defun hellmacs-net-no-proxy ()
  "The hosts reached directly: `hellmacs-no-proxy', else $NO_PROXY's."
  (or hellmacs-no-proxy
      (when-let* ((value (or (getenv "NO_PROXY") (getenv "no_proxy"))))
        (split-string value "[, \t]+" t))))

(defun hellmacs-net-rewrite (url)
  "URL, fetched through its mirror in `hellmacs-mirrors' if it has one."
  (or (seq-some (pcase-lambda (`(,from . ,to))
                  (and (string-prefix-p from url)
                       (concat to (substring url (length from)))))
                hellmacs-mirrors)
      url))

(defun hellmacs-net--host-port (proxy)
  "\"host:port\" of PROXY, a URL, as url.el wants it."
  (require 'url-parse)
  (let ((url (url-generic-parse-url (if (string-match-p "://" proxy) proxy (concat "http://" proxy)))))
    (format "%s:%d" (url-host url) (url-port url))))

(defun hellmacs-net--no-proxy-regexp (hosts)
  "A regexp matching the host names HOSTS describe, for url.el's no_proxy.
\"corp.example\" or \".corp.example\" matches it and every subdomain; \"*\" all."
  (if (member "*" hosts)
      "."
    (concat "\\`\\(?:"
            (mapconcat (lambda (host)
                         (let ((domain (regexp-quote (string-remove-prefix "." host))))
                           (concat "\\(?:.*\\.\\)?" domain)))
                       hosts "\\|")
            "\\)\\'")))

;;; A CA bundle for git and the JVMs ---------------------------------------------

(defvar hellmacs-net-ca-file (expand-file-name "ca-bundle.pem" hellmacs-data-dir)
  "Where the system's CAs and `hellmacs-ca-bundle' are combined, for git.")

(defconst hellmacs-net--system-ca-files
  '("/etc/ssl/certs/ca-certificates.crt"          ; Debian, Ubuntu, Arch, Alpine
    "/etc/pki/tls/certs/ca-bundle.crt"            ; Fedora, RHEL
    "/etc/ssl/ca-bundle.pem"                      ; openSUSE
    "/etc/ssl/cert.pem"                           ; macOS, BSDs
    "/opt/homebrew/etc/openssl@3/cert.pem" "/usr/local/etc/openssl@3/cert.pem")
  "Where operating systems keep their trusted CAs, as one PEM file.")

(defun hellmacs-net-ca-file ()
  "The combined CA bundle (the system's and `hellmacs-ca-bundle'), or nil.
Written again whenever a file it's made from is newer."
  (when hellmacs-ca-bundle
    (let* ((ca (expand-file-name hellmacs-ca-bundle))
           (system (seq-find #'file-readable-p hellmacs-net--system-ca-files))
           (sources (delq nil (list system ca))))
      (unless (file-readable-p ca)
        (error "`hellmacs-ca-bundle' is %s, which can't be read" (abbreviate-file-name ca)))
      (unless (and (file-exists-p hellmacs-net-ca-file)
                   (seq-every-p (lambda (f) (file-newer-than-file-p hellmacs-net-ca-file f)) sources))
        (make-directory (file-name-directory hellmacs-net-ca-file) t)
        (with-temp-file hellmacs-net-ca-file
          (dolist (f sources)
            (insert-file-contents f)
            (goto-char (point-max))
            (insert "\n"))))
      hellmacs-net-ca-file)))

;;; The JVMs: a truststore, and -D options ------------------------------------------
;;
;; JVMs don't read GnuTLS' trust files or $HTTPS_PROXY. They get a truststore
;; of their own -- the JDK's CAs plus yours, built by sync with the JDK's
;; keytool -- and system properties: `hellmacs-net-jvm-options', which the
;; JVM modules hand to JDTLS, kotlin-language-server and Gradle/Maven runs.
;; (Maven reads its proxy from your settings.xml, never from these.)

(defvar hellmacs-net-truststore (expand-file-name "jvm/truststore.p12" hellmacs-data-dir)
  "The JVMs' truststore: the JDK's CAs and `hellmacs-ca-bundle''s, built by sync.")

(defconst hellmacs-net--truststore-password "changeit"
  "The truststore's password: the JDK's own, since it only holds public certificates.")

(defun hellmacs-net-java-home ()
  "The JDK whose CAs and keytool the truststore comes from: $JAVA_HOME, else `java''s."
  (or (let ((home (getenv "JAVA_HOME"))) (and home (not (string-empty-p home)) home))
      (when-let* ((java (executable-find "java")))
        (file-name-directory (directory-file-name (file-name-directory (file-truename java)))))))

(defun hellmacs-net--jdk-cacerts ()
  (when-let* ((home (hellmacs-net-java-home)))
    (let ((file (expand-file-name "lib/security/cacerts" home)))
      (and (file-readable-p file) file))))

(defun hellmacs-net-truststore-current-p ()
  "Non-nil if the truststore exists and is newer than the CAs it's made from."
  (and hellmacs-ca-bundle
       (file-exists-p hellmacs-net-truststore)
       (seq-every-p (lambda (f) (file-newer-than-file-p hellmacs-net-truststore f))
                    (delq nil (list (expand-file-name hellmacs-ca-bundle) (hellmacs-net--jdk-cacerts))))))

(defun hellmacs-net--pem-certificates (file)
  "The certificates in PEM FILE, each as a string."
  (with-temp-buffer
    (insert-file-contents file)
    (let (certs)
      (while (re-search-forward "^-----BEGIN CERTIFICATE-----\n\\(?:.*\n\\)*?-----END CERTIFICATE-----$" nil t)
        (push (match-string 0) certs))
      (nreverse certs))))

(defun hellmacs-net-build-truststore ()
  "Build `hellmacs-net-truststore' from the JDK's CAs and `hellmacs-ca-bundle''s.
Written next to its place and moved there once complete. Signals an
error saying what's missing (a JDK, its keytool, a readable CA)."
  (let* ((home (or (hellmacs-net-java-home) (error "No JDK found (JAVA_HOME or java on the PATH) to build the truststore with")))
         (keytool (expand-file-name "bin/keytool" home))
         (cacerts (or (hellmacs-net--jdk-cacerts) (error "The JDK in %s has no lib/security/cacerts" home)))
         (ca (expand-file-name hellmacs-ca-bundle))
         (certs (hellmacs-net--pem-certificates ca))
         (tmp (concat hellmacs-net-truststore ".part"))
         (pem (make-temp-file "hellmacs-ca" nil ".pem"))
         (run (lambda (&rest args)
                (with-temp-buffer
                  (unless (zerop (apply #'call-process keytool nil t nil args))
                    (error "keytool %s failed: %s" (car args) (string-trim (buffer-string))))))))
    (unless (file-executable-p keytool) (error "No keytool in %s" home))
    (unless certs (error "No certificate in `hellmacs-ca-bundle' (%s)" (abbreviate-file-name ca)))
    (make-directory (file-name-directory hellmacs-net-truststore) t)
    (when (file-exists-p tmp) (delete-file tmp))
    (unwind-protect
        (progn
          (funcall run "-importkeystore" "-noprompt"
                   "-srckeystore" cacerts "-srcstorepass" hellmacs-net--truststore-password
                   "-destkeystore" tmp "-deststoretype" "PKCS12"
                   "-deststorepass" hellmacs-net--truststore-password)
          (cl-loop for cert in certs for i from 1
                   do (with-temp-file pem (insert cert "\n"))
                      (funcall run "-importcert" "-noprompt" "-trustcacerts"
                               "-alias" (format "hellmacs-ca-%d" i) "-file" pem
                               "-keystore" tmp "-storetype" "PKCS12"
                               "-storepass" hellmacs-net--truststore-password))
          (rename-file tmp hellmacs-net-truststore t))
      (delete-file pem)
      (when (file-exists-p tmp) (delete-file tmp)))
    hellmacs-net-truststore))

(declare-function hellmacs-sync--log "hellmacs-sync")

(defun hellmacs-net-sync ()
  "Build the JVMs' truststore when `hellmacs-ca-bundle' is set. For `hellmacs-sync-functions'."
  (when hellmacs-ca-bundle
    (if (hellmacs-net-truststore-current-p)
        (hellmacs-sync--log "JVM truststore is up to date")
      (hellmacs-net-build-truststore)
      (hellmacs-sync--log "JVM truststore built: the JDK's CAs and yours (%s)"
                          (abbreviate-file-name hellmacs-net-truststore)))))

(defun hellmacs-net--java-no-proxy (hosts)
  "HOSTS as Java's http.nonProxyHosts: \"a|*.b\", local addresses always in."
  (string-join
   (delete-dups
    (append '("localhost" "127.*" "[::1]")
            (mapcan (lambda (host)
                      (cond ((equal host "*") (list "*"))
                            ((string-prefix-p "." host) (list (concat "*" host)))
                            ;; A domain covers its subdomains; a plain name or an address doesn't.
                            ((and (string-search "." host)
                                  (not (string-match-p "\\`[0-9.]+\\'" host)))
                             (list host (concat "*." host)))
                            (t (list host))))
                    hosts)))
   "|"))

(defun hellmacs-net-jvm-options ()
  "System properties for the JVMs Hellmacs starts: the proxy, and the truststore.
Empty when nothing is set. The truststore only once sync has built it."
  (append
   (when-let* ((proxy (hellmacs-net-proxy)))
     (require 'url-parse)
     (let* ((url (url-generic-parse-url (if (string-match-p "://" proxy) proxy (concat "http://" proxy))))
            (host (url-host url))
            (port (number-to-string (url-port url))))
       (append (list (concat "-Dhttp.proxyHost=" host) (concat "-Dhttp.proxyPort=" port)
                     (concat "-Dhttps.proxyHost=" host) (concat "-Dhttps.proxyPort=" port))
               (list (concat "-Dhttp.nonProxyHosts=" (hellmacs-net--java-no-proxy (hellmacs-net-no-proxy)))))))
   (when (and hellmacs-ca-bundle (file-exists-p hellmacs-net-truststore))
     (list (concat "-Djavax.net.ssl.trustStore=" hellmacs-net-truststore)
           (concat "-Djavax.net.ssl.trustStorePassword=" hellmacs-net--truststore-password)
           "-Djavax.net.ssl.trustStoreType=PKCS12"))))

;;; All of Emacs: proxy and CA ----------------------------------------------------

(defun hellmacs-net-setup ()
  "Point Emacs at `hellmacs-proxy' and trust `hellmacs-ca-bundle'. Run after your init.el.
An environment proxy needs nothing: url.el reads $HTTPS_PROXY itself."
  (when hellmacs-proxy
    (let ((host-port (hellmacs-net--host-port hellmacs-proxy)))
      (setq url-proxy-services `(("http" . ,host-port) ("https" . ,host-port)))
      (when-let* ((hosts (hellmacs-net-no-proxy)))
        (push (cons "no_proxy" (hellmacs-net--no-proxy-regexp hosts)) url-proxy-services))))
  (when hellmacs-ca-bundle
    (let ((ca (expand-file-name hellmacs-ca-bundle)))
      (with-eval-after-load 'gnutls
        (add-to-list 'gnutls-trustfiles ca)))))

;;; Hellmacs' own fetching: mirrors, and git's settings ----------------------------

(defvar hellmacs-net--active nil
  "Non-nil inside `with-hellmacs-network'.")

(defvar hellmacs-net--outer-environment nil
  "`process-environment' outside every `with-hellmacs-network', while inside one.")

(defun hellmacs-net--git-config ()
  "The git settings for Hellmacs' own fetches, as (KEY . VALUE)s."
  (append (when hellmacs-proxy (list (cons "http.proxy" hellmacs-proxy)))
          (when-let* ((ca (hellmacs-net-ca-file))) (list (cons "http.sslCAInfo" ca)))
          (mapcar (pcase-lambda (`(,from . ,to)) (cons (format "url.%s.insteadOf" to) from))
                  hellmacs-mirrors)))

(defun hellmacs-net-environment (&optional base-environment)
  "`process-environment' for Hellmacs' own fetches, made from BASE-ENVIRONMENT.
Git settings go in GIT_CONFIG_COUNT/KEY_n/VALUE_n (after any already
there), and an explicit proxy's exceptions in NO_PROXY."
  (let* ((env (copy-sequence (or base-environment process-environment)))
         (config (hellmacs-net--git-config))
         (base (string-to-number (or (getenv-internal "GIT_CONFIG_COUNT" env) "0"))))
    (when config
      (cl-loop for (key . value) in config
               for i from base
               do (push (format "GIT_CONFIG_KEY_%d=%s" i key) env)
                  (push (format "GIT_CONFIG_VALUE_%d=%s" i value) env))
      (push (format "GIT_CONFIG_COUNT=%d" (+ base (length config))) env))
    (when-let* ((hosts (and hellmacs-proxy (hellmacs-net-no-proxy))))
      (let ((value (string-join hosts ",")))
        (push (concat "NO_PROXY=" value) env)
        (push (concat "no_proxy=" value) env)))
    env))

(defmacro with-hellmacs-network (&rest body)
  "Run BODY as Hellmacs' own fetching.
url.el fetches go to their mirrors (`hellmacs-mirrors'), and processes
started meanwhile -- git, including Elpaca's -- get the proxy, CA and
mirrors (`hellmacs-net-environment')."
  (declare (indent 0) (debug t))
  `(let* ((hellmacs-net--outer-environment (if hellmacs-net--active
                                               hellmacs-net--outer-environment
                                             process-environment))
          ;; Made again from the outer one when nested, so settings changed
          ;; since take effect and nothing is added twice.
          (process-environment (hellmacs-net-environment hellmacs-net--outer-environment))
          (hellmacs-net--active t))
     ,@body))

(defun hellmacs-net--mirror-a (args)
  "`url-retrieve-internal' fetches through a mirror, inside `with-hellmacs-network'."
  (if (and hellmacs-net--active hellmacs-mirrors (stringp (car args)))
      (cons (hellmacs-net-rewrite (car args)) (cdr args))
    args))
(advice-add 'url-retrieve-internal :filter-args #'hellmacs-net--mirror-a)

(provide 'hellmacs-net)
;;; hellmacs-net.el ends here
