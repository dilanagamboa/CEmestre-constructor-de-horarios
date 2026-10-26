# Auditoría de las Fases 0–3

Fecha: 2026-10-26.
Alcance: `racket/src/` (código productivo). Las pruebas se revisaron por separado para distinguir mutación permitida de mutación indebida.

## 1. Búsquedas obligatorias

Comandos ejecutados desde `racket/src/`:

```bash
for pat in 'set!' 'hash-set!' 'vector-set!' 'set-box!' '#:mutable' \
           'list->stream' 'Any' 'cast' 'stream->list'; do
  grep -RIn --fixed-strings -- "$pat" .
done
```

Resultados:

| Patrón | Coincidencias en `racket/src/` | Clasificación |
| --- | ---: | --- |
| `set!` | 0 | Limpio |
| `hash-set!` | 0 | Limpio |
| `vector-set!` | 0 | Limpio |
| `set-box!` | 0 | Limpio |
| `#:mutable` | 0 | Limpio |
| `list->stream` | 0 | Limpio |
| `Any` | 0 | Limpio |
| `cast` | 0 | Limpio |
| `stream->list` | 0 | Limpio |

No hay coincidencias que clasificar como incorrectas ni pendientes de corregir.

### 1.1 Nota sobre `any/c`

El filtro polimórfico usa `any/c` en sus contratos:

```racket
[filtrar-por-rango (-> (stream/c any/c)
                       (-> any/c real?)
                       real?
                       real?
                       (stream/c any/c))]
```

`any/c` **no** es el tipo `Any` de Typed Racket: es el contrato de Racket que acepta cualquier valor. Es necesario para que la misma función sirva a enteros, cadenas y combinaciones. La búsqueda de `Any` con mayúscula no encuentra ninguna coincidencia, y no se usa `cast`.

## 2. Variables globales reasignadas

No hay `set!` ni formas equivalentes. Las definiciones de nivel superior son constantes o funciones:

- `VERSION-FORMATO`, `DIAS`, `CARRERAS` y `OMITIR-CURSOS?` son constantes que no se reasignan.
- Los structs y contratos se definen una vez.
- Las funciones recursivas reciben el estado como parámetros (`pendientes`, `seleccion`, `creditos`, `vistos`, etc.).

No se encontró ningún patrón de reasignación global.

## 3. Bucles con estado mutable

No hay bucles imperativos con estado. El código productivo usa:

- recursión estructural (`generar`, `recorrer`, `grupo-compatible?`, `primer-repetido`, `sin-repetidos?`);
- `map`, `filter`, `ormap`, `andmap`, `append-map`;
- En las pruebas se usan `for/list` y `for/sum` para construir datos y verificar sumas; no aparecen en `racket/src/`.

No hay `do`, `set!` dentro de bucles ni acumuladores mutables en `racket/src/`. El `set-box!` que aparece en las pruebas es deliberado: sirve para contar evaluaciones y demostrar la pereza. Está clasificado como **solo utilizado en pruebas**.

## 4. Generación eager de combinaciones

Revisión de `racket/src/generador.rkt`:

- El generador recibe una lista de cursos y devuelve un `stream` construido con `stream-cons`, `stream-lazy` y `stream-append`.
- Las dos ramas de cada curso (omitir o elegir grupo) se envuelven en `stream-lazy`; el resto de los grupos también.
- No hay una lista auxiliar de todas las combinaciones.
- No se usa `list->stream`.
- La combinación se emite solo al llegar al final de la recursión, y solo si la selección no está vacía.
- La selección se guarda al revés y se invierte al emitir; no se materializa el universo completo de combinaciones.

Evidencia:

- `racket/tests/test-generador.rkt` pide el primer resultado de 60 cursos con un grupo cada uno. Hay 2^60 − 1 combinaciones posibles; el resultado es `C59-1 | 1` y la prueba termina en aproximadamente 2 segundos.
- `racket/tests/test-streams.rkt` demuestra con un contador que `stream-cons` no evalúa la cola hasta que se pide.
- `racket/tests/test-filtros.rkt` filtra un stream infinito de naturales y obtiene el primer elemento sin recorrerlo completo.

La primera versión del generador sí construía las ramas antes de `stream-append`; la prueba de 24 cursos lo detectó y se corrigió con `stream-lazy`. Ver `prototipo_streams.md`, sección 4.

## 5. Structs inmutables

Todos los structs de `types.rkt` y `universo.rkt` se declaran sin `#:mutable`. `#:transparent` solo afecta la impresión y la comparación, no la mutabilidad. Los campos se actualizan con constructores nuevos o `struct-copy`, que produce un valor nuevo.

## 6. Contratos y tipos

- Todos los módulos exportan sus funciones públicas con `contract-out`; `universo.rkt` además exporta el struct `universo` con contrato.
- No se usa Typed Racket, `Any` ni `cast`.
- El contrato del generador es `(-> universo? (stream/c combinacion?))`; el del filtro es genérico con `any/c`.
- Los contratos de stream se aplican a los elementos cuando se fuerzan, no a todo el stream de una vez.

## 7. Revisión de las pruebas

| Archivo | Mutación | Clasificación |
| --- | --- | --- |
| `test-filtros.rkt` | `set-box!` en el contador de pereza | Permitida: solo prueba |
| `test-streams.rkt` | `set-box!` en el contador de pereza | Permitida: solo prueba |
| `test-generador.rkt` | Ninguna | Limpio |
| `test-catalogo.rkt`, `test-preferencias.rkt`, `test-universo.rkt` | Ninguna | Limpios |
| `test-choques.rkt` | Ninguna | Limpio |

La mutación de las pruebas no se importa desde `racket/src/` y no afecta el código productivo. La prueba `el generador no usa conversion de listas completas` lee el fuente de `generador.rkt` y comprueba que no contiene `list->stream` ni `stream->list`.

## 8. Búsquedas complementarias

```bash
grep -RInE '\(set!|#:mutable|set-box!|hash-set!|vector-set!' racket/src
grep -RInE 'list->stream|stream->list|stream-length|stream-take' racket/src
```

Resultado: sin coincidencias en ambos casos.

También se revisó que no hubiera `define` de nivel superior reasignado. No se encontró.

## 9. Conclusión

La auditoría no encuentra mutación indebida, variables globales reasignadas, bucles con estado mutable, `Any`, `cast`, `list->stream` ni materialización eager de combinaciones en `racket/src/`. La única mutación es la de los contadores de las pruebas de pereza, que está permitida por el plan y está aislada en `racket/tests/`.

Estado: **limpio**. No hay correcciones pendientes en el código productivo.
