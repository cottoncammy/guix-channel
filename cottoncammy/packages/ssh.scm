;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (cottoncammy packages ssh)
  #:use-module (gnu packages multiprecision)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages crypto)
  #:use-module (gnu packages compression)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix utils))

(define-public libtomcrypt-variant
  (let ((base libtomcrypt))
    (package
      (inherit base)
      (name "libtomcrypt-variant")
      (version "23803626b67e29c76a2fa98e7c9f15fa56b01680")
      (source
        (origin
          (method git-fetch)
          (uri (git-reference
                 (url "https://github.com/libtom/libtomcrypt")
                 (commit version)))
          (file-name (git-file-name name version))
          (sha256
            (base32
              "00yx4nl8ywji5lk5m92927ab68gjv17ihw1phsi71l4vm4jvpc54"))))
      (arguments
        (substitute-keyword-arguments (package-arguments base)
          ((#:phases phases)
            #~(modify-phases #$phases
                (replace 'prepare-build
                  (lambda _
                    ;; We want the shared library by default so force it to be the
                    ;; default makefile target.
                    (delete-file "makefile")
                    (symlink "makefile.shared" "makefile")
                    #t))
                (replace 'install-static-library
                  (lambda* (#:key outputs make-flags #:allow-other-keys)
                    (apply invoke "make" "-f" "makefile.unix" "install" make-flags)
                    (let ((out (assoc-ref outputs "out"))
                          (static (assoc-ref outputs "static")))
                      (mkdir-p (string-append static "/lib"))
                      (mkdir-p (string-append static "/include"))
                      (rename-file (string-append out "/lib/libtomcrypt.a")
                                   (string-append static "/lib/libtomcrypt.a"))
                      (copy-recursively (string-append out "/include")
                                        (string-append static "/include"))
                      #t)))))))
      (native-inputs '()))))

(define-public dropbear-variant
  (let ((base dropbear))
    (package
      (inherit base)
      (name "dropbear-variant")
      (inputs (list libtomcrypt-variant libtommath libxcrypt zlib)))))
