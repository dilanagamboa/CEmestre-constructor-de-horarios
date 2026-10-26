# Guía para completar las Fases 0–3 de la Etapa 2

## 1. Propósito

Esta guía indica cómo completar totalmente las Fases 0, 1, 2 y 3 de la Etapa 2 del proyecto CEmestre, trabajando sobre la rama:

`feature/etapa2-fases-0-3`

El objetivo es que el equipo pueda:

1. Revisar lo que ya existe.
2. Completar lo faltante de las Personas A, B y C.
3. Mantener compatibilidad con la Etapa 1 en C.
4. Respetar el paradigma funcional en Racket.
5. Dejar pruebas y documentación suficientes para la defensa.
6. Registrar claramente qué hizo, qué verificó y qué decisiones tomó.

El equipo no debe implementar las Fases 4, 5, 6 ni 7, salvo que sea estrictamente necesario para ejecutar pruebas de las Fases 0–3.

---

## 2. Estado inicial conocido

Antes de modificar cualquier archivo, el equipo debe inspeccionar la rama y confirmar el estado real.

### 2.1 Elementos que ya existen

En la rama se encuentran, entre otros:

- Datos ampliados de Computadores y Física.
- Campo `career` en la salida del módulo C.
- Catálogos generados para ambas carreras.
- Estructura inicial de `racket/src/`.
- Estructuras y contratos en `racket/src/types.rkt`.
- Lectura del catálogo en `racket/src/catalogo.rkt`.
- Lectura de preferencias en `racket/src/preferencias.rkt`.
- Construcción del universo en `racket/src/universo.rkt`.
- Detección de choques en `racket/src/choques.rkt`.
- Pruebas iniciales para catálogo, preferencias, universo y choques.
- Catálogos y preferencias sintéticos para pruebas.

### 2.2 Elementos que deben verificarse o completarse

El equipo debe confirmar si existen y cumplen el plan:

- `racket/docs/decisiones.md`
- `racket/docs/entrada_catalogo.md`
- `racket/docs/preferencias.md`
- `racket/docs/estructuras.md`
- Prototipo de streams.
- Documentación de la Fase 0.
- Regresión del módulo C contra la Etapa 1.
- `racket/src/generador.rkt`
- `racket/src/filtros.rkt`
- Pruebas del generador.
- Pruebas de streams y pereza.
- Pruebas de polimorfismo paramétrico.
- Plan de pruebas del generador.
- Registro formal del progreso.

El equipo no debe asumir que un archivo está completo solo porque existe. Debe revisar su contenido, dependencias, pruebas y relación con el plan.

---

## 3. Reglas obligatorias para el equipo

### 3.1 Reglas de alcance

El equipo debe implementar únicamente lo necesario para las Fases 0–3:

- Decisiones y contratos.
- Datos y ampliación del módulo C.
- Tipos y lectura de entradas.
- Universo de cursos.
- Detección de choques.
- Generación de combinaciones.
- Streams.
- Polimorfismo paramétrico.
- Pruebas y documentación asociadas.

No debe implementar todavía:

- Exportación final de combinaciones.
- Programa principal completo.
- Filtro final de créditos integrado al flujo principal.
- Optimización avanzada.
- Interfaz.
- Sugerencias de horarios.
- Prolog.
- Restricciones diferentes de choques y, posteriormente, créditos.

### 3.2 Reglas funcionales

Todo el código nuevo de Racket debe:

- Evitar `set!`.
- Evitar estructuras mutables.
- Evitar variables reasignadas.
- Usar recursión, `map`, `filter`, `foldr`, `ormap`, `andmap` u otras funciones funcionales apropiadas.
- No convertir una lista completa en stream al final.
- No construir todas las combinaciones en memoria antes de devolverlas.
- Mantener structs inmutables.
- Mantener contratos o tipado explícito coherente en todos los módulos.

### 3.3 Reglas de compatibilidad

El equipo debe:

- Mantener el formato de salida de C.
- Mantener los nombres de campos existentes.
- Mantener el campo `career`.
- Mantener la identificación de un curso como pareja `(carrera, código)`.
- Mantener la regla de choques de la Etapa 1.
- No modificar la lógica curricular de C salvo para completar la asignación del campo de carrera.
- Evitar romper las pruebas existentes de C o Racket.

