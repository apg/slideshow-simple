#lang racket/base

(require syntax/readerr
         racket/string
         racket/stream
         racket/contract
         "./nodes.rkt")

(provide (rename-out [simple-read-syntax read-syntax])
         parse)


(define current-location (make-parameter #f))
(define current-path (make-parameter #f))

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
  (string-prefix? line "!"))

(define (literal-line? line)
  (string-prefix? line "\\"))


(define (cont-empty-slide slides line)
  (cond
   [(image-line? line)
    (cons (make-image-slide (substring line 1) (current-location))
          (cdr slides))]
   [(literal-line? line)
    (cons (make-paragraph-slide (substring line 1) (current-location))
          (cdr slides))]
   [(non-empty-string? (string-trim line))
    (cons (make-paragraph-slide line (current-location))
          (cdr slides))]
   [else slides]))

(define (cont-image-slide slides line)
  (cond
   [(comment-line? line)
    (cons (image-slide-notes-append (car slides) (substring line 1))
          (cdr slides))]
   [(non-empty-string? (string-trim line))
    (raise-read-error "can't add to an image slide"
                      (current-path)
                      (location-line (current-location))
                      (location-column (current-location))
                      0 1)]
   [else (cons empty-slide slides)]))

(define (cont-paragraph-slide slides line)
  (cond
   [(comment-line? line)
    (cons (paragraph-slide-notes-append (car slides) (substring line 1))
          (cdr slides))]
   [(literal-line? line)
    (cons (paragraph-slide-append (car slides) (substring line 1))
          (cdr slides))]
   [(non-empty-string? (string-trim line))
    (cons (paragraph-slide-append (car slides) (string-trim line))
          (cdr slides))]
   [else
    (if (non-empty-string? (string-trim line))
        (raise-read-error "can't add unknown to a paragraph slide"
                          (current-path)
                          (location-line (current-location))
                          (location-column (current-location))
                          0 1)
        (cons empty-slide slides))]))

(define (parse path port)
  (parameterize ([current-path path])
    (for/fold ([slides (list empty-slide)])
        ([line-no-col (in-positioned-port port 'any)])
      (define-values (line no col pos) (apply values line-no-col))
      (parameterize ([current-location (location no col)])
       (cond
        [(empty-slide? (car slides)) (cont-empty-slide slides line)]
        [(image-slide? (car slides)) (cont-image-slide slides line)]
        [(paragraph-slide? (car slides)) (cont-paragraph-slide slides line)]
        [(comment-line? line) slides]
        [else
         (raise-read-error "unable to parse line" (current-path) no col pos 1)]))))
)

(define (nodes->slides nodes)
  (for/list ([node (reverse nodes)]
             #:unless (empty-slide? node))
    (cond
     [(image-slide? node)
      `(slide #:title ""
              (bitmap ,(image-slide-path node))
              (comment ,(string-trim (string-join (image-slide-notes node) "\n"))))]
     [(paragraph-slide? node)
      `(slide #:title ""
              ,@(map (lambda (x)
                       `(t ,x))
                     (paragraph-slide-lines node))
              (comment ,(string-trim (string-join (paragraph-slide-notes node) "\n"))))]
     [else (error 'unknown-node)])))

(define (simple-read-syntax path port)
  (define nodes (parse path port))
  (define slides (nodes->slides nodes))
  (datum->syntax
   #f
   `(module my-slides slideshow
      (require pict)
      ,@slides)))
