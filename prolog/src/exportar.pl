% exportar.pl
% Exportación del resultado: escribe un registro JSON Lines por combinación
% al evaluarse, sin acumularlos en memoria.
%
% Veredicto viene de razon:evaluar_combinacion/3:
%   Veredicto = cumple
%   Veredicto = viola(Regla, Detalle)
%
% Detalle depende de la regla:
%   balance_carreras: carrera(Carrera, Creditos, Total, Maximo)
%   limite_por_area:  area(Area, Cantidad, Maximo)
%   incompatibilidad: par(A, B)
%
% Todo registro lleva "cursos" con los pares curso-grupo elegidos, que es
% la salida mínima que pide el enunciado (D4).
%
% Codificación: los datos reales traen tildes y caracteres especiales (los
% nombres de cursos y las descripciones de las reglas), así que el módulo
% se declara con encoding(utf8) para evitar warnings de secuencias multibyte
% ilegales y corrupción de salida.

:- encoding(utf8).

:- module(exportar, [escribir_resultado/3]).

:- use_module(constantes, [regla/2]).
:- use_module(reglas, [creditos_totales/2, cursos_de_area/3]).

% escribir_resultado(+Combinacion, +Veredicto, +Salida)
% Combinacion = combinacion(Id, Cursos); Salida es el stream abierto.
% Cada línea es un objeto JSON autocontenido (JSON Lines).

escribir_resultado(combinacion(Id, Cursos), cumple, Salida) :-
    creditos_totales(Cursos, CreditosTotales),
    lista_json_cursos(Cursos, CursosJson),
    format(Salida,
           '{"id":~w,"cursos":[~s],"cumple":true,"razon":"ninguna","razon_descripcion":"","creditos_totales":~w,"detalle":{},"cursos_areas":[]}~n',
           [Id, CursosJson, CreditosTotales]).

escribir_resultado(combinacion(Id, Cursos), viola(Regla, Detalle), Salida) :-
    creditos_totales(Cursos, CreditosTotales),
    lista_json_cursos(Cursos, CursosJson),
    (   Detalle = carrera(Carrera, Creditos, Total, Maximo)
    ->  escribir_razon_balance(Id, CursosJson, Regla, Carrera, Creditos, Total, Maximo, CreditosTotales, Salida)
    ;   Detalle = area(Area, Cantidad, Maximo)
    ->  escribir_razon_area(Id, CursosJson, Regla, Area, Cantidad, Maximo, Cursos, CreditosTotales, Salida)
    ;   Detalle = par(A, B)
    ->  escribir_razon_incompatibilidad(Id, CursosJson, Regla, A, B, CreditosTotales, Salida)
    ;   escribir_razon_generica(Id, CursosJson, Regla, CreditosTotales, Salida)
    ).

% razon 1: balance entre carreras
escribir_razon_balance(Id, CursosJson, Regla, Carrera, Creditos, Total, Maximo, CreditosTotales, Salida) :-
    regla(Regla, Desc),
    format(Salida,
           '{"id":~w,"cursos":[~s],"cumple":false,"razon":"~w","razon_descripcion":"~w","creditos_totales":~w,"detalle":{"carrera":"~w","creditos_carrera":~w,"creditos_totales":~w,"maximo_porcentaje":~w},"cursos_areas":[]}~n',
           [Id, CursosJson, Regla, Desc, CreditosTotales, Carrera, Creditos, Total, Maximo]).

% razon 2: limite por area
escribir_razon_area(Id, CursosJson, Regla, Area, Cantidad, Maximo, Cursos, CreditosTotales, Salida) :-
    regla(Regla, Desc),
    cursos_de_area(Cursos, Area, Codigos),
    lista_json_strings(Codigos, CodigosJson),
    format(Salida,
           '{"id":~w,"cursos":[~s],"cumple":false,"razon":"~w","razon_descripcion":"~w","creditos_totales":~w,"detalle":{"area":"~w","cantidad":~w,"maximo":~w,"cursos":[~s]},"cursos_areas":[~s]}~n',
           [Id, CursosJson, Regla, Desc, CreditosTotales, Area, Cantidad, Maximo, CodigosJson, CodigosJson]).

% razon 3: incompatibilidad
escribir_razon_incompatibilidad(Id, CursosJson, Regla, A, B, CreditosTotales, Salida) :-
    regla(Regla, Desc),
    format(Salida,
           '{"id":~w,"cursos":[~s],"cumple":false,"razon":"~w","razon_descripcion":"~w","creditos_totales":~w,"detalle":{"par":["~w","~w"]},"cursos_areas":[]}~n',
           [Id, CursosJson, Regla, Desc, CreditosTotales, A, B]).

% fallback si el detalle no coincide con lo esperado
escribir_razon_generica(Id, CursosJson, Regla, CreditosTotales, Salida) :-
    regla(Regla, Desc),
    format(Salida,
           '{"id":~w,"cursos":[~s],"cumple":false,"razon":"~w","razon_descripcion":"~w","creditos_totales":~w,"detalle":{},"cursos_areas":[]}~n',
           [Id, CursosJson, Regla, Desc, CreditosTotales]).

% lista_json_cursos(+Cursos, -Json)
% Pares curso-grupo como objetos JSON: {"carrera":..,"codigo":..,"grupo":..}
lista_json_cursos(Cursos, Json) :-
    maplist(curso_json, Cursos, Partes),
    atomic_list_concat(Partes, ',', Json).

curso_json(curso(Codigo, Grupo, _, Carrera, _), Texto) :-
    format(string(Texto), '{"carrera":"~w","codigo":"~w","grupo":~w}',
           [Carrera, Codigo, Grupo]).

% lista_json_strings(+Lista, -Json)
% Convierte una lista de átomos en una cadena JSON: "a","b","c"
% se usa atomic_list_concat para que un solo elemento (incluso de un solo
% carácter, como "a") quede entre comillas sin coma suelta; la lista vacía
% produce la cadena vacía, igual que antes
lista_json_strings(Lista, Json) :-
    findall(CodigoJson,
            (member(X, Lista),
             format(string(CodigoJson), '"~w"', [X])),
            Partes),
    atomic_list_concat(Partes, ',', Json).
