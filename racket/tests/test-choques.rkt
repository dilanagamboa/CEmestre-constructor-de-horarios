#lang racket

;; pruebas de choques.rkt: casos puntuales y consistencia con la bandera de C

(require rackunit
         json
         racket/runtime-path
         "../src/types.rkt"
         "../src/choques.rkt")

;; atajos para armar datos de prueba (horas en minutos: 480 = 08:00)
(define (b dia inicio fin) (bloque dia inicio fin))
(define (g . bloques) (grupo 1 "P" bloques #f))
(define (par gr) (par-curso-grupo (curso 'computadores "X1" "X" 3 '() '() (list gr) #f #t) gr))

(test-case "bloques"
  (check-true  (bloques-chocan? (b 'MON 480 600) (b 'MON 480 600)) "horario identico")
  (check-true  (bloques-chocan? (b 'MON 480 600) (b 'MON 540 660)) "traslape parcial")
  (check-true  (bloques-chocan? (b 'MON 480 720) (b 'MON 540 600)) "uno dentro del otro")
  (check-false (bloques-chocan? (b 'MON 480 600) (b 'MON 600 720)) "borde: fin igual a inicio")
  (check-false (bloques-chocan? (b 'MON 600 720) (b 'MON 480 600)) "borde en orden inverso")
  (check-false (bloques-chocan? (b 'MON 480 600) (b 'TUE 480 600)) "dias distintos"))

(define g-lun-mie (g (b 'MON 480 600) (b 'WED 480 600)))
(define g-mar-mie (g (b 'TUE 480 600) (b 'WED 540 660)))
(define g-mar-jue (g (b 'TUE 600 720) (b 'THU 480 600)))

(test-case "grupos"
  (check-true  (grupos-chocan? g-lun-mie g-mar-mie) "chocan en el segundo bloque")
  (check-true  (grupos-chocan? g-mar-mie g-lun-mie) "el choque es simetrico")
  (check-false (grupos-chocan? g-lun-mie g-mar-jue) "varios bloques sin choque")
  (check-false (grupos-chocan? (g) g-lun-mie) "grupo sin bloques nunca choca"))

(test-case "compatibilidad con la seleccion acumulada"
  (check-true  (grupo-compatible? g-lun-mie '()) "seleccion vacia")
  (check-true  (grupo-compatible? g-lun-mie (list (par g-mar-jue))) "sin choques")
  (check-false (grupo-compatible? g-lun-mie (list (par g-mar-jue) (par g-mar-mie))) "choca con el ultimo"))

;; ---------------- consistencia con el modulo de C ----------------
;; salidas que genera ./cemestre (ver README de la Etapa 1)
(define-runtime-path salida-computadores "../../data/salida_computadores.json")
(define-runtime-path salida-fisica "../../data/salida_fisica.json")

;; "HH:MM" a minutos, igual que minutes_of en conflicts.c
(define (hora->minutos texto)
  (match (string-split texto ":")
    [(list h m) (+ (* 60 (string->number h)) (string->number m))]))

(define (json->bloque j)
  (bloque (string->symbol (hash-ref j 'day))
          (hora->minutos (hash-ref j 'start))
          (hora->minutos (hash-ref j 'end))))

(define (json->grupo j)
  (grupo (hash-ref j 'number) (hash-ref j 'professor)
         (map json->bloque (hash-ref j 'blocks)) (hash-ref j 'has_conflict)))

(define (json->curso carrera j)
  (curso carrera (hash-ref j 'code) (hash-ref j 'name) (hash-ref j 'credits)
         (hash-ref j 'prerequisites) (hash-ref j 'corequisites)
         (map json->grupo (hash-ref j 'groups))
         (hash-ref j 'approved) (hash-ref j 'can_enroll)))

(define (leer-cursos ruta carrera)
  (map (lambda (j) (json->curso carrera j))
       (hash-ref (call-with-input-file ruta read-json) 'courses)))

;; #t si gr choca con algun grupo de otro curso del mismo catalogo,
;; que es lo que marca conflicts_detect_catalog en C
(define (choca-en-catalogo? c gr cursos)
  (ormap (lambda (otro)
           (and (not (equal? (curso-codigo otro) (curso-codigo c)))
                (ormap (lambda (h) (grupos-chocan? gr h)) (curso-grupos otro))))
         cursos))

;; compara, grupo por grupo, lo que calcula Racket con has_conflict de C
(define (verificar-consistencia ruta carrera)
  (if (file-exists? ruta)
      (let ([cursos (leer-cursos ruta carrera)])
        (for-each
         (lambda (c)
           (for-each
            (lambda (gr)
              (check-equal? (choca-en-catalogo? c gr cursos) (grupo-choque gr)
                            (format "~a grupo ~a" (curso-codigo c) (grupo-numero gr))))
            (curso-grupos c)))
         cursos))
      (fail (format "falta ~a: generarlo con ./cemestre" ruta))))

(test-case "consistencia con C: computadores"
  (verificar-consistencia salida-computadores 'computadores))

(test-case "consistencia con C: fisica"
  (verificar-consistencia salida-fisica 'fisica))