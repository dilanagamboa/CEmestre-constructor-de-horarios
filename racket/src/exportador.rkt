#lang racket

;; exporta las combinaciones en JSON Lines: un objeto JSON por linea
;; el stream se consume de a un elemento con recursion, cada combinacion se
;; escribe apenas se genera y nunca se arma la lista completa en memoria

(require json
         racket/stream
         "types.rkt")

(provide
 (contract-out
  [minutos->hora (-> minuto/c string?)]
  [combinacion->jsexpr (-> exact-positive-integer? combinacion? jsexpr?)]
  [exportar-combinaciones (-> (stream/c combinacion?) path-string? exact-nonnegative-integer?)]))
  

;; minutos desde las 00:00 a "HH:MM", el mismo formato que exporta C
(define (minutos->hora m)
  (format "~a:~a"
          (~r (quotient m 60) #:min-width 2 #:pad-string "0")
          (~r (remainder m 60) #:min-width 2 #:pad-string "0")))

(define (bloque->jsexpr b)
  (hasheq 'day (symbol->string (bloque-dia b))
          'start (minutos->hora (bloque-inicio b))
          'end (minutos->hora (bloque-fin b))))

;; un par curso-grupo con lo que Prolog necesita sin volver a abrir el catalogo
(define (par->jsexpr p)
  (define c (par-curso-grupo-curso p))
  (define g (par-curso-grupo-grupo p))
  (hasheq 'career (symbol->string (curso-carrera c))
          'code (curso-codigo c)
          'name (curso-nombre c)
          'group (grupo-numero g)
          'credits (curso-creditos c)
          'corequisites (curso-correquisitos c)
          'blocks (map bloque->jsexpr (grupo-bloques g))))

;; una combinacion con su identificador
(define (combinacion->jsexpr id k)
  (hasheq 'id id
          'total_credits (combinacion-creditos k)
          'course_count (length (combinacion-pares k))
          'courses (map par->jsexpr (combinacion-pares k))))

;; escribe una linea por combinacion; id avanza como parametro de la recursion
;; devuelve cuantas combinaciones escribio
(define (escribir-lineas combinaciones id salida)
  (cond
    [(stream-empty? combinaciones) (- id 1)]
    [else
     (write-json (combinacion->jsexpr id (stream-first combinaciones)) salida)
     (newline salida)
     (escribir-lineas (stream-rest combinaciones) (+ id 1) salida)]))

;; crea o reemplaza el archivo; si no hay combinaciones queda vacio
(define (exportar-combinaciones combinaciones ruta)
  (call-with-output-file ruta
    (lambda (salida) (escribir-lineas combinaciones 1 salida))
    #:exists 'replace))