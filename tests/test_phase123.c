#include <stdio.h>
#include <string.h>

#include "../include/utils.h"
#include "../include/catalog.h"
#include "../include/history.h"
#include "../include/conflicts.h"

static int tests_run    = 0;
static int tests_passed = 0;

#define CHECK(cond, msg) do {                                        \
    tests_run++;                                                     \
    if (cond) {                                                      \
        tests_passed++;                                              \
        printf("  [OK]   %s\n", msg);                                \
    } else {                                                         \
        printf("  [FAIL] %s\n", msg);                                \
    }                                                                \
} while (0)

static void test_utils(void) {
    printf("\n=== Fase 1: utils ===\n");

    char buf[64];

    safe_strcpy(buf, sizeof(buf), "  hola mundo \r\n");
    trim_whitespace(buf);
    CHECK(strcmp(buf, "hola mundo") == 0, "trim_whitespace quita espacios y \\r\\n");

    safe_strcpy(buf, sizeof(buf), "   ");
    trim_whitespace(buf);
    CHECK(buf[0] == '\0', "trim_whitespace deja cadena vacia si todo es espacio");

    char small[4];
    int ok = safe_strcpy(small, sizeof(small), "abcdef");
    CHECK(ok == 0 && strcmp(small, "abc") == 0, "safe_strcpy trunca sin desbordar");

    char line[] = "a;b;c";
    char *fields[3];
    int n = split_fields(line, ';', fields, 3);
    CHECK(n == 3, "split_fields devuelve 3 campos");
    CHECK(strcmp(fields[0], "a") == 0 &&
          strcmp(fields[1], "b") == 0 &&
          strcmp(fields[2], "c") == 0, "split_fields separa bien");
}

//En desuso pero util para tests, no hace falta borrarla
static const char *err_name(ErrorCode e) {
    switch (e) {
        case SUCCESS:                   return "SUCCESS";
        case ERROR_FILE_NOT_FOUND:      return "ERROR_FILE_NOT_FOUND";
        case ERROR_INVALID_FORMAT:      return "ERROR_INVALID_FORMAT";
        case ERROR_INCOMPLETE_DATA:     return "ERROR_INCOMPLETE_DATA";
        case ERROR_MEMORY_ALLOCATION:   return "ERROR_MEMORY_ALLOCATION";
        case ERROR_COURSE_NOT_FOUND:    return "ERROR_COURSE_NOT_FOUND";
        case ERROR_LIMIT_EXCEEDED:      return "ERROR_LIMIT_EXCEEDED";
        default:                        return "???";
    }
}

static void test_catalog(void) {
    printf("\n=== Fase 2: catalog ===\n");

    Catalog cat;
    ErrorCode err = catalog_load("data/catalogo.csv", &cat);

    CHECK(err == SUCCESS, "catalog_load archivo valido devuelve SUCCESS");
    CHECK(cat.course_count == 5, "catalog_load carga los 5 cursos");

    if (cat.course_count > 0) {
        int idx = catalog_find_course_index(&cat, "CE1106");
        CHECK(idx != -1, "catalog_find_course_index encuentra CE1106");

        if (idx != -1) {
            CHECK(strcmp(cat.courses[idx].name, "Paradigmas de Programacion") == 0,
                  "el nombre se parseo bien");
            CHECK(cat.courses[idx].credits == 4, "los creditos se parsearon bien");
            CHECK(cat.courses[idx].prerequisite_count == 1 &&
                  strcmp(cat.courses[idx].prerequisites[0], "CE1103") == 0,
                  "prerequisito de CE1106 es CE1103");
            CHECK(cat.courses[idx].group_count == 1, "CE1106 tiene 1 grupo");
            CHECK(cat.courses[idx].groups[0].block_count == 2,
                  "el grupo 1 de CE1106 tiene 2 bloques");
        }

        int idx2103 = catalog_find_course_index(&cat, "CE2103");
        if (idx2103 != -1) {
            CHECK(cat.courses[idx2103].corequisite_count == 1 &&
                  strcmp(cat.courses[idx2103].corequisites[0], "CE2105") == 0,
                  "correquisito de CE2103 es CE2105");
        }
    }

    catalog_free(&cat);

    /* archivo con codigo duplicado */
    Catalog dup;
    err = catalog_load("tests/data_invalid/catalogo_dup.csv", &dup);
    CHECK(err == ERROR_INVALID_FORMAT, "catalogo con codigo duplicado -> ERROR_INVALID_FORMAT");
    catalog_free(&dup);

    /* archivo con hora final antes de la inicial */
    Catalog bad;
    err = catalog_load("tests/data_invalid/catalogo_bad_time.csv", &bad);
    CHECK(err == ERROR_INVALID_FORMAT, "bloque con hora invalida -> ERROR_INVALID_FORMAT");
    catalog_free(&bad);

    /* archivo inexistente */
    Catalog nf;
    err = catalog_load("no_existe.csv", &nf);
    CHECK(err == ERROR_FILE_NOT_FOUND, "archivo inexistente -> ERROR_FILE_NOT_FOUND");
}

