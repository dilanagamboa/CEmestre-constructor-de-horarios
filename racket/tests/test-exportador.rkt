#lang racket

;; pruebas de exportador.rkt: se escribe el archivo y se vuelve a leer linea por linea

(require rackunit
         json
         racket/runtime-path
         racket/stream
         "../src/types.rkt"
         "../src/catalogo.rkt"
         "../src/preferencias.rkt"
         "../src/universo.rkt"
         "../src/generador.rkt"
         "../src/filtros.rkt"
         "../src/exportador.rkt")

(test-case "horas en formato HH:MM"
  (check-equal? (minutos->hora 450) "07:30")
  (check-equal? (minutos->hora 0) "00:00")
  (check-equal? (minutos->hora 1439) "23:59"))