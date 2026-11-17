% carga de las entradas de la etapa 3
% - combinaciones: la salida de racket en JSON Lines, una combinacion por
%   linea, que se entrega por backtracking como un termino
%       combinacion(Id, Cursos)
%       Cursos = [curso(Codigo, Grupo, Creditos, Carrera, Area), ...]
%
% no se usa assert, retract ni variables globales: las combinaciones viajan
% como argumentos
%
% todos los errores se lanzan como cemestre_error(Formato, Argumentos),
% listos para format/2, y main los convierte en un mensaje y un codigo de
% salida distinto de cero

:- module(cargar, [
    abrir_combinaciones/2,
    combinacion_leida/2,
    leer_combinaciones/2
]).

:- use_module(library(http/json)).
:- use_module(library(lists)).

% ------------------------------------------------------------------------
% combinaciones
% ------------------------------------------------------------------------

abrir_combinaciones(Ruta, Entrada) :-
    (   exists_file(Ruta)
    ->  true
    ;   throw(cemestre_error("no existe el archivo de combinaciones ~w", [Ruta]))
    ),
    open(Ruta, read, Entrada, [encoding(utf8)]).

% da una combinacion por cada solucion; quien la llama recorre el archivo
% completo por backtracking (con forall o un fallo forzado) y nunca se
% guarda el archivo entero en memoria
% las lineas vacias se saltan fallando hacia el repeat; el corte del final
% de archivo elimina el punto de eleccion del repeat, que si no reintentaria
% leer para siempre
combinacion_leida(Entrada, Combinacion) :-
    repeat,
    line_count(Entrada, Linea),
    read_line_to_string(Entrada, Texto),
    (   Texto == end_of_file
    ->  !, fail
    ;   linea_vacia(Texto)
    ->  fail
    ;   texto_a_combinacion(Texto, Linea, Combinacion)
    ).

% todas las combinaciones de un archivo en una lista; solo se usa en las
% pruebas, el programa principal recorre el archivo con combinacion_leida/2
leer_combinaciones(Ruta, Combinaciones) :-
    abrir_combinaciones(Ruta, Entrada),
    call_cleanup(findall(C, combinacion_leida(Entrada, C), Combinaciones),
                 close(Entrada)).

linea_vacia(Texto) :-
    split_string(Texto, "", " \t\r", [""]).

texto_a_combinacion(Texto, Linea, Combinacion) :-
    catch(atom_json_dict(Texto, Dict, []), _,
          throw(cemestre_error("linea ~w: no es un JSON valido", [Linea]))),
    (   is_dict(Dict)
    ->  true
    ;   throw(cemestre_error("linea ~w: se esperaba un objeto JSON", [Linea]))
    ),
    dict_a_combinacion(Dict, Linea, Combinacion).

dict_a_combinacion(Dict, Linea, combinacion(Id, Cursos)) :-
    campo(Dict, id, Linea, Id),
    entero_minimo(Id, 1, id, Linea),
    campo(Dict, courses, Linea, Lista),
    (   is_list(Lista), Lista \== []
    ->  true
    ;   throw(cemestre_error("linea ~w: courses debe ser una lista no vacia", [Linea]))
    ),
    maplist(dict_a_curso(Linea), Lista, Cursos).

dict_a_curso(Linea, Dict, curso(Codigo, Grupo, Creditos, Carrera, Area)) :-
    (   is_dict(Dict)
    ->  true
    ;   throw(cemestre_error("linea ~w: cada curso debe ser un objeto JSON", [Linea]))
    ),
    campo_atomo(Dict, code, Linea, Codigo),
    campo(Dict, group, Linea, Grupo),
    entero_minimo(Grupo, 1, group, Linea),
    campo(Dict, credits, Linea, Creditos),
    entero_minimo(Creditos, 0, credits, Linea),
    campo_atomo(Dict, career, Linea, Carrera),
    campo_atomo(Dict, area, Linea, Area).

campo(Dict, Clave, Linea, Valor) :-
    (   get_dict(Clave, Dict, Valor)
    ->  true
    ;   throw(cemestre_error("linea ~w: falta el campo ~w", [Linea, Clave]))
    ).

% texto no vacio convertido a atomo, para compararlo con los hechos de la
% politica (computadores-'FI1102')
campo_atomo(Dict, Clave, Linea, Atomo) :-
    campo(Dict, Clave, Linea, Texto),
    (   string(Texto), Texto \== ""
    ->  atom_string(Atomo, Texto)
    ;   throw(cemestre_error("linea ~w: ~w debe ser un texto no vacio", [Linea, Clave]))
    ).

entero_minimo(Valor, Minimo, Clave, Linea) :-
    (   integer(Valor), Valor >= Minimo
    ->  true
    ;   throw(cemestre_error("linea ~w: ~w debe ser un entero mayor o igual a ~w",
                             [Linea, Clave, Minimo]))
    ).