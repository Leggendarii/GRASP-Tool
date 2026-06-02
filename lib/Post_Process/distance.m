function d = distance(z1, z2)
    % DISTANCE Calculates the distance between two complex numbers.
    %
    % INPUT:
    %   z1    - First complex number.
    %   z2    - Second complex number.
    %
    % OUTPUT:
    %   d     - Distance between the two complex numbers.
    %
    % AUTHOR:
    %   Nicolae Darii (DTU and Siemens Gamesa)
    %
    % LICENSED UNDER:
    %   MIT License (see LICENSE file in the repository).
    %

    d = abs(z1 - z2);
end
