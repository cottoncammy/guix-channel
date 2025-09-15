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
    (version "37512025.257.63687")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                     (url "https://github.com/hagezi/dns-blocklists")
                     (commit "48ff0c94185619ec3fe002af8e98c32d782a228f")))
              (file-name (git-file-name name version))
              (sha256
                (base32 "07j111b5760sj4ry4m122l3rbxsy1r3i2a55mznm8dqxdbxy9igv"))
              (modules '((guix build utils)
                         (ice-9 ftw)
                         (srfi srfi-26)))
              (snippet
               '(begin
                  (for-each (lambda (name)
                              (delete-file-recursively name))
                             `(".github" "adblock" "adguard" "controld" "dnsmasq"
                               "domains" "hosts" "ips" "pac" "rpz" "share"
                               "submit_pullrequest_here" ".gitattributes"
                               ".gitignore" "LICENSE" "README.md" "index.html"
                               "sources.md"
                               ,@(map (lambda (name) (string-append "wildcard/" name))
                                      (scandir "wildcard"
                                        (cut (lambda (file stat)
                                               (not (string=? file "pro-onlydomains.txt")))
                                              <> #f)))))))))
    (build-system copy-build-system)
    (arguments
      '(#:install-plan
        '(("wildcard/pro-onlydomains.txt" "."))))
    (home-page "https://github.com/hagezi/dns-blocklists")
    (synopsis "DNS blocklist")
    (description "Blocks Ads, Affiliate, Tracking, Metrics, Telemetry, Phishing, Malware,
Scam, Fake, Cryptojacking, etc.")
    (license license:gpl3)))
