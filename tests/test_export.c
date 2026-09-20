#include <stdio.h>
#include <string.h>

#include "../include/catalog.h"
#include "../include/history.h"
#include "../include/conflicts.h"
#include "../include/validation.h"
#include "../include/export.h"
#include "../include/utils.h"

#define TEST_OUTPUT_PATH "tests/out_test.json"
#define BUFFER_SIZE      65536

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

static char buffer[BUFFER_SIZE];

/* lee todo el archivo en 'buffer'; devuelve 1 si pudo */
static int read_output(const char *path) {
    FILE *f = fopen(path, "r");
    if (f == NULL) return 0;
    size_t n = fread(buffer, 1, sizeof(buffer) - 1, f);
    buffer[n] = '\0';
    fclose(f);
    return 1;
}

/* cuenta cuantas veces aparece 'needle' dentro de 'haystack' */
static int count_occurrences(const char *haystack, const char *needle) {
    int count = 0;
    for (const char *p = strstr(haystack, needle); p != NULL;
         p = strstr(p + strlen(needle), needle)) {
        count++;
    }
    return count;
}

/* verifica que {} y [] estén balanceados fuera de los strings */
static int json_is_balanced(const char *s) {
    int depth_brace = 0, depth_bracket = 0, in_string = 0;
    for (const char *p = s; *p != '\0'; p++) {
        if (in_string) {
            if (*p == '\\' && p[1] != '\0') { p++; continue; }
            if (*p == '"') in_string = 0;
            continue;
        }
        if (*p == '"') in_string = 1;
        else if (*p == '{') depth_brace++;
        else if (*p == '}') { depth_brace--; if (depth_brace < 0) return 0; }
        else if (*p == '[') depth_bracket++;
        else if (*p == ']') { depth_bracket--; if (depth_bracket < 0) return 0; }
    }
    return !in_string && depth_brace == 0 && depth_bracket == 0;
}

/* Busca el valor booleano de 'key' (con su sangria, para distinguir campos
 * de curso de campos de grupo) en el objeto del curso 'code'.
 * Devuelve 1 (true), 0 (false) o -1 si no se encontró. */
static int course_bool(const char *code, const char *key) {
    char needle[64];
    snprintf(needle, sizeof(needle), "\"code\": \"%s\"", code);
    const char *course = strstr(buffer, needle);
    if (course == NULL) return -1;

    const char *field = strstr(course, key);
    if (field == NULL) return -1;
    field += strlen(key);

    if (strncmp(field, "true", 4) == 0)  return 1;
    if (strncmp(field, "false", 5) == 0) return 0;
    return -1;
}

#define KEY_COURSE_CONFLICT  "\n      \"has_conflict\": "
#define KEY_APPROVED         "\"approved\": "
#define KEY_CAN_ENROLL       "\"can_enroll\": "

static void test_pipeline_real(void) {
    printf("\n=== Exportador: pipeline completo con data/ ===\n");

    Catalog cat;
    StudentHistory hist;

    CHECK(catalog_load("data/catalogo.csv", &cat) == SUCCESS, "catalogo carga");
    CHECK(history_load("data/historial.csv", &cat, &hist) == SUCCESS, "historial carga");

    conflicts_detect_catalog(&cat);
    validation_mark_enrollable(&cat, &hist);

    ErrorCode err = export_catalog_json(TEST_OUTPUT_PATH, &cat, &hist);
    CHECK(err == SUCCESS, "export_catalog_json devuelve SUCCESS");
    CHECK(read_output(TEST_OUTPUT_PATH), "el archivo de salida existe y se puede leer");

    CHECK(buffer[0] == '{', "el JSON empieza con '{'");
    CHECK(strstr(buffer, "\"format_version\": 1") != NULL, "incluye format_version 1");
    CHECK(strstr(buffer, "\"course_count\": 5") != NULL, "course_count es 5");
    CHECK(count_occurrences(buffer, "\"code\": ") == cat.course_count,
          "hay un objeto por cada curso del catalogo");

    CHECK(count_occurrences(buffer, "\"name\": ") == 5, "campo name en cada curso");
    CHECK(count_occurrences(buffer, "\"credits\": ") == 5, "campo credits en cada curso");
    CHECK(count_occurrences(buffer, "\"groups\": ") == 5, "campo groups en cada curso");
    CHECK(count_occurrences(buffer, "\"prerequisites\": ") == 5, "campo prerequisites en cada curso");
    CHECK(count_occurrences(buffer, "\"corequisites\": ") == 5, "campo corequisites en cada curso");
    CHECK(count_occurrences(buffer, "\"approved\": ") == 5, "campo approved en cada curso");
    CHECK(count_occurrences(buffer, "\"can_enroll\": ") == 5, "campo can_enroll en cada curso");

        CHECK(json_is_balanced(buffer), "el JSON tiene llaves y corchetes balanceados");
    CHECK(count_occurrences(buffer, KEY_COURSE_CONFLICT) == 5, "campo has_conflict (curso) en cada curso");

    /* contenido: historial = CE1101, CE1103 */
    CHECK(course_bool("CE1101", KEY_APPROVED) == 1, "CE1101 aprobado");
    CHECK(course_bool("CE1101", KEY_CAN_ENROLL) == 0, "CE1101 aprobado -> no matriculable");
    CHECK(course_bool("CE1103", KEY_CAN_ENROLL) == 0, "CE1103 aprobado -> no matriculable");
    CHECK(course_bool("CE1106", KEY_APPROVED) == 0, "CE1106 no aprobado");
    CHECK(course_bool("CE1106", KEY_CAN_ENROLL) == 1, "CE1106 matriculable (prerrequisito CE1103 aprobado)");
    CHECK(course_bool("CE2103", KEY_CAN_ENROLL) == 0, "CE2103 no matriculable (falta CE1106)");
    CHECK(course_bool("CE2105", KEY_CAN_ENROLL) == 1, "CE2105 sin requisitos, matriculable");

    /* choques a nivel de curso: CE1101 y CE1106 comparten lunes 08:00-10:00 */
    CHECK(course_bool("CE1101", KEY_COURSE_CONFLICT) == 1, "CE1101 choca (curso)");
    CHECK(course_bool("CE1106", KEY_COURSE_CONFLICT) == 1, "CE1106 choca (curso)");
    CHECK(course_bool("CE2105", KEY_COURSE_CONFLICT) == 0, "CE2105 no choca (curso)");

    /* horarios y requisitos */
    CHECK(strstr(buffer, "{\"day\": \"MON\", \"start\": \"08:00\", \"end\": \"10:00\"}") != NULL,
          "bloque escrito con dia y horas HH:MM");
    CHECK(strstr(buffer, "\"prerequisites\": [\"CE1103\"]") != NULL, "prerrequisitos como arreglo de codigos");
    CHECK(strstr(buffer, "\"corequisites\": [\"CE2105\"]") != NULL, "correquisitos como arreglo de codigos");

    catalog_free(&cat);
}

