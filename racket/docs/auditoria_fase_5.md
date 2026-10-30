# Auditoría final de la Etapa 2

Fecha de cierre: 2026-10-29.
Alcance: código productivo de `racket/src/`, pruebas de `racket/tests/`, salida real de las dos carreras y compilación de la Etapa 1 en C.

## 1. Compilación y pruebas

| Verificación | Comando | Resultado |
| --- | --- | --- |
| Compilación de Racket | `raco make racket/src/*.rkt` | Compila sin errores |
| Pruebas de Racket | `raco test racket/tests` | 65 pruebas pasan |
| Compilación de C | `make clean && make` | Compila sin advertencias |
| Pruebas de C | `make test` | 48/48, 35/35 y 73/73 |
| Regresión de C | `bash tests/regression_etapa1.sh origin/main` | Cuatro verificaciones `OK`; solo difiere `career` |

La suite de Racket se reparte en 11 archivos: catálogo (6), preferencias (4), universo (6), choques (5), generador (14), filtros (9), streams (3), exportador (6), principal (4), casos límite (3) y validación de la salida real (5).

## 2. Mutación y variables reasignadas

Comandos ejecutados desde la raíz:

```bash
grep -rnE "set!|hash-set!|vector-set!|set-box!|#:mutable" racket/src
grep -rn "list->stream\|stream->list" racket/src
grep -rnE "\(for |\bAny\b|\bcast\b" racket/src
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
| `stream->list` | 0 | Limpio |
| `for` | 0 | Limpio; todo se resuelve con recursión y funciones de orden superior |
| `Any` de Typed Racket | 0 | Limpio |
| `cast` | 0 | Limpio |

La única mutación de la etapa está en `test-filtros.rkt` y `test-streams.rkt`, donde se usa `set-box!` en un contador para demostrar que la cola de un stream no se evalúa hasta pedirla. Esa mutación vive solo en las pruebas y no se importa desde `racket/src/`.

## 3. Contratos y tipos

- Todos los módulos de `racket/src/` exportan sus funciones públicas con `contract-out`; `universo.rkt` también exporta el struct `universo` con contrato.
- No se usa Typed Racket, `Any` ni `cast`.
- `en-rango` usa `parametric->/c` y es reutilizable para enteros, cadenas, pares y combinaciones.
- `filtrar-por-rango` usa `(stream/c any/c)` porque en Racket 9.3 `parametric->/c` no se puede combinar directamente con `stream/c`; el parámetro de tipo sigue siendo genérico y la extractora concreta la aporta el usuario.
- Los contratos de stream se aplican a los elementos cuando se fuerzan, no a todo el stream de una vez.

## 4. Generación perezosa

- El generador usa `stream-cons`, `stream-lazy` y `stream-append`; no construye una lista auxiliar de combinaciones.
- Las dos ramas de cada curso (omitir o elegir grupo) y el resto de los grupos se envuelven en `stream-lazy`.
- No hay `list->stream` ni `stream->list` en el código productivo.
- La prueba de 60 cursos con un grupo cada uno pide solo `stream-first` y obtiene `C59-1 | 1`; hay 2^60 − 1 combinaciones no vacías posibles.
- `test-casos-limite.rkt` pide las primeras 100 combinaciones del universo real de las dos carreras, del orden de 3.5 × 10^14, y termina sin materializar el resto.
- El exportador consume el stream de a un elemento y escribe cada línea en el momento en que la recibe.

## 5. Validación de la salida real

`racket/tests/test-validar-salida.rkt` ejecuta el flujo con `data/preferencias.json` y las dos salidas de C, y lee el JSONL con un lector independiente, como lo haría la Etapa 3. La salida tiene 762 combinaciones y cumple:

- todos los campos obligatorios y bien tipados;
- `total_credits` igual a la suma de los créditos de los cursos;
- créditos dentro del rango inclusivo 12–18;
- ningún choque entre los grupos de una misma combinación;
- cada curso existe en el catálogo de C y está marcado con `can_enroll = true`;
- cada curso aparece una sola vez por combinación;
- `career` coincide con la carrera del catálogo.

La distribución real es: 14 combinaciones con 3 cursos, 335 con 4, 361 con 5 y 52 con 6. Ninguna combinación está vacía y ninguna incluye los ocho cursos del archivo de preferencias.

## 6. Casos límite

| Caso | Evidencia | Resultado |
| --- | --- | --- |
| Mínimo igual a máximo | `preferencias_min_igual_max.json`, 6–6 | 6 combinaciones, todas de exactamente 6 créditos |
| Un solo curso con un solo grupo | `preferencias_un_curso.json` | Una sola combinación, `S4-1`, con 2 créditos |
| Rango sin resultados | `preferencias_rango_imposible.json` | Archivo de salida vacío y cantidad 0 |
| Universo vacío | `(universo '() '())` | `empty-stream` |
| Curso sin grupos | Curso sintético sin grupos | No se emite solo; se omite de las combinaciones |
| Borde de horario | `S1-1` y `S2-2` a las 10:00 | No chocan y producen combinación conjunta |
| Choque real | `MA0101` grupo 1 contra `MA1102` grupo 12 | No se combinan |
| Catálogo grande | 60 cursos, 2^60 − 1 combinaciones | Primer resultado inmediato |
| Salida vacía | `empty-stream` en el exportador | Archivo válido y vacío |
| Ruta de salida inválida | `main.rkt` con una carpeta inexistente | Mensaje por `stderr` y código 1 |

## 7. Efectos permitidos

Las únicas operaciones con efectos son:

- lectura de archivos en `lectura.rkt`;
- escritura de la salida en `exportador.rkt`;
- mensajes por pantalla y manejo de la línea de comandos en `main.rkt`.

Ninguna función reasigna variables ni modifica estructuras. El universo se construye con `struct-copy`, la selección y los créditos se acumulan como parámetros de la recursión y los avisos se devuelven en un struct nuevo.

## 8. Conclusión

La auditoría no encuentra mutación indebida, variables globales reasignadas, ciclos con estado mutable, `Any`, `cast`, `list->stream` ni materialización eager de combinaciones en `racket/src/`. La salida real está validada contra el catálogo de C, las pruebas de C siguen pasando y la regresión confirma que la lógica de la Etapa 1 no cambió salvo por el campo `career`.

Estado: **limpio**. Los detalles de la revisión final y el checklist de entrega están en `revision_final.md`.
