#lang racket

;; lee el JSON que exporta el modulo de C y lo convierte a los structs de types.rkt
;; C genera un archivo por carrera; leer-catalogo une varios en un solo catalogo

(require "types.rkt" "lectura.rkt")

(provide
 (contract-out
  [hora->minutos (-> string? (or/c minuto/c #f))]
  [leer-catalogo (-> (non-empty-listof path-string?) catalogo?)]
  [cursos-habilitados (-> catalogo? (listof curso?))]
  [buscar-curso (-> catalogo? carrera/c string? (or/c curso? #f))]))

;; version del formato de C que sabe leer este modulo (OUTPUT_FORMAT_VERSION)
(define VERSION-FORMATO 1)

(define DIAS '(MON TUE WED THU FRI SAT))
(define CARRERAS '(computadores fisica))

;; primera clave repetida de la lista, o #f si no hay
(define (primer-repetido claves)
  (cond
    [(empty? claves) #f]
    [(member (first claves) (rest claves)) (first claves)]
    [else (primer-repetido (rest claves))]))

;; "HH:MM" a minutos desde las 00:00, igual que minutes_of en conflicts.c
;; #f si el texto no es una hora valida
(define (hora->minutos texto)
  (match (regexp-match #px"^(\\d{2}):(\\d{2})$" texto)
    [(list _ h m)
     (let ([horas (string->number h)] [minutos (string->number m)])
       (and (< horas 24) (< minutos 60) (+ (* 60 horas) minutos)))]
    [_ #f]))

(define (json->bloque donde j)
  (define dia (string->symbol (campo donde j 'day string? "un texto")))
  (define inicio (hora->minutos (campo donde j 'start string? "un texto")))
  (define fin (hora->minutos (campo donde j 'end string? "un texto")))
  (cond
    [(not (memq dia DIAS)) (error-lectura donde "dia invalido ~a" dia)]
    [(not (and inicio fin)) (error-lectura donde "hora invalida, se espera HH:MM")]
    [(>= inicio fin) (error-lectura donde "un bloque termina antes de empezar")]
    [else (bloque dia inicio fin)]))

(define (json->grupo donde j)
  (define numero (campo donde j 'number exact-positive-integer? "un entero positivo"))
  (define aqui (format "~a grupo ~a" donde numero))
  (grupo numero
         (campo aqui j 'professor string? "un texto")
         (map (lambda (b) (json->bloque aqui b))
              (campo aqui j 'blocks (lista-de hash?) "una lista de bloques"))
         (campo aqui j 'has_conflict boolean? "true o false")))

(define (json->curso ruta j)
  (define codigo (campo ruta j 'code non-empty-string? "un texto no vacio"))
  (define donde (format "~a curso ~a" ruta codigo))
  (define carrera (string->symbol (campo donde j 'career string? "un texto")))
  (unless (memq carrera CARRERAS)
    (error-lectura donde "carrera invalida ~a" carrera))
  (define prerrequisitos
    (campo donde j 'prerequisites (lista-de non-empty-string?) "una lista de codigos"))
  (define correquisitos
    (campo donde j 'corequisites (lista-de non-empty-string?) "una lista de codigos"))
  (when (or (member codigo prerrequisitos) (member codigo correquisitos))
    (error-lectura donde "un curso no puede ser requisito de si mismo"))
  (define grupos
    (map (lambda (g) (json->grupo donde g))
         (campo donde j 'groups (lista-de hash?) "una lista de grupos")))
  (define grupo-repetido (primer-repetido (map grupo-numero grupos)))
  (when grupo-repetido
    (error-lectura donde "el grupo ~a aparece mas de una vez" grupo-repetido))
  ;; C resume en el curso la bandera de sus grupos; se valida el campo y su
  ;; coherencia, aunque los choques reales se recalculan desde los bloques.
  (define choque-curso (campo donde j 'has_conflict boolean? "true o false"))
  (unless (eq? choque-curso (ormap grupo-choque grupos))
    (error-lectura donde "has_conflict del curso no coincide con sus grupos"))
  (curso carrera
         codigo
         (campo donde j 'name non-empty-string? "un texto no vacio")
         (campo donde j 'credits exact-nonnegative-integer? "un entero no negativo")
         prerrequisitos
         correquisitos
         grupos
         (campo donde j 'approved boolean? "true o false")
         (campo donde j 'can_enroll boolean? "true o false")))

;; lee un archivo de C y devuelve su lista de cursos
(define (leer-cursos ruta)
  (define donde (format "~a" ruta))
  (define datos (leer-json ruta))
  (unless (hash? datos)
    (error-lectura donde "se esperaba un objeto JSON"))
  (unless (equal? (campo donde datos 'format_version exact-integer? "un entero") VERSION-FORMATO)
    (error-lectura donde "format_version distinto de ~a" VERSION-FORMATO))
  (define cursos
    (map (lambda (j) (json->curso donde j))
         (campo donde datos 'courses (lista-de hash?) "una lista de cursos")))
  (if (= (length cursos) (campo donde datos 'course_count exact-nonnegative-integer? "un entero"))
      cursos
      (error-lectura donde "course_count no coincide con la cantidad de cursos")))

;; un curso se identifica por carrera y codigo, asi que esa pareja no se puede repetir
(define (leer-catalogo rutas)
  (define cursos (append-map (lambda (r) (leer-cursos r)) rutas))
  (define repetido (primer-repetido (map (lambda (c) (list (curso-carrera c) (curso-codigo c))) cursos)))
  (if repetido
      (error-lectura "catalogo" "el curso ~a de ~a aparece mas de una vez" (second repetido) (first repetido))
      (catalogo cursos)))

;; cursos que C marco como matriculables
(define (cursos-habilitados cat)
  (filter curso-matriculable (catalogo-cursos cat)))

;; curso con esa carrera y codigo, o #f si no esta
(define (buscar-curso cat carrera codigo)
  (findf (lambda (c) (and (eq? (curso-carrera c) carrera)
                          (string=? (curso-codigo c) codigo)))
         (catalogo-cursos cat)))
