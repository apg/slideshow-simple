#lang racket/base

(require syntax/readerr
         racket/string
         racket/stream
         racket/contract
         "./nodes.rkt")

(provide (rename-out [simple-read-syntax read-syntax])
         parse)

;; when eof, return the current nodes
;; when the line starts with a `@` we make an image node.
;; when the line starts with a `\` we make a literal node with whatever after the next line.
;; when the line starts with a `#` we ignore the line as a comment.
;; when the line is blank, we commit the current node to the list of nodes.
;; when there is a current paragraph node, and there is an image, it is a syntax error.
;; when there is a current paragraph node, and there is a comment, the comment is ignored and the node is committed.

(define/contract (in-positioned-port port mode)
  (-> input-port? (or/c 'linefeed 'return 'linefeed-return 'any 'any-one) stream?)
  (port-count-lines! port)
  (define (loop port)
    (define-values (lineno col pos) (port-next-location port))
    (define line (read-line port mode))
    (if (eof-object? line)
        empty-stream
        (stream-cons (list line lineno col pos) (loop port))))
  (loop port))

(define (comment-line? line)
  (string-prefix? line "#"))

(define (image-line? line)
  (string-prefix? line "@"))

(define (literal-line? line)
  (string-prefix? line "\\"))

(define (parse path port)
  (for/fold ([slides (list empty-slide)])
            ([line-no-col (in-positioned-port port 'any)])
    (define-values (line no col pos) (apply values line-no-col))
    (define loc (location no col))
    (cond
     [(comment-line? line) slides]
     [(empty-slide? (car slides))
      (cond
       [(image-line? line) (cons (image-slide (substring line 1) loc)
                                 (cdr slides))]
       [(literal-line? line) (cons (make-paragraph-slide (substring line 1) loc)
                                   (cdr slides))]
       [(non-empty-string? (string-trim line)) (cons (make-paragraph-slide line loc)
                                                     (cdr slides))]
       [else slides])]
     [(image-slide? (car slides))
      (if (non-empty-string? (string-trim line))
          (raise-read-error "can't add to an image slide" path no col pos 1)
          (cons empty-slide slides))]
     [(paragraph-slide? (car slides))
      (cond
       [(literal-line? line) (cons (add-to-paragraph (car slides) (substring line 1))
                                   (cdr slides))]
       [(non-empty-string? (string-trim line)) (cons (add-to-paragraph (car slides) (string-trim line))
                                                     (cdr slides))]
       [else
        (if (non-empty-string? (string-trim line))
            (raise-read-error "can't add unknown to a paragraph slide" path no col pos 1)
            (cons empty-slide slides))])]
     [else
      (raise-read-error "unable to parse line" path no col pos 1)])))

(define (nodes->slides nodes)
  (for/list ([node (reverse nodes)]
             #:unless (empty-slide? node))
    (cond
     [(image-slide? node) `(slide #:title ""
                                  (bitmap ,(image-slide-path node)))]
     [(paragraph-slide? node) `(slide #:title ""
                                      ,@(map (lambda (x)
                                               `(t ,x))
                                             (paragraph-slide-lines node)))]
     [else (error 'unknown-node)])))

(define (simple-read-syntax path port)
  (define nodes (parse path port))
  (define slides (nodes->slides nodes))
  (datum->syntax
   #f
   `(module my-slides slideshow
      (require pict)
      ,@slides)))