---

## 4. Procedimiento general de trabajo

El equipo debe seguir este orden:

1. Inspeccionar el árbol completo de la rama.
2. Revisar el historial de commits y cambios relacionados.
3. Ejecutar o revisar las pruebas existentes.
4. Comparar el estado actual contra el plan.
5. Crear una matriz de tareas pendientes.
6. Completar cada fase en orden.
7. Probar cada módulo de forma aislada.
8. Probar las dependencias entre módulos.
9. Ejecutar una auditoría de mutación y de uso de streams.
10. Actualizar la documentación de progreso.
11. Preparar un resumen para la defensa.
12. No avanzar a la siguiente fase si la anterior no tiene evidencia suficiente.

---

# 5. Fase 0 — Arranque, decisiones y contrato

## 5.1 Objetivo

Cerrar las decisiones de diseño que afectan las Fases 1–3 y dejar documentado el contrato entre C, Racket y la futura etapa de Prolog.

## 5.2 Tareas del equipo

### A. Revisar y documentar las decisiones D1–D7

Crear o completar:

`racket/docs/decisiones.md`

La documentación debe incluir:

- Identificador de la decisión.
- Alternativas consideradas.
- Decisión final.
- Justificación.
- Consecuencias sobre el diseño.
- Archivos afectados.
- Cómo se verificará la decisión.

Debe documentarse como mínimo:

#### D1 — Definición de combinación

La solución debe declarar explícitamente si una combinación:

- Incluye todos los cursos de interés; o
- Es un subconjunto no vacío de los cursos habilitados.

La decisión debe ser coherente con el filtro por créditos.

La implementación debe quedar preparada para modificar esta regla en un solo módulo si el profesor responde algo diferente.

#### D2 — Tipos o contratos

Registrar si el proyecto usa:

- Typed Racket; o
- Racket con contratos.

En el estado actual se utilizan structs inmutables y contratos. El equipo debe mantener una sola estrategia en todos los módulos.

#### D3 — Formato de salida

Aunque la exportación corresponde principalmente a la Fase 4, en esta fase debe documentarse la decisión preliminar.

La decisión debe evaluar:

- Escritura incremental.
- Facilidad de consumo por Prolog.
- Legibilidad.
- Tamaño.
- Compatibilidad con streams.

#### D4 — Campos de combinación

Definir los campos obligatorios y los extras previstos:

- Pares curso-grupo.
- Créditos totales.
- Carrera por curso.
- Identificador o cantidad de cursos, si se decide incluirlos después.
- Información de horarios, si se necesita para Prolog.

#### D5 — Choques en el borde

Documentar que un bloque que termina exactamente cuando otro empieza no choca, si esta es la regla confirmada por C.

#### D6 — Fuente de los choques

Indicar que Racket calcula los choques entre grupos a partir de sus bloques y utiliza la bandera de C como referencia de consistencia.

#### D7 — Organización del repositorio

Documentar:

- Código C existente.
- Código Racket en `racket/`.
- Datos compartidos en `data/`.
- Pruebas en `racket/tests/`.
- Documentación en `racket/docs/`.
- Rama de trabajo.
- Convención de commits.
- Convención de revisión.

### B. Auditar el formato de entrada del catálogo

Crear o completar:

`racket/docs/entrada_catalogo.md`

Debe describir:

- Estructura del JSON generado por C.
- Campos obligatorios.
- Tipos de cada campo.
- Significado de `career`.
- Significado de `approved`.
- Significado de `can_enroll`.
- Significado de `has_conflict`.
- Representación de bloques horarios.
- Regla de `format_version`.
- Manejo de cursos sin grupos.
- Errores esperados.

### C. Auditar el formato de preferencias

Crear o completar:

`racket/docs/preferencias.md`

Debe incluir:

- Estructura del archivo.
- Campos mínimos y máximos de créditos.
- Carrera.
- Código del curso.
- Lista de grupos.
- Reglas de validación.
- Ejemplos conceptuales, sin necesidad de incluir código.
- Comportamiento ante cursos repetidos.
- Comportamiento ante grupos inexistentes.
- Comportamiento ante cursos no habilitados.

