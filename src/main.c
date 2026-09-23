#include <stdio.h>
#include <string.h>

#include "../include/constants.h"
#include "../include/structs.h"
#include "../include/catalog.h"
#include "../include/history.h"
#include "../include/conflicts.h"
#include "../include/validation.h"
#include "../include/export.h"

/* -------------------------------------------------------------------------
 * Punto de entrada del programa. main solo coordina el flujo:
 *
 *   cargar catalogo -> cargar historial -> detectar choques
 *   -> validar matricula -> exportar JSON
 *
 * Toda la logica esta en los modulos; aqui solo se revisan los codigos de
 * error, se imprimen mensajes y se libera la memoria.
 * ------------------------------------------------------------------------- */

/* Traduce un ErrorCode a un mensaje legible para el usuario. */
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

/* dice donde esta el problema cuando la carga del catalogo fallo */
static void print_load_detail(const LoadErrorInfo *info) {
    if (info->line > 0) {
        /* error en una linea especifica del CSV */
        if (info->course[0] != '\0') {
            fprintf(stderr, "  en la linea %d (curso: %s)\n", info->line, info->course);
        } else {
            fprintf(stderr, "  en la linea %d\n", info->line);
        }
    } else if (info->course[0] != '\0' && info->related[0] != '\0') {
        /* line == 0: el error salio de la revision final de requisitos,
         * que no esta ligada a una linea sino a un par curso-requisito */
        fprintf(stderr, "  el curso %s pide %s, que no esta en el catalogo\n",
                info->course, info->related);
    }
}

/* Muestra como usar el programa. Se imprime con -h/--help o si vienen
 * demasiados argumentos. */
static void print_usage(const char *program) {
    fprintf(stderr,
            "Uso: %s [catalogo.csv [historial.csv [salida.json]]]\n"
            "  Valores por defecto: %s, %s, %s\n",
            program, DEFAULT_CATALOG_PATH, DEFAULT_HISTORY_PATH,
            DEFAULT_OUTPUT_PATH);
}

int main(int argc, char *argv[]) {
    /* rutas por defecto (definidas en constants.h) */
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

    /* los argumentos son posicionales y opcionales: cada uno que venga
     * reemplaza la ruta por defecto correspondiente. Asi se puede correr
     * con el catalogo de Computadores o el de Fisica sin recompilar. */
    if (argc > 1) catalog_path = argv[1];
    if (argc > 2) history_path = argv[2];
    if (argc > 3) output_path  = argv[3];

    Catalog catalog;
    StudentHistory history;

    /* 1. catalogo. Si falla, catalog_load_ex ya libero lo que habia
     * cargado, por eso aqui no se llama catalog_free */
    LoadErrorInfo load_info;
    ErrorCode err = catalog_load_ex(catalog_path, &catalog, &load_info);
    if (err != SUCCESS) {
        fprintf(stderr, "Error al cargar el catalogo '%s': %s (codigo %d)\n",
                catalog_path, error_message(err), (int)err);
        print_load_detail(&load_info);
        return (int)err;   /* el ErrorCode se usa como codigo de salida del proceso */
    }

    /* 2. historial. Va despues del catalogo porque se valida contra el.
     * Desde aqui el catalogo ya tiene memoria reservada, entonces cada
     * salida por error debe liberarlo primero. */
    err = history_load(history_path, &catalog, &history);
    if (err != SUCCESS) {
        fprintf(stderr, "Error al cargar el historial '%s': %s (codigo %d)\n",
                history_path, error_message(err), (int)err);
        catalog_free(&catalog);
        return (int)err;
    }

    /* 3 y 4. choques de horario y elegibilidad segun requisitos.
     * Son independientes entre si: uno llena has_conflict de cada grupo
     * y el otro can_enroll de cada curso. */
    int conflict_groups = conflicts_detect_catalog(&catalog);
    validation_mark_enrollable(&catalog, &history);

    /* 5. exportar el JSON que lee la Etapa 2 */
    err = export_catalog_json(output_path, &catalog, &history);
    if (err != SUCCESS) {
        fprintf(stderr, "Error al exportar a '%s': %s (codigo %d)\n",
                output_path, error_message(err), (int)err);
        catalog_free(&catalog);
        return (int)err;
    }

    /* resumen en consola para verificar rapido que todo salio bien */
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

    /* el historial no se libera porque no usa memoria dinamica */
    catalog_free(&catalog);
    return SUCCESS;
}