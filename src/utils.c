#include <string.h>
#include <ctype.h>
#include "../include/utils.h"

void trim_whitespace(char *str) {
    // quitar espacios al final (incluyendo \r que queda si el archivo se editó en Windows)
    int len = (int)strlen(str);
    while (len > 0 && isspace((unsigned char)str[len - 1])) {
        str[len - 1] = '\0';
        len--;
    }

    // quitar espacios al inicio, moviendo el contenido al principio del buffer
    int start = 0;
    while (str[start] != '\0' && isspace((unsigned char)str[start])) {
        start++;
    }
    if (start > 0) {
        memmove(str, str + start, strlen(str + start) + 1);
    }
}

int safe_strcpy(char *dest, size_t dest_size, const char *src) {
    if (dest_size == 0) return 0;

    size_t src_len = strlen(src);
    if (src_len >= dest_size) {
        // no cabe completo, entonces se copia lo que se pueda y se corta ahí, pero siempre con '\0' al final
        memcpy(dest, src, dest_size - 1);
        dest[dest_size - 1] = '\0';
        return 0;
    }

    memcpy(dest, src, src_len + 1); // +1 para copiar el '\0' de src
    return 1;
}

int split_fields(char *line, char delimiter, char *fields[], int max_fields) {
    if (max_fields <= 0) return 0;

    int count = 0;
    fields[count++] = line;

    char *p = line;
    while (*p != '\0') {
        if (*p == delimiter) {
            *p = '\0';
            if (count >= max_fields) {
                return -1; // había más campos de los que el llamador esperaba
            }
            fields[count++] = p + 1;
        }
        p++;
    }

    return count;
}