# Entrada del catálogo

Este documento describe el JSON que produce la Etapa 1 en C y que consume `racket/src/catalogo.rkt`. El archivo se genera con:

```bash
./cemestre data/catalogo_computadores.csv data/historial_computadores.csv data/salida_computadores.json computadores
./cemestre data/catalogo_fisica.csv       data/historial_fisica.csv       data/salida_fisica.json       fisica
```

C genera **un archivo por carrera**. Racket puede leer uno o varios y unirlos en un solo `catalogo`, pero la identidad de un curso sigue siendo la pareja `(career, code)`: un mismo código puede existir en Computadores y en Física sin considerarse duplicado.

## 1. Estructura general

```json
{
  "format_version": 1,
  "course_count": 39,
  "courses": [
    {
      "code": "MA0101",
      "name": "Matematica general",
      "career": "computadores",
      "credits": 2,
      "prerequisites": [],
      "corequisites": [],
      "groups": [
        {
          "number": 1,
          "professor": "AZOFEIFA CUBERO ROBERTO",
          "blocks": [
            {"day": "WED", "start": "15:00", "end": "17:50"},
            {"day": "FRI", "start": "15:00", "end": "16:50"}
          ],
          "has_conflict": true
        }
      ],
      "has_conflict": true,
      "approved": false,
      "can_enroll": false
    }
  ]
}
```

El objeto raíz tiene exactamente estos campos:

| Campo | Tipo | Obligatorio | Significado |
| --- | --- | --- | --- |
| `format_version` | entero | sí | Versión del contrato de salida de C. `catalogo.rkt` solo acepta `1`. |
| `course_count` | entero no negativo | sí | Cantidad de cursos del archivo. Debe coincidir con `(length courses)`. |
| `courses` | arreglo de objetos | sí | Cursos del catálogo, en el orden en que C los cargó. |

## 2. Campos de un curso

| Campo | Tipo | Obligatorio | Significado |
| --- | --- | --- | --- |
| `code` | texto no vacío | sí | Código del curso, por ejemplo `CE2103`. |
| `name` | texto no vacío | sí | Nombre del curso tal como aparece en el plan. |
| `career` | `"computadores"` o `"fisica"` | sí | Carrera que aporta el curso. Lo asigna `catalog_set_career` en C. |
| `credits` | entero no negativo | sí | Créditos del curso. Puede ser `0` (por ejemplo `CI0200`). |
| `prerequisites` | arreglo de textos no vacíos | sí | Códigos de prerrequisitos. `[]` si no tiene. |
| `corequisites` | arreglo de textos no vacíos | sí | Códigos de correquisitos. `[]` si no tiene. |
| `groups` | arreglo de objetos | sí | Grupos u ofertas del curso. Puede ser `[]` si el curso no tiene grupos. |
| `has_conflict` | booleano | sí | Resumen del curso: verdadero si algún grupo tiene `has_conflict` verdadero. |
| `approved` | booleano | sí | Verdadero si el estudiante ya aprobó el curso según el historial. |
| `can_enroll` | booleano | sí | Verdadero si el curso cumple los requisitos curriculares, independientemente de los choques. |

### 2.1 `career`

`career` es la carrera **dueña del curso**. No indica la carrera del estudiante ni se deduce del nombre del archivo. C valida que sea `computadores` o `fisica` antes de asignarla a todos los cursos con `catalog_set_career`; si el argumento de carrera es inválido, el programa termina con `ERROR_INVALID_FORMAT` y no exporta.

La carrera forma parte de la identidad del curso porque un mismo código puede tener requisitos distintos en cada plan. Por ejemplo, `FI1102` existe en ambas carreras con listas de requisitos diferentes. Por eso `buscar-curso` recibe carrera y código, y `leer-catalogo` solo considera duplicado un par `(carrera, código)` repetido.

### 2.2 `approved`

`approved` lo calcula C con `history_has_course` al exportar. Un curso aprobado no se puede volver a matricular, aunque `can_enroll` sea verdadero por otros motivos. El universo de Racket elimina los cursos con `approved = true` y reporta un aviso.

### 2.3 `can_enroll`

`can_enroll` mide la elegibilidad **curricular**: prerrequisitos y correquisitos. No tiene en cuenta los choques de horario. Un curso puede ser `can_enroll = true` y aun así no caber en una combinación por choques.

Un correquisito se considera cumplido si ya está aprobado o si el estudiante podría matricularlo en el mismo periodo. Por eso `can_enroll` no garantiza que los correquisitos estén aprobados. Las Fases 0–3 conservan la lista `corequisites` para que fases posteriores exijan elegir juntos los cursos que se necesitan; el generador actual solo aplica choques y créditos, no esa restricción. El caso más claro es la pareja mutua `QU1102` / `QU1106` en Física.

### 2.4 `has_conflict`

Hay dos niveles:

- **Por grupo:** `groups[].has_conflict` es verdadero si ese grupo choca con algún grupo de **otro** curso del mismo catálogo. Los grupos alternativos de un mismo curso no se comparan entre sí.
- **Por curso:** `has_conflict` es verdadero si al menos un grupo del curso tiene la bandera verdadera.

La regla de borde de C es estricta: un bloque que termina exactamente cuando otro empieza **no** choca. Días distintos nunca chocan. Un grupo sin bloques nunca choca.

Racket no confía en la bandera para generar: recalcula los choques desde los bloques con `choques.rkt` (decisión D6). La bandera se conserva en el struct `grupo` y se usa en una prueba de consistencia. El lector de catálogo sí valida que `has_conflict` del curso sea igual a `(ormap grupo-choque grupos)`, para detectar archivos incoherentes.

## 3. Grupos y bloques

Un grupo tiene:

