# Prototipo de streams y pereza

Este documento registra el prototipo que se usó para comprobar que el generador devuelve streams reales y no una lista completa convertida al final. La evidencia ejecutable está en `racket/tests/test-streams.rkt` y en la prueba de catálogo grande de `racket/tests/test-generador.rkt`.

## 1. Biblioteca utilizada

Se usa `racket/stream`, la biblioteca de streams de la distribución estándar de Racket 9.3. Las operaciones relevantes son:

- `stream-cons`: construye un par de stream con cabeza y cola diferidas.
- `stream-first`: fuerza la cabeza.
- `stream-rest`: devuelve la cola; la cola puede seguir siendo diferida.
- `stream-lazy`: envuelve una expresión para no evaluarla hasta que se necesite.
- `stream-append`: concatena streams de forma perezosa.
- `stream-filter`: filtra sin recorrer todo el stream de entrada.
- `stream->list`: solo se usa en pruebas y en el consumidor final; no aparece en `racket/src/`.

No se usa `list->stream` en el código productivo. La auditoría de `racket/docs/auditoria_fases_0_3.md` lo confirma.

## 2. Qué significa pedir solo el primer elemento

Un stream se puede ver como una cabeza ya calculada y una cola que es una promesa. Al pedir:

```racket
(stream-first un-stream)
```

Racket solo evalúa lo necesario para producir la cabeza. No evalúa la cola ni construye los elementos siguientes.

El prototipo usa un contador en una caja para demostrarlo. La caja y el `set-box!` viven **solo en la prueba**, nunca en `racket/src/`:

```racket
(define contador (box 0))

(define (naturales n)
  (stream-cons n
               (begin
                 (set-box! contador (add1 (unbox contador)))
                 (naturales (add1 n)))))

(define s (naturales 0))
(unbox contador)        ; 0
(stream-first s)        ; 0
(unbox contador)        ; 0: la cola no se evaluó
(stream-first (stream-rest s)) ; 1
(unbox contador)        ; 1
```

Resultado observado en `racket/tests/test-streams.rkt`: **3 tests passed**. El contador permanece en 0 después de `stream-first` y aumenta cuando se fuerza la cola.

### 2.1 `stream-append`

`stream-append` también es perezoso: no recorre el segundo stream hasta que el primero se agota. La prueba `stream-append tambien conserva la pereza` verifica que el contador no se dispara antes de pedir el primer elemento.

## 3. Evidencia con el generador

La prueba `pedir solo el primer resultado de un catalogo grande` construye 60 cursos, cada uno con un grupo sin bloques. El número de combinaciones no vacías posibles es:

```
2^60 - 1 = 1 152 921 504 606 846 975
```

Si el generador materializara todas las combinaciones, la prueba no terminaría y agotaría la memoria. La prueba pide únicamente:

```racket
(stream-first (generar-combinaciones-de-cursos grandes))
```

y obtiene:

```
C59-1 | 1
```

El resultado es el esperado: se omiten los primeros 59 cursos y se elige el último, que es la primera combinación en el orden documentado. La suite `racket/tests/test-generador.rkt` tarda aproximadamente 2 segundos en este entorno, no minutos ni horas.

Otra evidencia es el oráculo:

```bash
raco test racket/tests/test-generador.rkt
# 14 tests passed
```

Las 41 combinaciones del rango total y las 26 del rango 6–10 se comparan contra archivos de texto generados a mano. Si el generador devolviera una lista completa, seguiría pasando el oráculo, pero no la prueba de 60 cursos.

## 4. Un problema real: construir las ramas antes de tiempo

La primera versión del generador usaba `stream-append` así:

```racket
(define sin-curso (generar resto seleccion creditos))
(define con-curso (elegir-grupos curso resto seleccion creditos))
(stream-append sin-curso con-curso)
```

Aunque `stream-append` es perezoso, **los argumentos se evalúan antes de llamarlo**. Cada llamada a `generar` construía a su vez las dos ramas del curso siguiente, y así sucesivamente. El resultado era un árbol de llamadas de tamaño exponencial antes de devolver el primer elemento. Con 24 cursos el proceso ya no terminaba.

La corrección fue envolver cada rama en `stream-lazy`:

```racket
(define sin-curso
  (if OMITIR-CURSOS?
      (stream-lazy (generar resto seleccion creditos))
      empty-stream))

(define con-curso
  (stream-lazy (elegir-grupos curso resto seleccion creditos)))

(stream-append sin-curso con-curso)
```

Dentro de `elegir-grupos` también se difiere cada grupo y el resto de la lista de grupos. Con eso, construir el stream es O(1) y pedir el primer resultado recorre solo el camino necesario hasta la primera combinación.

Esta experiencia es importante para la defensa: **usar `stream-append` no garantiza pereza si las ramas se construyen antes de la llamada**. Hay que diferir la construcción de las ramas, no solo la concatenación.

## 5. Dificultades con contratos y tipos

- `stream/c` aplica el contrato a los elementos a medida que se fuerzan, no a todo el stream de una vez. Eso es coherente con la pereza, pero significa que un elemento inválido puede fallar recién cuando se consume.
- El contrato del filtro usa `(stream/c any/c)` porque el filtro debe aceptar cualquier tipo. No se usa `Any` de Typed Racket ni `cast`.
- `stream-lazy` es una macro, no una función que reciba un thunk. Se escribe `(stream-lazy expresion)`, y la expresión se evalúa solo al forzar el stream.
- `stream-append` exige que todos sus argumentos sean streams; por eso las ramas se envuelven con `stream-lazy` o se usa `empty-stream`, nunca una lista.
- Las funciones recursivas que construyen streams no deben llamar a `stream->list` ni a `stream-length` en el camino productivo, porque eso fuerza todo.
- La memoización de Racket hace que un stream ya forzado se pueda recorrer varias veces sin recalcular; las pruebas se apoyan en eso.

## 6. Diseño que se trasladó al generador

El generador definitivo conserva el estado conceptual de la recursión:

| Estado | Significado |
| --- | --- |
| `pendientes` | Cursos que todavía no se decidieron, en el orden del universo. |
| `seleccion` | Pares curso-grupo ya elegidos, guardados al revés para consar en O(1). |
| `creditos` | Suma de los créditos de los pares elegidos. |

Para cada curso:

1. **Rama de omisión:** si `OMITIR-CURSOS?` es `#t`, se procesa el resto sin agregar el curso. Se emite primero.
2. **Rama de selección:** se recorren los grupos del curso en el orden del catálogo. Cada grupo compatible con la selección se agrega y se procesa el resto.
3. **Terminación:** cuando no quedan cursos, se emite una `combinacion` solo si `seleccion` no está vacía. La selección se invierte para conservar el orden del universo.

El stream se construye con `stream-lazy` y `stream-append`; no se usan listas auxiliares ni `list->stream`. La combinación vacía nunca se emite.

## 7. Cómo reproducir la evidencia

```bash
# desde la raíz del repositorio
raco test racket/tests/test-streams.rkt
raco test racket/tests/test-generador.rkt
raco test racket/tests
```

Resultados observados el 2026-10-26:

```
test-streams.rkt:   3 tests passed
test-generador.rkt: 14 tests passed
suite completa:     45 tests passed
```

La primera combinación del catálogo grande fue `C59-1 | 1`; el oráculo total produjo 41 combinaciones y el de varios grupos 26. Estos valores están registrados también en `racket/docs/plan_pruebas_generador.md`.
