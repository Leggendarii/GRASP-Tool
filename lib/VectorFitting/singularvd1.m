function [sistema, g, Cred, q] = singularvd1(Q, Yqd_res, svd_tol, C, D, poles, degree)
% singularvd1 - Singular Value Decomposition (SVD)-based processing for system frequency response.
%
% Syntax:
%   [g, Cred, polesred, q] = singularvd1(Q, mode, Yqd_res, svd_tol, C, D, poles, degree)
%
% Inputs:
%   Q            - Matrix for SVD analysis.
%   mode         - Mode of operation (0 for real, 1 for augmented with imaginary components).
%   Yqd_res      - Input vector to the system.
%   svd_tol      - Threshold for singular value filtering.
%   C            - Vector of coefficients associated with system poles.
%   poles        - Vector containing system poles.
%   D            - Direct transmission term (scalar or matrix).
%   degree       - Degree of the system.
%
% Outputs:
%   g            - Projected vector obtained from SVD transformation.
%   Cred         - Filtered coefficient vector corresponding to significant poles.
%   polesred     - Filtered poles after thresholding.
%   q            - Solution vector for pole-related coefficients.

% Step 1: Apply SVD based on the selected mode
if isreal(Q)
    mode=0;
else
    mode=1;
end
switch mode
    case 0
        % Real part analysis
        [U, Z, V] = svd(real(Q));
    case 1
        % Augment matrix Q with real and imaginary components
        Q = [real(Q) -imag(Q); imag(Q) real(Q)];
        [U, Z, V] = svd(Q);
end

% Transpose the matrix V for further calculations
V = transpose(V);

% Step 2: Project input vector Yqd_res using SVD-based transformation
switch mode
    case 0
        % Real part projection
        v = transpose(real(Yqd_res));
    case 1
        % Augmented projection for real and imaginary parts
        v = [transpose(real(Yqd_res)); transpose(imag(Yqd_res))];
end
g = transpose(U) * v; % Apply transformation

% Step 3: Filter singular values based on threshold svd_tol
r = find(diag(Z) > svd_tol); % Identify significant singular values
switch mode
    case 0
        rt = length(r); % Count significant values (real mode)
    case 1
        rt = 2 * length(r); % Count significant values (augmented mode)
end

% Step 4: Extract significant singular values and transform V matrix
Zz = diag(Z); % Extract diagonal singular values
switch mode
    case 0
        Zr = diag(Zz(1:rt)); % Filter diagonal singular values
        Vr = V(1:rt, :);     % Filter rows of V corresponding to significant values
    case 1
        Zr = diag([Zz(1:length(r)); Zz(1:length(r))]); % Augmented filtering
        Vr = [V(1:length(r), :); V(1:length(r), :)];   % Augmented rows of V
end

% Step 5: Solve for pole-related coefficients
gr = g(1:rt); % Extract corresponding projection values
q = (transpose(Vr) * transpose(Zr) * Zr * Vr) \ transpose(Vr) * transpose(Zr) * gr; % Solve equation

% Step 6: Filter poles and coefficients based on significance threshold
zero = 1E-8; % Minimum threshold for significance
switch mode
    case 0
        qsel = find(abs(q) >= zero); % Filter based on significance
    case 1
        q1 = q(1:degree) + 1i * q(degree+1:end); % Combine real and imaginary parts for complex mode
        qsel = find(abs(q1) >= zero); % Filter based on significance
end

% Step 7: Update coefficients and poles
Cred = C(qsel); % Select significant coefficients
polosred = poles(qsel); % Select significant poles

% Step 8: Build system representation and calculate frequency response
sistema = ss(diag(polosred), ones(length(polosred), 1), Cred, D); % State-space representation

end
