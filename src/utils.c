#include <string.h>
#include <ctype.h>
#include "../include/utils.h"

// funciones de apoyo para manejar strings, las usan catalog.c y history.c

// quita espacios, tabs y saltos de línea al inicio y al final, en el mismo buffer
void trim_whitespace(char *str) {
    // quitar espacios al final (incluyendo \r que queda si el archivo se editó en Windows)
    int len = (int)strlen(str);
    // el cast a unsigned char es necesario: isspace con un char negativo
    // (bytes de tildes en UTF-8) es comportamiento indefinido
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
        // memmove y no memcpy porque origen y destino se traslapan (es el mismo buffer)
        memmove(str, str + start, strlen(str + start) + 1);
    }
}

// versión segura de strcpy: nunca escribe más de dest_size bytes
// devuelve 1 si cupo completo y 0 si hubo que cortarlo, así quien la llama
// puede decidir si rechazar el dato en vez de aceptarlo truncado
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

// divide 'line' por 'delimiter' sin copiar nada: reemplaza cada separador
// por '\0' y guarda en 'fields' un puntero al inicio de cada campo
// por ejemplo "A;;B" queda como fields = {"A", "", "B"} y devuelve 3
// se hizo propia en vez de usar strtok porque strtok se salta los campos
// vacíos, y en el CSV un campo vacío significa algo (ej. sin requisitos)
// ojo: modifica 'line', y los punteros dejan de servir si 'line' cambia
int split_fields(char *line, char delimiter, char *fields[], int max_fields) {
    if (max_fields <= 0) return 0;

    // el primer campo siempre empieza al inicio de la línea
    int count = 0;
    fields[count++] = line;

    char *p = line;
    while (*p != '\0') {
        if (*p == delimiter) {
            *p = '\0';   // termina el campo anterior
            if (count >= max_fields) {
                return -1; // había más campos de los que el llamador esperaba
            }
            fields[count++] = p + 1;   // el siguiente campo empieza justo después
        }
        p++;
    }

    return count;
}