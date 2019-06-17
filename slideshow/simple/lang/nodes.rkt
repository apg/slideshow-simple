#lang racket/base

(require racket/math
         racket/string
         racket/struct
         racket/contract/base)

(provide (contract-out
          [struct location ((line exact-nonnegative-integer?)
                            (column exact-nonnegative-integer?))]
          [struct image-slide ((path path-string?)
                               (notes (listof string?))
                               (location location?))]
          [struct paragraph-slide ((lines (listof string?))
                                   (notes (listof string?))
                                   (location location?)
                                   (code? boolean?))]
          [struct quotation-slide ((lines (listof string?))
                                   (citation string?)
                                   (notes (listof string?))
                                   (location location?))]
          [struct list-slide ((items (listof string?))
                              (type (one-of/c 'bullet 'numeric))
                              (notes (listof string?))
                              (location location?))]
          [struct verbatim-slide ((accum list?)
                                  (location location?))]

          [code-slide? (-> any/c boolean?)]

          [make-image-slide (-> path-string?
                                location?
                                image-slide?)]
          [make-paragraph-slide (->* (string?                                                                     location?)
                                     (#:code? boolean?)
                                     paragraph-slide?)]
          [make-quotation-slide (-> string?
                                    location?
                                    quotation-slide?)]
          [make-list-slide (-> string?
                               (one-of/c 'bullet 'numeric)
                               location?
                               list-slide?)]
          [make-verbatim-slide (-> list?
                                   location?
                                   verbatim-slide?)]
          [paragraph-slide-append (-> paragraph-slide?
                                      string?
                                      paragraph-slide?)]
          [quotation-slide-append (-> quotation-slide?
                                      string?
                                      quotation-slide?)]
          [list-slide-append (-> list-slide?
                                 string?
                                 list-slide?)]

          [verbatim-slide-append (-> verbatim-slide?
                                 list?
                                 verbatim-slide?)]

          [image-slide-notes-append (-> image-slide?
                                        string?
                                        image-slide?)]
          [paragraph-slide-notes-append (-> paragraph-slide?
                                            string?
                                            paragraph-slide?)]
          [quotation-slide-notes-append (-> quotation-slide?
                                            string?
                                            quotation-slide?)]
          [list-slide-notes-append (-> list-slide?
                                       string?
                                       list-slide?)]
          )

         empty-slide
         empty-slide?)


(struct location (line column) #:transparent)

(struct image-slide (path notes location)
        #:constructor-name -image-slide
        #:transparent)

(define (make-image-slide path location)
  (-image-slide path '() location))

(struct paragraph-slide (lines notes location code?)
        #:constructor-name -paragraph-slide
        #:transparent)

(define (code-slide? s)
  (and (paragraph-slide? s)
       (paragraph-slide-code? s)))

(define (make-paragraph-slide line location #:code? [code? #f])
  (-paragraph-slide (list (string-trim line)) '() location code?))

(define (paragraph-slide-append p line)
  (define lines (paragraph-slide-lines p))
  (struct-copy paragraph-slide p
               [lines (append lines (list line))]))

(struct quotation-slide (lines citation notes location)
        #:constructor-name -quotation-slide
        #:transparent)

(define (quotation-slide-append p line)
  (define lines (quotation-slide-lines p))
  (struct-copy quotation-slide p
               [lines (append lines (list line))]))

(define (make-quotation-slide line location)
  (-quotation-slide (list (string-trim line)) "" '() location))

(struct list-slide (items type notes location)
        #:constructor-name -list-slide
        #:transparent)

(define (list-slide-append p item)
  (define items (list-slide-items p))
  (struct-copy list-slide p
               [items (append items (list item))]))

(define (make-list-slide item type location)
  (-list-slide (list (string-trim item)) type '() location))

(struct verbatim-slide (accum location)
        #:constructor-name -verbatim-slide
        #:transparent)

(define (verbatim-slide-append v item)
  (define accum (verbatim-slide-accum v))
  (struct-copy verbatim-slide v
               [accum (append accum (list item))]))

(define (make-verbatim-slide accum location)
  (-verbatim-slide (list accum) location))

(define-syntax-rule (make-slide-notator name accessor type)
  (define (name node line)
    (define notes (accessor node))
    (struct-copy type node
                 [notes (if (null? notes)
                            (cons line notes)
                            (append notes (list line)))])))

(make-slide-notator paragraph-slide-notes-append
                    paragraph-slide-notes
                    paragraph-slide)
(make-slide-notator image-slide-notes-append
                    image-slide-notes
                    image-slide)
(make-slide-notator quotation-slide-notes-append
                    quotation-slide-notes
                    quotation-slide)
(make-slide-notator list-slide-notes-append
                    list-slide-notes
                    list-slide)

(define empty-slide (make-paragraph-slide "" (location 0 0)))

(define (empty-slide? s)
  (eq? empty-slide s))