### D. Documentar el prototipo de streams

El equipo debe revisar si existe un prototipo de streams. Si no existe, debe crear la evidencia correspondiente en forma de archivo de documentación y prueba.

La documentación debe demostrar:

- Qué se evalúa de forma perezosa.
- Qué significa pedir únicamente el primer elemento.
- Que no se genera toda la solución antes de devolver el resultado.
- Qué biblioteca de streams se usa.
- Qué dificultades existen con contratos o tipos.
- Qué diseño se trasladará al generador definitivo.

No se debe aceptar como prototipo una lista completa transformada posteriormente a stream.

### E. Documentar la comparación de formatos

Crear o completar:

`racket/docs/formatos_salida.md`

Comparar:

- JSON.
- JSON Lines.
- CSV.
- Hechos de Prolog.

La decisión final debe relacionarse con:

- Consumo incremental.
- Compatibilidad con streams.
- Lectura desde Prolog.
- Preservación de estructuras anidadas.
- Facilidad de depuración.

## 5.3 Criterio de cierre de la Fase 0

La fase solo se considera terminada si:

- D1–D7 están documentadas.
- El formato del catálogo está documentado.
- El formato de preferencias está documentado.
- Existe evidencia del prototipo de streams.
- Existe una comparación de formatos.
- Las decisiones son coherentes con el código actual.
- El equipo registra cualquier decisión provisional.

---

# 6. Fase 1 — Datos y ampliación de C

## 6.1 Objetivo

Tener datos de seis semestres para ambas carreras, conservar la lógica de la Etapa 1 y agregar el campo de carrera por curso.

## 6.2 Tareas del equipo

### A. Verificar el campo de carrera en C

Revisar:

- `include/constants.h`
- `include/structs.h`
- `include/catalog.h`
- `src/catalog.c`
- `src/export.c`
- `src/main.c`

Confirmar que:

- La carrera es válida.
- Se asigna a todos los cursos del catálogo.
- Se exporta al JSON.
- Se mantiene estable para cada carrera.
- Un catálogo de Computadores no contiene cursos marcados como Física.
- Un catálogo de Física no contiene cursos marcados como Computadores.

### B. Revisar los datos de Computadores

Verificar:

- Cursos de semestres 1–6.
- Créditos.
- Prerrequisitos.
- Correquisitos.
- Grupos.
- Horarios.
- Cursos sin grupos.
- Datos de fuente.
- Consistencia entre plan, horarios y catálogo generado.

### C. Revisar los datos de Física

Verificar los mismos elementos para:

- `data/fuente/plan_fisica.csv`
- `data/catalogo_fisica.csv`
- `data/salida_fisica.json`

### D. Verificar la regresión de Etapa 1

El equipo debe ejecutar o revisar una prueba de regresión que confirme:

- La salida conserva la información anterior.
- La única diferencia funcional esperada es el nuevo campo `career`.
- La lógica de choques no cambió.
- La lógica de requisitos y correquisitos no cambió.
- Los cursos antiguos mantienen el mismo estado de matriculabilidad.

Si hay diferencias adicionales, el equipo debe investigarlas y documentarlas antes de continuar.

### E. Revisar los archivos de prueba

Confirmar la existencia de casos para:

- Archivo válido.
- Archivo corrupto.
- Archivo vacío.
- Archivo inexistente.
- Cursos con varios grupos.
- Cursos no habilitados.
- Rango imposible de créditos.
- Rango que cubre todas las combinaciones.

## 6.3 Documentación obligatoria

Actualizar:

`racket/docs/progreso_fase_1.md`

Debe contener:

- Archivos revisados.
- Cantidad de cursos por carrera.
- Cursos agregados.
- Casos sin grupos.
- Casos de correquisitos especiales.
- Resultado de la regresión.
- Problemas encontrados.
- Correcciones realizadas.
- Evidencia de las pruebas ejecutadas.

## 6.4 Criterio de cierre de la Fase 1

La fase se considera terminada si:

