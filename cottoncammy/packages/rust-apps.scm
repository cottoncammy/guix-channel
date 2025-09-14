;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (cottoncammy packages rust-apps)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system cargo)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:))

(define-public yazi
  (package
    (name "yazi")
    (version "25.5.31")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                     (url "https://github.com/sxyazi/yazi")
                     (commit version)))
              (file-name (git-file-name name version))
              (sha256
                (base32 "1hz1nhq02b18cljw9i4jd1wxvd4gzvcgzkg0qfacvqbpj7zmvgqj"))))
    (build-system cargo-build-system)
    (inputs (cons* (cargo-inputs 'yazi)))
    (arguments `(#:install-source? #f))
    (home-page "https://yazi-rs.github.io")
    (synopsis "Blazing fast terminal file manager written in Rust, based on async I/O")
    (description "Yazi is a terminal file manager written in Rust, based on non-blocking
async I/O. It aims to provide an efficient, user-friendly, and customizable file
management experience.")
    (license license:expat)))

(define-public steamguard-cli
  (package
    (name "steamguard-cli")
    (version "0.17.1")
    (source (origin
              (method url-fetch)
              (uri (crate-uri "steamguard-cli" version))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
                (base32 "1hz1nhq02b18cljw9i4jd1wxvd4gzvcgzkg0qfacvqbpj7zmvgqj"))))
    (build-system cargo-build-system)
    (inputs (cons* (cargo-inputs 'steamguard-cli)))
    (arguments
      `(#:install-source? #f
        #:features '("qr")))
    (home-page "https://github.com/dyc3/steamguard-cli")
    (synopsis "A utility for generating 2FA codes for Steam and managing Steam trade,
market, and other confirmations")
    (description "A command line utility for setting up and using Steam Mobile
Authenticator (AKA Steam 2FA). It can also be used to respond to trade, market, and any
other steam mobile confirmations that you would normally get in the app.")
    (license (list license:gpl3+
                   license:expat
                   license:asl2.0))))

(define-public git-credential-keepassxc
  (package
    (name "git-credential-keepassxc")
    (version "0.14.1")
    (source (origin
              (method url-fetch)
              (uri (crate-uri "git-credential-keepassxc" version))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
                (base32 "1hz1nhq02b18cljw9i4jd1wxvd4gzvcgzkg0qfacvqbpj7zmvgqj"))))
    (build-system cargo-build-system)
    (inputs (cons* (cargo-inputs 'git-credential-keepassxc)))
    (arguments
      `(#:install-source? #f
        #:features '("notification" "strict-caller")))
    (home-page "https://github.com/Frederick888/git-credential-keepassxc")
    (synopsis "Helper that allows Git (and shell scripts) to use KeePassXC as credential
store")
    (description "A Git credential helper that allows Git (and shell scripts) to get/store logins from/to KeePassXC. It communicates with KeePassXC using
keepassxc-protocol, which was originally designed for browser extensions.")
    (license license:gpl3+)))
