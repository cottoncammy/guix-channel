;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (cottoncammy packages ssh)
  #:use-module (gnu packages multiprecision)
  #:use-module (gnu packages ssh)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (srfi srfi-26))

(define-public libtommath-variant
  (let ((base libtommath))
    (package
      (inherit base)
      (name "libtommath-variant")
      (source (origin
                (inherit (package-source base))
                (patches
                  (map (lambda (patch)
                         (search-path
                           (map (cut string-append <> "/cottoncammy/packages/patches")
                                %load-path)
                           patch))
                       '("libtommath-makefile-include.patch"
                         "libtommath-makefile-shared.patch")))))
      (arguments
        (substitute-keyword-arguments (package-arguments base)
          ((#:modules modules)
           `((srfi srfi-26)
             ,@modules))
          ((#:phases phases)
            #~(modify-phases #$phases
                (delete 'remove-static-library)
                (replace 'install-static-library
                  (lambda* (#:key outputs make-flags #:allow-other-keys)
                    (apply invoke "make" "-f" "makefile.unix" "install" make-flags)
                      (let ((out (assoc-ref outputs "out"))
                            (static (assoc-ref outputs "static")))
                        (mkdir-p (string-append static "/lib"))
                        (mkdir-p (string-append static "/include"))
                        (rename-file (string-append out "/lib/libtommath.a")
                                     (string-append static "/lib/libtommath.a"))
                        (copy-recursively (string-append out "/include")
                                          (string-append static "/include")))
                    #t))))
          ((#:make-flags _)
            #~(list (string-append "PREFIX=" (assoc-ref %outputs "out"))
                    (string-append "CC=" #$(cc-for-target))
                    (let ((target #$(%current-target-system)))
                      (when (not (string-null? target))
                        (string-append "_ARCH=" (car (string-split target #\-)))))))))
      (native-inputs '()))))

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
      (inputs (modify-inputs (package-inputs base)
                (replace "libtommath" libtommath-variant)))
      (native-inputs '()))))

(define-public dropbear-variant
  (let ((base dropbear))
    (package
      (inherit base)
      (name "dropbear-variant")
      (inputs (modify-inputs (package-inputs base)
                (replace "libtomcrypt" libtomcrypt-variant)
                (replace "libtommath" libtommath-variant))))))