- Ambas carreras tienen datos de seis semestres.
- El campo `career` aparece correctamente en la salida.
- C sigue compilando.
- La regresión no muestra cambios no justificados.
- Los datos de prueba existen.
- La documentación explica las decisiones y excepciones de los datos.

---

# 7. Fase 2 — Tipos y lectura de entradas

## 7.1 Objetivo

Cargar catálogo y preferencias en estructuras inmutables, validar errores y construir el universo de cursos de trabajo.

## 7.2 Tareas de la Persona A

Revisar y completar:

`racket/src/types.rkt`

Debe existir una representación coherente para:

- Bloques.
- Grupos.
- Cursos.
- Catálogo.
- Intereses.
- Preferencias.
- Pares curso-grupo.
- Combinaciones.

El equipo debe verificar:

- Contratos explícitos.
- Structs inmutables.
- Carreras válidas.
- Créditos no negativos.
- Listas con tipos apropiados.
- Combinaciones no vacías.
- Compatibilidad entre constructores y consumidores.

Crear o completar:

`racket/docs/estructuras.md`

Debe explicar:

- Cada estructura.
- Propósito de cada campo.
- Invariantes.
- Relación entre estructuras.
- Por qué son inmutables.
- Cómo se usan durante la generación.

## 7.3 Tareas de la Persona B

Revisar y completar:

`racket/src/catalogo.rkt`

El lector debe:

- Leer el JSON generado por C.
- Validar `format_version`.
- Validar `course_count`.
- Validar campos obligatorios.
- Validar carreras.
- Validar horas.
- Validar bloques.
- Validar grupos.
- Construir structs.
- Reportar errores controlados.
- Unir los catálogos de ambas carreras.
- Identificar cursos por carrera y código.

Debe verificarse especialmente que el mismo código pueda existir en ambas carreras sin considerarse duplicado.

Completar las pruebas de:

- Catálogo válido.
- Catálogo corrupto.
- Archivo vacío.
- Archivo inexistente.
- Carrera inválida.
- Hora inválida.
- Cantidad de cursos incorrecta.
- Código repetido dentro de una carrera.
- Mismo código en carreras diferentes.

## 7.4 Tareas de la Persona C

Revisar y completar:

`racket/src/preferencias.rkt`

Debe validar:

- Objeto JSON.
- Mínimo de créditos.
- Máximo de créditos.
- Mínimo menor o igual al máximo.
- Créditos no negativos.
- Cursos de interés.
- Carrera válida.
- Código no vacío.
- Lista de grupos.
- Grupos positivos.
- Grupos no repetidos.

Revisar y completar:

`racket/src/universo.rkt`

El universo debe:

- Cruzar preferencias con el catálogo.
- Eliminar cursos aprobados.
- Eliminar cursos no matriculables.
- Mantener únicamente grupos solicitados y existentes.
- Reportar grupos inexistentes.
- Reportar cursos inexistentes.
- Reportar cursos no habilitados.
- Reportar cursos repetidos.
- Preservar el orden de las preferencias.
- No modificar el catálogo original.

## 7.5 Documentación obligatoria

Crear o completar:

`racket/docs/progreso_fase_2.md`

Debe incluir:

- Tipos definidos.
- Contratos utilizados.
- Formato de entrada validado.
- Errores controlados.
- Decisiones sobre cursos repetidos.
- Decisiones sobre cursos aprobados.
- Decisiones sobre grupos inexistentes.
- Ejemplos de entradas válidas e inválidas.
- Relación entre catálogo, preferencias y universo.

## 7.6 Criterio de cierre de la Fase 2

La fase se considera terminada si:

- Todos los tipos están definidos y documentados.
- Catálogo y preferencias se cargan correctamente.
- Los errores se reportan sin fallos inesperados.
- El universo es correcto para todos los casos de prueba.
- Los structs permanecen inmutables.
- Las pruebas existentes siguen pasando.
- El equipo puede explicar el flujo completo de lectura.

---

# 8. Fase 3 — Choques, streams y polimorfismo

## 8.1 Objetivo

Implementar el núcleo funcional de la Etapa 2:

