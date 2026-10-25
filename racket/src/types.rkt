#lang racket

;; tipos del modulo de Racket, modelados con structs inmutables y contratos
;; los structs de Racket son inmutables por defecto (no se usa #:mutable)
;; #:transparent permite comparar con equal? e imprimir el contenido en las pruebas

(provide
 dia/c
 minuto/c
 carrera/c
 (contract-out
  (struct bloque ([dia dia/c] [inicio minuto/c] [fin minuto/c]))
  (struct grupo ([numero exact-positive-integer?]
                 [profesor string?]
                 [bloques (listof bloque?)]
                 [choque boolean?]))
  (struct curso ([carrera carrera/c]
                 [codigo non-empty-string?]
                 [nombre non-empty-string?]
                 [creditos exact-nonnegative-integer?]
                 [prerrequisitos (listof non-empty-string?)]
                 [correquisitos (listof non-empty-string?)]
                 [grupos (listof grupo?)]
                 [aprobado boolean?]
                 [matriculable boolean?]))
  (struct catalogo ([cursos (listof curso?)]))
  (struct interes ([carrera carrera/c]
                   [codigo non-empty-string?]
                   [grupos (non-empty-listof exact-positive-integer?)]))
  (struct preferencias ([intereses (listof interes?)]
                        [creditos-min exact-nonnegative-integer?]
                        [creditos-max exact-nonnegative-integer?]))
  (struct par-curso-grupo ([curso curso?] [grupo grupo?]))
  (struct combinacion ([pares (non-empty-listof par-curso-grupo?)]
                       [creditos exact-nonnegative-integer?]))))

;; dias que usa el JSON de la Etapa 1
(define dia/c (or/c 'MON 'TUE 'WED 'THU 'FRI 'SAT))

;; hora como minutos desde las 00:00, igual que minutes_of en conflicts.c
(define minuto/c (integer-in 0 1439))

;; un dia de clase de un grupo
(struct bloque (dia inicio fin) #:transparent)

;; choque es la bandera has_conflict de C, solo se usa para verificar choques.rkt
(struct grupo (numero profesor bloques choque) #:transparent)

;; carrera que aporta el curso, mismo valor que escribe el modulo de C
(define carrera/c (or/c 'computadores 'fisica))

;; un curso se identifica por carrera y codigo, porque un mismo codigo puede
;; tener requisitos distintos en cada carrera
(struct curso (carrera codigo nombre creditos prerrequisitos correquisitos
                       grupos aprobado matriculable)
  #:transparent)

;; cursos de las dos carreras
(struct catalogo (cursos) #:transparent)

;; un curso de interes con los grupos que el estudiante acepta
(struct interes (carrera codigo grupos) #:transparent)

;; lo que lee preferencias.rkt: cursos de interes y rango de creditos
(struct preferencias (intereses creditos-min creditos-max) #:transparent)

;; un curso con el grupo elegido; guarda los structs completos para que el
;; exportador tenga creditos y carrera sin volver a buscar en el catalogo
(struct par-curso-grupo (curso grupo) #:transparent)

;; una combinacion valida; creditos se acumula en la recursion del generador
(struct combinacion (pares creditos) #:transparent)