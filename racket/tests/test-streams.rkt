#lang racket

;; evidencia del prototipo de streams: una cola no se evalua hasta pedirla
;; la mutacion de la caja vive solo en la prueba, no en racket/src/

(require rackunit
         racket/runtime-path
         racket/stream)

(define-runtime-path generador "../src/generador.rkt")

(test-case "stream-cons difiere la evaluacion de la cola"
  (define contador (box 0))
  (define (naturales n)
    (stream-cons n
                 (begin
                   (set-box! contador (add1 (unbox contador)))
                   (naturales (add1 n)))))
  (define stream (naturales 0))
  (check-equal? (unbox contador) 0)
  (check-equal? (stream-first stream) 0)
  (check-equal? (unbox contador) 0)
  (define resto (stream-rest stream))
  (check-equal? (stream-first resto) 1)
  (check-equal? (unbox contador) 1))

(test-case "stream-append tambien conserva la pereza"
  (define contador (box 0))
  (define (uno)
    (stream-cons 1
                 (begin
                   (set-box! contador (add1 (unbox contador)))
                   empty-stream)))
  (define (dos)
    (stream-cons 2
                 (begin
                   (set-box! contador (add1 (unbox contador)))
                   empty-stream)))
  (define unidos (stream-append (uno) (dos)))
  (check-equal? (stream-first unidos) 1)
  (check-equal? (unbox contador) 0)
  (check-equal? (stream-first (stream-rest unidos)) 2)
  (check-true (<= (unbox contador) 2)))

(test-case "el generador no usa conversion de listas completas"
  (define fuente (file->string generador))
  (check-false (regexp-match? #rx"list->stream" fuente))
  (check-false (regexp-match? #rx"stream->list" fuente)))