- Detección de compatibilidad.
- Generación perezosa de combinaciones.
- Filtro genérico reutilizable.
- Pruebas aisladas y combinadas.

## 8.2 Tareas de la Persona A: choques

Revisar y completar:

`racket/src/choques.rkt`

Debe incluir:

- Choque entre dos bloques.
- Choque entre dos grupos.
- Compatibilidad de un grupo con una selección.
- Recorrido recursivo de la selección.
- Criterio de borde coherente con C.
- Tratamiento de grupos sin bloques.

Debe evitar:

- Estado global.
- Mutación.
- Uso exclusivo de la bandera `has_conflict`.
- Comparación entre grupos alternativos del mismo curso.

Las pruebas deben cubrir:

- Horarios idénticos.
- Traslape parcial.
- Un bloque dentro de otro.
- Borde sin choque.
- Días diferentes.
- Grupos con varios bloques.
- Grupos vacíos.
- Simetría de la función de choque.
- Compatibilidad con selección vacía.
- Compatibilidad con varios grupos acumulados.

El equipo debe agregar una prueba de consistencia contra las banderas producidas por C y documentar cualquier discrepancia.

## 8.3 Tareas de la Persona B: generador con streams

Crear o completar:

`racket/src/generador.rkt`

El diseño debe cumplir:

- Recibir el universo de cursos.
- Considerar las alternativas de cada curso.
- Permitir omitir un curso si D1 así lo establece.
- Elegir grupos compatibles.
- Acumular créditos sin mutación.
- Devolver un stream de `Combinacion`.
- No devolver la combinación vacía.
- No materializar todas las combinaciones antes de construir el stream.
- Generar resultados bajo demanda.
- Permitir pedir solo los primeros resultados.

El equipo debe documentar la estrategia de recursión:

- Estado conceptual de la recursión.
- Cursos pendientes.
- Selección acumulada.
- Créditos acumulados.
- Rama de omisión.
- Rama de selección de grupo.
- Condición de terminación.
- Exclusión de combinación vacía.

### Pruebas obligatorias

Crear o completar:

`racket/tests/test-generador.rkt`

Debe incluir:

- Un catálogo pequeño con resultados calculados manualmente.
- Un curso con un solo grupo.
- Un curso con varios grupos.
- Cursos que chocan.
- Cursos que no chocan.
- Grupos con varios bloques.
- Combinación vacía excluida.
- Universo vacío.
- Curso sin grupos.
- Preferencias con varios grupos.
- Resultados en el orden documentado.
- Cantidad esperada de combinaciones.
- Créditos acumulados correctos.

### Prueba de pereza

El equipo debe incluir una prueba que demuestre que:

- Pedir el primer elemento no obliga a generar toda la solución.
- Un catálogo grande puede producir el primer resultado sin recorrer todas las combinaciones.
- El generador no usa `list->stream` sobre una lista completa.
- No se almacenan todas las soluciones en una lista auxiliar.

La prueba puede usar contadores, mensajes de diagnóstico o una estructura de prueba equivalente, pero no debe introducir mutación en el código productivo.

## 8.4 Tareas de la Persona C: filtro polimórfico

Crear o completar:

`racket/src/filtros.rkt`

Debe existir una función genérica reutilizable que:

- Reciba un stream de elementos de cualquier tipo.
- Reciba una función para extraer un valor comparable.
- Reciba un rango inclusivo.
- Devuelva un stream filtrado.
- No dependa específicamente de `Combinacion`.
- No tenga una implementación separada para cada tipo.

El equipo debe documentar:

- Qué representa el parámetro de tipo.
- Qué función extrae el valor a comparar.
- Cómo se aplican los límites.
- Por qué la función es reutilizable.
- Cómo se conserva la pereza del stream.

### Pruebas obligatorias

Crear o completar:

`racket/tests/test-filtros.rkt`

El filtro debe probarse con al menos:

- Enteros.
- Cadenas o valores derivados de cadenas.
- Combinaciones.
- Dos extractores diferentes.
- Límites inclusivos.
- Rango sin resultados.
- Rango que incluye todos los elementos.
- Mínimo igual al máximo.
- Elementos fuera del rango.

