#include <stdio.h>
#include <string.h>

#include "../include/catalog.h"
#include "../include/area.h"

/* pruebas del modulo de areas (Etapa 3): carga valida, errores controlados
 * y areas de los catalogos reales de las dos carreras */

static int tests_run    = 0;
static int tests_passed = 0;

#define CHECK(cond, msg) do {                                        \
    tests_run++;                                                     \
    if (cond) {                                                      \
        tests_passed++;                                              \
        printf("OK   - %s\n", msg);                                  \
    } else {                                                         \
        printf("FAIL - %s\n", msg);                                  \
    }                                                                \
} while (0)

/* area de 'code' en el catalogo, o "" si el curso no existe */
static const char *area_of(const Catalog *cat, const char *code) {
    int idx = catalog_find_course_index(cat, code);
    return idx < 0 ? "" : cat->courses[idx].area;
}

/* carga data/catalogo.csv y luego el archivo de areas; devuelve el codigo de area_load */
static ErrorCode load_with_areas(const char *areas_path, Catalog *cat, LoadErrorInfo *info) {
    if (catalog_load("data/catalogo.csv", cat) != SUCCESS) return ERROR_FILE_NOT_FOUND;
    return area_load(areas_path, cat, info);
}

static void test_valid_areas(void) {
    printf("\n=== Areas: lista valida ===\n");
    CHECK(area_is_valid("matematica") && area_is_valid("programacion"), "areas de la lista son validas");
    CHECK(!area_is_valid("Matematica"), "el area distingue mayusculas");
    CHECK(!area_is_valid("") && !area_is_valid(NULL), "vacia o NULL no es valida");
    CHECK(!area_is_valid(AREA_UNASSIGNED), "sin_area no se puede escribir en el archivo");
}

static void test_load_ok(void) {
    printf("\n=== Areas: carga valida ===\n");
    Catalog cat;
    LoadErrorInfo info;
    CHECK(load_with_areas("tests/data_valid/areas_catalogo.csv", &cat, &info) == SUCCESS,
          "carga con comentario, linea vacia y espacios");
    CHECK(strcmp(area_of(&cat, "CE1101"), "programacion") == 0, "CE1101 -> programacion");
    CHECK(strcmp(area_of(&cat, "CE1106"), "programacion") == 0, "espacio antes del area se ignora");
    CHECK(strcmp(area_of(&cat, "CE2105"), "matematica") == 0, "CE2105 -> matematica");
    catalog_free(&cat);

    CHECK(catalog_load("data/catalogo.csv", &cat) == SUCCESS, "catalogo de ejemplo carga");
    area_set_unassigned(&cat);
    CHECK(strcmp(area_of(&cat, "CE2103"), AREA_UNASSIGNED) == 0, "sin archivo cada curso queda sin_area");
    catalog_free(&cat);
}

static void test_load_errors(void) {
    printf("\n=== Areas: errores controlados ===\n");
    Catalog cat;
    LoadErrorInfo info;

    CHECK(load_with_areas("tests/data_invalid/no_existe.csv", &cat, &info) == ERROR_FILE_NOT_FOUND,
          "archivo inexistente -> ERROR_FILE_NOT_FOUND");
    catalog_free(&cat);

    CHECK(load_with_areas("tests/data_invalid/areas_curso_sin_area.csv", &cat, &info) == ERROR_INCOMPLETE_DATA
          && strcmp(info.course, "CE2105") == 0,
          "curso sin area -> ERROR_INCOMPLETE_DATA y dice cual (CE2105)");
    catalog_free(&cat);

    CHECK(load_with_areas("tests/data_invalid/areas_codigo_repetido.csv", &cat, &info) == ERROR_INVALID_FORMAT
          && info.line == 6,
          "codigo repetido -> ERROR_INVALID_FORMAT en la linea 6");
    catalog_free(&cat);

    CHECK(load_with_areas("tests/data_invalid/areas_area_invalida.csv", &cat, &info) == ERROR_INVALID_FORMAT
          && info.line == 5,
          "area mal escrita -> ERROR_INVALID_FORMAT en la linea 5");
    catalog_free(&cat);

    CHECK(load_with_areas("tests/data_invalid/areas_curso_desconocido.csv", &cat, &info) == ERROR_COURSE_NOT_FOUND
          && strcmp(info.course, "CE9999") == 0,
          "curso que no esta en el catalogo -> ERROR_COURSE_NOT_FOUND");
    catalog_free(&cat);

    CHECK(load_with_areas("tests/data_invalid/areas_sin_area.csv", &cat, &info) == ERROR_INVALID_FORMAT,
          "linea sin area -> ERROR_INVALID_FORMAT");
    catalog_free(&cat);

    CHECK(load_with_areas("tests/data_invalid/areas_campo_extra.csv", &cat, &info) == ERROR_INVALID_FORMAT,
          "linea con un campo de mas -> ERROR_INVALID_FORMAT");
    catalog_free(&cat);

    CHECK(area_load("tests/data_valid/areas_catalogo.csv", NULL, &info) == ERROR_INVALID_FORMAT,
          "catalogo NULL -> ERROR_INVALID_FORMAT");
}

/* todas las areas de un catalogo real deben venir de la lista valida */
static int all_valid(const Catalog *cat) {
    for (int i = 0; i < cat->course_count; i++) {
        if (!area_is_valid(cat->courses[i].area)) return 0;
    }
    return 1;
}

static void test_real_catalog(const char *career, const char *code, const char *expected) {
    char catalog_path[64], areas_path[64], msg[128];
    snprintf(catalog_path, sizeof(catalog_path), "data/catalogo_%s.csv", career);
    snprintf(areas_path, sizeof(areas_path), "data/areas_%s.csv", career);

    Catalog cat;
    LoadErrorInfo info;
    ErrorCode err = catalog_load(catalog_path, &cat);
    if (err == SUCCESS) err = area_load(areas_path, &cat, &info);

    snprintf(msg, sizeof(msg), "%s: cada curso de los 8 semestres tiene un area valida", career);
    CHECK(err == SUCCESS && all_valid(&cat), msg);
    snprintf(msg, sizeof(msg), "%s: %s -> %s", career, code, expected);
    CHECK(strcmp(area_of(&cat, code), expected) == 0, msg);
    catalog_free(&cat);
}

int main(void) {
    test_valid_areas();
    test_load_ok();
    test_load_errors();

    printf("\n=== Areas: catalogos reales ===\n");
    test_real_catalog("computadores", "CE1106", "programacion");
    test_real_catalog("fisica", "EL4513", "fisica");

    printf("\n%d/%d pruebas pasaron\n", tests_passed, tests_run);
    return (tests_passed == tests_run) ? 0 : 1;
}
