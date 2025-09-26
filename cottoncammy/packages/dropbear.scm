(define-module (cottoncammy packages dropbear)
  #:use-module ((gnu packages multiprecision) #:prefix multiprecision:)
  #:use-module ((gnu packages ssh) #:prefix ssh:)
  #:use-module (gnu packages crypto)
  #:use-module (gnu packages compression)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix utils))

(define %libtomcrypt
  (let ((base multiprecision:libtomcrypt))
    (package
      (inherit base)
      (version "23803626b67e29c76a2fa98e7c9f15fa56b01680")
      (source
        (origin
          (method git-fetch)
          (uri (git-reference
                 (url "https://github.com/libtom/libtomcrypt")
                 (commit version)))
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

(define-public dropbear
  (let ((base ssh:dropbear))
    (package
      (inherit base)
      (inputs (append
                (list multiprecision:libtommath libxcrypt zlib)
                (list %libtomcrypt))))))
