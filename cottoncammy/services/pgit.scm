;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (cottoncammy services pgit)
  #:use-module (cottoncammy packages pgit)
  #:use-module (gnu services)
  #:use-module (gnu services web)
  #:use-module (gnu services shepherd)
  #:use-module (gnu services admin)
  #:use-module (guix records)
  #:use-module (guix gexp)
  #:use-module (ice-9 match)
  #:use-module (ice-9 format)
  #:export (pgit-repository
            pgit-repository?
            pgit-configuration
            pgit-configuration?
            pgit-service-type))

(define-record-type* <pgit-repository>
  pgit-repository make-pgit-repository
  pgit-repository?
  ;; string
  (out-path                 pgit-repository-out-path)
  ;; string
  (path                     pgit-repository-path)
  ;; list of strings
  (revisions                pgit-repository-revisions
                            (default '("HEAD")))
  ;; string
  (theme                    pgit-repository-theme
                            (default "dracula"))
  ;; string
  (label                    pgit-repository-label
                            (default #f))
  ;; string
  (clone-url                pgit-repository-clone-url
                            (default #f))
  ;; string
  (home-url                 pgit-repository-home-url
                            (default #f))
  ;; string
  (description              pgit-repository-description
                            (default #f))
  ;; string
  (root-relative            pgit-repository-root-relative
                            (default "/"))
  ;; integer
  (max-commits              pgit-repository-max-commits
                            (default 0))
  ;; boolean
  (hide-tree-last-commit?   pgit-repository-hide-tree-last-commit?
                            (default #f)))

(define-record-type* <pgit-configuration>
  pgit-configuration make-pgit-configuration
  pgit-configuration?
  ;; symbol
  (pgit                     pgit-configuration-pgit
                            (default pgit))
  ;; <nginx-server-configuration>
  (nginx                    pgit-configuration-nginx)
  ;; list of <pgit-repository>
  (repositories             pgit-configuration-repositories
                            (default '()))
  ;; list of symbols
  (shepherd-provision       pgit-configuration-shepherd-provision
                            (default '(pgit)))
  ;; list of symbols
  (shepherd-requirement     pgit-configuration-shepherd-requirement
                            (default '())))

(define (pgit-shepherd-service config)
  (match-record config <pgit-configuration>
                (pgit repositories shepherd-provision shepherd-requirement)

    (define pgit-commands
      #~(list
        #$@(apply append
             (map (match-lambda
               (($ <pgit-repository> out-path path revisions theme label clone-url
                                     home-url description root-relative
                                     max-commits hide-tree-last-commit?)
                 (list #$pgit
                       #$@(if (string-null? out-path) '() '("-out" out-path))
                       #$@(if (string-null? path) '() '("-repo" path))
                       #$@(if (null? revisions)
                                '() (list "-revs" (format #f "~{~a~}" revisions)))
                       #$@(if (string-null? theme) '() '("-theme" theme))
                       #$@(if (string-null? label) '() '("-label" label))
                       #$@(if (string-null? clone-url) '() '("-clone-url" clone-url))
                       #$@(if (string-null? home-url) '() '("-home-url" home-url))
                       #$@(if (string-null? description) '() '("-desc" description))
                       #$@(if (string-null? root-relative)
                                '() '("-root-relative" root-relative))
                       #$@(if (not max-commits)
                                '() '("-max-commits" (number->string max-commits)))
                       #$@(if hide-tree-last-commit? '("-hide-tree-last-commit") '()))))
                repositories))))

      (list
        (shepherd-service
          (documentation "Run pgit, a static site generator for Git repositories.")
          (provision shepherd-provision)
          (requirement shepherd-requirement)
          (start #~(make-system-constructor #$@pgit-commands))
          (stop #~(make-system-destructor))
          (one-shot? #t)
          (respawn? #f)))))

(define (pgit-nginx-server config)
  (match-record config <pgit-configuration>
                (nginx)
    (list (nginx-server-configuration
            (inherit nginx)
            (locations (append
                         (list
                           (nginx-location-configuration
                             (uri "/")
                             (body '())))
                         (nginx-server-configuration-locations nginx)))))))

(define pgit-service-type
  (service-type
    (name 'pgit)
    (extensions
      (list (service-extension shepherd-root-service-type
                               pgit-shepherd-service)
            (service-extension nginx-service-type
                               pgit-nginx-server)))
    (description "Run pgit, a static site generator for Git repositories.")))
