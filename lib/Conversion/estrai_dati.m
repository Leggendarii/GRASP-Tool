function tabella = estrai_dati(nome_file)
    % ESTRAI_DATI Reads data from a CSV file and outputs it as a table.
    %
    % INPUT:
    %   nome_file - Name of the CSV file to read data from.
    %
    % OUTPUT:
    %   tabella   - Table containing the data read from the file.
    %
    % AUTHOR:
    %   Nicolae Darii (DTU and Siemens Gamesa)
    %
    % LICENSED UNDER:
    %   MIT License (see LICENSE file in the repository).
    %
    
    % Read data from the specified CSV file with header row
    dati = readtable(nome_file, 'Delimiter', ',', 'ReadVariableNames', true);
    
    % Output the data as a table
    tabella = dati;
    
    % Optionally display the table (commented out)
    % disp(tabella);
end