static void test_history(void) {
    printf("\n=== Fase 2: history ===\n");

    Catalog cat;
    catalog_load("data/catalogo.csv", &cat);

    StudentHistory hist;
    ErrorCode err = history_load("data/historial.csv", &cat, &hist);
    CHECK(err == SUCCESS, "history_load archivo valido devuelve SUCCESS");
    CHECK(hist.approved_count == 2, "history_load carga 2 cursos");

    CHECK(history_has_course(&hist, "CE1101") == 1, "historial contiene CE1101");
    CHECK(history_has_course(&hist, "CE1106") == 0, "historial no contiene CE1106");

    StudentHistory bad;
    err = history_load("tests/data_invalid/historial_unknown.csv", &cat, &bad);
    CHECK(err == ERROR_COURSE_NOT_FOUND,
          "historial con codigo desconocido -> ERROR_COURSE_NOT_FOUND");

    err = history_load("no_existe.csv", &cat, &bad);
    CHECK(err == ERROR_FILE_NOT_FOUND, "historial inexistente -> ERROR_FILE_NOT_FOUND");

    catalog_free(&cat);
}

static void test_conflicts(void) {
    printf("\n=== Fase 3: conflicts ===\n");

    /* caso directo: mismo dia, mismo horario -> choque */
    TimeBlock a = { MONDAY, 8, 0, 10, 0 };
    TimeBlock b = { MONDAY, 8, 0, 10, 0 };
    CHECK(conflicts_blocks_overlap(&a, &b) == 1, "bloques identicos chocan");

    /* traslape parcial */
    TimeBlock c = { MONDAY, 9, 0, 11, 0 };
    CHECK(conflicts_blocks_overlap(&a, &c) == 1, "traslape parcial choca");

    /* dias distintos -> no choca */
    TimeBlock d = { TUESDAY, 8, 0, 10, 0 };
    CHECK(conflicts_blocks_overlap(&a, &d) == 0, "dias distintos no chocan");

    /* adyacente pero sin solapar: 8-10 y 10-12 */
    TimeBlock e = { MONDAY, 10, 0, 12, 0 };
    CHECK(conflicts_blocks_overlap(&a, &e) == 0, "adyacentes sin solape no chocan");

    /* un bloque dentro de otro */
    TimeBlock f = { MONDAY, 9, 0, 9, 30 };
    CHECK(conflicts_blocks_overlap(&a, &f) == 1, "bloque contenido choca");

    /* ahora sobre el catalogo real */
    Catalog cat;
    catalog_load("data/catalogo.csv", &cat);

    int marked = conflicts_detect_catalog(&cat);
    CHECK(marked > 0, "conflicts_detect_catalog marca al menos un grupo");

    int ce1101 = catalog_find_course_index(&cat, "CE1101");
    int ce1106 = catalog_find_course_index(&cat, "CE1106");
    int ce2105 = catalog_find_course_index(&cat, "CE2105");

    CHECK(cat.courses[ce1101].groups[0].has_conflict == 1,
          "grupo 1 de CE1101 marcado como conflictivo");
    CHECK(cat.courses[ce1106].groups[0].has_conflict == 1,
          "grupo 1 de CE1106 marcado como conflictivo");
    CHECK(cat.courses[ce2105].groups[0].has_conflict == 0,
          "grupo 1 de CE2105 NO marcado (viernes, sin choque)");

    /* idempotencia: llamar dos veces no acumula */
    int marked2 = conflicts_detect_catalog(&cat);
    CHECK(marked2 == marked, "conflicts_detect_catalog es idempotente");

    catalog_free(&cat);
}

int main(void) {
    test_utils();
    test_catalog();
    test_history();
    test_conflicts();

    printf("\n===============================\n");
    printf("Pasaron %d/%d pruebas\n", tests_passed, tests_run);
    printf("===============================\n");

    return (tests_passed == tests_run) ? 0 : 1;
}