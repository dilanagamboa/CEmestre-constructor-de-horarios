#include <stdio.h>
#include <string.h>

#include "../include/catalog.h"
#include "../include/history.h"
#include "../include/validation.h"
#include "../include/utils.h"

static int tests_run = 0;
static int tests_passed = 0;

#define CHECK(cond, msg)                                                     \
    do {                                                                     \
        tests_run++;                                                         \
        if (cond) {                                                          \
            tests_passed++;                                                  \
            printf("OK   - %s\n", msg);                                      \
        } else {                                                             \
            printf("FAIL - %s\n", msg);                                      \
        }                                                                    \
    } while (0)

static void course_init(Course *course, const char *code) {
    memset(course, 0, sizeof(*course));
    safe_strcpy(course->code, MAX_CODE_LENGTH, code);
    safe_strcpy(course->name, MAX_NAME_LENGTH, code);
    course->credits = 4;
    course->prerequisite_count = 0;
    course->corequisite_count = 0;
    course->group_count = 0;
    course->can_enroll = 0;
}

static void course_add_prereq(Course *course, const char *code) {
    safe_strcpy(course->prerequisites[course->prerequisite_count],
                MAX_CODE_LENGTH, code);
    course->prerequisite_count++;
}

static void course_add_coreq(Course *course, const char *code) {
    safe_strcpy(course->corequisites[course->corequisite_count],
                MAX_CODE_LENGTH, code);
    course->corequisite_count++;
}

static void history_add(StudentHistory *history, const char *code) {
    safe_strcpy(history->approved_courses[history->approved_count],
                MAX_CODE_LENGTH, code);
    history->approved_count++;
}

static int course_can_enroll(const Catalog *catalog, const char *code) {
    int idx = catalog_find_course_index(catalog, code);
    if (idx < 0) {
        return -1;
    }
    return catalog->courses[idx].can_enroll;
}

int main(void) {
    Course courses[6];
    Catalog catalog;
    StudentHistory history;
    Course c;
    int idx;

    catalog.courses = courses;
    catalog.course_count = 0;
    catalog.capacity = 6;

    /* A: sin requisitos */
    course_init(&c, "A");
    courses[catalog.course_count++] = c;

    /* B: prerrequisito A */
    course_init(&c, "B");
    course_add_prereq(&c, "A");
    courses[catalog.course_count++] = c;

    /* C: prerrequisitos A y D */
    course_init(&c, "C");
    course_add_prereq(&c, "A");
    course_add_prereq(&c, "D");
    courses[catalog.course_count++] = c;

    /* D: sin requisitos */
    course_init(&c, "D");
    courses[catalog.course_count++] = c;

    /* E: correquisito A */
    course_init(&c, "E");
    course_add_coreq(&c, "A");
    courses[catalog.course_count++] = c;

    /* F: correquisito D */
    course_init(&c, "F");
    course_add_coreq(&c, "D");
    courses[catalog.course_count++] = c;

    /* 1. Historial vacío */
    history_init(&history);
    validation_mark_enrollable(&catalog, &history);

    CHECK(course_can_enroll(&catalog, "A") == 1,
          "historial vacio: A sin requisitos es matriculable");
    CHECK(course_can_enroll(&catalog, "D") == 1,
          "historial vacio: D sin requisitos es matriculable");
    CHECK(course_can_enroll(&catalog, "B") == 0,
          "historial vacio: B con prerrequisito A no es matriculable");
    CHECK(course_can_enroll(&catalog, "C") == 0,
          "historial vacio: C con prerrequisitos A y D no es matriculable");
    CHECK(course_can_enroll(&catalog, "E") == 0,
          "historial vacio: E con correquisito A no es matriculable");
    CHECK(course_can_enroll(&catalog, "F") == 0,
          "historial vacio: F con correquisito D no es matriculable");

    /* 2. Historial con A aprobado */
    history_init(&history);
    history_add(&history, "A");
    validation_mark_enrollable(&catalog, &history);

    CHECK(course_can_enroll(&catalog, "B") == 1,
          "A aprobado: B con prerrequisito A es matriculable");
    CHECK(course_can_enroll(&catalog, "C") == 0,
          "A aprobado: C aun necesita D");
    CHECK(course_can_enroll(&catalog, "E") == 1,
          "A aprobado: E con correquisito A es matriculable");
    CHECK(course_can_enroll(&catalog, "F") == 0,
          "A aprobado: F aun necesita D como correquisito");

    /* 3. Historial con A y D aprobados */
    history_init(&history);
    history_add(&history, "A");
    history_add(&history, "D");
    validation_mark_enrollable(&catalog, &history);

    CHECK(course_can_enroll(&catalog, "C") == 1,
          "A y D aprobados: C cumple prerrequisitos");
    CHECK(course_can_enroll(&catalog, "F") == 1,
          "D aprobado: F cumple correquisito");

    /* 4. Pruebas directas de las funciones de validación */
    history_init(&history);

    idx = catalog_find_course_index(&catalog, "A");
    CHECK(validation_has_prerequisites(&catalog.courses[idx], &history) == 1,
          "A no tiene prerrequisitos: validacion directa");

    idx = catalog_find_course_index(&catalog, "B");
    CHECK(validation_has_prerequisites(&catalog.courses[idx], &history) == 0,
          "B con prerrequisito A incumplido: validacion directa");

    idx = catalog_find_course_index(&catalog, "E");
    CHECK(validation_has_corequisites(&catalog.courses[idx], &history) == 0,
          "E con correquisito A incumplido: validacion directa");

    history_add(&history, "A");
    idx = catalog_find_course_index(&catalog, "E");
    CHECK(validation_has_corequisites(&catalog.courses[idx], &history) == 1,
          "E con correquisito A aprobado: validacion directa");

    printf("\n%d/%d pruebas pasaron\n", tests_passed, tests_run);
    return (tests_passed == tests_run) ? 0 : 1;
}