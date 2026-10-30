#lang racket

;; casos limite de la Fase 5: rangos extremos, un solo curso y un universo grande

(require rackunit
         json
         racket/runtime-path
         racket/stream
         "../src/types.rkt"
         "../src/catalogo.rkt"
         "../src/generador.rkt"
         "../src/main.rkt")

(define-runtime-path sintetico "data/catalogo_sintetico.json")
(define-runtime-path min-igual-max "data/preferencias_min_igual_max.json")
(define-runtime-path un-curso "data/preferencias_un_curso.json")
(define-runtime-path computadores "../../data/salida_computadores.json")
(define-runtime-path fisica "../../data/salida_fisica.json")

;; corre el flujo con el catalogo sintetico y devuelve las lineas exportadas
(define (lineas-de prefs)
  (define ruta (make-temporary-file "salida~a.jsonl"))
  (define-values (cantidad avisos) (ejecutar prefs ruta (list sintetico)))
  (define lineas (map string->jsexpr (file->lines ruta)))
  (delete-file ruta)
  lineas)

;; texto "S1-1 S4-1" de una linea, igual que en los archivos esperados
(define (resumen l)
  (string-join (map (lambda (c) (format "~a-~a" (hash-ref c 'code) (hash-ref c 'group)))
                    (hash-ref l 'courses))))

(test-case "minimo igual a maximo: solo combinaciones de exactamente 6 creditos"
  (define lineas (lineas-de min-igual-max))
  (check-equal? (length lineas) 6)
  (check-true (andmap (lambda (l) (= (hash-ref l 'total_credits) 6)) lineas))
  (check-equal? (sort (map resumen lineas) string<?)
                (sort '("S2-1 S3-1" "S2-1 S3-2" "S2-2 S3-1" "S2-2 S3-2" "S1-1 S4-1" "S1-2 S4-1")
                      string<?)))

(test-case "un solo curso con un solo grupo produce una sola combinacion"
  (define lineas (lineas-de un-curso))
  (check-equal? (map resumen lineas) '("S4-1"))
  (check-equal? (hash-ref (first lineas) 'total_credits) 2))

(test-case "universo grande: todos los cursos habilitados reales con todos sus grupos"
  ;; con este universo hay del orden de 3.5e14 combinaciones posibles; pedir
  ;; las primeras 100 termina de inmediato porque el stream solo calcula lo que se pide
  (define cursos (cursos-habilitados (leer-catalogo (list computadores fisica))))
  (define primeras (stream->list (stream-take (generar-combinaciones-de-cursos cursos) 100)))
  (check-equal? (length primeras) 100)
  (check-true (andmap combinacion? primeras)))