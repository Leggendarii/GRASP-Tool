function frecresmatrix = expfracpar1(degree, poles_mat, poles, residues, vectorfrec)
% expfracpar1 - Computes the frequency response matrix based on pole-residue representation.
%
% Syntax:
%   frecresmatrix = expfracpar1(degree, poles_mat, residuos, vectorfrec)
%
% Inputs:
%   degree       - Degree of the system (number of poles).
%   poles_mat    - Diagonal matrix containing the poles of the system.
%   residues     - Residue vector associated with the poles.
%   vectorfrec   - Frequency vector over which the response is calculated.
%
% Outputs:
%   MatrizRespFrec - Matrix representing the frequency response of the system.

    % Step 1: Initialize c-index to classify the poles (real or complex-conjugate pairs)
    cindex = zeros(1, degree); % Array to indicate pole type: 0 = real, 1 = start of complex pair, 2 = end of complex pair
    for m = 1:degree
        if imag(poles(m)) ~= 0 % Check if the pole is complex
            if m == 1
                cindex(m) = 1; % Start of a complex-conjugate pair
            else
                if cindex(m-1) == 0 || cindex(m-1) == 2
                    cindex(m) = 1; % Mark as the start of a new complex-conjugate pair
                    cindex(m+1) = 2; % Mark the next pole as the end of the pair
                else
                    cindex(m) = 2; % Mark as the end of an ongoing complex-conjugate pair
                end
            end
        end
    end

    % Step 2: Initialize the frequency response matrix
    samples=length(vectorfrec);
    frecresmatrix = zeros(samples, degree); % Preallocate the matrix for efficiency

    % Step 3: Calculate the frequency response for each pole
    for m = 1:degree
        if cindex(m) == 0 % Real pole
            frecresmatrix(:, m) = residues(m) ./ (vectorfrec - poles(m));
        elseif cindex(m) == 1 % Start of a complex-conjugate pair
            % Frequency response for the real and imaginary parts of the complex pair
            frecresmatrix(:, m) = ...
                residues(m) ./ (vectorfrec - poles(m)) + ...
                conj(residues(m)) ./ (vectorfrec - conj(poles(m)));
            frecresmatrix(:, m+1) = ...
                1i * residues(m) ./ (vectorfrec - poles(m)) - ...
                1i * conj(residues(m)) ./ (vectorfrec - conj(poles(m)));
        end
    end
end