| Campo | Tipo | Obligatorio | Significado |
| --- | --- | --- | --- |
| `number` | entero positivo | sí | Número de grupo dentro del curso. No se puede repetir en el mismo curso. |
| `professor` | texto | sí | Profesor del grupo. C lo escribe tal como está en la fuente. |
| `blocks` | arreglo de bloques | sí | Bloques horarios. Puede ser `[]`. |
| `has_conflict` | booleano | sí | Bandera de C para ese grupo. |

Un bloque tiene:

| Campo | Tipo | Obligatorio | Significado |
| --- | --- | --- | --- |
| `day` | `MON`, `TUE`, `WED`, `THU`, `FRI` o `SAT` | sí | Día de la clase. |
| `start` | texto `HH:MM` | sí | Hora de inicio en formato de 24 horas. |
| `end` | texto `HH:MM` | sí | Hora de fin en formato de 24 horas. Debe ser mayor que `start`. |

Las horas se convierten a minutos desde las 00:00 (0–1439). El lector rechaza horas fuera de rango, texto que no sea `HH:MM`, días desconocidos y bloques que terminan antes de empezar. Un grupo con `blocks = []` es válido y nunca choca.

## 4. Cursos sin grupos

Un curso puede tener `"groups": []`. Esto ocurre con actividades del plan que la Guía no ofrece con ese código, por ejemplo:

- Computadores: `SE1100`, `SE1200`, `SE1400`.
- Física: `CI0200`, `FI2104`, `IF3501`.

El curso sigue existiendo en el catálogo y puede estar aprobado. El universo de Racket lo excluye si el estudiante lo pide, porque no hay ningún grupo que elegir, y reporta un aviso. El generador también lo omite de las combinaciones.

## 5. Reglas de validación de `catalogo.rkt`

`leer-catalogo` aplica estas reglas a cada archivo y al conjunto:

| Regla | Error |
| --- | --- |
| El archivo existe y no está vacío. | `exn:fail:user` con “el archivo no existe” o “el archivo esta vacio”. |
| El contenido es JSON válido. | `exn:fail:user` con “no es un JSON valido”. |
| El objeto raíz es un hash. | “se esperaba un objeto JSON”. |
| `format_version` es entero e igual a `1`. | “format_version distinto de 1”. |
| `course_count` es entero no negativo y coincide con la cantidad de cursos. | “course_count no coincide con la cantidad de cursos”. |
| Cada curso tiene todos los campos obligatorios. | “falta el campo …”. |
| `career` es una carrera válida. | “carrera invalida …”. |
| `code`, `name`, `professor` son textos; `code` y `name` no vacíos. | “el campo … debe ser …”. |
| `credits` es entero no negativo. | “el campo credits debe ser un entero no negativo”. |
| `prerequisites` y `corequisites` son listas de textos no vacíos. | “el campo … debe ser una lista de codigos”. |
| Un curso no es requisito ni correquisito de sí mismo. | “un curso no puede ser requisito de si mismo”. |
| `groups` es una lista de objetos; cada grupo tiene `number`, `professor`, `blocks` y `has_conflict`. | “el campo … debe ser …”. |
| Los números de grupo son positivos y no se repiten dentro del curso. | “el grupo … aparece mas de una vez”. |
| Los bloques tienen día válido, horas válidas y `end > start`. | “dia invalido”, “hora invalida”, “un bloque termina antes de empezar”. |
| `approved`, `can_enroll` y los `has_conflict` son booleanos. | “el campo … debe ser true o false”. |
| `has_conflict` del curso coincide con sus grupos. | “has_conflict del curso no coincide con sus grupos”. |
| No hay dos cursos con la misma pareja `(career, code)` en el conjunto de archivos. | “el curso … de … aparece mas de una vez”. |

El mismo código en carreras distintas es válido. Un código repetido dentro de la misma carrera, aunque venga en archivos distintos, es un error.

## 6. Errores esperados y pruebas

Los archivos de `racket/tests/data/` cubren:

- catálogo válido: `catalogo_sintetico.json`;
- archivo vacío: `catalogo_vacio.json`;
- archivo inexistente: se usa una ruta que no existe;
- JSON malformado: `catalogo_json_malformado.json`;
- raíz que no es objeto: `catalogo_no_objeto.json`;
- carrera inválida: `catalogo_carrera_invalida.json`;
- hora inválida: `catalogo_corrupto.json`;
- `course_count` incorrecto: `catalogo_conteo_incorrecto.json`;
- código repetido en una carrera: `catalogo_codigo_repetido.json`;
- mismo código en carreras distintas: `catalogo_mismo_codigo_dos_carreras.json`;
- grupo repetido: `catalogo_grupo_repetido.json`;
- campo obligatorio faltante: `catalogo_sin_campo.json`;
- auto-requisito: `catalogo_auto_requisito.json`;
- `has_conflict` incoherente: `catalogo_choque_incoherente.json`;
- `format_version` distinto: `catalogo_formato_version.json`.

Las pruebas están en `racket/tests/test-catalogo.rkt` y se ejecutan con:

```bash
raco test racket/tests/test-catalogo.rkt
```

## 7. Relación con el resto de la Etapa 2

1. `catalogo.rkt` convierte cada JSON en structs `curso`, `grupo` y `bloque`.
2. `preferencias.rkt` lee los cursos y grupos que el estudiante quiere.
3. `universo.rkt` cruza ambas entradas, elimina aprobados y no habilitados, y deja solo los grupos solicitados que existen.
4. `generador.rkt` recibe ese universo y produce combinaciones.
5. `filtros.rkt` filtra las combinaciones por créditos.

El catálogo original no se modifica: `universo.rkt` usa `struct-copy` para crear cursos con la lista de grupos recortada, y las pruebas comprueban que el catálogo conserva sus grupos originales.
