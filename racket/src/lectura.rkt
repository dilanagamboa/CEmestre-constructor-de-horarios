#lang racket

;; utilidades comunes para leer los archivos JSON de entrada
;; ante un dato mal formado se lanza exn:fail:user con el archivo y el detalle,
;; asi main.rkt lo atrapa y el programa nunca se cae

(require json)

(provide
 (contract-out
  [error-lectura (->* (string? string?) () #:rest list? none/c)]
  [leer-json (-> path-string? any/c)]
  [campo (-> string? hash? symbol? (-> any/c any/c) string? any/c)]
  [lista-de (-> (-> any/c any/c) (-> any/c any/c))]))

;; lanza el error con el lugar donde ocurrio y un mensaje con formato
(define (error-lectura donde fmt . args)
  (raise-user-error (format "~a: ~a" donde (apply format fmt args))))

;; lee el archivo completo como JSON; falla si no existe, esta vacio o no es JSON
(define (leer-json ruta)
  (define texto (format "~a" ruta))
  (cond
    [(not (file-exists? ruta)) (error-lectura texto "el archivo no existe")]
    [else
     (define datos
       (with-handlers ([exn:fail:read? (lambda (e) (error-lectura texto "no es un JSON valido"))])
         (call-with-input-file ruta read-json)))
     (if (eof-object? datos)
         (error-lectura texto "el archivo esta vacio")
         datos)]))

;; devuelve el campo clave de j si cumple ok?, si no lanza error
(define (campo donde j clave ok? descripcion)
  (define valor (hash-ref j clave (lambda () (error-lectura donde "falta el campo ~a" clave))))
  (if (ok? valor)
      valor
      (error-lectura donde "el campo ~a debe ser ~a" clave descripcion)))

;; predicado para listas cuyos elementos cumplen ok?
(define ((lista-de ok?) v)
  (and (list? v) (andmap ok? v)))
