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
(define-runtime-path no-objeto "data/preferencias_no_objeto.json")
(define-runtime-path creditos-negativos "data/preferencias_creditos_negativos.json")
(define-runtime-path carrera-invalida "data/preferencias_carrera_invalida.json")
(define-runtime-path codigo-vacio "data/preferencias_codigo_vacio.json")
(define-runtime-path grupos-vacios "data/preferencias_grupos_vacios.json")
(define-runtime-path grupo-no-positivo "data/preferencias_grupo_no_positivo.json")
(define-runtime-path grupos-repetidos "data/preferencias_grupos_repetidos.json")
(define-runtime-path courses-no-lista "data/preferencias_courses_no_lista.json")
(define-runtime-path sin-maximo "data/preferencias_sin_maximo.json")
(define-runtime-path json-malformado "data/preferencias_json_malformado.json")
(define-runtime-path vacio "data/preferencias_vacio.json")
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

(test-case "validaciones del contrato de preferencias"
  (check-exn exn:fail:user? (lambda () (leer-preferencias no-objeto)) "se esperaba un objeto")
  (check-exn exn:fail:user? (lambda () (leer-preferencias creditos-negativos)) "creditos negativos")
  (check-exn exn:fail:user? (lambda () (leer-preferencias carrera-invalida)) "carrera invalida")
  (check-exn exn:fail:user? (lambda () (leer-preferencias codigo-vacio)) "codigo vacio")
  (check-exn exn:fail:user? (lambda () (leer-preferencias grupos-vacios)) "sin grupos")
  (check-exn exn:fail:user? (lambda () (leer-preferencias grupo-no-positivo)) "grupo no positivo")
  (check-exn exn:fail:user? (lambda () (leer-preferencias grupos-repetidos)) "grupos repetidos")
  (check-exn exn:fail:user? (lambda () (leer-preferencias courses-no-lista)) "courses no es lista")
  (check-exn exn:fail:user? (lambda () (leer-preferencias sin-maximo)) "falta max_credits")
  (check-exn exn:fail:user? (lambda () (leer-preferencias json-malformado)) "JSON malformado")
  (check-exn exn:fail:user? (lambda () (leer-preferencias vacio)) "archivo vacio"))
