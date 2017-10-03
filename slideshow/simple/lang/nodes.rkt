#lang racket/base

(require racket/math
         racket/struct
         racket/contract/base)

(provide (contract-out
          [struct location ((line natural?) (column natural?))]
          [struct image-slide ((path path-string?)
                               (notes (listof string?))
                               (location location?))]
          [struct paragraph-slide ((lines (listof string?))
                                   (notes (listof string?))
                                   (location location?))]
          [make-image-slide (-> path-string? location? image-slide?)]
          [make-paragraph-slide (-> string? location? paragraph-slide?)]
          [paragraph-slide-append (-> paragraph-slide? string? paragraph-slide?)]
          [image-slide-notes-append (-> image-slide? string? image-slide?)]
          [paragraph-slide-notes-append (-> paragraph-slide? string? paragraph-slide?)]
          )

         empty-slide
         empty-slide?)


(struct location (line column) #:transparent)

(struct image-slide (path notes location)
        #:constructor-name -image-slide
        #:transparent)

(define (make-image-slide path location)
  (-image-slide path (list "") location))

(struct paragraph-slide (lines notes location)
        #:constructor-name -paragraph-slide
        #:transparent)

(define (make-paragraph-slide line location)
  (-paragraph-slide (list line) (list "") location))

(define (paragraph-slide-append p line)
  (define lines (paragraph-slide-lines p))
  (struct-copy paragraph-slide p
               [lines (append lines (list line))]))

(define-syntax-rule (make-slide-notator name accessor type)
  (define (name node line)
    (define notes (accessor node))
    (struct-copy type node
                 [notes (append notes (list line))])))

(make-slide-notator paragraph-slide-notes-append paragraph-slide-notes paragraph-slide)
(make-slide-notator image-slide-notes-append image-slide-notes image-slide)

(define empty-slide (make-paragraph-slide "" (location 0 0)))

(define (empty-slide? s)
  (eq? empty-slide s))
