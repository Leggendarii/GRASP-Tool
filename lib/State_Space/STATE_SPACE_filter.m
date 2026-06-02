%% Symbolic Linearization of VSC Filter Dynamics (LCL Filter)

% ============================================================
% 1. Symbolic definition of states, inputs, and parameters
% ============================================================

% Symbolic variables: filter currents/voltages (dq frame) and parameters
syms siL_d_s siL_q_s svpoc_d_s svpoc_q_s svvsc_d_s svvsc_q_s sig_d_s sig_q_s ...
     somega sL_vsc sR_vsc sC_filt somega_b

% ============================================================
% 2. Definition of state, input, and parameter vectors
% ============================================================

x = [siL_d_s; ...                   % Filter inductor current (d-axis)
     siL_q_s; ...                   % Filter inductor current (q-axis)
     svpoc_d_s; ...                 % Filter capacitor voltage (d-axis)
     svpoc_q_s];                    % Filter capacitor voltage (q-axis)

u = [svvsc_d_s; ...                 % VSC output voltage (d-axis)
     svvsc_q_s; ...                 % VSC output voltage (q-axis)
     sig_d_s; ...                   % Grid current (d-axis)
     sig_q_s];                      % Grid current (q-axis)

params = [sL_vsc; ...               % VSC filter inductance (pu)
          sR_vsc; ...               % VSC filter resistance (pu)
          sC_filt; ...              % Filter capacitance (pu)
          somega_b; ...             % Base angular frequency
          somega];                   % Operating angular frequency

% ============================================================
% 3. Nonlinear dynamic equations (LCL filter in dq frame)
% ============================================================

% Filter inductor voltage equation (d-axis)
f1 = (svvsc_d_s - svpoc_d_s - sR_vsc*siL_d_s + somega*sL_vsc*siL_q_s)*somega_b/sL_vsc;

% Filter inductor voltage equation (q-axis)  
f2 = (svvsc_q_s - svpoc_q_s - sR_vsc*siL_q_s - somega*sL_vsc*siL_d_s)*somega_b/sL_vsc;

% Filter capacitor current equation (d-axis)
f3 = (siL_d_s - sig_d_s + somega*sC_filt*svpoc_q_s)*somega_b/sC_filt;

% Filter capacitor current equation (q-axis)
f4 = (siL_q_s - sig_q_s - somega*sC_filt*svpoc_d_s)*somega_b/sC_filt;

f = [f1; f2; f3; f4];

% ============================================================
% 4. Compute the Jacobian matrices A and B
% ============================================================

A = jacobian(f, x);  % Partial derivatives of f w.r.t. state vector
B = jacobian(f, u);  % Partial derivatives of f w.r.t. input vector

% ============================================================
% 5. Output equations (filter states)
% ============================================================

h = [siL_d_s; siL_q_s; svpoc_d_s; svpoc_q_s];  % Output: all filter states

% ============================================================
% 6. Compute the Jacobian matrices C and D
% ============================================================

C = jacobian(h, x);  % Partial derivatives of h w.r.t. state vector
D = jacobian(h, u);  % Partial derivatives of h w.r.t. input vector

% ============================================================
% 7. Define equilibrium point and nominal parameters
% ============================================================

% Equilibrium state variables
x_eq = [iL_d_s; iL_q_s; vpoc_d_s; vpoc_q_s];   % Steady-state filter states

% Equilibrium input variables
u_eq = [vvsc_d_s; vvsc_q_s; ig_d_s; ig_q_s];   % Steady-state inputs

% Parameter values (per-unit normalized)
params_val = [L_vsc/L_base; ...    % Normalized filter inductance
              R_vsc/Z_base; ...    % Normalized filter resistance
              C_filt/C_base; ...   % Normalized filter capacitance
              omega_b; ...         % Base frequency
              1];                   % Normalized operating frequency

% ============================================================
% 8. Substitute operating point and compute numerical Jacobians
% ============================================================

A_lin_grid = double(subs(A, [x; u; params], [x_eq; u_eq; params_val]));
B_lin_grid = double(subs(B, [x; u; params], [x_eq; u_eq; params_val]));
C_lin_grid = double(subs(C, [x; u; params], [x_eq; u_eq; params_val]));
D_lin_grid = double(subs(D, [x; u; params], [x_eq; u_eq; params_val]));

% ============================================================
% 9. Build the state-space linearized model
% ============================================================

ss_filter = ss(A_lin_grid, B_lin_grid, C_lin_grid, D_lin_grid);

% ------------------------------------------------------------
% The resulting state-space model (ss_filter) represents the
% linearized dynamics of the VSC-side LCL filter in synchronous
% dq reference frame. Includes cross-coupling terms and full
% per-unit normalization.
% 
% 4th-order system: 2 inductor + 2 capacitor states
% Critical for filter resonance analysis and converter-grid
% stability studies.
% ------------------------------------------------------------
