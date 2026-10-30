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


;; exporta a un archivo temporal y devuelve cuantas escribio y las lineas leidas
(define (exportar-y-leer stream)
  (define ruta (make-temporary-file "salida~a.jsonl"))
  (define escritas (exportar-combinaciones stream ruta))
  (define lineas (map string->jsexpr (file->lines ruta)))
  (delete-file ruta)
  (values escritas lineas))

(test-case "ida y vuelta: una linea por combinacion"
  (define-values (escritas lineas) (exportar-y-leer combinaciones))
  (check-equal? escritas 26)
  (check-equal? (length lineas) 26)
  (check-equal? (map (lambda (l) (hash-ref l 'id)) lineas) (range 1 27)))

(test-case "campos obligatorios y coherencia"
  (define-values (escritas lineas) (exportar-y-leer combinaciones))
  (for-each
   (lambda (l)
     (define cursos (hash-ref l 'courses))
     (check-equal? (hash-ref l 'total_credits)
                   (apply + (map (lambda (c) (hash-ref c 'credits)) cursos)))
     (check-true (<= 6 (hash-ref l 'total_credits) 10))
     (check-equal? (hash-ref l 'course_count) (length cursos))
     (for-each
      (lambda (c)
        (check-not-false (member (hash-ref c 'career) '("computadores" "fisica")))
        (check-true (exact-positive-integer? (hash-ref c 'group))))
      cursos))
   lineas))

(test-case "la primera linea coincide con la primera combinacion"
  (define-values (escritas lineas) (exportar-y-leer combinaciones))
  (check-equal? (first lineas)
                (combinacion->jsexpr 1 (stream-first combinaciones))))

(test-case "sin combinaciones queda un archivo vacio"
  (define-values (escritas lineas) (exportar-y-leer empty-stream))
  (check-equal? escritas 0)
  (check-equal? lineas '()))