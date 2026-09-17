#ifndef UTILS_H
#define UTILS_H

#include <stddef.h>

// quita espacios, tabs y saltos de línea al inicio y al final de str, en el mismo buffer
void trim_whitespace(char *str);

// copia src a dest sin desbordar dest_size, garantizando siempre '\0' al final
// devuelve 1 si cupo completo
int safe_strcpy(char *dest, size_t dest_size, const char *src);

// split in-place por 'delimiter' ('\0' en cada uno), 'fields' es un arreglo de punteros
// al inicio de cada campo, vacíos incluidos (a diferencia de strtok).

// devuelve el n de campos, o -1 si > max_fields
int split_fields(char *line, char delimiter, char *fields[], int max_fields);

#endif