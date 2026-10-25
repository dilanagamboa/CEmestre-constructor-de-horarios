#lang racket

;; pruebas de catalogo.rkt: archivo valido, fila corrupta, archivo vacio e inexistente

(require rackunit
         racket/runtime-path
         "../src/types.rkt"
         "../src/catalogo.rkt")

(define-runtime-path sintetico "data/catalogo_sintetico.json")
(define-runtime-path corrupto "data/catalogo_corrupto.json")
(define-runtime-path vacio "data/catalogo_vacio.json")
(define-runtime-path inexistente "data/no_existe.json")
(define-runtime-path real-computadores "../../data/salida_computadores.json")
(define-runtime-path real-fisica "../../data/salida_fisica.json")

(test-case "horas"
  (check-equal? (hora->minutos "07:30") 450)
  (check-equal? (hora->minutos "00:00") 0)
  (check-false (hora->minutos "25:00"))
  (check-false (hora->minutos "7:30")))

(test-case "catalogo sintetico valido"
  (define cat (leer-catalogo (list sintetico)))
  (check-equal? (length (catalogo-cursos cat)) 7)
  (check-equal? (map curso-codigo (cursos-habilitados cat)) '("S1" "S2" "S3" "S4" "S7"))
  (check-equal? (curso-carrera (buscar-curso cat 'fisica "S3")) 'fisica)
  (check-false (buscar-curso cat 'computadores "S3") "S3 es de fisica")
  (check-equal? (bloque (quote MON) 480 600)
                (first (grupo-bloques (first (curso-grupos (buscar-curso cat 'computadores "S1")))))))

(test-case "errores controlados"
  (check-exn exn:fail:user? (lambda () (leer-catalogo (list corrupto))) "hora 25:00")
  (check-exn exn:fail:user? (lambda () (leer-catalogo (list vacio))) "archivo vacio")
  (check-exn exn:fail:user? (lambda () (leer-catalogo (list inexistente))) "archivo inexistente")
  (check-exn exn:fail:user? (lambda () (leer-catalogo (list sintetico sintetico))) "cursos repetidos"))

(test-case "catalogo real de las dos carreras"
  (define cat (leer-catalogo (list real-computadores real-fisica)))
  (check-true (and (buscar-curso cat 'computadores "FI1102")
                   (buscar-curso cat 'fisica "FI1102")
                   #t)
              "FI1102 esta en las dos carreras como cursos distintos")
  (check-true (andmap curso-matriculable (cursos-habilitados cat))))
