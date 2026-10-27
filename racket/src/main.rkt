#lang racket

;; programa principal de la Etapa 2:
;; catalogo + preferencias -> universo -> generador -> filtro de creditos -> exportador
;;
;; uso:
;;   racket racket/src/main.rkt
;;   racket racket/src/main.rkt <preferencias.json> <salida.jsonl> <catalogo.json> ...
;; sin argumentos usa las rutas de constantes.rkt

(require "types.rkt"
         "constantes.rkt"
         "catalogo.rkt"
         "preferencias.rkt"
         "universo.rkt"
         "generador.rkt"
         "filtros.rkt"
         "exportador.rkt")

(provide
 (contract-out
  [ejecutar (-> path-string? path-string? (non-empty-listof path-string?)
                (values exact-nonnegative-integer? (listof string?)))]))

;; corre todo el flujo; devuelve cuantas combinaciones exporto y los avisos del universo
(define (ejecutar ruta-preferencias ruta-salida rutas-catalogo)
  (define prefs (leer-preferencias ruta-preferencias))
  (define u (construir-universo (leer-catalogo rutas-catalogo) prefs))
  (define combinaciones (filtrar-por-creditos (generar-combinaciones u) prefs))
  (values (exportar-combinaciones combinaciones ruta-salida)
          (universo-avisos u)))

;; argumentos de la linea de comandos a las tres rutas; #f si no son validos
(define (leer-argumentos args)
  (match args
    ['() (list PREFERENCIAS-POR-DEFECTO SALIDA-POR-DEFECTO CATALOGOS-POR-DEFECTO)]
    [(list prefs salida catalogo catalogos ...) (list prefs salida (cons catalogo catalogos))]
    [_ #f]))

(module+ main
  (define rutas (leer-argumentos (vector->list (current-command-line-arguments))))
  (unless rutas
    (eprintf "uso: racket racket/src/main.rkt [<preferencias> <salida> <catalogo> ...]\n")
    (exit 1))
  ;; los errores de lectura son exn:fail:user: se muestran y el programa sale con 1
  (with-handlers ([exn:fail:user? (lambda (e)
                                    (eprintf "error: ~a\n" (exn-message e))
                                    (exit 1))])
    (define-values (cantidad avisos) (apply ejecutar rutas))
    (for-each (lambda (a) (printf "aviso: ~a\n" a)) avisos)
    (printf "~a combinaciones exportadas a ~a\n" cantidad (second rutas))))