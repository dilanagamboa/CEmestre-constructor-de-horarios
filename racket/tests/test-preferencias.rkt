#lang racket

;; pruebas de preferencias.rkt con los archivos de prueba

(require rackunit
         racket/runtime-path
         "../src/types.rkt"
         "../src/preferencias.rkt")

(define-runtime-path varios-grupos "data/preferencias_varios_grupos.json")
(define-runtime-path no-habilitado "data/preferencias_no_habilitado.json")
(define-runtime-path rango-imposible "data/preferencias_rango_imposible.json")
(define-runtime-path rango-total "data/preferencias_rango_total.json")
(define-runtime-path min-mayor "data/preferencias_min_mayor.json")
(define-runtime-path inexistente "data/no_existe.json")
(define-runtime-path reales "../../data/preferencias.json")

(test-case "varios grupos por curso"
  (define p (leer-preferencias varios-grupos))
  (check-equal? (preferencias-creditos-min p) 6)
  (check-equal? (preferencias-creditos-max p) 10)
  (check-equal? (first (preferencias-intereses p)) (interes 'computadores "S1" '(1 2)))
  (check-equal? (interes-carrera (third (preferencias-intereses p))) 'fisica))

(test-case "los demas archivos de prueba cargan"
  (check-equal? (length (preferencias-intereses (leer-preferencias no-habilitado))) 7)
  (check-equal? (preferencias-creditos-min (leer-preferencias rango-imposible)) 20)
  (check-equal? (preferencias-creditos-max (leer-preferencias rango-total)) 100)
  (check-true (preferencias? (leer-preferencias reales))))

(test-case "errores controlados"
  (check-exn exn:fail:user? (lambda () (leer-preferencias min-mayor)) "minimo mayor que maximo")
  (check-exn exn:fail:user? (lambda () (leer-preferencias inexistente)) "archivo inexistente"))