static void test_escape_and_edge_shapes(void) {
    printf("\n=== Exportador: escapes y formas limite ===\n");

    Course courses[3];
    Catalog cat;
    StudentHistory hist;
    history_init(&hist);

    cat.courses = courses;
    cat.course_count = 0;
    cat.capacity = 3;

    /* curso 0: nombre con comillas, backslash, salto de linea; profesor con tilde */
    memset(&courses[0], 0, sizeof(Course));
    safe_strcpy(courses[0].code, MAX_CODE_LENGTH, "X1");
    safe_strcpy(courses[0].name, MAX_NAME_LENGTH, "Dijo \"hola\" \\ fin\nlinea");
    courses[0].credits = 2;
    courses[0].group_count = 1;
    courses[0].groups[0].group_number = 1;
    safe_strcpy(courses[0].groups[0].professor, MAX_PROFESSOR_LENGTH, "Jos\xC3\xA9 P\xC3\xA9rez");
    courses[0].groups[0].block_count = 0;   /* grupo sin horario */
    cat.course_count++;

    /* curso 1: sin grupos */
    memset(&courses[1], 0, sizeof(Course));
    safe_strcpy(courses[1].code, MAX_CODE_LENGTH, "X2");
    safe_strcpy(courses[1].name, MAX_NAME_LENGTH, "Sin grupos");
    courses[1].credits = 1;
    cat.course_count++;

    ErrorCode err = export_catalog_json(TEST_OUTPUT_PATH, &cat, &hist);
    CHECK(err == SUCCESS, "exporta catalogo armado a mano");
    CHECK(read_output(TEST_OUTPUT_PATH), "lee el archivo generado");
    CHECK(json_is_balanced(buffer), "JSON balanceado con caracteres especiales");

    CHECK(strstr(buffer, "Dijo \\\"hola\\\" \\\\ fin\\nlinea") != NULL,
          "escapa comillas, backslash y salto de linea en el nombre");
    CHECK(strstr(buffer, "Jos\xC3\xA9 P\xC3\xA9rez") != NULL, "conserva las tildes (UTF-8)");
    CHECK(strstr(buffer, "\"blocks\": []") != NULL, "grupo sin bloques -> \"blocks\": []");
    CHECK(strstr(buffer, "\"groups\": [],") != NULL, "curso sin grupos -> \"groups\": []");

    /* catalogo vacio */
    Catalog empty;
    catalog_init(&empty);
    err = export_catalog_json(TEST_OUTPUT_PATH, &empty, &hist);
    CHECK(err == SUCCESS, "exporta catalogo vacio");
    CHECK(read_output(TEST_OUTPUT_PATH), "lee el archivo del catalogo vacio");
    CHECK(json_is_balanced(buffer), "JSON del catalogo vacio balanceado");
    CHECK(strstr(buffer, "\"courses\": []") != NULL, "catalogo vacio -> \"courses\": []");
    CHECK(strstr(buffer, "\"course_count\": 0") != NULL, "catalogo vacio -> course_count 0");
    catalog_free(&empty);
}

static void test_errors(void) {
    printf("\n=== Exportador: manejo de errores ===\n");

    Catalog cat;
    StudentHistory hist;
    catalog_init(&cat);
    history_init(&hist);

    CHECK(export_catalog_json(NULL, &cat, &hist) == ERROR_INVALID_FORMAT, "path NULL -> ERROR_INVALID_FORMAT");
    CHECK(export_catalog_json(TEST_OUTPUT_PATH, NULL, &hist) == ERROR_INVALID_FORMAT, "catalogo NULL -> ERROR_INVALID_FORMAT");
    CHECK(export_catalog_json(TEST_OUTPUT_PATH, &cat, NULL) == ERROR_INVALID_FORMAT, "historial NULL -> ERROR_INVALID_FORMAT");
    CHECK(export_catalog_json_stream(NULL, &cat, &hist) == ERROR_INVALID_FORMAT, "stream NULL -> ERROR_INVALID_FORMAT");
    CHECK(export_catalog_json("carpeta_que_no_existe/salida.json", &cat, &hist) == ERROR_FILE_WRITE,
          "ruta de salida inaccesible -> ERROR_FILE_WRITE");
}

int main(void) {
    test_pipeline_real();
    test_escape_and_edge_shapes();
    test_errors();

    remove(TEST_OUTPUT_PATH);

    printf("\n%d/%d pruebas pasaron\n", tests_passed, tests_run);
    return (tests_passed == tests_run) ? 0 : 1;
}