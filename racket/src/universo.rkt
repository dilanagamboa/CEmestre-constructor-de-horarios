#lang racket

;; cruza las preferencias con el catalogo y arma el universo de trabajo:
;; cada curso de interes que esta habilitado, solo con sus grupos de interes que existen
;; los problemas no detienen el programa, se devuelven como avisos

(require "types.rkt" "catalogo.rkt")

;; cursos con los que trabaja el generador y avisos para mostrar al usuario
(struct universo (cursos avisos) #:transparent)

(provide
 (contract-out
  (struct universo ([cursos (listof curso?)] [avisos (listof string?)]))
  [construir-universo (-> catalogo? preferencias? universo?)]))

(define (aviso i mensaje)
  (format "~a ~a: ~a" (interes-carrera i) (interes-codigo i) mensaje))

;; devuelve dos valores: el curso con sus grupos de interes (o #f) y sus avisos
(define (evaluar-interes cat i)
  (define c (buscar-curso cat (interes-carrera i) (interes-codigo i)))
  (cond
    [(not c) (values #f (list (aviso i "no esta en el catalogo")))]
    [(curso-aprobado c) (values #f (list (aviso i "ya esta aprobado")))]
    [(not (curso-matriculable c)) (values #f (list (aviso i "no esta habilitado (faltan requisitos)")))]
    [else
     (define numeros (map grupo-numero (curso-grupos c)))
     (define inexistentes (filter (lambda (n) (not (member n numeros))) (interes-grupos i)))
     (define elegidos (filter (lambda (g) (member (grupo-numero g) (interes-grupos i))) (curso-grupos c)))
     (define avisos (map (lambda (n) (aviso i (format "no tiene el grupo ~a" n))) inexistentes))
     (if (empty? elegidos)
         (values #f (append avisos (list (aviso i "no le queda ningun grupo de interes"))))
         (values (struct-copy curso c [grupos elegidos]) avisos))]))

;; recorre los intereses en orden; vistos, cursos y avisos se acumulan como parametros
(define (recorrer cat intereses vistos cursos avisos)
  (cond
    [(empty? intereses) (universo (reverse cursos) (reverse avisos))]
    [else
     (define i (first intereses))
     (define clave (list (interes-carrera i) (interes-codigo i)))
     (if (member clave vistos)
         (recorrer cat (rest intereses) vistos cursos
                   (cons (aviso i "esta repetido, se usa la primera aparicion") avisos))
         (let-values ([(c nuevos) (evaluar-interes cat i)])
           (recorrer cat (rest intereses) (cons clave vistos)
                     (if c (cons c cursos) cursos)
                     (append (reverse nuevos) avisos))))]))

(define (construir-universo cat prefs)
  (recorrer cat (preferencias-intereses prefs) '() '() '()))
