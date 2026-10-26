#lang racket

;; pruebas de exportador.rkt: se escribe el archivo y se vuelve a leer linea por linea

(require rackunit
         json
         racket/runtime-path
         racket/stream
         "../src/types.rkt"
         "../src/catalogo.rkt"
         "../src/preferencias.rkt"
         "../src/universo.rkt"
         "../src/generador.rkt"
         "../src/filtros.rkt"
         "../src/exportador.rkt")

(define-runtime-path sintetico "data/catalogo_sintetico.json")
(define-runtime-path varios-grupos "data/preferencias_varios_grupos.json")

;; combinaciones del catalogo sintetico entre 6 y 10 creditos
(define combinaciones
  (filtrar-por-rango
   (generar-combinaciones
    (construir-universo (leer-catalogo (list sintetico)) (leer-preferencias varios-grupos)))
   combinacion-creditos 6 10))

(test-case "horas en formato HH:MM"
  (check-equal? (minutos->hora 450) "07:30")
  (check-equal? (minutos->hora 0) "00:00")
  (check-equal? (minutos->hora 1439) "23:59"))

(test-case "una combinacion trae los campos obligatorios"
  (define j (combinacion->jsexpr 1 (stream-first combinaciones)))
  (check-equal? (hash-ref j 'id) 1)
  (check-equal? (hash-ref j 'course_count) (length (hash-ref j 'courses)))
  (check-equal? (hash-ref j 'total_credits)
                (apply + (map (lambda (c) (hash-ref c 'credits)) (hash-ref j 'courses))))
  (check-true (andmap (lambda (c) (hash-has-key? c 'career)) (hash-ref j 'courses))))