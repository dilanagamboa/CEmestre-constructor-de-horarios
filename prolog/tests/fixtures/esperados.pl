% resultados esperados, calculados a mano, de combinaciones_prueba.jsonl
% el orden de reglas por defecto es balance_carreras, limite_por_area e
% incompatibilidad, y la razon es la primera regla violada en ese orden
%
% esperado(Politica, Id, Cumple, Regla)
%   Politica: prueba (politica_prueba.pl) o sin_maximo (politica_sin_maximo.pl)
%   Regla: ninguna si cumple, si no la primera regla violada
%
% creditos por carrera escritos como computadores/fisica sobre el total

% politica_prueba.pl: computadores 60 %, fisica 80 %, N = 2
esperado(prueba,  1, true,  ninguna).           % 4/6 de 10, todo dentro
esperado(prueba,  2, false, balance_carreras).  % computadores 8 de 10 = 80 % > 60 %
esperado(prueba,  3, false, limite_por_area).   % tres cursos de fisica > 2
esperado(prueba,  4, false, incompatibilidad).  % FI1102 de las dos carreras
esperado(prueba,  5, false, balance_carreras).  % 8 de 12 = 66 % y tres de matematica, gana la regla 1
esperado(prueba,  6, false, balance_carreras).  % solo fisica: 100 % > 80 %
esperado(prueba,  7, false, balance_carreras).  % solo computadores: 100 % > 60 %
esperado(prueba,  8, true,  ninguna).           % computadores 6 de 10 = 60 % exacto, no lo supera
esperado(prueba,  9, false, limite_por_area).   % tres de fisica y par FI1102, gana la regla 2
esperado(prueba, 10, false, balance_carreras).  % un solo curso de fisica: 100 % > 80 %
esperado(prueba, 11, false, balance_carreras).  % viola las tres, 8 de 11 = 72 % > 60 %
esperado(prueba, 12, false, incompatibilidad).  % par EL2113-MT2001 declarado al reves
esperado(prueba, 13, false, balance_carreras).  % fisica 10 de 12 = 83 % > 80 %

% politica_sin_maximo.pl: computadores 60 %, fisica sin limite, N = 2
esperado(sin_maximo,  1, true,  ninguna).
esperado(sin_maximo,  2, false, balance_carreras).
esperado(sin_maximo,  3, false, limite_por_area).
esperado(sin_maximo,  4, false, incompatibilidad).
esperado(sin_maximo,  5, false, balance_carreras).
esperado(sin_maximo,  6, true,  ninguna).           % solo fisica, sin maximo definido
esperado(sin_maximo,  7, false, balance_carreras).
esperado(sin_maximo,  8, true,  ninguna).
esperado(sin_maximo,  9, false, limite_por_area).
esperado(sin_maximo, 10, true,  ninguna).           % un solo curso de fisica
esperado(sin_maximo, 11, false, balance_carreras).
esperado(sin_maximo, 12, false, incompatibilidad).
esperado(sin_maximo, 13, true,  ninguna).           % fisica 83 % sin limite

% casos donde cambiar el orden de las reglas cambia la razon reportada
% esperado_orden(Orden, Politica, Id, Regla)
esperado_orden([limite_por_area, balance_carreras, incompatibilidad], prueba, 5, limite_por_area).
esperado_orden([limite_por_area, balance_carreras, incompatibilidad], prueba, 11, limite_por_area).
esperado_orden([incompatibilidad, limite_por_area, balance_carreras], prueba, 9, incompatibilidad).
esperado_orden([incompatibilidad, balance_carreras, limite_por_area], prueba, 11, incompatibilidad).
