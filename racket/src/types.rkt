#lang racket

;; tipos del modulo de Racket, modelados con structs inmutables y contratos
;; los structs de Racket son inmutables por defecto (no se usa #:mutable)
;; #:transparent permite comparar con equal? e imprimir el contenido en las pruebas

(provide
 dia/c
 minuto/c
 (contract-out
  (struct bloque ([dia dia/c] [inicio minuto/c] [fin minuto/c]))
  (struct grupo ([numero exact-positive-integer?]
                 [profesor string?]
                 [bloques (listof bloque?)]
                 [choque boolean?]))))

;; dias que usa el JSON de la Etapa 1
(define dia/c (or/c 'MON 'TUE 'WED 'THU 'FRI 'SAT))

;; hora como minutos desde las 00:00, igual que minutes_of en conflicts.c
(define minuto/c (integer-in 0 1439))

;; un dia de clase de un grupo
(struct bloque (dia inicio fin) #:transparent)

;; choque es la bandera has_conflict de C, solo se usa para verificar choques.rkt
(struct grupo (numero profesor bloques choque) #:transparent)