% igual que politica_prueba.pl, pero fisica no tiene porcentaje maximo
% (decision D6: una carrera sin hecho de porcentaje no tiene limite)

max_porcentaje_carrera(computadores, 60).

max_cursos_por_area(2).

par_incompatible(computadores-'FI1102', fisica-'FI1102').
par_incompatible(fisica-'MT2001', computadores-'EL2113').
