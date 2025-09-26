;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (cottoncammy packages)
  #:use-module (gnu packages)
  #:use-module (guix packages)
  #:use-module (ice-9 match)
  #:replace (%patch-path
             search-patch)
  #:export (cottoncammy-patches
            %cottoncammy-package-module-path))

(define %cottoncammy-root-directory
  (letrec-syntax ((dirname* (syntax-rules ()
                              ((_ file)
                               (dirname file))
                              ((_ file head tail ...)
                               (dirname (dirname* file tail ...)))))
                  (try      (syntax-rules ()
                              ((_ (file things ...) rest ...)
                               (match (search-path %load-path file)
                                 (#f
                                  (try rest ...))
                                 (absolute
                                  (dirname* absolute things ...))))
                              ((_)
                               #f))))
    (try ("cottoncammy/packages/zig-apps.scm" cottoncammy/ packages/))))

(define %cottoncammy-package-module-path
  `((,%cottoncammy-root-directory . "cottoncammy/packages")))

(define %patch-path
  (make-parameter
    (map (lambda (directory)
           (if (string=? directory %cottoncammy-root-directory)
               (string-append directory "/cottoncammy/packages/patches")
               directory))
         %load-path)))

(define (search-patch file-name)
  (or (search-path (%patch-path) file-name)
      (error (format ("~a: patch not found") file-name))))

(define-syntax-rule (cottoncammy-patches file-name ...)
  (list (search-patch file-name) ...))
