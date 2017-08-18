#lang racket/base

(require rackunit
         "./reader.rkt"
         "./nodes.rkt")

(define (expect-read? input result desc)
  (check-equal? (parse "<input-string>" (open-input-string input))
                result
                (symbol->string desc)))

(expect-read? "#a comment"
              (list empty-slide)
              'just-a-comment)
(expect-read? "@foo.png" (list (image-slide "foo.png" (location 1 0))) 'just-an-image)
(expect-read? "paragraph" (list (make-paragraph-slide "paragraph" (location 1 0))) 'just-a-paragraph)
(expect-read? "\\paragraph" (list (make-paragraph-slide "paragraph" (location 1 0))) 'just-a-paragraph-from-literal)
(expect-read? "\\@paragraph" (list (make-paragraph-slide "@paragraph" (location 1 0))) 'just-a-paragraph-from-literal-image)

;; multiple slides now
(expect-read? "@foo.png\n\nparagraph"
              (list (make-paragraph-slide "paragraph" (location 3 0))
                    (image-slide "foo.png" (location 1 0)))
              'multiple-image-blank-paragraph)
(expect-read? "@foo.png\n#comment\n\nparagraph"
              (list (make-paragraph-slide "paragraph" (location 4 0))
                    (image-slide "foo.png" (location 1 0)))
              'multiple-image-comment-blank-paragraph)
