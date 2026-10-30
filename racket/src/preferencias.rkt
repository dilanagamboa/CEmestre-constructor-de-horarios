#lang racket

;; lee el archivo de preferencias del estudiante (JSON):
;; {"min_credits": 12, "max_credits": 18,
;;  "courses": [{"career": "computadores", "code": "CE2103", "groups": [1, 2]}, ...]}
;; aqui solo se valida el formato; si los cursos y grupos existen lo revisa universo.rkt

(require "types.rkt" "lectura.rkt")

(provide
 (contract-out
  [leer-preferencias (-> path-string? preferencias?)]))

(define CARRERAS '(computadores fisica))

;; #t si la lista no tiene elementos repetidos
(define (sin-repetidos? lista)
  (or (empty? lista)
      (and (not (member (first lista) (rest lista)))
           (sin-repetidos? (rest lista)))))

(define (json->interes donde j)
  (define codigo (campo donde j 'code non-empty-string? "un texto no vacio"))
  (define aqui (format "~a curso ~a" donde codigo))
  (define carrera (string->symbol (campo aqui j 'career string? "un texto")))
  (define grupos (campo aqui j 'groups (lista-de exact-positive-integer?) "una lista de enteros positivos"))
  (cond
    [(not (memq carrera CARRERAS)) (error-lectura aqui "carrera invalida ~a" carrera)]
    [(empty? grupos) (error-lectura aqui "debe indicar al menos un grupo")]
    [(not (sin-repetidos? grupos)) (error-lectura aqui "hay grupos repetidos")]
    [else (interes carrera codigo grupos)]))

(define (leer-preferencias ruta)
  (define donde (format "~a" ruta))
  (define datos (leer-json ruta))
  (unless (hash? datos)
    (error-lectura donde "se esperaba un objeto JSON"))
  (define minimo (campo donde datos 'min_credits exact-nonnegative-integer? "un entero no negativo"))
  (define maximo (campo donde datos 'max_credits exact-nonnegative-integer? "un entero no negativo"))
  (define intereses
    (map (lambda (j) (json->interes donde j))
         (campo donde datos 'courses (lista-de hash?) "una lista de cursos")))
  (if (<= minimo maximo)
      (preferencias intereses minimo maximo)
      (error-lectura donde "min_credits (~a) es mayor que max_credits (~a)" minimo maximo)))
