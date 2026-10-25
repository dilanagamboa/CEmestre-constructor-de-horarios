#lang racket

;; pruebas de universo.rkt: cruce de preferencias con el catalogo sintetico

(require rackunit
         racket/runtime-path
         "../src/types.rkt"
         "../src/catalogo.rkt"
         "../src/preferencias.rkt"
         "../src/universo.rkt")

(define-runtime-path sintetico "data/catalogo_sintetico.json")
(define-runtime-path varios-grupos "data/preferencias_varios_grupos.json")
(define-runtime-path no-habilitado "data/preferencias_no_habilitado.json")

(define cat (leer-catalogo (list sintetico)))

;; codigo y numeros de grupo de cada curso del universo
(define (resumen u)
  (map (lambda (c) (cons (curso-codigo c) (map grupo-numero (curso-grupos c))))
       (universo-cursos u)))

(test-case "varios grupos por curso"
  (define u (construir-universo cat (leer-preferencias varios-grupos)))
  (check-equal? (resumen u) '(("S1" 1 2) ("S2" 1 2) ("S3" 1 2) ("S4" 1)))
  (check-equal? (universo-avisos u) '()))

(test-case "cursos no habilitados, inexistentes, repetidos y grupos que no existen"
  (define u (construir-universo cat (leer-preferencias no-habilitado)))
  (check-equal? (resumen u) '(("S1" 1 2)) "solo S1 queda en el universo")
  (check-equal? (length (universo-avisos u)) 8)
  (check-not-false (member "computadores S5: no esta habilitado (faltan requisitos)" (universo-avisos u)))
  (check-not-false (member "computadores S6: ya esta aprobado" (universo-avisos u)))
  (check-not-false (member "computadores S9: no esta en el catalogo" (universo-avisos u)))
  (check-not-false (member "computadores S2: no tiene el grupo 3" (universo-avisos u)))
  (check-not-false (member "computadores S1: esta repetido, se usa la primera aparicion" (universo-avisos u))))
