# Plan y registro de pruebas del generador

Fecha de ejecución: 2026-10-26.
Comando principal:

```bash
raco test racket/tests
```

Resultado observado: **45 tests passed** en la suite completa. Las suites relacionadas con la Fase 3 son:

| Suite | Resultado |
| --- | ---: |
| `racket/tests/test-choques.rkt` | 5 tests passed |
| `racket/tests/test-generador.rkt` | 14 tests passed |
| `racket/tests/test-filtros.rkt` | 7 tests passed |
| `racket/tests/test-streams.rkt` | 3 tests passed |

## Tabla de casos

| ID | Caso | Entrada | Resultado esperado | Resultado observado | Estado | Revisó | Evidencia |
| --- | --- | --- | --- | --- | --- | --- | --- |
| G01 | Universo vacío | `(universo '() '())` y lista `'()` | Stream vacío | `stream-empty?` = `#t` | Aprobado | Ejecución de pruebas | `test-generador.rkt`, caso “universo vacio” |
| G02 | Un curso con un grupo | Curso A, grupo 1, 3 créditos | `A-1 \| 3` | `("A-1 \| 3")` | Aprobado | Ejecución de pruebas | `test-generador.rkt`, “un curso con un solo grupo” |
| G03 | Un curso con varios grupos | Curso A, grupos 1 y 2 | `A-1`, `A-2` en orden | `("A-1 \| 3" "A-2 \| 3")` | Aprobado | Ejecución de pruebas | `test-generador.rkt`, “un curso con varios grupos” |
| G04 | Dos cursos sin choque | A lunes 8–10, B martes 8–10 | `B-1`, `A-1`, `A-1 B-1` | `("B-1 \| 3" "A-1 \| 3" "A-1 B-1 \| 6")` | Aprobado | Ejecución de pruebas | `test-generador.rkt`, “dos cursos sin choque” |
| G05 | Dos cursos con choque contenido | A lunes 8–10, B lunes 9–10 | `B-1`, `A-1`; no `A-1 B-1` | `("B-1 \| 3" "A-1 \| 3")` | Aprobado | Ejecución de pruebas | `test-generador.rkt`, “dos cursos con choque contenido” |
| G06 | Choque parcial | A lunes 8–10, B lunes 9–11 | `B-1`, `A-1`; no `A-1 B-1` | `("B-1 \| 3" "A-1 \| 3")` | Aprobado | Ejecución de pruebas | `test-generador.rkt`, “dos cursos con choque parcial”; `test-choques.rkt` cubre el traslape parcial |
| G07 | Choque en el borde | A lunes 8–10, B lunes 10–12 | `B-1`, `A-1`, `A-1 B-1` | `("B-1 \| 3" "A-1 \| 3" "A-1 B-1 \| 6")` | Aprobado | Ejecución de pruebas | `test-generador.rkt`, “borde sin choque” |
| G08 | Curso omitido | Dos cursos sin choque | Se emiten combinaciones con A y con B por separado | `B-1`, `A-1`, `A-1 B-1` | Aprobado | Ejecución de pruebas | Mismo caso G04; D1 y `OMITIR-CURSOS?` |
| G09 | Combinación vacía | Universo con cuatro cursos | No se emite la combinación sin pares | 41 combinaciones; todas tienen al menos un par | Aprobado | Ejecución de pruebas | `test-generador.rkt`, “invariantes de las combinaciones” |
| G10 | Créditos acumulados | A 4 créditos, B 2 créditos | `2`, `4`, `6` | `(2 4 6)` | Aprobado | Ejecución de pruebas | `test-generador.rkt`, “creditos acumulados” |
| G11 | Preferencias con varios grupos | `preferencias_varios_grupos.json`, rango 6–10 | 26 combinaciones del oráculo | 26, texto idéntico a `esperado_varios_grupos.txt` | Aprobado | Oráculo manual | `test-generador.rkt`, “oraculo de varios grupos” |
| G12 | Grupo inexistente excluido del universo | `preferencias_no_habilitado.json`, S2 grupo 3 | S2 no queda en el universo; aviso “no tiene el grupo 3” | `("S1" 1 2)` y aviso presente | Aprobado | Ejecución de pruebas | `test-universo.rkt`, “cursos no habilitados…” |
| G13 | Curso no habilitado | S5 con requisitos faltantes | Fuera del universo; aviso | Aviso “no esta habilitado (faltan requisitos)” | Aprobado | Ejecución de pruebas | `test-universo.rkt` |
| G14 | Rango sin resultados | Stream de enteros, rango 10–20 | Stream vacío | `stream-empty?` = `#t` | Aprobado | Ejecución de pruebas | `test-filtros.rkt`, “enteros con limites inclusivos” |
| G15 | Solicitud del primer elemento | Oráculo total de 41 combinaciones | Primera = `S4-1 \| 2` | `S4-1 \| 2` | Aprobado | Ejecución de pruebas | `test-generador.rkt`, oráculo total |
| G16 | Catálogo grande | 60 cursos, un grupo cada uno | Primer resultado sin materializar 2^60 − 1 | `C59-1 \| 1` en ~2 s | Aprobado | Contraste con la prueba de pereza | `test-generador.rkt`, “pedir solo el primer resultado…” |
| G17 | Tres tipos en el filtro | Enteros, cadenas y combinaciones | Filtro genérico para los tres | `(2 3 4)`, `("bb" "ccc")`, 26 combinaciones | Aprobado | Ejecución de pruebas | `test-filtros.rkt` |
| G18 | Límites inclusivos | Enteros 1–5, rango 2–4; mínimo = máximo 2–2 | `2 3 4`; `2` | `(2 3 4)`; `(2)` | Aprobado | Ejecución de pruebas | `test-filtros.rkt`, “enteros con limites inclusivos” |
| G19 | Consistencia de choques con C | Salidas reales de ambas carreras | Cada bandera de C coincide con el cálculo de Racket | Sin diferencias en 221 y 308 grupos | Aprobado | Comparación C/Racket | `test-choques.rkt`, “consistencia con C” |
| G20 | Orden documentado | Oráculo total y oráculo de varios grupos | Orden exacto de los archivos de texto | Idéntico en ambos oráculos | Aprobado | Oráculo manual | `esperado_rango_total.txt`, `esperado_varios_grupos.txt` |

