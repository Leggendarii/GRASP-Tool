function system_f = PCCF1(Y, jw1, poles, weight, pole_tol, red_mode, opts)
    
% PCCF1: Performs vector fitting and SVD/balanced realization while checking stability.
    % Inputs:
    %   Y - Frequency response data (complex 1xfd0 vector)
    %   j*2*pi*fd0 - Complex frequency points (rad/s)
    %   poles - Initial poles (complex vector)
    %   weight - Weight vector for fitting
    %   pole_tol - Tolerance for pole convergence
    %   red_mode is the reduced-order methodology for the fitted state-space
    %   opts - Options for the vector fitting method
    % Outputs:
    %   system_f - Balanced and stable state-space system

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % GNU General Public License v3.0 (GPL-3.0)
    % Copyright (C) 2025 Luis Angel Garcia Reyes, UPC-MSCA-ADOreD
    % Email: luis.reyes@upc.edu
    % This program is free software: you can redistribute it and/or modify it 
    % under the terms of the GNU General Public License as published by the 
    % Free Software Foundation, either version 3 of the License, or (at your 
    % option) any later version.
    % This program is distributed in the hope that it will be useful, but 
    % WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
    % or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
    % for more details.
    % You should have received a copy of the GNU General Public License along 
    % with this program. If not, see <https://www.gnu.org/licenses/>.
    
    % This work has received funding from the ADOreD project
    % under the European Union’s Horizon Europe Research and 
    % Innovation Programme under the Marie Skłodowska-Curie 
    % Grant Agreement No. 101073554.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% Initialize variables
    
    iteration = 0; % Iteration counter
    max_iterations = 20; % Maximum number of iterations to prevent infinite loops
    pole_diff = Inf; % Initialize pole difference to a large value
    degree=length(poles); % Identifying the degree of the fitting
    
    %% Iterative vector fitting

    while pole_diff > pole_tol
        iteration = iteration + 1;
        
        % Perform vector fitting
        [States1, new_poles1, error_rms1, Yinnueva1] = vectfit3(Y, jw1, poles, weight, opts);
        
        % Calculate the maximum difference between old and new poles
        pole_diff = max(abs(new_poles1 - poles));
        
        % Update poles
        poles = new_poles1;
        
        % Break if max iterations are exceeded
        if iteration >= max_iterations
            warning('Maximum number of iterations reached. Pole fitting may not have converged.');
            break;
        end
    end

    %% Construct full state-space system
    A1 = full(States1.A); % State matrix A with poles
    B1 = States1.B; % Input vector B
    C1 = States1.C; % Output vector C
    D1 = States1.D; % Direct transmission term D
    system_full = ss(A1, B1, C1, D1);

    %% Check stability of the initial system
    if ~isstable(system_full)
        response = input('The initial system is unstable. Do you want to continue? (y/n): ', 's');
        if lower(response) ~= 'y'
            error('Execution stopped due to system instability.');
        end
    end

    %% Reducing the order by SVD or BR

switch red_mode
    case 1
    % Perform balanced realization (br)
    br_tol = 5E-4;
    system_f = BalancedRealization(system_full, br_tol);
    case 2
    % Perform singular value descomposition (svd)
    svd_tol = 1E-10;
    Q = expfracpar1(degree, A1, poles, C1, jw1);
    [system_f, g, Cred, q] = singularvd1(Q, Y, svd_tol, C1, D1, poles, degree);
end

    %% Check stability of the balanced system
    if ~isstable(system_f)
        response = input('The balanced system is unstable. Do you want to continue? (y/n): ', 's');
        if lower(response) ~= 'y'
            error('Execution stopped due to balanced system instability.');
        end
    end

    %% Display convergence information
    fprintf('Pole fitting converged after %d iterations.\n', iteration);
end

