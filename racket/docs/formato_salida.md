# Formato de salida de la Etapa 2

El programa escribe `data/combinaciones.jsonl` en formato JSON Lines: cada línea es un objeto JSON independiente con una combinación. Si ninguna combinación cumple el rango de créditos, el archivo queda vacío.

## Ejemplo de una línea

```json
{"id":1,"total_credits":15,"course_count":4,"courses":[{"career":"computadores","code":"MA2104","name":"Calculo superior","group":1,"credits":4,"corequisites":[],"blocks":[{"day":"TUE","start":"18:00","end":"19:50"}]}]}
```

## Campos de una combinación

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `id` | entero positivo | extra | Número de la combinación, desde 1, en el orden en que se generó |
| `total_credits` | entero no negativo | sí | Suma de los créditos de los cursos |
| `course_count` | entero positivo | extra | Cantidad de cursos de la combinación |
| `courses` | lista no vacía | sí | Pares curso-grupo seleccionados |

## Campos de cada curso

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `career` | `"computadores"` o `"fisica"` | sí | Carrera que aporta el curso |
| `code` | texto | sí | Código del curso |
| `group` | entero positivo | sí | Número del grupo elegido |
| `name` | texto | extra | Nombre del curso |
| `credits` | entero no negativo | extra | Créditos del curso |
| `corequisites` | lista de códigos | extra | Correquisitos del curso (ver D8) |
| `blocks` | lista de bloques | extra | Horario del grupo: `day` (`MON` a `SAT`), `start` y `end` en `HH:MM` |

## Justificación de los campos extra

- `id`: permite que Prolog y la Etapa 4 se refieran a una combinación concreta.
- `course_count` y `credits`: Prolog puede aplicar restricciones de créditos o de cantidad de cursos sin recalcular.
- `corequisites`: la regla de correquisitos le corresponde a Prolog (D8) y necesita este dato.
- `blocks`: Prolog revisa compatibilidades de horario sin volver a abrir el catálogo de C.
- `name`: la Etapa 4 lo muestra al usuario.

## Garantías

- Ninguna combinación tiene choques de horario entre sus grupos.
- `total_credits` está dentro del rango `[min_credits, max_credits]` de las preferencias.
- Un curso, identificado por `(career, code)`, aparece una sola vez por combinación.
- Todos los cursos estaban marcados como matriculables por el módulo de C.