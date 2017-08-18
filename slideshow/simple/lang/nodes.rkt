#lang racket/base

(require racket/math
         racket/struct
         racket/contract/base)

(provide (contract-out
          [struct location ((line natural?) (column natural?))]
          [struct image-slide ((path path-string?) (location location?))]
          [struct paragraph-slide ((lines (listof string?)) (location location?))]
          [make-paragraph-slide (-> string? location? paragraph-slide?)]
          [add-to-paragraph (-> paragraph-slide? string? paragraph-slide?)])

         empty-slide
         empty-slide?)


(struct location (line column) #:transparent)

(struct image-slide (path location) #:transparent)

(struct paragraph-slide (lines location)
        #:constructor-name -paragraph-slide
        #:transparent)

(define (make-paragraph-slide line location)
  (-paragraph-slide (list line) location))

(define(add-to-paragraph p line)
  (define lines (paragraph-slide-lines p))
  (struct-copy paragraph-slide p
               [lines (append lines (list line))]))

(define empty-slide (make-paragraph-slide "" (location 0 0)))

(define (empty-slide? s)
  (eq? empty-slide s))
