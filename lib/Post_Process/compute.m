function [E,L, Y_c_dq, Y_g_dq, Y_c_pn, Y_g_pn] = compute(f_g, Ydd_g, Ydq_g, Yqd_g, Yqq_g, ...
                                                                   f_c, Ydd_c, Ydq_c, Yqd_c, Yqq_c)
    % COMPUTE Computes eigenvalues and admittance matrices in dq and pn frames.
    %
    % INPUT:
    %   f_g     - Frequency vector for generator.
    %   Ydd_g   - d-d component of generator admittance (vector).
    %   Ydq_g   - d-q component of generator admittance (vector).
    %   Yqd_g   - q-d component of generator admittance (vector).
    %   Yqq_g   - q-q component of generator admittance (vector).
    %   f_c     - Frequency vector for controller.
    %   Ydd_c   - d-d component of controller admittance (vector).
    %   Ydq_c   - d-q component of controller admittance (vector).
    %   Yqd_c   - q-d component of controller admittance (vector).
    %   Yqq_c   - q-q component of controller admittance (vector).
    %
    % OUTPUT:
    %   E       - Matrix of eigenvalues for each frequency (2 x N).
    %   L       - Matrix of open loop gain matrix for each frequency (2 x N).
    %   Y_c_dq  - Controller admittance matrices in dq frame (2 x 2 x N).
    %   Y_g_dq  - Generator admittance matrices in dq frame (2 x 2 x N).
    %   Y_c_pn  - Controller admittance matrices in pn frame (2 x 2 x N).
    %   Y_g_pn  - Generator admittance matrices in pn frame (2 x 2 x N).
    %
    % DESCRIPTION:
    %   This function constructs admittance matrices for both generator and controller
    %   in the dq frame, computes their inverses, calculates the open-loop gain, and
    %   determines the eigenvalues for each frequency. It also converts the dq matrices
    %   to the positive-negative sequence (pn) frame.
    %
    % NOTE:
    %   The function assumes f_g and f_c are of the same length and aligned in frequency.
    %   If not, interpolation or alignment is required before calling this function.
    %
    % AUTHOR:
    %   Nicolae Darii (DTU and Siemens Gamesa)
    %
    % LICENSED UNDER:
    %   MIT License (see LICENSE file in the repository).
    
    % Preallocate output matrices for efficiency
    N = length(f_g); % Assuming f_g and f_c have the same length
    Y_g_dq = zeros(2,2,N);   % Generator admittance in dq frame
    Y_c_dq = zeros(2,2,N);   % Controller admittance in dq frame
    Y_g_pn = zeros(2,2,N);   % Generator admittance in pn frame
    Y_c_pn = zeros(2,2,N);   % Controller admittance in pn frame
    E = zeros(2,N);          % Eigenvalues for each frequency
    L = zeros(2,2,N);

    % Loop over all frequency points
    for n = 1:N
        % Construct generator admittance matrix in dq frame for frequency n
        Y_g_dq(:,:,n) = [Ydd_g(n), Ydq_g(n); 
                         Yqd_g(n), Yqq_g(n)];
        % Construct controller admittance matrix in dq frame for frequency n
        Y_c_dq(:,:,n) = [Ydd_c(n), Ydq_c(n); 
                         Yqd_c(n), Yqq_c(n)];
        
        % Compute the open-loop gain matrix L at this frequency
        % L = Y_c_dq * inv(Y_g_dq)
        L(:,:,n) = Y_c_dq(:,:,n) * inv(Y_g_dq(:,:,n));
        
        % Calculate the eigenvalues of the open-loop gain matrix
        E(:,n) = eig(L(:,:,n));
        
        % Convert dq admittance matrices to positive-negative (pn) sequence frame
        [Ypp_g, Ypn_g, Ynp_g, Ynn_g] = dq2pn(Ydd_g(n), Ydq_g(n), Yqd_g(n), Yqq_g(n));
        [Ypp_c, Ypn_c, Ynp_c, Ynn_c] = dq2pn(Ydd_c(n), Ydq_c(n), Yqd_c(n), Yqq_c(n));
        
        % Store the pn frame admittance matrices for generator and controller
        Y_g_pn(:,:,n) = [Ypp_g, Ypn_g; Ynp_g, Ynn_g];
        Y_c_pn(:,:,n) = [Ypp_c, Ypn_c; Ynp_c, Ynn_c];
    end
end
