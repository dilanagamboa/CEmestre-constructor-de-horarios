% politica academica de la etapa 3 (borrador)
% todos los valores de las reglas salen de estos hechos, ninguno queda
% escrito dentro del codigo de las reglas

% regla 1: porcentaje maximo de los creditos de la combinacion que puede
% aportar cada carrera; una carrera sin hecho aqui no tiene limite
max_porcentaje_carrera(computadores, 70).
max_porcentaje_carrera(fisica, 70).

% regla 2: maximo de cursos de una misma area en una combinacion
max_cursos_por_area(3).

% regla 3: pares de cursos que no pueden ir juntos en una combinacion
% cada curso se escribe como Carrera-Codigo, porque un mismo codigo puede
% estar en las dos carreras; la relacion es simetrica, asi que cada par se
% declara una sola vez y el orden dentro del par no importa

% el mismo curso en los dos planes: llevarlo dos veces no suma formacion
par_incompatible(computadores-'FI1102', fisica-'FI1102').   % Fisica general II
par_incompatible(computadores-'FI1202', fisica-'FI1202').   % Laboratorio de fisica general II
par_incompatible(computadores-'MA2104', fisica-'MA2104').   % Calculo superior

% codigos distintos con el mismo contenido central en cada plan
par_incompatible(computadores-'EL2113', fisica-'MT2001').   % circuitos de corriente continua
par_incompatible(computadores-'PI2609', fisica-'PI2610').   % probabilidad y estadistica
par_incompatible(computadores-'CE1111', fisica-'MA3106').   % metodos numericos