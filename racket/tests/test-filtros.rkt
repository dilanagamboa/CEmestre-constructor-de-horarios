#lang racket

;; pruebas del filtro polimorfico: enteros, cadenas y combinaciones

(require rackunit
         racket/runtime-path
         racket/stream
         "../src/types.rkt"
         "../src/catalogo.rkt"
         "../src/preferencias.rkt"
         "../src/universo.rkt"
         "../src/generador.rkt"
         "../src/filtros.rkt")

(define-runtime-path sintetico "data/catalogo_sintetico.json")
(define-runtime-path rango-total "data/preferencias_rango_total.json")

(define cat (leer-catalogo (list sintetico)))
(define universo (construir-universo cat (leer-preferencias rango-total)))
(define combinaciones (generar-combinaciones universo))

(test-case "enteros con limites inclusivos"
  (check-equal? (stream->list (filtrar-por-rango (stream 1 2 3 4 5) identity 2 4))
                '(2 3 4))
  (check-equal? (stream->list (filtrar-por-rango (stream 1 2 3) identity 2 2))
                '(2))
  (check-equal? (stream->list (filtrar-por-rango (stream 1 2 3) identity 0 100))
                '(1 2 3))
  (check-true (stream-empty? (filtrar-por-rango (stream 1 2 3) identity 10 20))))

(test-case "cadenas con un valor derivado"
  (check-equal? (stream->list (filtrar-por-rango (stream "a" "bb" "ccc" "dddd")
                                                 string-length 2 3))
                '("bb" "ccc"))
  (check-equal? (stream->list (filtrar-por-rango (stream "1" "12" "123" "1234")
                                                 (lambda (s) (string->number s)) 12 123))
                '("12" "123")))

(test-case "combinaciones por creditos"
  (define filtradas (filtrar-por-rango combinaciones combinacion-creditos 6 10))
  (check-equal? (stream-length filtradas) 26)
  (check-true (andmap (lambda (c) (<= 6 (combinacion-creditos c) 10))
                      (stream->list filtradas))))

(test-case "combinaciones con un segundo extractor"
  (define filtradas
    (filtrar-por-rango combinaciones
                       (lambda (c) (length (combinacion-pares c)))
                       2 3))
  (check-true (andmap (lambda (c) (<= 2 (length (combinacion-pares c)) 3))
                      (stream->list filtradas)))
  (check-true (< 0 (stream-length filtradas))))

(test-case "elementos fuera del rango"
  (check-equal? (stream->list (filtrar-por-rango (stream -2 -1 0 1 2) identity 0 1))
                '(0 1)))

(test-case "minimo mayor que maximo"
  (check-exn exn:fail:contract?
             (lambda () (filtrar-por-rango (stream 1 2 3) identity 5 1))))

(test-case "el filtro conserva la pereza"
  (define contador (box 0))
  (define (naturales n)
    (stream-cons n
                 (begin
                   (set-box! contador (add1 (unbox contador)))
                   (naturales (add1 n)))))
  (define primeros (filtrar-por-rango (naturales 0) identity 100 200))
  (check-equal? (stream-first primeros) 100)
  (check-true (< (unbox contador) 200)
              "no se recorrio el stream completo para obtener el primer resultado"))

(test-case "en-rango es parametrico: mismo criterio para tres tipos"
  (check-true ((en-rango identity 1 5) 3))
  (check-false ((en-rango string-length 1 2) "abc"))
  (check-true ((en-rango (lambda (p) (car p)) 0 10) (cons 7 "x"))))

  
(define-runtime-path varios-grupos "data/preferencias_varios_grupos.json")

(test-case "filtro de creditos con el rango de las preferencias"
  (define prefs (leer-preferencias varios-grupos))
  (define filtradas (stream->list (filtrar-por-creditos combinaciones prefs)))
  (check-equal? (length filtradas) 26)
  (check-true (andmap (lambda (k) (<= 6 (combinacion-creditos k) 10)) filtradas)))