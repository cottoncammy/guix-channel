(define-module (cottoncammy packages nginx)
  #:use-module ((gnu packages web) #:prefix web:)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages pcre)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages compression)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix utils))

(define-public nginx
  (package
    (inherit web:nginx)
    (native-inputs (list libxml2 libxslt pcre openssl zlib))
    (arguments
      (substitute-keyword-arguments (package-arguments web:nginx)
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
                              "auto/types/uintptr_t"))))))))))