## Oráculos manuales

Los archivos `racket/tests/data/esperado_rango_total.txt` y `esperado_varios_grupos.txt` se construyeron a mano a partir del catálogo sintético. Sus comentarios indican los choques:

- `S1-1` choca con `S2-1`;
- `S1-2` choca con `S3-1`;
- `S1-1` y `S2-2` se tocan en el borde y no chocan.

El generador produce las 41 combinaciones no vacías del rango total y las 26 del rango 6–10 en el mismo orden. La prueba compara el texto completo, no solo la cantidad.

## Evidencia de pereza

La prueba G16 construye 60 cursos con un grupo cada uno. El número de combinaciones no vacías es 2^60 − 1, imposible de materializar. La prueba pide solo `stream-first` y obtiene `C59-1 | 1`; además, `test-streams.rkt` demuestra con un contador que `stream-cons` no evalúa la cola hasta que se pide.

La auditoría de `racket/src/` confirma que no se usa `list->stream` ni `stream->list` en el código productivo. El detalle está en `racket/docs/auditoria_fases_0_3.md`.

## Revisión cruzada

- **Generador contra oráculos manuales:** los dos archivos de texto se escribieron de forma independiente y se comparan línea por línea.
- **Choques contra C:** `test-choques.rkt` recalcula los choques de los catálogos reales y los compara con las banderas `has_conflict` que produjo C.
- **Filtro contra tres tipos:** enteros, cadenas y combinaciones usan la misma función `filtrar-por-rango`; no hay una implementación por tipo.
- **Revisión pendiente:** los casos y la evidencia están disponibles; el equipo debe revisar la tabla y firmar la defensa.

## Cómo reproducir

```bash
raco test racket/tests/test-choques.rkt
raco test racket/tests/test-generador.rkt
raco test racket/tests/test-filtros.rkt
raco test racket/tests/test-streams.rkt
raco test racket/tests
```

La suite completa debe reportar 45 tests passed.