El filtro de créditos debe demostrarse usando `Combinacion`, pero no debe ser la única demostración del polimorfismo.

## 8.5 Plan de pruebas de la Fase 3

Crear o completar:

`racket/docs/plan_pruebas_generador.md`

Debe incluir una tabla con:

- Identificador.
- Caso.
- Entrada.
- Resultado esperado.
- Resultado observado.
- Estado.
- Persona que revisó.
- Evidencia o archivo de prueba.

Los casos mínimos son:

1. Universo vacío.
2. Un curso con un grupo.
3. Un curso con varios grupos.
4. Dos cursos sin choque.
5. Dos cursos con choque.
6. Choque parcial.
7. Choque en borde.
8. Curso omitido.
9. Combinación vacía.
10. Créditos acumulados.
11. Preferencias con varios grupos.
12. Grupo inexistente excluido del universo.
13. Curso no habilitado.
14. Rango sin resultados.
15. Solicitud del primer elemento.
16. Catálogo grande.
17. Tres tipos en el filtro polimórfico.
18. Límites inclusivos.

## 8.6 Criterio de cierre de la Fase 3

La fase se considera terminada si:

- `choques.rkt` está probado.
- `generador.rkt` devuelve streams reales.
- No se usa `list->stream` para ocultar una generación eager.
- Se excluye la combinación vacía.
- Se verifica la pereza.
- `filtros.rkt` es genérico y reutilizable.
- Se demuestra polimorfismo con al menos tres tipos.
- Las pruebas comparan resultados contra un oráculo manual.
- Existe revisión cruzada documentada.
- No hay mutación en `racket/src/`.

---

# 9. Documentación transversal del progreso

Además de la documentación específica del plan, el equipo debe crear:

`racket/docs/progreso_fases_0_3.md`

## 9.1 Contenido obligatorio

### Identificación de la ejecución

- Fecha de inicio.
- Fecha de finalización.
- Rama.
- Commit inicial.
- Commit final.
- Versión de Racket.
- Sistema operativo usado.
- Comandos de prueba ejecutados.

### Registro por fase

Para cada fase:

- Objetivo.
- Estado inicial.
- Archivos revisados.
- Archivos creados.
- Archivos modificados.
- Pruebas ejecutadas.
- Resultados.
- Problemas encontrados.
- Decisiones tomadas.
- Riesgos pendientes.
- Estado final.

### Registro por persona

Para cada persona:

- Tareas asignadas.
- Evidencia encontrada.
- Trabajo completado.
- Trabajo que ya existía.
- Trabajo pendiente.
- Archivos relacionados.
- Pruebas asociadas.

### Decisiones modificadas

Si el equipo cambia una decisión previa, debe registrar:

- Decisión original.
- Nueva decisión.
- Razón.
- Impacto en módulos.
- Impacto en pruebas.
- Impacto en futuras fases.

### Limitaciones

El equipo debe declarar claramente:

- Qué no pudo verificar.
- Qué depende de una respuesta del profesor.
- Qué pruebas no pudo ejecutar.
- Qué herramientas o versiones faltaron.
- Qué supuestos se utilizaron.

---

# 10. Documento de defensa del código

Crear:

`racket/docs/guia_defensa.md`

Este archivo debe permitir que cualquier integrante explique el código.

## 10.1 Preguntas que debe responder

### Sobre el diseño

- ¿Qué es una combinación?
- ¿Por qué la combinación no puede ser vacía?
- ¿Por qué se eligieron contratos o Typed Racket?
- ¿Por qué los structs son inmutables?
- ¿Cómo se identifica un curso?
- ¿Por qué se conserva la carrera dentro del curso?

### Sobre la lectura

- ¿Qué ocurre si el JSON está corrupto?
- ¿Qué ocurre si falta un campo?
- ¿Qué ocurre si un curso no existe?
- ¿Qué ocurre si un grupo solicitado no existe?
- ¿Qué ocurre si el curso ya fue aprobado?
- ¿Cómo se detectan cursos duplicados?

### Sobre choques

