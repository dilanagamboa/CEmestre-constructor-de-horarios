% reglas de politica academica
% cada regla es una clausula de regla_violada/4, que tiene exito una vez
% por cada forma en que la combinacion incumple esa regla y devuelve el
% detalle del incumplimiento:
%
%   regla_violada(Regla, Politica, Combinacion, Detalle)
%
% Politica es el modulo donde se cargaron los hechos de la politica; los
% limites (porcentajes, N y pares) salen siempre de esos hechos y ninguno
% esta escrito aqui
%
% este modulo solo dice si una regla se viola; la primera regla violada y
% el veredicto se deciden en razon.pl

:- module(reglas, [
    regla_violada/4,
    creditos_totales/2,
    creditos_de_carrera/3,
    cursos_de_area/3
]).

:- use_module(library(lists)).
:- use_module(library(aggregate)).
:- use_module(cargar, [hecho_politica/2]).

% ------------------------------------------------------------------------
% regla 1: balance entre carreras
% una carrera incumple si sus creditos superan su porcentaje maximo del
% total de la combinacion; se compara 100 * Creditos > Maximo * Total para
% no dividir, asi el porcentaje exacto (60 % de 10) no se rechaza por un
% error de redondeo; una carrera sin porcentaje en la politica no tiene
% limite porque nunca se encuentra un Maximo para ella
% ------------------------------------------------------------------------
regla_violada(balance_carreras, Politica, combinacion(_, Cursos),
              carrera(Carrera, Creditos, Total, Maximo)) :-
    creditos_totales(Cursos, Total),
    creditos_de_carrera(Cursos, Carrera, Creditos),
    hecho_politica(Politica, max_porcentaje_carrera(Carrera, Maximo)),
    100 * Creditos > Maximo * Total.

% ------------------------------------------------------------------------
% regla 2: limite por area
% ninguna area puede tener mas de N cursos en la combinacion
% ------------------------------------------------------------------------
regla_violada(limite_por_area, Politica, combinacion(_, Cursos),
              area(Area, Cantidad, Maximo)) :-
    hecho_politica(Politica, max_cursos_por_area(Maximo)),
    cursos_de_area(Cursos, Area, Codigos),
    length(Codigos, Cantidad),
    Cantidad > Maximo.

% ------------------------------------------------------------------------
% predicados auxiliares
% ------------------------------------------------------------------------

creditos_totales(Cursos, Total) :-
    aggregate_all(sum(Creditos), member(curso(_, _, Creditos, _, _), Cursos), Total).

% creditos que aporta cada carrera presente en la combinacion
% con Carrera libre enumera las carreras, con Carrera dada calcula o
% verifica sus creditos; una carrera ausente no tiene solucion
creditos_de_carrera(Cursos, Carrera, Creditos) :-
    setof(K, Co^G^Cr^Ar^member(curso(Co, G, Cr, K, Ar), Cursos), Carreras),
    member(Carrera, Carreras),
    aggregate_all(sum(C), member(curso(_, _, C, Carrera, _), Cursos), Creditos).

% codigos de los cursos de cada area presente en la combinacion
% con Area libre enumera las areas, con Area dada da sus cursos
cursos_de_area(Cursos, Area, Codigos) :-
    setof(A, Co^G^Cr^K^member(curso(Co, G, Cr, K, A), Cursos), Areas),
    member(Area, Areas),
    findall(Codigo, member(curso(Codigo, _, _, _, Area), Cursos), Codigos).