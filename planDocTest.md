**Instituto Tecnológico de Costa Rica**

Escuela de Ingeniería en Computadores · Paradigmas de Programación (CE1106)

Proyecto CEmestre · Etapa 2 (Paradigma Funcional, Racket)

**Plan de trabajo del equipo**

*Del 2 al 26 de octubre de 2026 · Equipo de 3 integrantes*

| Inicio de trabajo | Entrega oficial (último commit) | Meta interna del equipo |
| ----- | ----- | ----- |
| Viernes 2 de octubre | Viernes 30 de octubre, 9:30 a.m. | **Terminado el lunes 26 por la noche** |

Este plan traduce el enunciado de la Etapa 2 (con la Etapa 1 ya completada y todo el trabajo en el mismo repositorio) en fases de trabajo concretas para tres personas (Persona A, Persona B y Persona C). Cada fase indica qué hace cada quien, qué entrega y cuándo se considera cerrada. El reparto está pensado para que la carga sea equivalente (unas 52 horas por persona, aproximadamente 2 horas diarias), para que cada integrante lidere un área completa y para que todos revisen el código de los demás, ya que en la defensa cualquiera puede ser interrogado sobre cualquier parte. El margen de seguridad es de tres días completos más la mañana del 30\. Por ser un grupo de 3, se evalúa únicamente con la tabla de 100 puntos.

# **1\. Resumen de la etapa**

El objetivo es construir, en Racket y con paradigma funcional, el programa que toma el catálogo validado de la Etapa 1 y las preferencias del estudiante, genera las combinaciones válidas de horario (un grupo por curso, sin choques), las filtra por el rango de créditos y las exporta a un archivo que consumirá la Etapa 3 (Prolog).

* **Entradas:** catálogo exportado por el módulo de C (ahora con el campo carrera por curso y con 6 semestres por carrera) y un archivo de preferencias con cursos de interés (con más de un grupo cuando aplique), créditos mínimos y máximos.

* **Salida:** un archivo con, como mínimo, la lista de pares curso-grupo, los créditos totales y la carrera de origen de cada curso, por cada combinación. El formato lo elige y justifica el grupo, y funciona como contrato con Prolog.

* **Exigencias técnicas:** generación con streams, tipado explícito (Typed Racket o contratos), al menos una función con polimorfismo paramétrico reutilizable, y ninguna mutación (set\!, estructuras mutables ni variables reasignadas).

* **El módulo NO debe:** armar un horario final ni sugerir combinaciones, optimizar o aplicar preferencias, tener interfaz, ni aplicar restricciones distintas a los créditos.

* **Peso de la etapa:** 8% de la nota del curso. La defensa permite pedir cambios en vivo, y sin README, sin compilar o sin defensa la nota es 0\.

# **2\. Roles del equipo y equidad de la carga**

Cada persona lidera un área, pero ninguna es dueña exclusiva de un módulo: las pruebas y las revisiones cruzadas se reparten para que quien escribe un módulo no sea el único que lo conoce.

| Persona | Área que lidera y defiende | Criterios de rúbrica que lidera |
| :---- | :---- | :---- |
| **Persona A** | **Datos, tipos y salida.** Ampliación del módulo en C (campo carrera) y datos de Ingeniería en Computadores semestres 5 y 6, structs y tipos (types.rkt), detección de choques (choques.rkt) y exportador con su contrato de formato. | Co-lidera generación sin choques (20) y lidera tipos (8). |
| **Persona B** | **Entradas de prueba y motor de generación.** Formato de preferencias y catálogo sintético con resultados a mano, lector del catálogo, generador con streams y flujo principal (main.rkt). | Lidera generación sin choques (20) y streams (15). |
| **Persona C** | **Datos de la segunda carrera, filtros y calidad.** Datos de la Licenciatura semestres 5 y 6 y generación del catálogo oficial, lector de preferencias y universo, filtro polimórfico, filtro de créditos, oráculo de pruebas y auditoría de mutación y tipos. | Lidera polimorfismo (8), filtrado por créditos (7) y principios funcionales (12). |

**Carga estimada por fase (horas aproximadas por persona):**

| Fase | Persona A | Persona B | Persona C |
| :---- | :---- | :---- | :---- |
| Fase 0 | 4 | 4 | 4 |
| Fase 1 | 8 | 7 | 8 |
| Fase 2 | 7 | 8 | 8 |
| Fase 3 | 9 | 11 | 9 |
| Fase 4 | 9 | 7 | 8 |
| Fase 5 | 6 | 7 | 6 |
| Fase 6 | 5 | 4 | 5 |
| Fase 7 | 4 | 4 | 4 |
| **Total aprox.** | **52 h** | **52 h** | **52 h** |

