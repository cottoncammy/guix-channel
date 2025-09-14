;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (cottoncammy services dnscrypt-proxy)
  #:use-module (gnu packages dns)
  #:use-module (gnu packages admin)
  #:use-module (gnu system shadow)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module (gnu services dns)
  #:use-module (gnu services networking)
  #:use-module (gnu services admin)
  #:use-module (guix records)
  #:use-module (guix gexp)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 binary-ports)
  #:use-module (srfi srfi-28)
  #:export (dnscrypt-proxy-configuration
            dnscrypt-proxy-configuration?
            dnscrypt-proxy-service-type))

(define-record-type* <dnscrypt-proxy-configuration>
  dnscrypt-proxy-configuration make-dnscrypt-proxy-configuration
  dnscrypt-proxy-configuration?
  ;; symbol
  (dnscrypt-proxy           dnscrypt-proxy-configuration-dnscrypt-proxy
                            (default dnscrypt-proxy))
  ;; string
  (pid-file                 dnscrypt-proxy-configuration-pid-file
                            (default "/var/run/dnscrypt-proxy.pid"))
  ;; file-like
  (config-file              dnscrypt-proxy-configuration-config-file)
  ;; file-like
  (forwarding-rules         dnscrypt-proxy-configuration-forwarding-rules
                            (default #f))
  ;; file-like
  (cloaking-rules           dnscrypt-proxy-configuration-cloaking-rules
                            (default #f))
  ;; file-like
  (map-file                 dnscrypt-proxy-configuration-map-file
                            (default #f))
  ;; file-like
  (cert-file                dnscrypt-proxy-configuration-cert-file
                            (default #f))
  ;; file-like
  (cert-key-file            dnscrypt-proxy-configuration-cert-key-file
                            (default #f))
  ;; file-like
  (blocked-names            dnscrypt-proxy-configuration-blocked-names
                            (default #f))
  ;; file-like
  (blocked-ips              dnscrypt-proxy-configuration-blocked-ips
                            (default #f))
  ;; file-like
  (allowed-names            dnscrypt-proxy-configuration-allowed-names
                            (default #f))
  ;; file-like
  (allowed-ips              dnscrypt-proxy-configuration-allowed-ips
                            (default #f))
  ;; list of symbols
  (shepherd-provision       dnscrypt-proxy-configuration-shepherd-provision
                            (default '(dnscrypt-proxy)))
  ;; list of symbols
  (shepherd-requirement     dnscrypt-proxy-configuration-shepherd-requirement
                            (default '())))

(define (compute-config in out)
  (let* ((acc '())
         (key-regex-fmt "^\\s*(?!#)(~a)\\s*=\\s*(['\"]?[A-Za-z0-9_]+['\"]?).*$")
         (keys-to-remove '("user_name" "log_file_latest" "tls_key_log_file"))
         (keys-to-remove-regex
           (format #f key-regex-fmt (string-join keys-to-remove "|")))
         (section-regex-fmt "^\\s*(?!#)(\\[~a\\]|).*$")
         (section-regex (format #f section-regex-fmt "[A-Za-z0-9_]+"))
         (sections-to-remove-regex
           (format #f section-regex-fmt "doh_client_x509_auth|monitoring_ui"))
         (keys-to-upsert '(("log_files_max_size" . #f)
                           ("log_files_max_age" . #f)
                           ("log_files_max_backups" . #f)))
         (keys-to-upsert-regex
           (format #f key-regex-fmt (string-join (map car keys-to-upsert) "|"))))

    (define (mark-seen! k)
      (let ((entry (assoc k keys-to-upsert)))
        (when entry (set-cdr! entry #t))))

    (define (missing-upsert-keys)
      (map car (filter (lambda (entry) (not (cdr entry))) keys-to-upsert)))

    (let loop ((line (read-line in))
               (skip? #f))
      (if (eof-object? line)
        (let* ((missing (missing-upsert-keys))
               (final (reverse (append out
                                 (map (lambda (k) (string-append k " = 0")) missing)))))
          (display (string-join final #\newline) out))
        (lambda ()
          (cond
            ((and skip? (string-match section-regex line)) (loop (read-line in) #f))
            (skip? (loop (read-line in) #t))
            ((string-match sections-to-remove-regex line) (loop (read-line in) #t))
            ((string-match keys-to-remove-regex line) (loop (read-line in) skip?))
            ((let ((m (string-match keys-to-upsert-regex line)))
              (and m
                   (let* ((k (match:substring m 1))
                          (v (match:substring m 2)))
                     (if (string=? v (number->string 0))
                       (set! acc (cons line acc))
                       (set! acc (cons (string-append k " = 0") acc)))
                     (mark-seen! k))
                   #t))
              (loop (read-line in) skip?))
            ((let ((missing (missing-upsert-keys)))
               (and (not (null? missing)) (string-match section-regex line))
               (begin
                 (set! acc (append
                             (map (lambda (k) (string-append k " = 0" missing) acc))))
                 (loop (read-line in) skip?))))
            (else
              (set! acc (cons line acc))
              (loop (read-line in) skip?))))))))

(define (computed-config-file config)
  (match-record config <dnscrypt-proxy-configuration>
    (config-file)
    (with-imported-modules '((guix build utils))
      #~(begin
          (use-modules (guix build utils))

          (with-atomic-file-replacement #$config-file
            (lambda (in out)
              (compute-config in out)))))))

(define (dnscrypt-proxy-shepherd-service config)
  (match-record config <dnscrypt-proxy-configuration>
    (dnscrypt-proxy pid-file config-file shepherd-provision shepherd-requirement)
    (unless config-file
      (error "Must supply a config-file"))
    (let ((computed-config (computed-config-file config)))
      (list
        (shepherd-service
          (documentation "Run dnscrypt-proxy.")
          (provision shepherd-provision)
          (requirement `(user-processes loopback ,@shepherd-requirement))
          (start #~(make-forkexec-constructor
                     (list (string-append #$dnscrypt-proxy "/sbin/dnscrypt-proxy")
                           "-config" #$computed-config
                           "-pidfile" #$pid-file)
                     #:user "dnscrypt-proxy"
                     #:group "dnscrypt-proxy"
                     #:pid-file #$pid-file))
          (stop #~(make-kill-destructor))
          (actions (list (shepherd-configuration-action computed-config))))))))

(define %dnscrypt-proxy-accounts
  (list (user-group
          (name "dnscrypt-proxy")
          (system? #t))
        (user-account
          (name "dnscrypt-proxy")
          (group "dnscrypt-proxy")
          (system? #t)
          (comment "dnscrypt-proxy user")
          (home-directory "/var/empty")
          (shell (file-append shadow "/sbin/nologin")))))

(define (dnscrypt-proxy-activation config)
  (match-record config <dnscrypt-proxy-configuration>
    (pid-file
     config-file
     forwarding-rules cloaking-rules
     map-file
     cert-file cert-key-file
     blocked-names blocked-ips
     allowed-names allowed-ips)
    (unless config-file
      (error "Must supply a config-file"))
    (with-imported-modules '((gnu build activation) (guix build utils))
      #~(begin
          (use-modules (gnu build activation)
                       (guix build utils))

          (define (ensure-dir-p dir)
            (unless (file-exists? dir)
              (mkdir-p/perms (dirname dir)
                             (getpwnam "dnscrypt-proxy")
                             #o755)))

            (ensure-dir-p #$pid-file)

            (call-with-input-file #$config-file
              (lambda (port)
                (let loop ((line (read-line port)))
                  (if (eof-object? line)
                      #f
                      (let ((m (string-match
                                 "^\\s*(?!#)([A-Za-z0-9_]*?file)\\s*=\\s*['\"]([^']*)['\"]"
                                 line)))
                        (if m
                          (let* ((k (match:substring m 1))
                                 (v (match:substring m 2))
                                 (symlinked-files `(("map_file" . #$map-file)
                                                    ("cert_file" . #$cert-file)
                                                    ("cert_key_file" . #$cert-key-file)
                                                    ("blocked_names_file" . #$blocked-names)
                                                    ("blocked_ips_file" . #$blocked-ips)
                                                    ("allowed_names_file" . #$allowed-names)
                                                    ("allowed_ips_file" . #$allowed-ips)
                                                    ("cache_file"))))
                            (let ((value (assoc-ref k symlinked-files)))
                              (if (value)
                                (unless (string=? k "cache_file")
                                  (ensure-dir-p v)
                                  (when (null? value)
                                    (error (format #f "value of ~s is null" k)))
                                  (symlink v value))
                                ;; assume it's a valid key
                                (ensure-dir-p v))))
                          (loop (read-line port))))))))))))

(define dnscrypt-proxy-service-type
  (service-type
    (name 'dnscrypt-proxy)
    (extensions
      (list (service-extension shepherd-root-service-type
                               dnscrypt-proxy-shepherd-service)
            (service-extension activation-service-type
                               dnscrypt-proxy-activation)
            (service-extension account-service-type
                               (const %dnscrypt-proxy-accounts))))
    (description "Run dnscrypt-proxy.")))
