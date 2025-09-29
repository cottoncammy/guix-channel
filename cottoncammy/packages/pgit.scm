;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (cottoncammy packages pgit)
  #:use-module (gnu packages version-control)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module ((guix licenses) #:prefix license:))

(define-public pgit
  (package
    (name "pgit")
    (version "1.1.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                     (url "https://github.com/picosh/pgit")
                     (commit version)))
              (file-name (git-file-name name version))
              (sha256
                (base32 "1k3am66vzd4mfqpnp1fhi16lvvw5kzp5zhw6kn3fkpvvixln4mpk"))))
    (build-system gnu-build-system)
    (inputs (list git))
    (home-page "https://pgit.pico.sh")
    (synopsis "Static site generator for Git repositories")
    (description "Generates a commit log, files, and references based on a Git repository
and the provided revisions.")
    (license license:expat)))
