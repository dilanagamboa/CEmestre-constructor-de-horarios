#lang racket

;; deteccion de choques de horario con funciones puras
;; sigue el mismo criterio que conflicts.c de la Etapa 1:
;; dias distintos nunca chocan, se usa < estricto (un bloque que termina 10:00
;; no choca con uno que empieza 10:00) y un grupo sin bloques nunca choca

(require "types.rkt")

(provide
 (contract-out
  [bloques-chocan? (-> bloque? bloque? boolean?)]
  [grupos-chocan? (-> grupo? grupo? boolean?)]
  [grupo-compatible? (-> grupo? (listof par-curso-grupo?) boolean?)]))

;; #t si a y b son del mismo dia y cada uno empieza antes de que termine el otro
(define (bloques-chocan? a b)
  (and (eq? (bloque-dia a) (bloque-dia b))
       (< (bloque-inicio a) (bloque-fin b))
       (< (bloque-inicio b) (bloque-fin a))))

;; #t si algun bloque de g1 choca con algun bloque de g2
(define (grupos-chocan? g1 g2)
  (ormap (lambda (a)
           (ormap (lambda (b) (bloques-chocan? a b))
                  (grupo-bloques g2)))
         (grupo-bloques g1)))

;; #t si g no choca con ningun grupo de la seleccion acumulada
;; la seleccion se recorre con recursion, sin estado
(define (grupo-compatible? g seleccion)
  (cond
    [(empty? seleccion) #t]
    [(grupos-chocan? g (par-curso-grupo-grupo (first seleccion))) #f]
    [else (grupo-compatible? g (rest seleccion))]))