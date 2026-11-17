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

:- module(exportar, [escribir_resultado/3]).

:- use_module(constantes, [regla/2]).
:- use_module(reglas, [creditos_totales/2, cursos_de_area/3]).

% escribir_resultado(+Combinacion, +Veredicto, +Salida)
% Combinacion = combinacion(Id, Cursos); Salida es el stream abierto.
% Cada línea es un objeto JSON autocontenido (JSON Lines).

escribir_resultado(combinacion(Id, Cursos), cumple, Salida) :-
    creditos_totales(Cursos, CreditosTotales),
    format(Salida,
           '{"id":~w,"cumple":true,"razon":"ninguna","razon_descripcion":"","creditos_totales":~w,"detalle":{},"cursos_areas":[]}~n',
           [Id, CreditosTotales]).

escribir_resultado(combinacion(Id, Cursos), viola(Regla, Detalle), Salida) :-
    creditos_totales(Cursos, CreditosTotales),
    (   Detalle = carrera(Carrera, Creditos, Total, Maximo)
    ->  escribir_razon_balance(Id, Regla, Carrera, Creditos, Total, Maximo, CreditosTotales, Salida)
    ;   Detalle = area(Area, Cantidad, Maximo)
    ->  escribir_razon_area(Id, Regla, Area, Cantidad, Maximo, Cursos, CreditosTotales, Salida)
    ;   Detalle = par(A, B)
    ->  escribir_razon_incompatibilidad(Id, Regla, A, B, CreditosTotales, Salida)
    ;   escribir_razon_generica(Id, Regla, CreditosTotales, Salida)
    ).

% razon 1: balance entre carreras
escribir_razon_balance(Id, Regla, Carrera, Creditos, Total, Maximo, CreditosTotales, Salida) :-
    regla(Regla, Desc),
    format(Salida,
           '{"id":~w,"cumple":false,"razon":"~w","razon_descripcion":"~w","creditos_totales":~w,"detalle":{"carrera":"~w","creditos_carrera":~w,"creditos_totales":~w,"maximo_porcentaje":~w},"cursos_areas":[]}~n',
           [Id, Regla, Desc, CreditosTotales, Carrera, Creditos, Total, Maximo]).

% razon 2: limite por area
escribir_razon_area(Id, Regla, Area, Cantidad, Maximo, Cursos, CreditosTotales, Salida) :-
    regla(Regla, Desc),
    cursos_de_area(Cursos, Area, Codigos),
    lista_json_strings(Codigos, CodigosJson),
    format(Salida,
           '{"id":~w,"cumple":false,"razon":"~w","razon_descripcion":"~w","creditos_totales":~w,"detalle":{"area":"~w","cantidad":~w,"maximo":~w,"cursos":[~s]},"cursos_areas":[~s]}~n',
           [Id, Regla, Desc, CreditosTotales, Area, Cantidad, Maximo, CodigosJson, CodigosJson]).

% razon 3: incompatibilidad
escribir_razon_incompatibilidad(Id, Regla, A, B, CreditosTotales, Salida) :-
    regla(Regla, Desc),
    format(Salida,
           '{"id":~w,"cumple":false,"razon":"~w","razon_descripcion":"~w","creditos_totales":~w,"detalle":{"par":["~w","~w"]},"cursos_areas":[]}~n',
           [Id, Regla, Desc, CreditosTotales, A, B]).

% fallback si el detalle no coincide con lo esperado
escribir_razon_generica(Id, Regla, CreditosTotales, Salida) :-
    regla(Regla, Desc),
    format(Salida,
           '{"id":~w,"cumple":false,"razon":"~w","razon_descripcion":"~w","creditos_totales":~w,"detalle":{},"cursos_areas":[]}~n',
           [Id, Regla, Desc, CreditosTotales]).

% lista_json_strings(+Lista, -Json)
% Convierte una lista de átomos en una cadena JSON: "a","b","c"
lista_json_strings([], "").
lista_json_strings([A], String) :-
    format(string(String), '"~w"', [A]).
lista_json_strings([A | Resto], String) :-
    format(string(Prefijo), '"~w",', [A]),
    lista_json_strings(Resto, RestoString),
    string_concat(Prefijo, RestoString, String).
