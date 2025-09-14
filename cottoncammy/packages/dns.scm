;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (cottoncammy packages dns)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (ice-9 format))

(define-public dns-blockednames
  (package
    (name "dns-blockednames")
    (version "37512025.248.59909")
    (source (origin
              (method url-fetch)
              (uri (format #f
                     "https://raw.githubusercontent.com/hagezi/dns-blocklists/refs/tags/~a/wildcard/pro-onlydomains.txt" version))
              (file-name (string-append name version))
              (sha256
                (base32 "156mqc0wgl2w0mayhadg5smakwycv1d3q2f3x7p1j37gb63p45sn"))))
    (build-system copy-build-system)
    (arguments
      '(#:install-plan
        '(("." "dns-blockednames.txt"))))
    (home-page "https://github.com/hagezi/dns-blocklists")
    (synopsis "DNS blocklist")
    (description "Blocks Ads, Affiliate, Tracking, Metrics, Telemetry, Phishing, Malware,
Scam, Fake, Cryptojacking, etc.")
    (license license:gpl3)))
