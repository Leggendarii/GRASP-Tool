function save_PSCAD_reference(txt_name)
    % SAVE_PSCAD_REFERENCE Reads reference data from a text file,
    % extracts the first three columns (time and two values), and saves
    % them as a CSV file in the 'data' folder.
    %
    % INPUT:
    %   txt_name - Name of the text file containing the reference data.
    %
    % OUTPUT:
    %   No direct outputs. The function saves a CSV file named
    %   'reference_case_PSCAD.csv' in the 'data' directory.
    %
    % AUTHOR:
    %   Nicolae Darii (DTU and Siemens Gamesa)
    %
    % LICENSED UNDER:
    %   MIT License (see LICENSE file in the repository).
    %
    
    % Extract data table from the input file
    T = estrai_dati(txt_name);

    % Extract individual columns for time and values
    Time = T{:,1};
    Val1 = T{:,2};
    Val2 = T{:,3};

    % Create a new table with labeled columns
    T = table(Time, Val1, Val2, 'VariableNames', {'Time', 'Val1', 'Val2'});

    % Save the table as a CSV file in the 'data' folder
    writetable(T, fullfile('data', 'reference_case_PSCAD.csv'));
end
