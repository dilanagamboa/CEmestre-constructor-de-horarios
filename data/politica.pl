% politica academica de la etapa 3 (borrador)
% todos los valores de las reglas salen de estos hechos, ninguno queda
% escrito dentro del codigo de las reglas

% regla 1: porcentaje maximo de los creditos de la combinacion que puede
% aportar cada carrera; una carrera sin hecho aqui no tiene limite
max_porcentaje_carrera(computadores, 70).
max_porcentaje_carrera(fisica, 70).

% regla 2: maximo de cursos de una misma area en una combinacion
max_cursos_por_area(3).

% regla 3: pares incompatibles, se definen en la fase 1 con los cursos
% de los semestres 7 y 8