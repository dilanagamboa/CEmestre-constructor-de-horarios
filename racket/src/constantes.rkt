#lang racket

;; rutas por defecto del programa, centralizadas en un solo lugar
;; se resuelven desde la ubicacion de este archivo, asi el programa funciona
;; sin importar desde que carpeta se ejecute

(require racket/runtime-path)

(provide CATALOGOS-POR-DEFECTO
         PREFERENCIAS-POR-DEFECTO
         SALIDA-POR-DEFECTO)

(define-runtime-path computadores "../../data/salida_computadores.json")
(define-runtime-path fisica "../../data/salida_fisica.json")
(define-runtime-path preferencias "../../data/preferencias.json")
(define-runtime-path salida "../../data/combinaciones.jsonl")

;; salidas de C de las dos carreras
(define CATALOGOS-POR-DEFECTO (list computadores fisica))
(define PREFERENCIAS-POR-DEFECTO preferencias)
(define SALIDA-POR-DEFECTO salida)