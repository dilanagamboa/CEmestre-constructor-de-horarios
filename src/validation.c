#include "../include/validation.h"
#include "../include/history.h"
#include "../include/catalog.h"

int validation_has_prerequisites(const Course *course,
                                 const StudentHistory *history) {
    if (course == NULL || history == NULL) {
        return 0;
    }

    for (int i = 0; i < course->prerequisite_count; i++) {
        if (!history_has_course(history, course->prerequisites[i])) {
            return 0;
        }
    }

    return 1;
}

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

    if (history_has_course(history, c->code)) return 1;
    if (visiting[idx]) return 1;
    if (!validation_has_prerequisites(c, history)) return 0;

    visiting[idx] = 1;
    int ok = 1;
    for (int i = 0; i < c->corequisite_count && ok; i++) {
        int j = catalog_find_course_index(catalog, c->corequisites[i]);
        if (j < 0 || !coreq_reachable(catalog, j, history, visiting)) ok = 0;
    }
    visiting[idx] = 0;
    return ok;
}

int validation_corequisites_ok(const Catalog *catalog,
                               const Course *course,
                               const StudentHistory *history) {
    if (catalog == NULL || course == NULL || history == NULL) {
        return 0;
    }

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

void validation_mark_enrollable(Catalog *catalog,
                                const StudentHistory *history) {
    if (catalog == NULL) {
        return;
    }

    for (int i = 0; i < catalog->course_count; i++) {
        Course *course = &catalog->courses[i];

        if (history == NULL) {
            course->can_enroll = 0;
            continue;
        }

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