La Persona B concentra más horas en la Fase 3 porque el generador es el módulo más delicado, y lo compensa con menos carga en las Fases 4 y 6\. Las Personas A y C asumen la recolección de datos de las dos carreras (Fase 1), mientras B prepara las entradas de prueba que desbloquean todo el desarrollo.

# **3\. Decisiones que se cierran en la Fase 0**

Estas decisiones condicionan todo el diseño. Deben quedar escritas en racket/docs/decisiones.md el domingo 4, porque varias terminan en el README (2.2.1 y 2.2.3). Las propuestas son un punto de partida para la reunión, no una imposición.

| Id | Decisión | Propuesta y razón |
| :---- | :---- | :---- |
| D1 | Qué es una combinación | El enunciado pide “un grupo por cada curso habilitado” y también filtrar por créditos. Si la combinación debiera incluir todos los cursos, el total de créditos sería fijo y el filtro no tendría sentido. **Propuesta:** el universo son los cursos de la lista de interés que están habilitados según C. Una combinación es un subconjunto no vacío de ese universo, con un grupo de interés por curso y sin choques entre los grupos. **Confirmar con el profesor** y dejar el diseño parametrizable por si responde otra cosa. |
| D2 | Typed Racket o contratos | El enunciado acepta ambos. **Propuesta:** Typed Racket en todos los módulos. Si el prototipo de la Fase 0 muestra fricción con los streams, usar contratos (\`-\>\`, \`struct/c\`) en las fronteras de cada módulo. Decidir una sola vez y aplicarlo igual en todo el código. |
| D3 | Formato de salida | Candidatos: JSON, JSON Lines, CSV, hechos de Prolog. **Propuesta de partida:** JSON Lines (una combinación por línea), porque permite escribir de forma incremental mientras se consume el stream y se lee línea por línea desde Prolog. La decisión se toma con la tabla comparativa de C y debe quedar ligada a una decisión de diseño real (README 2.2.3). |
| D4 | Campos adicionales por combinación | Obligatorios: pares curso-grupo, créditos totales y carrera de cada curso. **Propuesta de extras (a justificar):** identificador de combinación, cantidad de cursos, y por cada curso nombre, créditos y horario del grupo, pues Prolog necesitará créditos y compatibilidades sin volver a abrir el catálogo. |
| D5 | Choque en el borde | Si un bloque termina a la misma hora en que empieza otro, ¿chocan? **Propuesta:** adoptar exactamente el criterio que ya usa el módulo de C (verificarlo en el código de la Etapa 1), para que ambas etapas sean coherentes. |
| D6 | Fuente de los choques | El enunciado de la Etapa 1 solo exigía un indicador de choque por curso (sí o no), no con quién choca. Por eso lo más probable es que Racket deba calcular los choques entre pares a partir de los horarios (choques.rkt) y lo contraste con la bandera de C en pruebas. Si el módulo de C ya exporta los pares en conflicto, se usa ese dato. La auditoría de la Fase 0 confirma cuál es el caso y en ningún caso se altera la lógica de C. |
| D7 | Organización del repositorio | Repositorio único para todas las etapas. El código de C se sigue desarrollando donde ya está, en una rama por tarea, y el de Racket vive en la carpeta racket/ (con src/, tests/ y docs/). El catálogo generado por C se guarda en data/ y Racket lo lee desde ahí, sin copias duplicadas. |

# **4\. Cronograma general**

| Fase | Fechas 2026 | Días | Entregable principal |
| :---- | :---- | :---- | :---- |
| Fase 0 · Arranque, decisiones y contrato | Vie 2 – Dom 4 oct | 3 | Repo reorganizado \+ decisiones D1 a D7 \+ prototipos |
| Fase 1 · Ampliación de C y datos de 6 semestres | Lun 5 – Jue 8 oct | 4 | Catálogo oficial con campo carrera \+ entradas de prueba |
| Fase 2 · Tipos y lectura de entradas | Vie 9 – Lun 12 oct | 4 | types.rkt, catalogo.rkt, preferencias.rkt, universo.rkt |
| Fase 3 · Choques, generación con streams, filtro polimórfico | Mar 13 – Sáb 17 oct | 5 | choques.rkt, generador.rkt, filtros.rkt probados |
| Fase 4 · Créditos, exportación e integración | Dom 18 – Mié 21 oct | 4 | Programa integrado que genera el archivo de salida |
| Fase 5 · Pruebas integrales y auditoría | Jue 22 – Vie 23 oct | 2 | Salida validada \+ auditoría de mutación y tipos |
| Fase 6 · README | Sáb 24 – Dom 25 oct | 2 | README completo (2.1, 2.2.1, 2.2.2, 2.2.3, 2.3) |
| Fase 7 · Repaso y defensa | Lun 26 oct | 1 | Simulacro \+ checklist \+ último commit esa noche |
| **Margen de seguridad** | Mar 27 – Jue 29 oct | 3 | Solo imprevistos, ensayo y entrega del enlace. Sin funcionalidades nuevas. |
| **Entrega oficial** | **Vie 30 oct, 9:30 a.m.** | — | Fecha máxima de último commit (el trabajo ya estará cerrado el 26). |

# **5\. Desglose detallado por fase**

Los colores identifican al responsable: azul para la Persona A, verde para la Persona B y naranja para la Persona C. Las filas grises corresponden a tareas de todo el equipo.

## **FASE 0 · Arranque, decisiones y contrato**

**Fechas:** Viernes 2 – Domingo 4 de octubre     **Duración:** 3 días

**Objetivo:** Preparar el repositorio existente (el mismo de la Etapa 1\) para recibir el código de Racket, cerrar las decisiones de diseño que condicionan todo lo demás (sección 3\) y validar con pequeños prototipos que streams, tipado y ausencia de mutación son viables.

| Responsable | Tareas | Entregable |
| :---- | :---- | :---- |
| **Todos** | Reunión de arranque (1.5 h): leer juntos el enunciado completo y cerrar las decisiones D1 a D7. Acordar tablero de tareas (una tarjeta por tarea de este plan) y dos checkpoints semanales de 20 minutos (por ejemplo martes y viernes). Confirmar que los tres tienen la misma versión de Racket instalada y que el repositorio clona y corre en las tres máquinas. | Decisiones D1 a D7 anotadas en racket/docs/decisiones.md. |
| **Persona A** | Reorganiza el repositorio existente de la Etapa 1 (no se crea uno nuevo): etiqueta el estado ya entregado como etapa1-entregada, agrega la carpeta racket/ con src/, tests/ y docs/, actualiza .gitignore para los archivos compilados de Racket y confirma la convención de una rama por tarea con pull request revisado por otra persona. Audita el archivo de salida real de la Etapa 1: campos, tipos, separadores y, en especial, cómo viene el choque (booleano o lista de grupos). Lo documenta en racket/docs/entrada\_catalogo.md. Agrega al README existente una sección “Etapa 2” con los encabezados 2.1, 2.2.1, 2.2.2, 2.2.3 y 2.3 (o un racket/README.md enlazado desde el principal). | Repositorio reorganizado \+ racket/docs/entrada\_catalogo.md. |
| **Persona B** | Prototipo de streams (30 a 40 líneas): genera combinaciones de un grupo por curso de forma perezosa y comprueba que pedir solo el primer elemento no evalúa el resto. Verifica cómo se tipan los streams en Typed Racket y si hay fricción con la librería de streams. Escribe una nota con la recomendación para D2 (Typed Racket o contratos). Confirma que el prototipo no usa set\!, estructuras mutables ni variables reasignadas. | Rama spike/streams \+ nota de recomendación D2. |
| **Persona C** | Compara los formatos de salida candidatos (JSON, JSON Lines, CSV, hechos de Prolog) con criterios escritos: escritura incremental desde un stream, facilidad de lectura en Prolog, legibilidad y tamaño. Prototipo de una función con polimorfismo paramétrico ((All (A) ...)) para confirmar que compila y se usa con dos tipos distintos. Redacta y envía al profesor la consulta sobre D1 (qué es exactamente una combinación). | Tabla comparativa de formatos (D3) \+ consulta enviada. |

**✔ Criterio de cierre:** Repositorio reorganizado, D1 a D7 decididas por escrito (D1 puede quedar “provisional” hasta que responda el profesor) y los tres prototipos corriendo.

## **FASE 1 · Ampliación del módulo de la Etapa 1 y datos de 6 semestres**

**Fechas:** Lunes 5 – Jueves 8 de octubre     **Duración:** 4 días

**Objetivo:** Entregar el catálogo oficial de 6 semestres por carrera con el campo carrera por curso, y dejar listas las entradas de prueba (preferencias y catálogo sintético) para desarrollar sin esperar a los datos reales.

| Responsable | Tareas | Entregable |
| :---- | :---- | :---- |
| **Persona A** | Agrega el campo carrera por curso al exportador del módulo en C, sin modificar la lógica de choques ni de requisitos. Prueba de regresión: la salida debe ser idéntica a la del estado etiquetado etapa1-entregada, salvo por el campo nuevo (comparación con diff). Se trabaja en una rama del mismo repositorio. Recolecta y carga los semestres 5 y 6 de Ingeniería en Computadores desde la Guía de Horarios: código, nombre, créditos, grupos, horarios, requisitos y correquisitos. Entrega el cambio en C y los datos a más tardar el miércoles 7 al mediodía, porque C genera el catálogo final con ellos. | Módulo C actualizado (rama del mismo repositorio) \+ datos IC semestres 5 y 6\. |
| **Persona B** | Define y documenta el formato del archivo de preferencias: lista de cursos de interés con sus grupos (más de un grupo por curso cuando aplique), créditos mínimos y créditos máximos (racket/docs/preferencias.md). Crea cuatro archivos de preferencias de prueba: varios grupos por curso, un curso no habilitado, rango imposible y rango que abarca todo. Construye un catálogo sintético pequeño (6 a 8 cursos) con choques conocidos y calcula a mano las combinaciones esperadas. Será la base de las pruebas de generación. | racket/docs/preferencias.md \+ 4 archivos de preferencias \+ catálogo sintético con resultados esperados a mano. |
| **Persona C** | Recolecta y carga los semestres 5 y 6 de la Licenciatura elegida en la Etapa 1\. Verifica que los requisitos y correquisitos que apuntan a semestres 1 a 4 existan en el dataset. Cuando A entregue, ejecuta el módulo en C con las dos carreras completas (6 semestres) y genera el catálogo oficial de esta etapa (data/catalogo\_6sem). Revisa que el catálogo generado conserve exactamente los mismos resultados de choques y requisitos que la Etapa 1 para los semestres 1 a 4\. | Datos de la Licenciatura semestres 5 y 6 \+ data/catalogo\_6sem generado. |
| **Todos** | Revisión cruzada de datos: A revisa 10 filas al azar del dataset de C, C revisa 10 de A y B revisa 10 de cada carrera. Cualquier error se corrige antes de cerrar la fase. Registrar en una nota compartida cualquier caso raro que aparezca (insumo para el README 2.2.2). | Datasets verificados. |

**✔ Criterio de cierre:** Existe un catálogo oficial de 6 semestres por carrera con el campo carrera, la regresión de C pasa y hay entradas de prueba listas.

## **FASE 2 · Tipos y lectura de entradas en Racket**

**Fechas:** Viernes 9 – Lunes 12 de octubre     **Duración:** 4 días

**Objetivo:** Tener el catálogo y las preferencias cargados en memoria con tipos explícitos y errores controlados, y obtener el universo de cursos sobre el cual se generarán combinaciones.

| Responsable | Tareas | Entregable |
| :---- | :---- | :---- |
| **Persona A** | Escribe racket/src/types.rkt: structs inmutables y tipos explícitos para Curso, Grupo, Horario/Bloque, Carrera, Catalogo, Preferencias, ParCursoGrupo y Combinacion (Typed Racket o contratos según D2). Publica el archivo el sábado 10 al mediodía, porque B y C dependen de él. Mientras tanto, B y C trabajan sobre las firmas acordadas en la Fase 0\. Documenta cada tipo en racket/docs/estructuras.md (base del README 2.3). | racket/src/types.rkt compilando \+ racket/docs/estructuras.md. |
| **Persona B** | Escribe racket/src/catalogo.rkt: lee el archivo producido por C y construye las structs. Valida campos faltantes, tipos incorrectos y carrera inválida con errores controlados (el programa nunca se cae por un dato mal formado). Implementa la función que obtiene los cursos habilitados (los que el módulo C marcó como matriculables). Pruebas con rackunit: archivo válido, una fila corrupta, archivo vacío y archivo inexistente. | racket/src/catalogo.rkt \+ racket/tests/test-catalogo.rkt. |
| **Persona C** | Escribe racket/src/preferencias.rkt: lee el archivo de preferencias y valida (mínimo menor o igual al máximo, créditos no negativos, formato). Escribe racket/src/universo.rkt: cruza preferencias con catálogo y devuelve, por cada curso de interés habilitado, sus grupos de interés que sí existen. Reporta sin romper el programa los cursos no habilitados, los grupos inexistentes y los cursos repetidos. Pruebas con rackunit con los cuatro archivos de preferencias de la Fase 1\. | racket/src/preferencias.rkt \+ racket/src/universo.rkt \+ tests. |
| **Todos** | Revisión cruzada de 30 minutos: cada persona revisa el módulo de otra. Verificar que \`raco test\` corre completo en las tres máquinas. | Pruebas de lectura en verde. |

**✔ Criterio de cierre:** Con el catálogo oficial y cada archivo de preferencias de prueba se obtiene el universo de trabajo correcto, con errores controlados y todo tipado.

## **FASE 3 · Núcleo: choques, generación con streams y filtro polimórfico**

**Fechas:** Martes 13 – Sábado 17 de octubre     **Duración:** 5 días

**Objetivo:** Construir los tres componentes que concentran la mayor parte de la rúbrica (generación sin choques, streams, principios funcionales y polimorfismo paramétrico), cada uno probado por separado.

| Responsable | Tareas | Entregable |
| :---- | :---- | :---- |
| **Persona A** | Escribe racket/src/choques.rkt con funciones puras: bloques que chocan (mismo día e intervalos que se traslapan, siguiendo D5), grupos que chocan (varios bloques por grupo) y compatibilidad de un grupo con la selección ya acumulada. Prueba de consistencia: sobre el catálogo real, el resultado de estas funciones debe coincidir con la bandera de choque calculada por C (D6). Casos de prueba: horario idéntico, traslape parcial, borde (fin igual a inicio), días distintos, grupos con varios bloques. | racket/src/choques.rkt \+ racket/tests/test-choques.rkt. |
| **Persona B** | Escribe racket/src/generador.rkt: generación recursiva y perezosa de combinaciones. Para cada curso se decide omitirlo o elegir uno de sus grupos compatibles con lo ya elegido. Los créditos se acumulan como parámetro de la recursión (sin mutación). Devuelve un stream de Combinacion. Está prohibido construir la lista completa y envolverla al final (list-\>stream) porque el enunciado lo excluye explícitamente. Excluye la combinación vacía. Pruebas con el catálogo sintético (resultado contra lo calculado a mano) y prueba de pereza: con un catálogo enorme, pedir el primer elemento debe ser inmediato. | racket/src/generador.rkt \+ racket/tests/test-generador.rkt. |
| **Persona C** | Escribe racket/src/filtros.rkt: función o funciones con polimorfismo paramétrico ((All (A) ...)), por ejemplo filtrar un stream de cualquier tipo A con un criterio extraíble de A y un rango, de modo que sirvan para más de un tipo y más de un criterio, sin una función por caso. Pruebas que demuestren la reutilización con al menos tres tipos de elemento (enteros, cadenas y Combinacion). Redacta el plan de pruebas del generador de B (lista de casos) y lo ejecuta el viernes 16 y sábado 17 sobre el código de B. | racket/src/filtros.rkt \+ racket/tests/test-filtros.rkt \+ plan de pruebas del generador. |
| **Todos** | Revisión cruzada de 30 minutos del generador: lo revisa alguien que no lo escribió, contra el plan de pruebas de C y buscando cualquier rastro de mutación. | Generador aprobado por revisión. |

**✔ Criterio de cierre:** Choques, generador y filtro funcionan y pasan sus pruebas por separado. Es la fase con más riesgo, por eso es la más larga y el sábado 17 queda como colchón interno.

## **FASE 4 · Filtro de créditos, exportación e integración**

**Fechas:** Domingo 18 – Miércoles 21 de octubre     **Duración:** 4 días

**Objetivo:** Unir todos los módulos en un solo programa que lea las entradas, genere, filtre por créditos y escriba el archivo de salida.

| Responsable | Tareas | Entregable |
| :---- | :---- | :---- |
| **Persona A** | Escribe racket/src/exportador.rkt: serializa cada combinación según D3 y D4 y la escribe consumiendo el stream de a un elemento, sin forzarlo completo. Incluye los tres campos obligatorios (pares curso-grupo, créditos totales y carrera de origen de cada curso) más los extras acordados en D4, cada uno con su justificación. Escribe racket/docs/formato\_salida.md: el contrato para Prolog con un ejemplo de registro y el tipo de cada campo. Prueba de ida y vuelta (escribir y volver a leer). | racket/src/exportador.rkt \+ racket/docs/formato\_salida.md \+ tests. |
| **Persona B** | Escribe racket/src/main.rkt: flujo completo (catálogo, preferencias, universo, generación, filtro, exportación) con rutas de archivo recibidas por parámetro y centralizadas en un módulo de constantes. Mensajes de error claros y código de salida distinto de cero ante fallos de lectura. Instrucciones de ejecución (\`racket racket/src/main.rkt ...\`) probadas desde un clon limpio. | racket/src/main.rkt \+ constantes \+ instrucciones de ejecución. |
| **Persona C** | Instancia el filtro polimórfico para créditos: rango inclusivo con el mínimo y el máximo de las preferencias, tomando los créditos totales de la Combinacion. Prueba contra un oráculo independiente: en el catálogo sintético, calcula con listas simples (solo en el código de pruebas) todas las combinaciones válidas y compara con el resultado del stream. Segunda instancia del filtro solo en pruebas (por ejemplo por cantidad de cursos) para evidenciar la reutilización. No entra al programa principal, porque el enunciado prohíbe otras restricciones. | Filtro de créditos integrado \+ pruebas con oráculo. |
| **Todos** | Primera ejecución de punta a punta con los datos reales de ambas carreras el martes 20\. Anotar fallos y repartirlos el mismo día. Revisión cruzada de 30 minutos entre los tres antes de cerrar la fase. | Programa integrado que genera el archivo de salida. |

**✔ Criterio de cierre:** Con las preferencias de prueba se produce un archivo de salida completo, en el formato acordado, sin cargar todas las combinaciones en memoria.

## **FASE 5 · Pruebas integrales y auditoría de requisitos no funcionales**

**Fechas:** Jueves 22 – Viernes 23 de octubre     **Duración:** 2 días

**Objetivo:** Demostrar con evidencia que se cumple todo lo que exige el enunciado, en especial lo que se castiga con cero: compilar, no mutar y respetar el paradigma.

| Responsable | Tareas | Entregable |
| :---- | :---- | :---- |
| **Persona A** | Valida la salida de punta a punta con los datos reales de 6 semestres de ambas carreras mediante un script de pruebas: campos obligatorios presentes y bien tipados, créditos totales iguales a la suma de los cursos, créditos dentro del rango, ningún choque dentro de una combinación y carrera consistente con el catálogo. Lee el archivo con un lector independiente, simulando a la etapa de Prolog (idealmente con SWI-Prolog si está disponible). | racket/tests/validar-salida \+ reporte. |
| **Persona B** | Pruebas de estrés: catálogo grande con muchos grupos, un solo curso con un solo grupo, rango sin resultados, mínimo igual a máximo, rango que cubre todo. Mide el tiempo hasta la primera combinación frente al tiempo total y confirma que la memoria se mantiene estable. Define qué se escribe cuando no hay combinaciones (archivo válido y vacío, por ejemplo) y lo documenta. | Reporte de estrés \+ casos límite anotados. |
| **Persona C** | Auditoría de mutación: búsqueda de set\!, hash-set\!, vector-set\!, set-box\!, structs mutables y variables reasignadas en todo src/. Documenta el resultado. Auditoría de tipos y diseño: módulos tipados sin escapes innecesarios (cast, Any), sin list-\>stream al final, recursión en lugar de ciclos con estado. Compilación limpia de Racket (\`raco make\`) y \`raco test\` completos en una máquina distinta, y verificación de que el módulo en C sigue compilando tras los cambios de la Fase 1\. | racket/docs/auditoria.md con resultados. |
| **Todos** | Elegir el caso límite real más interesante de los registrados (insumo del README 2.2.2) y corregir cualquier hallazgo de las auditorías. | Caso límite seleccionado. |

**✔ Criterio de cierre:** Salida validada automáticamente, auditorías limpias y programa probado con datos reales sin errores.

## **FASE 6 · README y documentación**

**Fechas:** Sábado 24 – Domingo 25 de octubre     **Duración:** 2 días

**Objetivo:** Redactar el README exigido, con evidencia concreta del proyecto real y no genérica. Cada persona ya tiene borradores desde su fase correspondiente.

| Responsable | Tareas | Entregable |
| :---- | :---- | :---- |
| **Persona A** | 2.1 Arquitectura del proyecto: diagrama de módulos (salida de C, catalogo, universo, generador, filtros, exportador, archivo para Prolog) y flujo de datos. 2.3 Estructuras de datos desarrolladas: structs y tipos, apoyándose en racket/docs/estructuras.md. | Secciones 2.1 y 2.3. |
| **Persona B** | 2.2.1 Justificación de decisiones propias y específicas (D1, D2, D5, D6, uso de streams y generación recursiva) con ejemplos de los planes de estudio reales. 2.2.2 El caso límite real encontrado y cómo se resolvió, con el ejemplo concreto. | Secciones 2.2.1 y 2.2.2. |
| **Persona C** | 2.2.3 Justificación del formato de salida ligada a una decisión de diseño real (escritura incremental desde el stream, lectura en Prolog, campos extra). Instrucciones de compilación y ejecución, estructura del repositorio y cómo correr las pruebas. | Sección 2.2.3 \+ instrucciones de uso. |
| **Todos** | Revisión conjunta final del README (45 minutos): claridad, ortografía, coherencia con el código y que cada persona pueda explicar cualquier sección. | README completo en el repositorio. |

**✔ Criterio de cierre:** README completo con las cinco secciones exigidas (2.1, 2.2.1, 2.2.2, 2.2.3 y 2.3), subido al repositorio. Sin documentación la nota es 0\.

## **FASE 7 · Repaso general, simulacro de defensa y cierre**

**Fechas:** Lunes 26 de octubre (último commit esa noche)     **Duración:** 1 día

**Objetivo:** Llegar a la defensa con el código dominado por los tres y todos los aspectos operativos verificados, dejando tres días completos de margen antes del límite.

| Responsable | Tareas | Entregable |
| :---- | :---- | :---- |
| **Todos** | Cada integrante repasa todo el código, no solo su módulo. Simulacro de defensa de 40 minutos con modificaciones en vivo que cada persona hace sobre un módulo que no escribió. Ejemplos: cambiar el criterio del filtro, cambiar el formato de salida a CSV, cambiar la regla del borde de un choque, agregar un campo a la salida, contar las combinaciones sin exportarlas. | Simulacro realizado. |
| **Persona A** | Verifica el checklist de la sección 9 en lo relacionado con datos, formato de salida y el cumplimiento de “el módulo NO debe…”. | Checklist parte A firmado. |
| **Persona B** | Clona el repositorio en limpio en otra máquina, compila el módulo en C y el de Racket y ejecuta ambos con los datos reales. Confirma con el profesor el equipo para la revisión (aspecto operativo 7.3) y deja claro quién lo lleva (aspecto 9). | Compilación limpia confirmada \+ equipo confirmado. |
| **Persona C** | Revisa el repositorio: commits significativos y progresivos de los tres, ramas, pull requests, etiquetas. Prepara el enlace del repositorio y lo entrega por TEC-Digital el martes 27 (no se espera al último día). | Repositorio ordenado \+ enlace listo. |

**✔ Criterio de cierre:** Último commit el lunes 26 por la noche. Del martes 27 al jueves 29 solo se usa el margen para imprevistos y repaso, sin funcionalidades nuevas. El límite oficial es el viernes 30 a las 9:30 a.m.

# **6\. Rúbrica oficial y responsable de cada criterio**

| Criterio de evaluación | Peso | Fase(s) | Responsable |
| :---- | :---- | :---- | :---- |
| Generación correcta de combinaciones sin choques | 20 | Fase 3 y 4 | B (generador) y A (choques) |
| Uso de streams | 15 | Fase 0 (prototipo), 3 y 4 | B |
| Principios de diseño funcional (inmutabilidad, recursión) | 12 | Todas; auditoría en Fase 5 | C audita, todos aplican |
| Uso de tipos (Typed Racket / contratos) | 8 | Fase 0 (D2) y 2 | A |
| Función con polimorfismo paramétrico | 8 | Fase 3 | C |
| Filtrado correcto por rango de créditos | 7 | Fase 4 | C |
| README (documentación) | 15 | Fase 6 (borradores desde Fase 2\) | Todos |
| Manejo del repositorio | 15 | Todas (transversal) | Todos; revisa C en Fase 7 |

# **7\. Matriz de cumplimiento del enunciado**

Cada requisito del enunciado tiene un lugar donde se construye y una forma concreta de verificarlo, para que nada quede sin cubrir.

| Requisito del enunciado | Dónde se cumple | Cómo se verifica |
| :---- | :---- | :---- |
| RF1. Leer el catálogo de C | catalogo.rkt (Fase 2\) | Pruebas con archivo válido, corrupto, vacío e inexistente |
| RF2. Generar con streams, no listas completas | generador.rkt (Fase 3\) | Prueba de pereza \+ auditoría sin list-\>stream final (Fase 5\) |
| RF3. Filtrar por rango de créditos | filtros.rkt y filtro de créditos (Fases 3 y 4\) | Límites inclusivos, mínimo igual a máximo, rango vacío, oráculo |
| RF4. Tipos explícitos | types.rkt y todos los módulos (Fase 2 en adelante) | Compilación tipada; auditoría de Any y cast |
| RF5. Polimorfismo paramétrico reutilizable | filtros.rkt (Fase 3\) | Pruebas con al menos tres tipos de elemento y dos criterios |
| RF6. Exportar al formato acordado | exportador.rkt (Fase 4\) | Script de validación de la salida (Fase 5\) |
| Entrada: campo carrera por curso, sin tocar lógica de C | Fase 1 (módulo C) | Prueba de regresión con diff contra la etiqueta etapa1-entregada |
| Entrada: 6 semestres por carrera (antes 4\) | Fase 1 (datos) | Revisión cruzada fila por fila (Fases 1 y 5\) |
| Entrada: preferencias con más de un grupo por curso | Fase 1 (B) y Fase 2 (C) | Archivos de prueba con varios grupos por curso |
| Salida mínima: pares curso-grupo, créditos totales, carrera por curso | Fase 4 (A) | Script de validación de la salida |
| Formato y campos extra justificados | Fase 0 (D3, D4) y README 2.2.3 | Revisión del README en Fase 6 |
| El módulo NO arma horario final, NO optimiza, NO tiene interfaz, NO aplica otras restricciones | Diseño de main.rkt (Fase 4\) | Checklist de Fase 7; el segundo filtro existe solo en pruebas |
| Sin mutación (set\!, mutables, variables reasignadas) | Todas las fases | Auditoría de Fase 5 y regla de revisión en cada pull request |
| README 2.1, 2.2.1, 2.2.2, 2.2.3 y 2.3 | Fase 6 | Revisión conjunta; sin README la nota es 0 |
| Repositorio con commits progresivos de los tres | Transversal | Revisión de historial en Fase 7 |
| Defensa con modificaciones en vivo; todos conocen todo | Fase 7 | Simulacro con intercambio de módulos |
| Compila y funciona (si no compila, nota 0\) | Fases 4, 5 y 7 | Clon limpio en otra máquina antes del cierre |
| Grupo de 3: se evalúa sobre 100 puntos | Todo el plan | La optimización por poda temprana no es obligatoria (solo para grupos de 4\) |

# **8\. Convenciones del repositorio**

El manejo del repositorio vale 15 puntos por sí solo y se evalúa el trabajo progresivo de los tres.

* **Repositorio único:** todas las etapas viven en el mismo repositorio. El código de la Etapa 1 se mantiene donde está y el de Racket va en racket/ (src/ con types, catalogo, preferencias, universo, choques, generador, filtros, exportador, main y constantes; tests/ y docs/). Los datos compartidos quedan en data/ y el README principal incorpora la sección de la Etapa 2\.

* **Ramas:** una por tarea con el formato feat/persona-tema (por ejemplo feat/b-generador). Main protegida, y todo cambio entra por pull request revisado por otra persona.

* **Commits:** pequeños y frecuentes, en español, con formato tipo: descripción (por ejemplo “feat: agrega filtro polimórfico por rango”). Cada persona debería hacer commits todas las semanas, no solo al cierre de fase.

* **Etiquetas:** etapa1-entregada (estado ya entregado de la Etapa 1\) y, para esta etapa, e2-v0.1-datos, e2-v0.2-lectura, e2-v0.3-nucleo, e2-v0.4-integracion y e2-v1.0-entrega.

* **Regla de revisión:** antes de aprobar un pull request se busca set\!, hash-set\!, vector-set\! y set-box\!, y se confirma que los tipos o contratos estén presentes.

# **9\. Checklist final antes de entregar**

Basado en los aspectos operativos del enunciado. Se revisa uno por uno el lunes 26 antes del último commit.

* El código está en Racket y en paradigma funcional (de lo contrario la nota es 0).

* El código compila y corre sin errores en una máquina limpia (de lo contrario la nota es 0).

* No hay set\!, estructuras mutables ni variables globales reasignadas en ningún archivo.

* Las combinaciones se generan con streams y no se envuelve una lista completa al final.

* Hay tipos explícitos (Typed Racket o contratos) y al menos una función con polimorfismo paramétrico reutilizada.

* El filtro por créditos usa el rango de las preferencias (inclusivo) y es la única restricción aplicada.

* El archivo de salida trae pares curso-grupo, créditos totales y carrera de cada curso, y los campos extra están justificados.

* El catálogo tiene 6 semestres por carrera y el campo carrera por curso; la lógica de C no se modificó.

* El archivo de preferencias incluye más de un grupo por curso cuando aplica.

* El README está subido con 2.1, 2.2.1, 2.2.2, 2.2.3 y 2.3 (sin README la nota es 0).

* El repositorio muestra commits significativos de los tres integrantes, con ramas y pull requests.

* El enlace del repositorio está entregado por TEC-Digital.

* Los tres integrantes conocen todo el código y pueden modificarlo en vivo durante la defensa.

* Se confirmó con el profesor el equipo para la revisión y alguien del grupo lo lleva.

* Último commit antes del viernes 30 de octubre a las 9:30 a.m. (meta del equipo: lunes 26 por la noche).

# **10\. Riesgos y recomendaciones**

| Riesgo | Mitigación |
| :---- | :---- |
| Los streams o el tipado dan problemas en Typed Racket | El prototipo de la Fase 0 lo detecta temprano. Si hay bloqueo, se usan contratos para las fronteras (permitido por el enunciado) y se decide el mismo día. |
| types.rkt se atrasa y bloquea a B y C | A lo publica el sábado 10 al mediodía. Antes de eso, B y C trabajan con las firmas acordadas en la Fase 0\. |
| Los datos de semestres 5 y 6 se atrasan | El desarrollo de las Fases 2 a 4 usa el catálogo sintético de la Fase 1, por lo que nadie queda bloqueado. Los datos reales solo se necesitan para la integración del martes 20\. |
| El profesor responde D1 con otra interpretación | El universo y la generación están separados del filtro. Cambiar la regla de qué es una combinación toca un solo módulo (generador) y el simulacro de la Fase 7 ya practica ese tipo de cambio. |
| Un cambio en el código de C rompe la Etapa 1 ya entregada | La etiqueta etapa1-entregada, la prueba de regresión con diff de la Fase 1, el trabajo en ramas con pull request y la verificación de compilación de C en las Fases 5 y 7\. |
| Se cuela mutación sin querer | Regla en cada pull request: búsqueda de set\! y compañía antes de aprobar, más la auditoría formal de la Fase 5\. |
| Una fase se atrasa por otras evaluaciones | El colchón del sábado 17, el margen del 27 al 29 y las dos jornadas de Fase 5 absorben retrasos. Lo que nunca se sacrifica es el checklist operativo, porque compilar, documentar y presentarse a la defensa valen la nota completa. |
| Alguien no domina el código ajeno | Cada fase incluye revisión cruzada y la Fase 7 un simulacro con intercambio de módulos. Las revisiones de pull request las hace siempre otra persona. |

**Prioridad si algo se atrasa:** primero se sacrifica el colchón (sábado 17 y margen del 27 al 29), nunca el checklist operativo.