#lang racket

;; generador perezoso de combinaciones de cursos y grupos
;;
;; El universo ya viene filtrado por catalogo.rkt/universo.rkt: solo trae
;; cursos habilitados y, en cada curso, solo los grupos de interes que
;; existen. Aqui se decide que subconjunto no vacio de esos cursos se toma
;; y con que grupo se toma cada uno.
;;
;; La recursion tiene este estado conceptual:
;;   - pendientes: cursos que todavia no se decidieron, en el orden del universo
;;   - seleccion: pares curso-grupo ya elegidos (se guarda al reves y se
;;     invierte al emitir, para que la combinacion conserve el orden del universo)
;;   - creditos: suma de los creditos de los pares ya elegidos
;;
;; Para cada curso hay dos ramas:
;;   - omitirlo (solo si OMITIR-CURSOS? es #t, decision D1)
;;   - elegir uno de sus grupos, siempre que no choque con la seleccion
;;
;; La rama de omision se emite primero. Cuando no quedan cursos se emite una
;; combinacion solo si la seleccion no esta vacia. El resultado es un stream:
;; cada cola se calcula cuando se pide, no se construye la lista completa.

(require "types.rkt"
         "universo.rkt"
         "choques.rkt"
         racket/stream)

(provide
 (contract-out
  [generar-combinaciones (-> universo? (stream/c combinacion?))]
  [generar-combinaciones-de-cursos (-> (listof curso?) (stream/c combinacion?))]))

;; Decision D1: una combinacion puede omitir cursos. Si el profesor confirma
;; que deben estar todos los cursos del universo, basta con cambiar esta
;; constante a #f; el resto del generador no necesita cambios.
(define OMITIR-CURSOS? #t)

;; Emite las combinaciones que eligen un grupo de 'curso' y despues procesan
;; 'resto'. Los grupos se prueban en el orden del catalogo. Tanto la rama de
;; cada grupo como el resto de la lista de grupos se envuelven en stream-lazy:
;; asi construir el stream no dispara la recursion de las ramas.
(define (elegir-grupos curso resto seleccion creditos)
  (define (recorrer grupos)
    (cond
      [(empty? grupos) empty-stream]
      [else
       (define grupo (first grupos))
       (define elegido
         (if (grupo-compatible? grupo seleccion)
             (stream-lazy
              (generar resto
                       (cons (par-curso-grupo curso grupo) seleccion)
                       (+ creditos (curso-creditos curso))))
             empty-stream))
       (stream-append elegido
                      (stream-lazy (recorrer (rest grupos))))]))
  (recorrer (curso-grupos curso)))

;; Genera el stream a partir de la lista de cursos pendientes.
(define (generar pendientes seleccion creditos)
  (cond
    [(empty? pendientes)
     ;; no se devuelve la combinacion vacia: el enunciado pide un subconjunto
     ;; no vacio de cursos
     (if (empty? seleccion)
         empty-stream
         (stream-cons (combinacion (reverse seleccion) creditos)
                      empty-stream))]
    [else
     (define curso (first pendientes))
     (define resto (rest pendientes))
     ;; rama 1: no llevar este curso (D1). Se difiere para no construir toda
     ;; la recursion de omisiones antes de devolver el primer resultado.
     (define sin-curso
       (if OMITIR-CURSOS?
           (stream-lazy (generar resto seleccion creditos))
           empty-stream))
     ;; rama 2: llevar uno de sus grupos, si es compatible
     (define con-curso
       (stream-lazy (elegir-grupos curso resto seleccion creditos)))
     (stream-append sin-curso con-curso)]))

;; Punto de entrada para pruebas y para el futuro programa principal.
(define (generar-combinaciones-de-cursos cursos)
  (generar cursos '() 0))

;; Punto de entrada de la Fase 3: recibe el universo ya construido.
(define (generar-combinaciones universo)
  (generar-combinaciones-de-cursos (universo-cursos universo)))
