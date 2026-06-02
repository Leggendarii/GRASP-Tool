%% Symbolic Linearization of DC-Link Dynamics

% ============================================================
% 1. Symbolic definition of states, inputs, and parameters
% ============================================================

% Symbolic variables: DC voltage, power references, measurements
syms sVdc_mes sP_ref sig_d_c sig_q_c svpoc_d_c svpoc_q_c sC_dc sVdc_n sPn

% ============================================================
% 2. Definition of state, input, and parameter vectors
% ============================================================

x = sVdc_mes;                       % State vector: measured DC-link voltage

u = [sP_ref; ...                    % Active power reference
     sig_d_c; ...                   % Controlled d-axis current
     sig_q_c; ...                   % Controlled q-axis current
     svpoc_d_c; ...                 % PoC voltage (d-axis)
     svpoc_q_c];                    % PoC voltage (q-axis)

params = [sC_dc; ...                % DC-link capacitance (pu)
          sVdc_n; ...               % Nominal DC voltage (pu)
          sPn];                      % Power base (pu)

% ============================================================
% 3. Measured power and nonlinear dynamic equation
% ============================================================

% Instantaneous active power at PoC (dq frame)
P_meas = svpoc_d_c * sig_d_c + svpoc_q_c * sig_q_c;

% DC-link voltage dynamics: C*dVdc/dt = (P_ref - P_meas)/(Vdc)
% Per-unit normalized form with proper scaling
f1 = (sP_ref - P_meas) / (sC_dc * sVdc_mes) * (sPn / sVdc_n^2);
f = f1;

% ============================================================
% 4. Compute the Jacobian matrices A and B
% ============================================================

A = jacobian(f, x);  % Partial derivatives of f w.r.t. state vector
B = jacobian(f, u);  % Partial derivatives of f w.r.t. input vector

% ============================================================
% 5. Output equations (DC-link voltage)
% ============================================================

h = sVdc_mes;  % Output: measured DC-link voltage

% ============================================================
% 6. Compute the Jacobian matrices C and D
% ============================================================

C = jacobian(h, x);  % Partial derivatives of h w.r.t. state vector
D = jacobian(h, u);  % Partial derivatives of h w.r.t. input vector

% ============================================================
% 7. Define equilibrium point and nominal parameters
% ============================================================

% Equilibrium state variable
x_eq = vdc_mes;                         % Steady-state DC voltage

% Equilibrium input variables
u_eq = [pref; ig_d_c; ig_q_c; vpoc_d_c; vpoc_q_c];  % Steady-state operating point

% Parameter values (per-unit normalized)
params_val = [C_dc; V_dc; P_base];      % [DC capacitance; nominal voltage; power base]

% ============================================================
% 8. Substitute operating point and compute numerical Jacobians
% ============================================================

A_lin_power = double(subs(A, [x; u; params], [x_eq; u_eq; params_val]));
B_lin_power = double(subs(B, [x; u; params], [x_eq; u_eq; params_val]));
C_lin_power = double(subs(C, [x; u; params], [x_eq; u_eq; params_val]));
D_lin_power = double(subs(D, [x; u; params], [x_eq; u_eq; params_val]));

% ============================================================
% 9. Build the state-space linearized model
% ============================================================

ss_dc = ss(A_lin_power, B_lin_power, C_lin_power, D_lin_power);

% ------------------------------------------------------------
% The resulting state-space model (ss_dc) represents the
% linearized DC-link voltage dynamics for a grid-connected VSC.
% 
% Key features:
% - 1st-order system driven by active power balance
% - Proper per-unit scaling: (Pn/Vdc_n^2) ensures unit consistency
% - ∂P_meas/∂Vdc term appears in A matrix (nonlinear voltage dependence)
% - Essential for DC-link stability analysis and outer-loop design
% ------------------------------------------------------------
