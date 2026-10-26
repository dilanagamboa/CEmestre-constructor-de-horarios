#lang racket

;; pruebas del generador perezoso contra oraculos manuales y casos minimos

(require rackunit
         racket/runtime-path
         racket/stream
         racket/string
         "../src/types.rkt"
         "../src/catalogo.rkt"
         "../src/preferencias.rkt"
         "../src/universo.rkt"
         "../src/generador.rkt"
         "../src/filtros.rkt")

(define-runtime-path sintetico "data/catalogo_sintetico.json")
(define-runtime-path rango-total "data/preferencias_rango_total.json")
(define-runtime-path varios-grupos "data/preferencias_varios_grupos.json")
(define-runtime-path esperado-total "data/esperado_rango_total.txt")
(define-runtime-path esperado-varios "data/esperado_varios_grupos.txt")

;; atajos para los casos armados a mano
(define (b dia inicio fin) (bloque dia inicio fin))
(define (g numero . bloques) (grupo numero "P" bloques #f))
(define (c codigo creditos grupos)
  (curso 'computadores codigo codigo creditos '() '() grupos #f #t))

(define (par->texto p)
  (format "~a-~a"
          (curso-codigo (par-curso-grupo-curso p))
          (grupo-numero (par-curso-grupo-grupo p))))

(define (combinacion->texto combinacion)
  (format "~a | ~a"
          (string-join (map par->texto (combinacion-pares combinacion)) " ")
          (combinacion-creditos combinacion)))

(define (lineas-oraculo ruta)
  (for/list ([linea (in-list (file->lines ruta))]
             #:unless (or (string=? linea "")
                          (string-prefix? linea "#")))
    linea))

(define cat (leer-catalogo (list sintetico)))

(define (combinaciones-con-preferencias ruta minimo maximo)
  (define universo (construir-universo cat (leer-preferencias ruta)))
  (stream->list
   (filtrar-por-rango (generar-combinaciones universo)
                      combinacion-creditos minimo maximo)))

(test-case "oraculo del rango total"
  (define combinaciones (combinaciones-con-preferencias rango-total 0 100))
  (check-equal? (length combinaciones) 41)
  (check-equal? (map combinacion->texto combinaciones)
                (lineas-oraculo esperado-total)))

(test-case "oraculo de varios grupos"
  (define combinaciones (combinaciones-con-preferencias varios-grupos 6 10))
  (check-equal? (length combinaciones) 26)
  (check-equal? (map combinacion->texto combinaciones)
                (lineas-oraculo esperado-varios)))

(test-case "invariantes de las combinaciones"
  (define combinaciones (combinaciones-con-preferencias rango-total 0 100))
  (check-true (andmap (lambda (c) (not (empty? (combinacion-pares c))))
                      combinaciones)
              "la combinacion vacia no se emite")
  (check-true
   (andmap
    (lambda (c)
      (= (combinacion-creditos c)
         (for/sum ([p (in-list (combinacion-pares c))])
           (curso-creditos (par-curso-grupo-curso p)))))
    combinaciones)
   "los creditos son la suma de los cursos elegidos"))

(test-case "universo vacio"
  (check-true (stream-empty? (generar-combinaciones (universo '() '()))))
  (check-true (stream-empty? (generar-combinaciones-de-cursos '()))))

(test-case "un curso con un solo grupo"
  (define curso-a (c "A" 3 (list (g 1 (b 'MON 480 600)))))
  (check-equal? (map combinacion->texto
                     (stream->list (generar-combinaciones-de-cursos (list curso-a))))
                '("A-1 | 3")))

(test-case "un curso con varios grupos"
  (define curso-a (c "A" 3 (list (g 1 (b 'MON 480 600))
                                 (g 2 (b 'TUE 480 600)))))
  (check-equal? (map combinacion->texto
                     (stream->list (generar-combinaciones-de-cursos (list curso-a))))
                '("A-1 | 3" "A-2 | 3")))

(test-case "dos cursos sin choque"
  (define curso-a (c "A" 3 (list (g 1 (b 'MON 480 600)))))
  (define curso-b (c "B" 3 (list (g 1 (b 'TUE 480 600)))))
  (check-equal? (map combinacion->texto
                     (stream->list (generar-combinaciones-de-cursos
                                    (list curso-a curso-b))))
                '("B-1 | 3" "A-1 | 3" "A-1 B-1 | 6")))

(test-case "dos cursos con choque contenido"
  (define curso-a (c "A" 3 (list (g 1 (b 'MON 480 600)))))
  (define curso-b (c "B" 3 (list (g 1 (b 'MON 540 600)))))
  (check-equal? (map combinacion->texto
                     (stream->list (generar-combinaciones-de-cursos
                                    (list curso-a curso-b))))
                '("B-1 | 3" "A-1 | 3")))

(test-case "dos cursos con choque parcial"
  (define curso-a (c "A" 3 (list (g 1 (b 'MON 480 600)))))
  (define curso-b (c "B" 3 (list (g 1 (b 'MON 540 660)))))
  (check-equal? (map combinacion->texto
                     (stream->list (generar-combinaciones-de-cursos
                                    (list curso-a curso-b))))
                '("B-1 | 3" "A-1 | 3")))

(test-case "borde sin choque"
  (define curso-a (c "A" 3 (list (g 1 (b 'MON 480 600)))))
  (define curso-b (c "B" 3 (list (g 1 (b 'MON 600 720)))))
  (check-equal? (map combinacion->texto
                     (stream->list (generar-combinaciones-de-cursos
                                    (list curso-a curso-b))))
                '("B-1 | 3" "A-1 | 3" "A-1 B-1 | 6")))

(test-case "grupos con varios bloques"
  (define curso-a (c "A" 3 (list (g 1 (b 'MON 480 600) (b 'WED 480 600)))))
  (define curso-b (c "B" 3 (list (g 1 (b 'WED 540 660)))))
  (check-equal? (map combinacion->texto
                     (stream->list (generar-combinaciones-de-cursos
                                    (list curso-a curso-b))))
                '("B-1 | 3" "A-1 | 3")))

(test-case "curso sin grupos"
  (define sin-grupos (c "A" 3 '()))
  (define curso-b (c "B" 2 (list (g 1 (b 'TUE 480 600)))))
  (check-true (stream-empty? (generar-combinaciones-de-cursos (list sin-grupos))))
  (check-equal? (map combinacion->texto
                     (stream->list (generar-combinaciones-de-cursos
                                    (list sin-grupos curso-b))))
                '("B-1 | 2")))

(test-case "creditos acumulados"
  (define curso-a (c "A" 4 (list (g 1 (b 'MON 480 600)))))
  (define curso-b (c "B" 2 (list (g 1 (b 'TUE 480 600)))))
  (define combinaciones
    (stream->list (generar-combinaciones-de-cursos (list curso-a curso-b))))
  (check-equal? (map combinacion-creditos combinaciones) '(2 4 6)))

(test-case "pedir solo el primer resultado de un catalogo grande"
  ;; 60 cursos de un grupo producen 2^60 - 1 combinaciones; si el generador
  ;; fuese eager esta prueba no terminaria.
  (define grandes
    (for/list ([i (in-range 60)])
      (c (format "C~a" i) 1 (list (g 1)))))
  (define primera (stream-first (generar-combinaciones-de-cursos grandes)))
  (check-equal? (combinacion->texto primera) "C59-1 | 1"))