- ¿Cómo se determina que dos bloques chocan?
- ¿Qué ocurre en el borde de dos bloques?
- ¿Por qué los grupos alternativos del mismo curso no se comparan?
- ¿Cómo se compara Racket con la bandera de C?
- ¿Qué sucede con un grupo sin horario?

### Sobre streams

- ¿Por qué el generador devuelve un stream?
- ¿Qué significa que sea perezoso?
- ¿Cómo se evita generar todas las combinaciones?
- ¿Qué se evalúa al solicitar solo el primer resultado?
- ¿Por qué `list->stream` no sería suficiente?

### Sobre polimorfismo

- ¿Qué tipo de elementos acepta el filtro?
- ¿Cómo se extrae el valor que se compara?
- ¿Por qué el filtro funciona con enteros, cadenas y combinaciones?
- ¿Qué parte del filtro no depende de un tipo específico?

### Sobre paradigma funcional

- ¿Dónde se evidencia la inmutabilidad?
- ¿Dónde se utiliza recursión?
- ¿Qué reemplaza a los ciclos con estado?
- ¿Qué reemplaza a las variables reasignables?
- ¿Cómo se acumulan selección y créditos?

## 10.2 Formato de explicación por módulo

Para cada módulo, documentar:

- Responsabilidad.
- Entradas.
- Salidas.
- Invariantes.
- Dependencias.
- Funciones principales.
- Casos de error.
- Pruebas.
- Posibles cambios en vivo durante la defensa.

Módulos mínimos:

- `types.rkt`
- `lectura.rkt`
- `catalogo.rkt`
- `preferencias.rkt`
- `universo.rkt`
- `choques.rkt`
- `generador.rkt`
- `filtros.rkt`

---

# 11. Auditoría final de las Fases 0–3

Antes de declarar terminado el trabajo, el equipo debe realizar estas búsquedas en `racket/src/`:

- `set!`
- `hash-set!`
- `vector-set!`
- `set-box!`
- `#:mutable`
- `list->stream`
- `Any`
- `cast`
- Variables globales reasignadas.
- Bucles con estado mutable.
- Generación eager de todas las combinaciones.

Cada coincidencia debe clasificarse como:

- Permitida.
- Incorrecta.
- Solo utilizada en pruebas.
- Pendiente de corregir.

La auditoría debe quedar documentada en:

`racket/docs/auditoria_fases_0_3.md`

---

# 12. Criterio global de aceptación

El equipo puede declarar completadas las Fases 0–3 únicamente cuando:

- Todas las decisiones de la Fase 0 están documentadas.
- Los formatos de entrada están documentados.
- Los datos de ambas carreras están verificados.
- El campo `career` se conserva en C y JSON.
- La regresión de C está documentada.
- Los tipos y contratos están documentados.
- Catálogo, preferencias y universo funcionan.
- Los errores de lectura están controlados.
- Choques funciona con los casos límite.
- El generador utiliza streams reales.
- El generador no materializa todas las combinaciones.
- La combinación vacía está excluida.
- El filtro es polimórfico y reutilizable.
- Existen pruebas con tres tipos diferentes.
- Todas las pruebas de las Fases 0–3 pasan.
- La auditoría no encuentra mutación indebida.
- Existe un registro completo del progreso.
- Existe una guía para la defensa.
- Se documentan claramente las limitaciones y decisiones provisionales.

---

# 13. Orden recomendado de ejecución

El equipo debe trabajar en este orden exacto:

1. Revisar rama y estado inicial.
2. Completar documentación de Fase 0.
3. Validar C, datos y regresión.
4. Completar documentación de Fase 1.
5. Revisar y estabilizar `types.rkt`.
6. Revisar catálogo y preferencias.
7. Revisar universo.
8. Completar pruebas de lectura.
9. Revisar choques.
10. Crear o completar el generador.
11. Crear pruebas manuales del generador.
12. Verificar pereza.
13. Crear el filtro polimórfico.
14. Probarlo con tres tipos.
15. Ejecutar auditoría funcional.
16. Crear registro de progreso.
17. Crear guía de defensa.
18. Ejecutar la lista final de aceptación.

No se debe avanzar directamente a la Fase 4 hasta que esta lista esté completa.
