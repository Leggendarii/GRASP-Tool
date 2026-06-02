function E = exchange(E)
    % EXCHANGE Swaps components if necessary based on distance.
    %
    % INPUT:
    %   E   - Matrix containing the components to be swapped (2xN).
    %
    % OUTPUT:
    %   E   - Modified matrix after performing the swap operation.
    %
    % AUTHOR:
    %   Nicolae Darii (DTU and Siemens Gamesa)
    %
    % LICENSED UNDER:
    %   MIT License (see LICENSE file in the repository).
    %

    [rows, cols] = size(E);
    
    % Iterate over the columns of the matrix
    for j = 2:cols  % starts from the second column
        dist1 = distance(E(1,j), E(1,j-1));  % distance between E(1,j) and E(1,j-1)
        dist2 = distance(E(1,j), E(2,j-1));  % distance between E(1,j) and E(2,j-1)
        
        % If E(1,j) is farther from E(1,j-1) than from E(2,j-1), swap them
        if dist1 > dist2
            % Swap the values
            temp = E(1,j);
            E(1,j) = E(2,j);
            E(2,j) = temp;
        end
    end
end
