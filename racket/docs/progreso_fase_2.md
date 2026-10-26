# Progreso de la Fase 2: tipos, lectura y universo

Fecha de revisión: 2026-10-26.
Rama: `feature/etapa2-fases-0-3`.

## 1. Objetivo

Cargar el catálogo y las preferencias en estructuras inmutables, validar los errores de formato y construir el universo de cursos con el que trabaja el generador.

## 2. Tipos definidos

Los tipos están en `racket/src/types.rkt` y se documentan en detalle en `racket/docs/estructuras.md`.

| Tipo | Propósito |
| --- | --- |
| `bloque` | Día y minutos de inicio/fin de una clase. |
| `grupo` | Número, profesor, bloques y bandera de choque de C. |
| `curso` | Carrera, código, nombre, créditos, requisitos, grupos y banderas. |
| `catalogo` | Lista de cursos de una o varias carreras. |
| `interes` | Curso que el estudiante quiere y grupos aceptados. |
| `preferencias` | Intereses y rango de créditos. |
| `par-curso-grupo` | Curso con el grupo elegido. |
| `combinacion` | Pares no vacíos y créditos acumulados. |
| `universo` | Cursos recortados y avisos (definido en `universo.rkt`). |

Todos los structs son inmutables, transparentes y se exportan con `contract-out`. No se usa `#:mutable`, `set!`, `hash-set!`, `vector-set!` ni `set-box!` en `racket/src/`.

## 3. Contratos utilizados

| Módulo | Funciones o structs con contrato |
| --- | --- |
| `types.rkt` | Todos los structs y alias `dia/c`, `minuto/c`, `carrera/c`. |
| `lectura.rkt` | `error-lectura`, `leer-json`, `campo`, `lista-de`. |
| `catalogo.rkt` | `hora->minutos`, `leer-catalogo`, `cursos-habilitados`, `buscar-curso`. |
| `preferencias.rkt` | `leer-preferencias`. |
| `universo.rkt` | Struct `universo` y `construir-universo`. |
| `choques.rkt` | `bloques-chocan?`, `grupos-chocan?`, `grupo-compatible?`. |
| `generador.rkt` | `generar-combinaciones`, `generar-combinaciones-de-cursos`. |
| `filtros.rkt` | `filtrar-por-rango`. |

Los contratos se aplican en las fronteras. Las funciones internas (por ejemplo, `json->curso`, `evaluar-interes`, `generar`) no repiten contratos para no duplicar validaciones y costos.

## 4. Formato de entrada validado

### 4.1 Catálogo

`catalogo.rkt` valida:

- archivo existente, no vacío y con JSON válido;
- objeto raíz;
- `format_version = 1`;
- `course_count` correcto;
- campos obligatorios y tipos;
- carreras válidas;
- horas `HH:MM`, días válidos y `end > start`;
- grupos, números positivos y no repetidos;
- `approved`, `can_enroll` y `has_conflict` booleanos;
- coherencia de `has_conflict` del curso con sus grupos;
- auto-requisitos;
- pareja `(carrera, código)` única en el conjunto de archivos.

El mismo código en carreras distintas es válido. El detalle está en `racket/docs/entrada_catalogo.md`.

### 4.2 Preferencias

`preferencias.rkt` valida:

- archivo existente, no vacío y con JSON válido;
- objeto raíz;
- `min_credits` y `max_credits` enteros no negativos;
- `min_credits <= max_credits`;
- `courses` como lista de objetos;
- carrera válida;
- código no vacío;
- `groups` como lista no vacía de enteros positivos;
- grupos no repetidos dentro de un curso.

El detalle está en `racket/docs/preferencias.md`.

## 5. Errores controlados

Todos los errores de lectura se lanzan con `error-lectura`, que usa `raise-user-error` y produce `exn:fail:user`. El mensaje incluye el archivo, el curso o el grupo cuando se conoce y una descripción del problema. `leer-json` distingue:

- archivo inexistente: “el archivo no existe”;
- archivo vacío: “el archivo esta vacio”;
- JSON malformado: “no es un JSON valido”.

La Etapa 2 no tiene todavía un `main.rkt` que capture estos errores; las pruebas los verifican directamente con `check-exn`. El futuro programa principal deberá envolver la lectura en un manejador que muestre el mensaje y termine con un código distinto de cero.

## 6. Decisiones sobre casos especiales

### 6.1 Cursos repetidos en preferencias

`preferencias.rkt` permite que un curso aparezca más de una vez; no es un error de formato. `universo.rkt` conserva la primera aparición, ignora las siguientes y agrega el aviso:

```
computadores S1: esta repetido, se usa la primera aparicion
```

La razón es que el archivo lo escribe una persona y el programa debe explicar el problema sin abortar. Si la primera aparición no tiene grupos válidos y la segunda sí, se usa la primera y se pierde la segunda; esto es coherente con “se usa la primera aparición” y está documentado.

