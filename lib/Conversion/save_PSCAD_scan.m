function save_PSCAD_scan(name_vsc, name_grid)
    % SAVE_PSCAD_SCAN Reads PSCAD impedance data for converter and grid,
    % combines them into a single table, and saves the result as a CSV file
    % in the 'data' directory.
    %
    % INPUT:
    %   name_vsc  - File name containing the converter (VSC) impedance data.
    %   name_grid - File name containing the grid impedance data.
    %
    % OUTPUT:
    %   No direct output arguments. The function saves a CSV file
    %   containing frequency and DQ impedance components for both converter
    %   and grid into the 'data' folder.
    %
    % AUTHOR:
    %   Nicolae Darii (DTU and Siemens Gamesa)
    %
    % LICENSED UNDER:
    %   MIT License (see LICENSE file in the repository).
    %

    [f_g, Ydd_g, Ydq_g, Yqd_g, Yqq_g] = read_data(name_grid);
    [f_c, Ydd_c, Ydq_c, Yqd_c, Yqq_c] = read_data(name_vsc);

    % Prompt the user for the output file name
    name = input('Enter the file name (without extension): ', 's');

    % Create a table combining converter and grid impedance data
    T = table(f_c', Ydd_c', Ydq_c', Yqd_c', Yqq_c', ...
              Ydd_g', Ydq_g', Yqd_g', Yqq_g', ...
              'VariableNames', {'f', 'Ydd_c', 'Ydq_c', 'Yqd_c', 'Yqq_c', ...
                                'Ydd_g', 'Ydq_g', 'Yqd_g', 'Yqq_g'});

    % Create the output folder if it does not exist
    if ~exist('data', 'dir')
        mkdir('data');
    end

    % Save the combined table as a CSV file
    writetable(T, fullfile('data', name + ".csv"));
end
