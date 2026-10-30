#lang racket

;; prueba de punta a punta de main.rkt con el catalogo sintetico

(require rackunit
         json
         racket/runtime-path
         "../src/main.rkt")

(define-runtime-path sintetico "data/catalogo_sintetico.json")
(define-runtime-path varios-grupos "data/preferencias_varios_grupos.json")
(define-runtime-path no-habilitado "data/preferencias_no_habilitado.json")
(define-runtime-path rango-imposible "data/preferencias_rango_imposible.json")
(define-runtime-path inexistente "data/no_existe.json")

;; corre el flujo hacia un archivo temporal y devuelve cantidad, avisos y lineas
(define (correr prefs)
  (define ruta (make-temporary-file "salida~a.jsonl"))
  (define-values (cantidad avisos) (ejecutar prefs ruta (list sintetico)))
  (define lineas (map string->jsexpr (file->lines ruta)))
  (delete-file ruta)
  (values cantidad avisos lineas))

(test-case "flujo completo con varios grupos por curso"
  (define-values (cantidad avisos lineas) (correr varios-grupos))
  (check-equal? cantidad 26)
  (check-equal? (length lineas) 26)
  (check-equal? avisos '()))

(test-case "los avisos del universo llegan al programa principal"
  (define-values (cantidad avisos lineas) (correr no-habilitado))
  (check-equal? (length avisos) 8))

(test-case "rango sin resultados deja el archivo vacio"
  (define-values (cantidad avisos lineas) (correr rango-imposible))
  (check-equal? cantidad 0)
  (check-equal? lineas '()))

(test-case "archivo de entrada inexistente es un error controlado"
  (check-exn exn:fail:user?
             (lambda () (ejecutar inexistente (make-temporary-file) (list sintetico)))))