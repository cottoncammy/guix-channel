;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (cottoncammy packages fonts)
  #:use-module (gnu packages fonts)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix utils))

(define-public font-terminus-variant
  (let ((base font-terminus))
    (package
      (inherit base)
      (name "font-terminus-variant")
      (outputs (append (package-outputs base) '("psf")))
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
