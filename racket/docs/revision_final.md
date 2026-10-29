# Revisión final y checklist de entrega de la Etapa 2

Fecha: 2026-10-29.
Rama de cierre: `doc_test`.
Alcance: Fases 0 a 5 completadas; documentación de la Fase 6 y revisión de la Fase 7.

Este documento reúne la evidencia de la revisión final, el checklist operativo del plan y las correcciones hechas al cerrar la etapa. La auditoría técnica detallada está en `auditoria_fase_5.md`; la explicación del código para la defensa está en `guia_defensa.md`.

## 1. Checklist operativo

| Requisito | Estado | Evidencia |
| --- | --- | --- |
| El código está en Racket y en paradigma funcional | Cumplido | `racket/src/` con structs inmutables, recursión, streams y funciones de orden superior; sin `set!`, `#:mutable`, `set-box!`, `hash-set!` ni `vector-set!`. |
| El código compila y corre sin errores en una máquina limpia | Cumplido en este entorno | `raco make racket/src/*.rkt`, `raco test racket/tests` y `make clean && make && make test`; ver sección 2. |
| No hay variables globales reasignadas | Cumplido | Las definiciones de nivel superior son constantes o funciones; el estado viaja como parámetro de la recursión. |
| Las combinaciones se generan con streams y no se envuelve una lista completa | Cumplido | `generador.rkt` usa `stream-cons`, `stream-lazy` y `stream-append`; no usa `list->stream` ni `stream->list`. |
| Hay tipos explícitos y una función con polimorfismo paramétrico reutilizada | Cumplido | Contratos `contract-out` en todos los módulos; `en-rango` con `parametric->/c`; `filtrar-por-rango` con `stream/c any/c`. |
| El filtro por créditos usa el rango de las preferencias y es la única restricción | Cumplido | `filtrar-por-creditos` con límites inclusivos; no hay otras restricciones en el flujo principal. |
| La salida trae pares curso-grupo, créditos totales y carrera por curso | Cumplido | `data/combinaciones.jsonl` y contrato de `formato_salida.md`; campos extra justificados. |
| El catálogo tiene 6 semestres por carrera y el campo carrera | Cumplido | 39 cursos y 6 semestres por carrera; `career` en cada curso; regresión de C sin cambios funcionales. |
| Las preferencias incluyen más de un grupo por curso cuando aplica | Cumplido | `data/preferencias.json` y `racket/tests/data/preferencias_varios_grupos.json` tienen cursos con varios grupos. |
| El README tiene 2.1, 2.2.1, 2.2.2, 2.2.3 y 2.3 | Cumplido | Nueva sección “Etapa 2” en `README.md`, con arquitectura, decisiones, caso límite, formato, estructuras, uso y pruebas. |
| El repositorio muestra commits significativos de los tres integrantes, ramas y pull requests | Parcial, a cargo del equipo | El historial tiene ramas y commits de las tres áreas; la verificación de pull requests y de la autoría final corresponde al equipo. |
| El enlace del repositorio está entregado por TEC-Digital | Pendiente del equipo | No se puede verificar desde el repositorio. |
| Los tres integrantes conocen todo el código y pueden modificarlo en vivo | Pendiente del equipo | La guía de defensa y el simulacro de la Fase 7 son el insumo; la confirmación es del equipo. |
| Se confirmó con el profesor el equipo para la revisión | Pendiente del equipo | Aspecto operativo fuera del repositorio. |
| Último commit antes del viernes 30 de octubre a las 9:30 a.m. | Cumplido en la medida de esta revisión | Los commits de cierre se hicieron el 2026-10-29, antes del límite. |

## 2. Evidencia ejecutada

### 2.1 Racket

```bash
raco make racket/src/*.rkt
raco test racket/tests
racket racket/src/main.rkt
```

Resultados:

- compilación sin errores;
- 65 pruebas aprobadas;
- 762 combinaciones exportadas a `data/combinaciones.jsonl` con las preferencias reales.

