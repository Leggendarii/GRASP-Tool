%% Symbolic Linearization of Lead-Lag Filter Dynamics

% ============================================================
% 1. Symbolic definition of states, inputs, and parameters
% ============================================================

% Symbolic variables: states, measurements, and filter parameters
syms sT1 sT2 sFlux_laglead sVdc_mes sVdc_mes_filt

% ============================================================
% 2. Definition of state, input, and parameter vectors
% ============================================================

params = [sT1; sT2];            % Filter time constants [T1; T2]
x = [sFlux_laglead];            % State vector: internal filter state
u = [sVdc_mes];                 % Input vector: measured DC-link voltage

% ============================================================
% 3. Nonlinear dynamic equations (lead-lag filter state equation)
% ============================================================

% Lead-lag filter dynamics: first-order state-space realization
% Equivalent to transfer function: (1 + T1*s)/(1 + T2*s)
f1 = -(1/sT2) * sFlux_laglead + sVdc_mes;  % State derivative
f = f1;

% ============================================================
% 4. Compute the Jacobian matrices A and B
% ============================================================

A = jacobian(f, x);  % Partial derivatives of f w.r.t. state vector
B = jacobian(f, u);  % Partial derivatives of f w.r.t. input vector

% ============================================================
% 5. Output equations (lead-lag filtered voltage)
% ============================================================

% Filter output equation: y = (1/T2 + T1/T2^2)*x + (T1/T2)*u
h = (1/sT2 - sT1/sT2^2) * sFlux_laglead + sT1/sT2 * sVdc_mes;

% ============================================================
% 6. Compute the Jacobian matrices C and D
% ============================================================

C = jacobian(h, x);  % Partial derivatives of h w.r.t. state vector
D = jacobian(h, u);  % Partial derivatives of h w.r.t. input vector

% ============================================================
% 7. Define equilibrium point and nominal parameters
% ============================================================

% Parameter values (time constants in seconds)
params_val = [T1; T2];

% Equilibrium values (steady-state: x_ss = T2 * u)
u_eq = vdc_mes;                     % Equilibrium DC voltage measurement
x_eq = vdc_mes * T2;                % Equilibrium filter state

% ============================================================
% 8. Substitute operating point and compute numerical Jacobians
% ============================================================

A_lin_laglead = double(subs(A, [x; u; params], [x_eq; u_eq; params_val]));
B_lin_laglead = double(subs(B, [x; u; params], [x_eq; u_eq; params_val]));
C_lin_laglead = double(subs(C, [x; u; params], [x_eq; u_eq; params_val]));
D_lin_laglead = double(subs(D, [x; u; params], [x_eq; u_eq; params_val]));

% ============================================================
% 9. Build the state-space linearized model
% ============================================================

ss_laglead = ss(A_lin_laglead, B_lin_laglead, C_lin_laglead, D_lin_laglead);

% ------------------------------------------------------------
% The resulting state-space model (ss_laglead) represents the
% linearized dynamics of a lead-lag filter applied to DC-link
% voltage measurements. Typically used for noise filtering or
% phase compensation in outer control loops of grid converters.
% 
% Transfer function equivalence: G(s) = (1 + T1*s)/(1 + T2*s)
% Steady-state gain: T1/T2
% ------------------------------------------------------------
