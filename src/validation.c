#include "../include/validation.h"
#include "../include/history.h"
#include "../include/catalog.h"

/* -------------------------------------------------------------------------
 * Decide si el estudiante puede matricular cada curso segun su historial.
 * La politica de correquisitos esta explicada en validation.h: un
 * correquisito se cumple si ya esta aprobado o si se puede matricular en
 * el mismo periodo.
 * ------------------------------------------------------------------------- */

/* Prerrequisitos: TODOS tienen que estar aprobados.
 * Un curso sin prerrequisitos no entra al for y devuelve 1. */
int validation_has_prerequisites(const Course *course,
                                 const StudentHistory *history) {
    if (course == NULL || history == NULL) {
        return 0;
    }

    for (int i = 0; i < course->prerequisite_count; i++) {
        if (!history_has_course(history, course->prerequisites[i])) {
            return 0;   /* basta con que falte uno */
        }
    }

    return 1;
}

/* Version estricta de correquisitos: solo cuenta lo ya aprobado.
 * No es la que se usa para calcular can_enroll (esa es
 * validation_corequisites_ok), pero se deja disponible en la interfaz. */
int validation_has_corequisites(const Course *course,
                                const StudentHistory *history) {
    if (course == NULL || history == NULL) {
        return 0;
    }

    for (int i = 0; i < course->corequisite_count; i++) {
        if (!history_has_course(history, course->corequisites[i])) {
            return 0;
        }
    }

    return 1;
}

/* 1 si el curso 'idx' ya esta aprobado o se puede matricular en este mismo periodo.
 * 'visiting' marca los cursos de la cadena actual: si una cadena de correquisitos
 * vuelve a un curso ya visitado (correquisitos mutuos), se asume que se matriculan juntos. */
static int coreq_reachable(const Catalog *catalog, int idx,
                           const StudentHistory *history, int *visiting) {
    const Course *c = &catalog->courses[idx];

    if (history_has_course(history, c->code)) return 1;   /* ya aprobado */
    if (visiting[idx]) return 1;   /* ciclo: se matriculan juntos (evita recursion infinita) */
    if (!validation_has_prerequisites(c, history)) return 0;   /* no se puede llevar todavia */

    /* el correquisito tambien puede tener sus propios correquisitos,
     * por eso se revisan recursivamente */
    visiting[idx] = 1;
    int ok = 1;
    for (int i = 0; i < c->corequisite_count && ok; i++) {
        int j = catalog_find_course_index(catalog, c->corequisites[i]);
        if (j < 0 || !coreq_reachable(catalog, j, history, visiting)) ok = 0;
    }
    /* se desmarca al salir: 'visiting' solo representa la cadena actual,
     * no todos los cursos que alguna vez se revisaron */
    visiting[idx] = 0;
    return ok;
}

/* Revisa los correquisitos de 'course' con la politica del proyecto.
 * Ejemplo: si un curso teorico y su laboratorio se piden mutuamente, al
 * revisar el laboratorio desde el teorico se vuelve al teorico, que ya
 * esta marcado en 'visiting', y se acepta que van juntos. */
int validation_corequisites_ok(const Catalog *catalog,
                               const Course *course,
                               const StudentHistory *history) {
    if (catalog == NULL || course == NULL || history == NULL) {
        return 0;
    }

    /* un arreglo de marcas por cada curso; se inicializa en 0 y se
     * marca el curso de partida para detectar si la cadena vuelve a el */
    int visiting[MAX_COURSES] = {0};
    int self = catalog_find_course_index(catalog, course->code);
    if (self >= 0) visiting[self] = 1;

    for (int i = 0; i < course->corequisite_count; i++) {
        int j = catalog_find_course_index(catalog, course->corequisites[i]);
        if (j < 0 || !coreq_reachable(catalog, j, history, visiting)) {
            return 0;
        }
    }
    return 1;
}

/* Llena can_enroll de cada curso del catalogo.
 * Un curso es matriculable si no esta aprobado, cumple sus prerrequisitos
 * y sus correquisitos (segun validation_corequisites_ok). */
void validation_mark_enrollable(Catalog *catalog,
                                const StudentHistory *history) {
    if (catalog == NULL) {
        return;
    }

    for (int i = 0; i < catalog->course_count; i++) {
        Course *course = &catalog->courses[i];

        /* sin historial no se puede validar nada: se marca como no matriculable */
        if (history == NULL) {
            course->can_enroll = 0;
            continue;
        }

        /* decision del grupo: un curso ya aprobado no se vuelve a matricular */
        if (history_has_course(history, course->code)) {
            course->can_enroll = 0;
            continue;
        }

        if (validation_has_prerequisites(course, history) &&
            validation_corequisites_ok(catalog, course, history)) {
            course->can_enroll = 1;
        } else {
            course->can_enroll = 0;
        }
    }
}