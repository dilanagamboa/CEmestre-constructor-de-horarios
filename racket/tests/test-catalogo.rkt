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
(define-runtime-path carrera-invalida "data/catalogo_carrera_invalida.json")
(define-runtime-path conteo-incorrecto "data/catalogo_conteo_incorrecto.json")
(define-runtime-path codigo-repetido "data/catalogo_codigo_repetido.json")
(define-runtime-path mismo-codigo "data/catalogo_mismo_codigo_dos_carreras.json")
(define-runtime-path grupo-repetido "data/catalogo_grupo_repetido.json")
(define-runtime-path sin-campo "data/catalogo_sin_campo.json")
(define-runtime-path auto-requisito "data/catalogo_auto_requisito.json")
(define-runtime-path choque-incoherente "data/catalogo_choque_incoherente.json")
(define-runtime-path formato-version "data/catalogo_formato_version.json")
(define-runtime-path json-malformado "data/catalogo_json_malformado.json")
(define-runtime-path no-objeto "data/catalogo_no_objeto.json")
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

(test-case "validaciones del contrato del catalogo"
  (check-exn exn:fail:user? (lambda () (leer-catalogo (list carrera-invalida))) "carrera invalida")
  (check-exn exn:fail:user? (lambda () (leer-catalogo (list conteo-incorrecto))) "course_count incorrecto")
  (check-exn exn:fail:user? (lambda () (leer-catalogo (list codigo-repetido))) "codigo repetido")
  (check-exn exn:fail:user? (lambda () (leer-catalogo (list grupo-repetido))) "grupo repetido")
  (check-exn exn:fail:user? (lambda () (leer-catalogo (list sin-campo))) "campo obligatorio faltante")
  (check-exn exn:fail:user? (lambda () (leer-catalogo (list auto-requisito))) "curso requisito de si mismo")
  (check-exn exn:fail:user? (lambda () (leer-catalogo (list choque-incoherente))) "has_conflict incoherente")
  (check-exn exn:fail:user? (lambda () (leer-catalogo (list formato-version))) "format_version distinto")
  (check-exn exn:fail:user? (lambda () (leer-catalogo (list json-malformado))) "JSON malformado")
  (check-exn exn:fail:user? (lambda () (leer-catalogo (list no-objeto))) "JSON que no es objeto"))

(test-case "mismo codigo en carreras diferentes"
  (define cat (leer-catalogo (list mismo-codigo)))
  (check-equal? (length (catalogo-cursos cat)) 2)
  (check-equal? (curso-creditos (buscar-curso cat 'computadores "X1")) 2)
  (check-equal? (curso-creditos (buscar-curso cat 'fisica "X1")) 3)
  (check-false (buscar-curso cat 'computadores "NOEXISTE")))

(test-case "catalogo real de las dos carreras"
  (define cat (leer-catalogo (list real-computadores real-fisica)))
  (check-true (and (buscar-curso cat 'computadores "FI1102")
                   (buscar-curso cat 'fisica "FI1102")
                   #t)
              "FI1102 esta en las dos carreras como cursos distintos")
  (check-true (andmap curso-matriculable (cursos-habilitados cat))))