La salida real se validó con `test-validar-salida.rkt`: campos obligatorios, créditos iguales a la suma, rango 12–18, ningún choque, cursos matriculables, carrera consistente y un curso como máximo una vez por combinación. La distribución es 14 combinaciones de 3 cursos, 335 de 4, 361 de 5 y 52 de 6.

### 2.2 C y regresión

```bash
make clean
make
make test
bash tests/regression_etapa1.sh origin/main
```

Resultados:

- `tests/run_tests`: 48/48;
- `tests/run_phase4`: 35/35;
- `tests/run_export`: 73/73;
- regresión: las salidas de Computadores y Física son idénticas a `origin/main` salvo por el campo `career`;
- 39 cursos por carrera, 17 aprobados en Computadores y 14 en Física, 8 cursos matriculables en cada carrera.

### 2.3 Casos límite

- mínimo igual a máximo (6–6): 6 combinaciones, todas de 6 créditos;
- un solo curso con un solo grupo: una combinación, `S4-1`, 2 créditos;
- rango sin resultados: archivo vacío y cantidad 0;
- universo vacío: `empty-stream`;
- curso sin grupos: se omite;
- borde de horario: `S1-1` y `S2-2` no chocan;
- catálogo grande: 60 cursos, 2^60 − 1 combinaciones, primer resultado inmediato;
- ruta de salida inválida: mensaje por `stderr` y código 1.

## 3. Correcciones de la revisión final

| Hallazgo | Corrección | Archivo |
| --- | --- | --- |
| El `.gitignore` no ignoraba el bytecode compilado de Racket. | Se agregó `compiled/`, `*.zo` y `*.dep`. | `.gitignore` |
| Un error de escritura en `main.rkt` mostraba una traza interna. | Se captura `exn:fail:filesystem?` y se muestra un mensaje con código 1. | `racket/src/main.rkt` |
| El README solo documentaba la Etapa 1. | Se agregó la sección completa de la Etapa 2 con 2.1, 2.2.1, 2.2.2, 2.2.3, 2.3, uso y pruebas. | `README.md` |
| Varios documentos de las Fases 0–3 decían que no existían el exportador ni `main.rkt`. | Se marcaron como documentos históricos y se actualizaron las decisiones, la guía de defensa y el contrato de formato. | `racket/docs/` |
| El plan de trabajo anterior era `plan_Fase0-3.md` y el plan vigente es `planDocTest.md`. | Se reemplazó el archivo histórico por el plan completo de la etapa. | `planDocTest.md` |

## 4. Limitaciones que se deben declarar en la defensa

- La Etapa 2 no incluye interfaz, sugerencias, optimización ni la Etapa 3 en Prolog.
- No se impone la regla de correquisitos dentro de las combinaciones; el exportador entrega `corequisites` para que Prolog la aplique (D8). La combinación real `id = 13` incluye `FI1202` sin `FI1102`, y la `id = 52` incluye ambos; ambas son válidas para esta etapa.
- El generador permite omitir cursos (D1). Si el profesor exige que todos estén, se cambia `OMITIR-CURSOS?` a `#f` en un solo módulo.
- El programa no impone una carrera de estudiante; `data/preferencias.json` mezcla Computadores y Física para ejercitar los dos catálogos.
- La instalación de Racket de la revisión fue local; en otra máquina deben usarse `racket` y `raco` del entorno del equipo.
- La entrega del enlace, la confirmación del profesor y el simulacro de defensa son tareas operativas del equipo, no verificables desde el repositorio.

## 5. Conclusión

La Etapa 2 queda completa para el alcance de las Fases 0 a 5: el código compila, las 65 pruebas de Racket y las 156 pruebas de C pasan, la salida real está validada contra el catálogo de C y el README documenta las secciones exigidas. Las correcciones de la revisión final no cambian el diseño ni el formato de salida; solo cierran higiene del repositorio, manejo de errores y documentación.
