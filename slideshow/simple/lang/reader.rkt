#lang racket/base

(require syntax/readerr
         racket/match
         racket/string
         racket/stream
         racket/contract
         slideshow
         slideshow/text
         pict
         "./nodes.rkt")

(provide (rename-out [simple-read-syntax read-syntax])
         parse)


(define current-location (make-parameter #f))
(define current-path (make-parameter #f))

(define base-font-size 48)

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

(define (fenced-code-line? line)
  (string-prefix? line "```"))

(define (image-line? line)
  (string-prefix? line "!"))

(define (literal-line? line)
  (string-prefix? line "\\"))

(define (bullet-line? line)
  (string-prefix? line "- "))

(define (numeric-line? line)
  (regexp-match? #px"^[0-9]+. " line))

(define (verbatim-line? line)
  (string-prefix? line "@"))

(define (strip-numlist-prefix s)
  (match (string-split s "." #:repeat? #f)
    [(list _ item) (string-trim item)]
    [(list item) (string-trim item)]
    [_ (abort "unknown numeric list prefix")]))

(define (quotation-line? line)
  (string-prefix? line ">"))

(define (quotation-citation-line? line)
  (string-prefix? line "> --"))

(define (abort msg)
    (raise-read-error msg
                      (current-path)
                      (location-line (current-location))
                      (location-column (current-location))
                      1 1))

(define (cont-empty-slide slides line)
  (cond
   [(image-line? line)
    (cons (make-image-slide (substring line 1) (current-location))
          (cdr slides))]
   [(quotation-line? line)
    (cons (make-quotation-slide (substring line 2) (current-location))
          (cdr slides))]
   [(quotation-citation-line? line)
    (abort "can't cite non-existant quote")]
   [(bullet-line? line)
    (cons (make-list-slide (string-trim (substring line 2))
                           'bullet
                           (current-location))
          (cdr slides))]
   [(numeric-line? line)
    (cons (make-list-slide (strip-numlist-prefix line)
                           'numeric
                           (current-location))
          (cdr slides))]
   [(fenced-code-line? line)
    (cons (make-paragraph-slide "" (current-location)  #:code? #t)
          (cdr slides))]
   [(literal-line? line)
    (cons (make-paragraph-slide (substring line 1) (current-location))
          (cdr slides))]
   [(verbatim-line? line)
    (cons (make-verbatim-slide
           (read-verbatim (substring line 1)) (current-location))
          (cdr slides))]
   [(comment-line? line) slides]
   [(non-empty-string? (string-trim line))
    (cons (make-paragraph-slide line (current-location))
          (cdr slides))]
   [else slides]))

(define (cont-image-slide slides line)
  (cond
   [(comment-line? line)
    (cons (image-slide-notes-append (car slides) (substring line 1))
          (cdr slides))]
   [(fenced-code-line? line) (abort "improper start of fenced code")]
   [(non-empty-string? (string-trim line))
    (abort "can't add to an image slide")]
   [else (cons empty-slide slides)]))

(define (cont-list-slide slides line)
  (cond
   [(comment-line? line)
    (cons (list-slide-notes-append (car slides) (substring line 1))
          (cdr slides))]
   [(bullet-line? line)
    (if (eq? 'bullet (list-slide-type (car slides)))
        (cons
         (list-slide-append (car slides)  (substring line 2))
         (cdr slides))
        (abort "can't append numeric list item to bullet list slide."))]
   [(numeric-line? line)
    (if (eq? 'numeric (list-slide-type (car slides)))
        (cons
         (list-slide-append (car slides) (strip-numlist-prefix line))
         (cdr slides))
        (abort "can't append bullet list item to numeric list slide."))]
   [(fenced-code-line? line) (abort "improper start of fenced code")]
   [(non-empty-string? (string-trim line))
    (abort "improper addition to a list slide")]
   [else (cons empty-slide slides)]))

(define (cont-paragraph-slide slides line)
  (cond
   [(code-slide? (car slides))
    (if (fenced-code-line? line)
        (cons empty-slide slides)
        (cons (paragraph-slide-append (car slides) line)
              (cdr slides)))]
   [(comment-line? line)
    (cons (paragraph-slide-notes-append (car slides) (substring line 1))
          (cdr slides))]
   [(literal-line? line)
    (cons (paragraph-slide-append (car slides) (substring line 1))
          (cdr slides))]
   [(non-empty-string? (string-trim line))
    (cons (paragraph-slide-append (car slides) (string-trim line))
          (cdr slides))]
   [(fenced-code-line? line) (abort "improper start of fenced code")]
   [else (cons empty-slide slides)]))

(define (cont-quotation-slide slides line)
  (cond
   [(comment-line? line)
    (cons (quotation-slide-notes-append (car slides) (substring line 1))
          (cdr slides))]
   [(quotation-citation-line? line)
    (cons (struct-copy quotation-slide (car slides)
                       [citation (substring line 2)])
          (cdr slides))]
   [(quotation-line? line)
    (cons (quotation-slide-append (car slides) (substring line 2))
          (cdr slides))]
   [(fenced-code-line? line) (abort "improper start of fenced code")]
   [else
    (if (non-empty-string? (string-trim line))
        (abort "can't add unknown to a quote slide")
        (cons empty-slide slides))]))

(define (read-verbatim line)
  (define (handler e)
    (abort (format "read error in verbatim: ~a" e)))
  (with-handlers ([exn:fail:read? handler])
    (read (open-input-string line))))

(define (cont-verbatim-slide slides line)
  (cond
   [(comment-line? line) slides]
   [(verbatim-line? line)
    (cons (verbatim-slide-append (car slides)
                                 (read-verbatim (substring line 1)))
          (cdr slides))]
   [else
    (if (non-empty-string? (string-trim line))
        (abort "can't add unknown to a verbatim slide")
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
        [(quotation-slide? (car slides))
         (cont-quotation-slide slides line)]
        [(list-slide? (car slides))
         (cont-list-slide slides line)]
        [(verbatim-slide? (car slides)) (cont-verbatim-slide slides line)]
        [(paragraph-slide? (car slides)) (cont-paragraph-slide slides line)]
        [(comment-line? line) (begin (display "WOOOT") slides)]
        [else
         (abort "unable to parse line")])))))

(define (render-notes node accessor)
  `(comment
    ,(string-trim (string-join (accessor node) "\n"))))


(define (stage-image-slide node)
  `(slide (scale-to-fit (bitmap
                         ,(image-slide-path node))
                        (client-w)
                        (client-h)
                        #:mode 'preserve)
          ,(render-notes node image-slide-notes)))

(define (stage-paragraph-slide node)
  (define paragraphs (paragraph-slide-lines node))
  (define alignment (if (> (length paragraphs) 1) 'left 'center))
  (define (itemize p)
    `(with-size ,base-font-size
        (para #:fill? #t
              #:align ',alignment
              ,p)))
  `(slide
    ,@(for/list ([p paragraphs])
        (itemize p))
    ,(render-notes node paragraph-slide-notes)))

(define (stage-paragraph-code-slide node)
  (define paragraphs (paragraph-slide-lines node))
  (define alignment (if (> (length paragraphs) 1) 'left 'center))
  (define (itemize p)
    `(with-size ,base-font-size
        (with-font 'modern
           (para #:fill? #t
                 #:align ',alignment
                 ,p))
))
  `(slide
    ,@(for/list ([p paragraphs])
        (itemize p))
    ,(render-notes node paragraph-slide-notes)))

(define (stage-list-slide node)
  (define (itemize text bullet)
    `(with-size ,base-font-size
        (item #:bullet ,bullet
              #:align 'left
              #:fill? #t
              ,text)))
  (define (bullets-for-items items type)
    (for/list ([(_ i) (in-indexed items)])
      (if (eq? type 'bullet)
          'bullet
          `(with-size ,base-font-size (t ,(format "~a." (add1 i)))))))
  (define items (list-slide-items node))
  `(slide
    ,@(for/list ([item items]
                 [bullet (bullets-for-items items (list-slide-type node))])
        (itemize item bullet))
    ,(render-notes node list-slide-notes)))

(define (stage-quotation-slide node)
  `(slide
    (parameterize ([current-main-font (cons 'italic (current-main-font))])
      (with-size ,base-font-size
         (para #:fill? #t
             #:align 'center
             ,(format "``~a''"
                      (string-join (quotation-slide-lines node) "\n")))))
    (para #:align 'right ,(quotation-slide-citation node))
    ,(render-notes node quotation-slide-notes)))

(define (stage-verbatim-slide node)
  `(begin ,@(verbatim-slide-accum node)))

(define (nodes->slides nodes)
  (for/list ([node (reverse nodes)]
             #:unless (empty-slide? node))
    (cond
     [(code-slide? node) (stage-paragraph-code-slide node)]
     [(paragraph-slide? node) (stage-paragraph-slide node)]
     [(image-slide? node) (stage-image-slide node)]
     [(list-slide? node) (stage-list-slide node)]
     [(quotation-slide? node) (stage-quotation-slide node)]
     [(verbatim-slide? node) (stage-verbatim-slide node)]
     [else (error 'unknown-node)])))

(define (simple-read-syntax path port)
  (define nodes (parse path port))
  (define slides (nodes->slides nodes))

  (datum->syntax
   #f
   `(module my-slides slideshow
      (require pict)
      (require slideshow/text)
      ,@slides)))
