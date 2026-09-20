#include <stdio.h>
#include <string.h>

#include "../include/constants.h"
#include "../include/structs.h"
#include "../include/catalog.h"
#include "../include/history.h"
#include "../include/conflicts.h"
#include "../include/validation.h"
#include "../include/export.h"

static const char *error_message(ErrorCode err) {
    switch (err) {
        case SUCCESS:                 return "sin errores";
        case ERROR_FILE_NOT_FOUND:    return "no se pudo abrir el archivo";
        case ERROR_INVALID_FORMAT:    return "formato invalido o dato inconsistente";
        case ERROR_INCOMPLETE_DATA:   return "datos incompletos";
        case ERROR_MEMORY_ALLOCATION: return "no hay memoria suficiente";
        case ERROR_COURSE_NOT_FOUND:  return "el historial menciona un curso que no esta en el catalogo";
        case ERROR_LIMIT_EXCEEDED:    return "se excedio un limite de tamanio";
        case ERROR_FILE_WRITE:        return "no se pudo escribir el archivo de salida";
        default:                      return "error desconocido";
    }
}

static void print_usage(const char *program) {
    fprintf(stderr,
            "Uso: %s [catalogo.csv [historial.csv [salida.json]]]\n"
            "  Valores por defecto: %s, %s, %s\n",
            program, DEFAULT_CATALOG_PATH, DEFAULT_HISTORY_PATH,
            DEFAULT_OUTPUT_PATH);
}

int main(int argc, char *argv[]) {
    const char *catalog_path = DEFAULT_CATALOG_PATH;
    const char *history_path = DEFAULT_HISTORY_PATH;
    const char *output_path  = DEFAULT_OUTPUT_PATH;

    if (argc > 1 && (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0)) {
        print_usage(argv[0]);
        return SUCCESS;
    }
    if (argc > 4) {
        print_usage(argv[0]);
        return ERROR_INVALID_FORMAT;
    }
    if (argc > 1) catalog_path = argv[1];
    if (argc > 2) history_path = argv[2];
    if (argc > 3) output_path  = argv[3];

        Catalog catalog;
    StudentHistory history;

    ErrorCode err = catalog_load(catalog_path, &catalog);
    if (err != SUCCESS) {
        fprintf(stderr, "Error al cargar el catalogo '%s': %s (codigo %d)\n",
                catalog_path, error_message(err), (int)err);
        return (int)err;
    }

    err = history_load(history_path, &catalog, &history);
    if (err != SUCCESS) {
        fprintf(stderr, "Error al cargar el historial '%s': %s (codigo %d)\n",
                history_path, error_message(err), (int)err);
        catalog_free(&catalog);
        return (int)err;
    }

    /* 3. choques de horario y 4. elegibilidad segun requisitos */
    int conflict_groups = conflicts_detect_catalog(&catalog);
    validation_mark_enrollable(&catalog, &history);

    /* 5. exportar */
    err = export_catalog_json(output_path, &catalog, &history);
    if (err != SUCCESS) {
        fprintf(stderr, "Error al exportar a '%s': %s (codigo %d)\n",
                output_path, error_message(err), (int)err);
        catalog_free(&catalog);
        return (int)err;
    }

    int total_groups = 0;
    int enrollable = 0;
    for (int i = 0; i < catalog.course_count; i++) {
        total_groups += catalog.courses[i].group_count;
        if (catalog.courses[i].can_enroll) enrollable++;
    }

    printf("Catalogo:   %s (%d cursos, %d grupos)\n",
           catalog_path, catalog.course_count, total_groups);
    printf("Historial:  %s (%d cursos aprobados)\n",
           history_path, history.approved_count);
    printf("Choques:    %d grupos con choque de horario\n", conflict_groups);
    printf("Matricula:  %d cursos matriculables\n", enrollable);
    printf("Salida:     %s\n", output_path);

    catalog_free(&catalog);
    return SUCCESS;
}