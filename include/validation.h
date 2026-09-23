#ifndef VALIDATION_H
#define VALIDATION_H

#include "structs.h"
#include "constants.h"

#include <stddef.h>

/*
 * Fase 4: validación de matrícula.
 *
 * Política de correquisitos adoptada por el grupo:
 * un correquisito se considera cumplido si el curso ya está aprobado o si
 * el estudiante podría matricularlo en el mismo periodo (cumple sus propios
 * prerrequisitos y, recursivamente, sus propios correquisitos). Así, dos
 * cursos que se exigen mutuamente (un curso y su laboratorio) son
 * matriculables juntos. Que los correquisitos no aprobados se elijan
 * juntos en el horario lo debe hacer cumplir la etapa que arma las
 * combinaciones (Etapa 2), con la lista "corequisites" del archivo de salida.
 */

/* Devuelve 1 si todos los prerrequisitos del curso están en el historial.
 * Devuelve 0 si falta al menos uno, o si course/history es NULL. */
int validation_has_prerequisites(const Course *course,
                                 const StudentHistory *history);

/* Devuelve 1 si todos los correquisitos del curso están en el historial
 * (política estricta: solo cuenta lo ya aprobado).
 * Devuelve 0 si falta al menos uno, o si course/history es NULL. */
int validation_has_corequisites(const Course *course,
                                const StudentHistory *history);

/* Devuelve 1 si cada correquisito del curso está aprobado o se puede
 * matricular en el mismo periodo (política del proyecto, ver arriba).
 * Devuelve 0 si alguno no es alcanzable, o si algún puntero es NULL. */
int validation_corequisites_ok(const Catalog *catalog,
                               const Course *course,
                               const StudentHistory *history);

/* Recorre el catálogo y actualiza can_enroll para cada curso:
 * 1 si cumple prerrequisitos y correquisitos (según validation_corequisites_ok),
 * 0 en caso contrario.
 * Es idempotente: reinicia can_enroll en cada llamada.
 * Un curso aprobado tampoco es matriculable*/
void validation_mark_enrollable(Catalog *catalog,
                                const StudentHistory *history);

#endif