#lang racket

;; validacion de la salida con los datos reales de las dos carreras (6 semestres)
;; lee el archivo JSON Lines como lo haria la Etapa 3, sin usar los structs de
;; Racket, y revisa cada combinacion contra el catalogo de C

(require rackunit
         json
         racket/runtime-path
         "../src/main.rkt")

(define-runtime-path computadores "../../data/salida_computadores.json")
(define-runtime-path fisica "../../data/salida_fisica.json")
(define-runtime-path preferencias "../../data/preferencias.json")

(define ruta (make-temporary-file "salida~a.jsonl"))
(define-values (cantidad avisos) (ejecutar preferencias ruta (list computadores fisica)))
(define lineas (map string->jsexpr (file->lines ruta)))
(delete-file ruta)

(define prefs (call-with-input-file preferencias read-json))
(define minimo (hash-ref prefs 'min_credits))
(define maximo (hash-ref prefs 'max_credits))

;; cursos de C indexados por (carrera codigo), leidos directo del JSON
(define cursos-c
  (append-map (lambda (r) (hash-ref (call-with-input-file r read-json) 'courses))
              (list computadores fisica)))
(define (curso-c carrera codigo)
  (findf (lambda (c) (and (equal? (hash-ref c 'career) carrera)
                          (equal? (hash-ref c 'code) codigo)))
         cursos-c))

;; "HH:MM" a minutos, independiente de catalogo.rkt
(define (minutos h)
  (+ (* 60 (string->number (substring h 0 2))) (string->number (substring h 3 5))))

;; misma regla que conflicts.c: mismo dia y traslape con < estricto
(define (chocan? a b)
  (for*/or ([x (hash-ref a 'blocks)] [y (hash-ref b 'blocks)])
    (and (equal? (hash-ref x 'day) (hash-ref y 'day))
         (< (minutos (hash-ref x 'start)) (minutos (hash-ref y 'end)))
         (< (minutos (hash-ref y 'start)) (minutos (hash-ref x 'end))))))

(test-case "se exporto al menos una combinacion y la cantidad coincide"
  (check-true (> cantidad 0))
  (check-equal? (length lineas) cantidad))

(test-case "creditos: suma correcta y dentro del rango"
  (for ([l lineas])
    (define cursos (hash-ref l 'courses))
    (check-equal? (hash-ref l 'total_credits)
                  (apply + (map (lambda (c) (hash-ref c 'credits)) cursos)))
    (check-true (<= minimo (hash-ref l 'total_credits) maximo))))

(test-case "ningun choque dentro de una combinacion"
  (for ([l lineas])
    (define cursos (hash-ref l 'courses))
    (for* ([i (in-range (length cursos))] [j (in-range (add1 i) (length cursos))])
      (check-false (chocan? (list-ref cursos i) (list-ref cursos j))
                   (format "combinacion ~a" (hash-ref l 'id))))))

(test-case "cada curso coincide con el catalogo de C"
  (for ([l lineas])
    (for ([c (hash-ref l 'courses)])
      (define original (curso-c (hash-ref c 'career) (hash-ref c 'code)))
      (check-not-false original)
      (check-true (hash-ref original 'can_enroll))
      (check-equal? (hash-ref c 'credits) (hash-ref original 'credits))
      (check-not-false (findf (lambda (g) (= (hash-ref g 'number) (hash-ref c 'group)))
                              (hash-ref original 'groups))))))

(test-case "un curso aparece una sola vez por combinacion"
  (for ([l lineas])
    (define claves (map (lambda (c) (list (hash-ref c 'career) (hash-ref c 'code)))
                        (hash-ref l 'courses)))
    (check-false (check-duplicates claves))))