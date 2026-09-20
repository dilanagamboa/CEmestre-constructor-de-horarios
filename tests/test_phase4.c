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

/* ---------------- helpers ---------------- */

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
    if (idx < 0) return -1;
    return catalog->courses[idx].can_enroll;
}

static int snapshot_can_enroll(const Catalog *catalog, int *out, int max) {
    if (catalog->course_count > max) return 0;
    for (int i = 0; i < catalog->course_count; i++) {
        out[i] = catalog->courses[i].can_enroll;
    }
    return 1;
}

/* ---------------- main ---------------- */

int main(void) {
    Course courses[10];
    Catalog catalog;
    StudentHistory history;
    Course c;
    int idx;

    catalog.courses = courses;
    catalog.course_count = 0;
    catalog.capacity = 10;

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

    /* G: multiples correquisitos A y D */
    course_init(&c, "G");
    course_add_coreq(&c, "A");
    course_add_coreq(&c, "D");
    courses[catalog.course_count++] = c;

    /* Caso real: correquisitos mutuos, como CE2103 y CE2104 del TEC.
     * Ambos comparten el prerrequisito comun R y se exigen entre si. */
    course_init(&c, "R");
    courses[catalog.course_count++] = c;

    course_init(&c, "H");
    course_add_prereq(&c, "R");
    course_add_coreq(&c, "I");
    courses[catalog.course_count++] = c;

    course_init(&c, "I");
    course_add_prereq(&c, "R");
    course_add_coreq(&c, "H");
    courses[catalog.course_count++] = c;

    /* ============ Bloque 1: historial vacio ============ */
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
    CHECK(course_can_enroll(&catalog, "G") == 0,
          "historial vacio: G con multiples correquisitos no es matriculable");

    /* ============ Bloque 2: solo A aprobado ============ */
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

    /* Multiple correquisitos: solo uno cumplido -> no matriculable */
    CHECK(course_can_enroll(&catalog, "G") == 0,
          "A aprobado: G con multiples correquisitos (falta D) no es matriculable");

    /* ============ Bloque 3: A y D aprobados ============ */
    history_init(&history);
    history_add(&history, "A");
    history_add(&history, "D");
    validation_mark_enrollable(&catalog, &history);

    CHECK(course_can_enroll(&catalog, "C") == 1,
          "A y D aprobados: C cumple prerrequisitos");
    CHECK(course_can_enroll(&catalog, "F") == 1,
          "D aprobado: F cumple correquisito");
    CHECK(course_can_enroll(&catalog, "G") == 1,
          "A y D aprobados: G cumple multiples correquisitos");

    /* ============ Bloque 4: idempotencia ============ */
    {
        int snap1[10];
        int snap2[10];

        history_init(&history);
        history_add(&history, "A");
        history_add(&history, "D");
        history_add(&history, "R");

        validation_mark_enrollable(&catalog, &history);
        CHECK(snapshot_can_enroll(&catalog, snap1, 10),
              "idempotencia: snapshot inicial tomado");

        validation_mark_enrollable(&catalog, &history);
        CHECK(snapshot_can_enroll(&catalog, snap2, 10),
              "idempotencia: segundo snapshot tomado");

        int equal = 1;
        for (int i = 0; i < catalog.course_count; i++) {
            if (snap1[i] != snap2[i]) { equal = 0; break; }
        }
        CHECK(equal, "idempotencia: segunda llamada produce el mismo estado");
    }

    /* ============ Bloque 5: caso real, correquisitos mutuos ============ */
    history_init(&history);
    history_add(&history, "R");
    validation_mark_enrollable(&catalog, &history);

    CHECK(course_can_enroll(&catalog, "H") == 0,
          "caso real: H tiene R y exige I como correquisito (no aprobado) -> no matriculable");
    CHECK(course_can_enroll(&catalog, "I") == 0,
          "caso real: I tiene R y exige H como correquisito (no aprobado) -> no matriculable");

    /* Si por alguna razon el estudiante ya trae H aprobado en el historial,
     * I si seria matriculable: valida la simetria de la politica. */
    history_init(&history);
    history_add(&history, "R");
    history_add(&history, "H");
    validation_mark_enrollable(&catalog, &history);

    CHECK(course_can_enroll(&catalog, "I") == 1,
          "caso real: I es matriculable si H ya esta aprobado (politica simetrica)");

    /* ============ Bloque 6: validaciones directas ============ */
    history_init(&history);

    idx = catalog_find_course_index(&catalog, "A");
    CHECK(validation_has_prerequisites(&catalog.courses[idx], &history) == 1,
          "validacion directa: A sin prerrequisitos cumple");

    idx = catalog_find_course_index(&catalog, "B");
    CHECK(validation_has_prerequisites(&catalog.courses[idx], &history) == 0,
          "validacion directa: B con prerrequisito A incumplido");

    idx = catalog_find_course_index(&catalog, "E");
    CHECK(validation_has_corequisites(&catalog.courses[idx], &history) == 0,
          "validacion directa: E con correquisito A incumplido");

    history_add(&history, "A");
    idx = catalog_find_course_index(&catalog, "E");
    CHECK(validation_has_corequisites(&catalog.courses[idx], &history) == 1,
          "validacion directa: E con correquisito A aprobado");

    /* Robustez ante NULL */
    CHECK(validation_has_prerequisites(NULL, &history) == 0,
          "robustez: course NULL devuelve 0");
    CHECK(validation_has_corequisites(&catalog.courses[0], NULL) == 0,
          "robustez: history NULL devuelve 0");

    /* Independencia entre elegibilidad curricular y choque de horario */
    history_init(&history);
    history_add(&history, "A");
    catalog.courses[catalog_find_course_index(&catalog, "B")].groups[0].has_conflict = 1;
    validation_mark_enrollable(&catalog, &history);
    CHECK(course_can_enroll(&catalog, "B") == 1, "independencia: can_enroll no depende de has_conflict");

    /* ============ Bloque 7: un curso ya aprobado no es matriculable ============ */
    history_init(&history);
    history_add(&history, "A");
    history_add(&history, "D");
    validation_mark_enrollable(&catalog, &history);

    CHECK(course_can_enroll(&catalog, "A") == 0,
          "aprobado: A esta en el historial, no es matriculable");
    CHECK(course_can_enroll(&catalog, "D") == 0,
          "aprobado: D esta en el historial, no es matriculable");
    CHECK(course_can_enroll(&catalog, "B") == 1,
          "aprobado: B sigue matriculable (A cumplido, B no esta aprobado)");

    history_init(&history);
    validation_mark_enrollable(&catalog, &history);
    CHECK(course_can_enroll(&catalog, "A") == 1,
          "aprobado: sin A en el historial, A vuelve a ser matriculable");

    printf("\n%d/%d pruebas pasaron\n", tests_passed, tests_run);
    return (tests_passed == tests_run) ? 0 : 1;

}