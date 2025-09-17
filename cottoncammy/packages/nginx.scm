(define-module (cottoncammy packages nginx)
  #:use-module ((gnu packages web) #:prefix web:)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (ice-9 match))

(define-public nginx
  (package
    (inherit web:nginx)
    (arguments
      (substitute-keyword-arguments (package-arguments web:nginx)
        ((#:configure-flags _)
         #~(list "--with-http_ssl_module"
                 "--with-http_v2_module"
                 "--with-http_xslt_module"
                 "--with-http_gzip_static_module"
                 "--with-http_gunzip_module"
                 "--with-http_addition_module"
                 "--with-http_sub_module"
                 "--with-pcre-jit"
                 "--with-debug"
                 "--with-compat"
                 "--with-stream"
                 "--with-stream_ssl_module"
                 "--with-http_stub_status_module"
                 ;; Even when not cross-building, we pass the
                 ;; --crossbuild option to avoid customizing for the
                 ;; kernel version on the build machine.
                 #$(let ((system "Linux")  ; uname -s
                         (release "3.2.0") ; uname -r
                         ;; uname -m
                         (machine (match (or (%current-target-system)
                                             (%current-system))
                                    ("x86_64-linux"   "x86_64")
                                    ("i686-linux"     "i686")
                                    ("mips64el-linux" "mips64")
                                    ("aarch64-linux"  "aarch64")
                                    ;; Prevent errors when querying
                                    ;; this package on unsupported
                                    ;; platforms, e.g. when running
                                    ;; "guix package --search="
                                    (_                "UNSUPPORTED"))))
                     (string-append "--crossbuild="
                                    system ":" release ":" machine))))))))
