#lang racket

;; exporta las combinaciones en JSON Lines: un objeto JSON por linea
;; el stream se consume de a un elemento con recursion, cada combinacion se
;; escribe apenas se genera y nunca se arma la lista completa en memoria

(require json
         racket/stream
         "types.rkt")

(provide
 (contract-out
  [minutos->hora (-> minuto/c string?)]))

;; minutos desde las 00:00 a "HH:MM", el mismo formato que exporta C
(define (minutos->hora m)
  (format "~a:~a"
          (~r (quotient m 60) #:min-width 2 #:pad-string "0")
          (~r (remainder m 60) #:min-width 2 #:pad-string "0")))

(define (bloque->jsexpr b)
  (hasheq 'day (symbol->string (bloque-dia b))
          'start (minutos->hora (bloque-inicio b))
          'end (minutos->hora (bloque-fin b))))