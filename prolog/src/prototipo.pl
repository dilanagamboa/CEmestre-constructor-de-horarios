% prototipo de la fase 0
% lee las combinaciones de racket una por una, arma el termino
% combinacion(Id, Cursos) y evalua la regla de balance contra la politica
%
% uso desde la raiz del repositorio:
%   swipl prolog/src/prototipo.pl data/combinaciones.jsonl data/politica.pl

:- use_module(library(http/json)).

:- initialization(main, main).

main(Argumentos) :-
    rutas(Argumentos, RutaCombinaciones, RutaPolitica),
    consult(RutaPolitica),
    setup_call_cleanup(
        open(RutaCombinaciones, read, Entrada, [encoding(utf8)]),
        forall(combinacion_leida(Entrada, Combinacion),
               mostrar_veredicto(Combinacion)),
        close(Entrada)).

% rutas por defecto si no se pasan argumentos
rutas([], 'data/combinaciones.jsonl', 'data/politica.pl').
rutas([C], C, 'data/politica.pl').
rutas([C, P | _], C, P).

% da una combinacion por cada solucion, de modo que forall recorre el
% archivo completo por backtracking sin cargarlo entero en memoria
% el corte detiene el repeat al llegar al final del archivo
combinacion_leida(Entrada, Combinacion) :-
    repeat,
    json_read_dict(Entrada, Dict, [end_of_file(fin)]),
    (   Dict == fin
    ->  !, fail
    ;   dict_a_combinacion(Dict, Combinacion)
    ).

dict_a_combinacion(Dict, combinacion(Id, Cursos)) :-
    get_dict(id, Dict, Id),
    get_dict(courses, Dict, ListaCursos),
    maplist(dict_a_curso, ListaCursos, Cursos).

% el area todavia no viene de racket, se marca como sin_area
dict_a_curso(Dict, curso(Codigo, Grupo, Creditos, Carrera, Area)) :-
    get_dict(code, Dict, TextoCodigo),
    atom_string(Codigo, TextoCodigo),
    get_dict(group, Dict, Grupo),
    get_dict(credits, Dict, Creditos),
    get_dict(career, Dict, TextoCarrera),
    atom_string(Carrera, TextoCarrera),
    (   get_dict(area, Dict, TextoArea)
    ->  atom_string(Area, TextoArea)
    ;   Area = sin_area
    ).

% regla 1 de ejemplo: alguna carrera supera su porcentaje maximo
% se compara con enteros (100 * C > Max * T) para no usar division
viola_balance(combinacion(_, Cursos), Carrera) :-
    total_creditos(Cursos, Total),
    Total > 0,
    max_porcentaje_carrera(Carrera, Maximo),
    creditos_de_carrera(Cursos, Carrera, CreditosCarrera),
    100 * CreditosCarrera > Maximo * Total.

total_creditos(Cursos, Total) :-
    findall(C, member(curso(_, _, C, _, _), Cursos), Lista),
    sum_list(Lista, Total).

creditos_de_carrera(Cursos, Carrera, Suma) :-
    findall(C, member(curso(_, _, C, Carrera, _), Cursos), Lista),
    sum_list(Lista, Suma).

mostrar_veredicto(Combinacion) :-
    Combinacion = combinacion(Id, Cursos),
    length(Cursos, N),
    (   viola_balance(Combinacion, Carrera)
    ->  format("~w (~w cursos): viola balance (~w)~n", [Id, N, Carrera])
    ;   format("~w (~w cursos): cumple~n", [Id, N])
    ).