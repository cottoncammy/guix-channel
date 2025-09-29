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
                    #t))
                (replace 'check
                  (lambda* (#:key tests? test-target make-flags #:allow-other-keys)
                    (when tests?
                      (apply invoke "make" test-target make-flags)
                      (invoke "./test"))))))
          ((#:make-flags make-flags)
            #~(append
                (list (string-append "CC=" #$(cc-for-target)))
                (filter (lambda (flag)
                          (not (string-prefix? "CC" flag)))
                        #$make-flags)))))
      (native-inputs '()))))

(define-public libtomcrypt-variant
  (let ((base libtomcrypt))
    (package
      (inherit base)
      (name "libtomcrypt-variant")
      (source (origin
                (inherit (package-source base))
                (patches
                  (map (lambda (patch)
                         (search-path
                           (map (cut string-append <> "/cottoncammy/packages/patches")
                                %load-path)
                           patch))
                       '("libtomcrypt-makefile-include.patch"
                         "libtomcrypt-makefile-shared.patch")))))
      (arguments
        (substitute-keyword-arguments (package-arguments base)
          ((#:phases phases)
            #~(modify-phases #$phases
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
                      #t)))
                (replace 'check
                  (lambda* (#:key tests? test-target make-flags #:allow-other-keys)
                    (when tests?
                      (apply invoke "make" test-target make-flags)
                        (invoke "./test"))))))))
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
