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
  [en-rango (parametric->/c (A) (-> (-> A real?) real? real? (-> A boolean?)))]
  [filtrar-por-rango (-> (stream/c any/c)
                         (-> any/c real?)
                         real?
                         real?
                         (stream/c any/c))]))

;; construye el criterio: #t si el valor que extraer saca del elemento esta en
;; [minimo, maximo]; es parametrico en A porque nunca inspecciona el elemento,
;; solo se lo pasa a extraer
(define (en-rango extraer minimo maximo)
  (lambda (elemento)
    (<= minimo (extraer elemento) maximo)))

(define (filtrar-por-rango elementos extraer minimo maximo)
  (unless (<= minimo maximo)
    (raise-arguments-error 'filtrar-por-rango
                           "el minimo no puede ser mayor que el maximo"
                           "minimo" minimo
                           "maximo" maximo))
  (stream-filter (en-rango extraer minimo maximo) elementos))