### 6.2 Cursos aprobados

Se eliminan del universo y se reporta:

```
computadores S6: ya esta aprobado
```

Un curso aprobado no debe volver a matricularse.

### 6.3 Cursos no habilitados

Se eliminan del universo y se reporta:

```
computadores S5: no esta habilitado (faltan requisitos)
```

`can_enroll` mide requisitos curriculares, no choques. Un curso puede ser habilitado y aun así no caber en una combinación.

### 6.4 Cursos inexistentes

Si la pareja `(carrera, código)` no está en el catálogo, se elimina el interés y se reporta:

```
computadores S9: no esta en el catalogo
```

### 6.5 Grupos inexistentes

Se conservan solo los grupos solicitados que existen en el catálogo. Los que no existen se reportan:

```
computadores S2: no tiene el grupo 3
```

Si no queda ningún grupo válido, el curso se excluye y se agrega:

```
computadores S2: no le queda ningun grupo de interes
```

### 6.6 Orden

- Los cursos del universo siguen el orden de las preferencias.
- Los grupos de cada curso siguen el orden del catálogo, no el orden en que se escribieron en las preferencias.
- Los avisos se acumulan en el orden en que se detectan.

### 6.7 Catálogo original

`universo.rkt` usa `struct-copy` para crear un curso nuevo con la lista de grupos recortada. El catálogo original no se modifica; la prueba `no modifica el catalogo original` compara los grupos de `S1` antes y después.

## 7. Ejemplos

### 7.1 Entrada válida

Catálogo sintético `catalogo_sintetico.json` con siete cursos; preferencias `preferencias_varios_grupos.json` con rango 6–10 y cuatro cursos. El universo queda:

```
S1 grupos 1, 2
S2 grupos 1, 2
S3 grupos 1, 2
S4 grupo 1
```

### 7.2 Entrada con problemas

`preferencias_no_habilitado.json` pide siete cursos; el universo deja solo `S1` y produce ocho avisos: no habilitado, aprobado, inexistente, grupo inexistente, repetido y curso sin grupos. La prueba verifica el orden y el contenido de los avisos.

### 7.3 Catálogo con errores

Los archivos `catalogo_carrera_invalida.json`, `catalogo_conteo_incorrecto.json`, `catalogo_codigo_repetido.json`, `catalogo_grupo_repetido.json`, `catalogo_sin_campo.json`, `catalogo_auto_requisito.json`, `catalogo_choque_incoherente.json` y `catalogo_formato_version.json` producen `exn:fail:user` con mensajes específicos.

## 8. Relación catálogo–preferencias–universo

```
catalogo.json ──► catalogo.rkt ──► catalogo
                                      │
preferencias.json ──► preferencias.rkt ──► preferencias
                                      │
                                      ▼
                           universo.rkt / construir-universo
                                      │
                                      ▼
                         universo: cursos + avisos
```

Reglas del cruce:

1. Buscar el curso por `(carrera, código)`.
2. Si no existe, avisar y descartar.
3. Si está aprobado, avisar y descartar.
4. Si no es matriculable, avisar y descartar.
5. Comparar los grupos pedidos con los grupos reales.
6. Conservar solo los grupos que existen; avisar por los que no.
7. Si no queda ningún grupo, avisar y descartar el curso.
8. Mantener el orden de las preferencias y no modificar el catálogo.

## 9. Pruebas ejecutadas

| Suite | Resultado |
| --- | --- |
| `racket/tests/test-catalogo.rkt` | 6 tests passed |
| `racket/tests/test-preferencias.rkt` | 4 tests passed |
| `racket/tests/test-universo.rkt` | 6 tests passed |

Comando:

```bash
raco test racket/tests/test-catalogo.rkt
raco test racket/tests/test-preferencias.rkt
raco test racket/tests/test-universo.rkt
```

Las pruebas cubren catálogo válido, corrupto, vacío, inexistente, carrera inválida, hora inválida, conteo incorrecto, código repetido, mismo código en carreras distintas, grupo repetido, campo faltante, auto-requisito, formato incorrecto y JSON malformado; preferencias válidas, archivo vacío, inexistente, malformado, créditos negativos, rango imposible, carrera inválida, código vacío, grupos vacíos, no positivos y repetidos; y universo vacío, orden, avisos, cursos aprobados/no habilitados/inexistentes, grupos inexistentes y no modificación del catálogo.

## 10. Estado final

La Fase 2 queda cerrada: los tipos están definidos y documentados, catálogo y preferencias se cargan con errores controlados, el universo preserva el orden y no muta el catálogo original, y todas las pruebas pasan. Queda pendiente para fases posteriores la restricción de correquisitos dentro de las combinaciones y el programa principal que capture los errores de usuario.
