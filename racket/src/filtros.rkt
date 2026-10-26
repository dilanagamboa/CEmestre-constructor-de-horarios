#lang racket

;; filtro generico y perezoso por rango inclusivo.
;;
;; No conoce Combinacion ni ningun otro tipo concreto: recibe cualquier
;; stream, una funcion que extrae de cada elemento un numero real y los dos
;; limites del rango. Por eso sirve igual para enteros, cadenas (usando su
;; longitud como valor comparable) o combinaciones (usando sus creditos).
;;
;; El stream de salida conserva la pereza del stream de entrada: stream-filter
;; solo pide elementos al stream original cuando alguien pide elementos del
;; resultado.

(require racket/stream)

(provide
 (contract-out
  [filtrar-por-rango (-> (stream/c any/c)
                         (-> any/c real?)
                         real?
                         real?
                         (stream/c any/c))]))

(define (filtrar-por-rango elementos extraer minimo maximo)
  (unless (<= minimo maximo)
    (raise-arguments-error 'filtrar-por-rango
                           "el minimo no puede ser mayor que el maximo"
                           "minimo" minimo
                           "maximo" maximo))
  (stream-filter (lambda (elemento)
                   (define valor (extraer elemento))
                   (and (<= minimo valor) (<= valor maximo)))
                 elementos))
