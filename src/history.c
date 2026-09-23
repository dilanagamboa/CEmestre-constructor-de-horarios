#include <stdio.h>
#include <string.h>
#include "../include/history.h"
#include "../include/utils.h"

// formato de historial.csv: un código de curso aprobado por línea, por ejemplo
//   CE1101
//   CE1102

// deja el historial vacío; como el arreglo es fijo dentro del struct,
// basta con poner el contador en 0 (no hay memoria dinámica que liberar)
void history_init(StudentHistory *history) {
    history->approved_count = 0;
}

// búsqueda lineal: devuelve 1 si el código está entre los aprobados, 0 si no
// la usan validation.c (requisitos) y export.c (campo "approved")
int history_has_course(const StudentHistory *history, const char *code) {
    for (int i = 0; i < history->approved_count; i++) {
        if (strcmp(history->approved_courses[i], code) == 0) {
            return 1;
        }
    }
    return 0;
}

// carga el historial y lo valida contra el catálogo, por eso el catálogo
// se tiene que cargar primero (en main.c va en ese orden)
// ante cualquier dato inválido se cierra el archivo y se devuelve el error
ErrorCode history_load(const char *path, const Catalog *catalog, StudentHistory *history) {
    FILE *file = fopen(path, "r");
    if (file == NULL) {
        return ERROR_FILE_NOT_FOUND;
    }

    history_init(history);

    char line[MAX_LINE_LENGTH];
    while (fgets(line, sizeof(line), file) != NULL) {
        // quita espacios y el salto de línea ("\r\n" si viene de Windows)
        trim_whitespace(line);

        // líneas vacías se ignoran
        if (line[0] == '\0') {
            continue;
        }

        // un código que no cabe en MAX_CODE_LENGTH ya es un dato mal transcrito
        if (strlen(line) >= MAX_CODE_LENGTH) {
            fclose(file);
            return ERROR_INVALID_FORMAT;
        }

        // el código debe existir en el catálogo ya cargado
        // (atrapa errores de digitación, como CE1110 en vez de CE1101)
        if (catalog_find_course_index(catalog, line) == -1) {
            fclose(file);
            return ERROR_COURSE_NOT_FOUND;
        }

        // un curso repetido en el historial no es posible
        if (history_has_course(history, line)) {
            fclose(file);
            return ERROR_INVALID_FORMAT;
        }

        // se revisa antes de copiar para no escribir fuera del arreglo
        if (history->approved_count >= MAX_APPROVED_COURSES) {
            fclose(file);
            return ERROR_LIMIT_EXCEEDED;
        }

        // ya validado, se guarda en la siguiente posición libre
        safe_strcpy(history->approved_courses[history->approved_count], MAX_CODE_LENGTH, line);
        history->approved_count++;
    }

    fclose(file);

    // historial vacío no es problema (estudiante de primer ingreso)
    return SUCCESS;
}