;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (cottoncammy packages nginx)
  #:use-module (gnu packages web)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix utils))

(define-public nginx-variant
  (let ((base nginx))
    (package
      (inherit base)
      (name "nginx-variant")
      (native-inputs (package-inputs base))
      (arguments
        (substitute-keyword-arguments (package-arguments base)
          ((#:phases phases)
            #~(modify-phases #$phases
                (add-before 'configure 'patch-ngx-test-cc
                  (lambda _
                    (for-each (lambda (file)
                                (substitute* file
                                  (("^(\\s*ngx_test=\")(\\$CC)(.*)$" all begin cc end)
                                   (string-append begin (which "gcc") end))))
                              '("auto/endianness"
                                "auto/feature"
                                "auto/include"
                                "auto/types/sizeof"
                                "auto/types/typedef"
                                "auto/types/uintptr_t")))))))))))
