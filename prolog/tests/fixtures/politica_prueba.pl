% politica de prueba para los casos de combinaciones_prueba.jsonl
% valores distintos a data/politica.pl a proposito, para que los casos
% limite queden en numeros faciles de revisar a mano

max_porcentaje_carrera(computadores, 60).
max_porcentaje_carrera(fisica, 80).

max_cursos_por_area(2).

par_incompatible(computadores-'FI1102', fisica-'FI1102').
% declarado al reves que el anterior para probar que la regla es simetrica
par_incompatible(fisica-'MT2001', computadores-'EL2113').
