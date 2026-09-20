#include "../include/validation.h"
#include "../include/history.h"

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
            validation_has_corequisites(course, history)) {
            course->can_enroll = 1;
        } else {
            course->can_enroll = 0;
        }
    }
}