(define-module (cottoncammy packages fonts)
  #:use-module ((gnu packages fonts) #:prefix fonts:)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix utils))

(define-public font-terminus
  (let ((base fonts:font-terminus))
    (package
      (inherit base)
      (outputs (cons "psf" (package-outputs base)))
      (arguments
        (substitute-keyword-arguments (package-arguments base)
          ((#:phases phases)
            #~(modify-phases #$phases
                (add-before 'build-more-bits 'build-psf
                  (lambda* (#:key make-flags #:allow-other-keys)
                    (apply invoke "make" "psf" make-flags)))
                (add-after 'build-psf 'install-psf
                  (lambda* (#:key make-flags outputs #:allow-other-keys)
                    (let ((psf (assoc-ref outputs "psf")))
                      (apply invoke "make" "install-psf" (string-append "prefix=" psf)
                             make-flags)))))))))))
