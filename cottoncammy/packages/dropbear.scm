(define-module (cottoncammy packages dropbear)
  #:use-module ((gnu packages multiprecision) #:prefix multiprecision:)
  #:use-module ((gnu packages ssh) #:prefix ssh:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix utils))

(define-public libtomcrypt
  (let ((base multiprecision:libtomcrypt))
    (package
      (inherit base)
      (version "23803626b67e29c76a2fa98e7c9f15fa56b01680")
      (source
        (origin
          (method url-fetch)
          (uri (git-reference
                 (url "https://github.com/libtom/libtomcrypt")
                 (commit version)))
          (sha256
            (base32
              "00yx4nl8ywji5lk5m92927ab68gjv17ihw1phsi71l4vm4jvpc54"))))
      (native-inputs '()))))

(define-public dropbear
  (let ((base ssh:dropbear))
    (package
      (inherit base)
      (inputs (append
                (filter
                  (lambda (package)
                    (not (string=? (car package) "libtomcrypt")))
                  (package-inputs base))
                `(("libtomcrypt" . libtomcrypt)))))))
