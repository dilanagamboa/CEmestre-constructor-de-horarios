#lang racket

;; evidencia del prototipo de streams: una cola no se evalua hasta pedirla
;; las colas lanzan error: si se evaluaran antes de tiempo, la prueba falla

(require rackunit
         racket/runtime-path
         racket/stream)

(define-runtime-path generador "../src/generador.rkt")

(test-case "stream-cons difiere la evaluacion de la cola"
  ;; si la cola se evaluara al construir el stream, el error saltaria aqui
  (define s (stream-cons 0 (error "la cola se evaluo antes de tiempo")))
  (check-equal? (stream-first s) 0)
  ;; la cola solo se evalua cuando se pide
  (check-exn exn:fail? (lambda () (stream-first (stream-rest s)))))

(test-case "stream-append tambien conserva la pereza"
  (define unidos (stream-append (stream-cons 1 (error "cola evaluada antes de tiempo"))
                                (stream-cons 2 empty-stream)))
  (check-equal? (stream-first unidos) 1))

(test-case "el generador no usa conversion de listas completas"
  (define fuente (file->string generador))
  (check-false (regexp-match? #rx"list->stream" fuente))
  (check-false (regexp-match? #rx"stream->list" fuente)))
