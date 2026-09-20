#ifndef VALIDATION_H
#define VALIDATION_H

#include "structs.h"
#include "constants.h"

#include <stddef.h>

/*
 * Fase 4: validación de matrícula.
 *
 * Política de correquisitos adoptada por el grupo:
 * un correquisito se considera cumplido únicamente si el curso ya
 * aparece en el historial de cursos aprobados. No se simula matrícula
 * simultánea en el mismo semestre; esa decisión se documenta en el README.
 */

/* Devuelve 1 si todos los prerrequisitos del curso están en el historial.
 * Devuelve 0 si falta al menos uno, o si course/history es NULL. */
int validation_has_prerequisites(const Course *course,
                                 const StudentHistory *history);

/* Devuelve 1 si todos los correquisitos del curso están en el historial.
 * Devuelve 0 si falta al menos uno, o si course/history es NULL. */
int validation_has_corequisites(const Course *course,
                                const StudentHistory *history);

/* Recorre el catálogo y actualiza can_enroll para cada curso:
 * 1 si cumple prerrequisitos y correquisitos, 0 en caso contrario.
 * Es idempotente: reinicia can_enroll en cada llamada. 
 * Un curso aprobado tampoco es matriculable*/
void validation_mark_enrollable(Catalog *catalog,
                                const StudentHistory *history);

#endif