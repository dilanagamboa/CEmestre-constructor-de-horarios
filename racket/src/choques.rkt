#lang racket

;; deteccion de choques de horario con funciones puras
;; sigue el mismo criterio que conflicts.c de la Etapa 1:
;; dias distintos nunca chocan, se usa < estricto (un bloque que termina 10:00
;; no choca con uno que empieza 10:00) y un grupo sin bloques nunca choca

(require "types.rkt")

(provide
 (contract-out
  [bloques-chocan? (-> bloque? bloque? boolean?)]))

;; #t si a y b son del mismo dia y cada uno empieza antes de que termine el otro
(define (bloques-chocan? a b)
  (and (eq? (bloque-dia a) (bloque-dia b))
       (< (bloque-inicio a) (bloque-fin b))
       (< (bloque-inicio b) (bloque-fin a))))