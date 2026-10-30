# Entrada de preferencias

`racket/src/preferencias.rkt` lee el archivo JSON con los cursos que el estudiante quiere matricular y el rango de créditos aceptado. El lector valida el formato; la existencia de cursos y grupos se revisa después, en `universo.rkt`, porque para eso hace falta el catálogo.

## 1. Estructura

```json
{
  "min_credits": 12,
  "max_credits": 18,
  "courses": [
    {"career": "computadores", "code": "CE2103", "groups": [1]},
    {"career": "computadores", "code": "EL2113", "groups": [1, 2]},
    {"career": "fisica", "code": "MA1103", "groups": [1, 2]}
  ]
}
```

El objeto raíz tiene tres campos obligatorios:

| Campo | Tipo | Significado |
| --- | --- | --- |
| `min_credits` | entero no negativo | Mínimo de créditos que el estudiante quiere en una combinación. |
| `max_credits` | entero no negativo | Máximo de créditos que el estudiante quiere en una combinación. |
| `courses` | arreglo de objetos | Cursos de interés. Puede ser `[]`, en cuyo caso el universo queda vacío. |

Cada curso de interés tiene:

| Campo | Tipo | Significado |
| --- | --- | --- |
| `career` | `"computadores"` o `"fisica"` | Carrera del curso. |
| `code` | texto no vacío | Código del curso. |
| `groups` | arreglo no vacío de enteros positivos | Números de grupo que el estudiante acepta. |

La pareja `(career, code)` identifica el curso. Un mismo código en carreras distintas es un curso distinto y puede aparecer dos veces en `courses` con carreras diferentes.

## 2. Reglas de validación

`leer-preferencias` valida:

| Regla | Error controlado |
| --- | --- |
| El archivo existe y no está vacío. | `exn:fail:user` con “el archivo no existe” o “el archivo esta vacio”. |
| El contenido es JSON válido. | “no es un JSON valido”. |
| El objeto raíz es un hash. | “se esperaba un objeto JSON”. |
| `min_credits` y `max_credits` son enteros no negativos. | “el campo … debe ser un entero no negativo”. |
| `min_credits <= max_credits`. | “min_credits … es mayor que max_credits …”. |
| `courses` es una lista de objetos. | “el campo courses debe ser una lista de cursos”. |
| `career` es válida. | “carrera invalida …”. |
| `code` no está vacío. | “el campo code debe ser un texto no vacio”. |
| `groups` es una lista de enteros positivos. | “el campo groups debe ser una lista de enteros positivos”. |
| `groups` no está vacía. | “debe indicar al menos un grupo”. |
| No hay grupos repetidos dentro de un curso. | “hay grupos repetidos”. |

Un rango con `min_credits = max_credits` es válido. Un rango sin resultados también es válido: el filtro simplemente devuelve un stream vacío.

## 3. Ejemplos

### 3.1 Válido

```json
{
  "min_credits": 6,
  "max_credits": 10,
  "courses": [
    {"career": "computadores", "code": "S1", "groups": [1, 2]},
    {"career": "fisica", "code": "S3", "groups": [2]}
  ]
}
```

El lector devuelve `(preferencias (list (interes ...) ...) 6 10)`.

### 3.2 Inválido: mínimo mayor que máximo

```json
{"min_credits": 10, "max_credits": 6, "courses": []}
```

`leer-preferencias` lanza `exn:fail:user` y no construye el struct.

### 3.3 Inválido: un grupo no positivo o repetido

```json
{"min_credits": 0, "max_credits": 10,
 "courses": [{"career": "computadores", "code": "S1", "groups": [0]}]}
```

El contrato exige enteros positivos. Si se repite `[1, 1]`, el lector también lo rechaza.

## 4. Comportamiento ante casos especiales

### Cursos repetidos

El lector de preferencias **permite** que un curso aparezca más de una vez; no lo considera un error de formato. `universo.rkt` conserva la primera aparición, ignora las siguientes y agrega el aviso:

```
computadores S1: esta repetido, se usa la primera aparicion
```

La razón es que el usuario puede editar el archivo a mano y el programa debe explicar el problema sin abortar. La decisión se documenta también en `progreso_fase_2.md`.

### Grupos inexistentes

El lector solo comprueba que los números sean positivos y no estén repetidos. `universo.rkt` compara contra los grupos reales del catálogo:

- los grupos solicitados que existen se conservan;
- los que no existen se reportan con “no tiene el grupo N”;
- si no queda ningún grupo válido, el curso se excluye y se reporta “no le queda ningun grupo de interes”.

### Cursos inexistentes

El lector no puede saberlo sin el catálogo. `universo.rkt` busca la pareja `(career, code)` y, si no existe, excluye el interés y reporta:

```
computadores S9: no esta en el catalogo
```

### Cursos aprobados

`universo.rkt` excluye los cursos con `approved = true` y reporta:

```
computadores S6: ya esta aprobado
```

### Cursos no habilitados

`universo.rkt` excluye los cursos con `can_enroll = false` (cuando no están aprobados) y reporta:

```
computadores S5: no esta habilitado (faltan requisitos)
```

## 5. Relación con catálogo y universo

El flujo es:

```
preferencias.json ──leer-preferencias──► preferencias
                                             │
catalogo.json ─────leer-catalogo────────► catalogo
                                             │
                                             ▼
                                  construir-universo
                                             │
                                             ▼
                         universo (cursos + avisos)
```

`construir-universo` no modifica el catálogo. Para cada interés crea un curso nuevo con `struct-copy` y la lista de grupos recortada, de modo que el catálogo original conserva todos sus grupos. El orden de los cursos del universo es el orden de las preferencias; el orden de los grupos dentro de un curso es el orden del catálogo.

## 6. Pruebas

`racket/tests/test-preferencias.rkt` cubre:

- archivo válido con varios grupos;
- archivo real `data/preferencias.json`;
- archivo inexistente;
- archivo vacío;
- JSON malformado;
- raíz que no es objeto;
- créditos negativos;
- mínimo mayor que máximo;
- carrera inválida;
- código vacío;
- lista de grupos vacía;
- grupo no positivo;
- grupos repetidos;
- `courses` que no es lista;
- falta de `max_credits`.

Los archivos están en `racket/tests/data/preferencias_*.json`. La suite se ejecuta con:

```bash
raco test racket/tests/test-preferencias.rkt
```
