function [f0_g, Ydd_g, Ydq_g, Yqd_g, Yqq_g] = read_data(file_name)
    % LEGGI_DATI Reads data from a file and converts it into separate
    % output variables. File format is specifically from Z-Tool output.
    %
    % INPUT:
    %   file_name - Name of the file containing the data to be read.
    %
    % OUTPUT:
    %   f0_g    - Frequency data extracted from the file.
    %   Ydd_g   - DQ frame element (1,1) from the file.
    %   Ydq_g   - DQ frame element (1,2) from the file.
    %   Yqd_g   - DQ frame element (2,1) from the file.
    %   Yqq_g   - DQ frame element (2,2) from the file.
    %
    % AUTHOR:
    %   Nicolae Darii (DTU and Siemens Gamesa)
    %
    % LICENSED UNDER:
    %   MIT License (see LICENSE file in the repository).
    %
    
    % Leggi tutto il file come testo, separato da tab, saltando header
    T_g = readtable(file_name, ...
        'Delimiter', '\t', ...
        'ReadVariableNames', false, ...
        'NumHeaderLines', 1, ...
        'TextType', 'string');

    % Rimuovi parentesi tonde dai numeri complessi
    T_g = varfun(@(s) erase(erase(s, "("), ")"), T_g);

    % Converti stringhe complesse in double complessi
    data = zeros(height(T_g), width(T_g));
    for c = 1:width(T_g)
        data(:, c) = arrayfun(@(s) str2num(s), T_g.(c)); %#ok<ST2NM>
    end

    % Output variabili (trasposte come nell'originale)
    f0_g = data(:, 1).';
    Ydd_g = data(:, 2).';
    Ydq_g = data(:, 3).';
    Yqd_g = data(:, 4).';
    Yqq_g = data(:, 5).';
end
