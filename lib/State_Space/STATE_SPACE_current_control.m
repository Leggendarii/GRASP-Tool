%% Symbolic Linearization of Inner Current Control Loops (PI Regulators)

% ============================================================
% 1. Symbolic definition of states, inputs, and parameters
% ============================================================

% Symbolic variables: current references, measurements, and PI gains
syms siref_d_c siref_q_c siL_d_c siL_q_c ...
     skp_inner_d_pu ski_inner_d_pu skp_inner_q_pu ski_inner_q_pu sCd sCq sVdc_mes

% ============================================================
% 2. Definition of state, input, and parameter vectors
% ============================================================

x = [sCd; sCq];                     % State vector: PI integrators [Cd; Cq]

u = [siref_d_c; ...                 % d-axis current reference
     siref_q_c; ...                 % q-axis current reference
     siL_d_c; ...                   % Measured filter current (d-axis)
     siL_q_c];                      % Measured filter current (q-axis)

params = [skp_inner_d_pu; ...       % d-axis PI proportional gain (pu)
          ski_inner_d_pu; ...       % d-axis PI integral gain (pu)
          skp_inner_q_pu; ...       % q-axis PI proportional gain (pu)
          ski_inner_q_pu];          % q-axis PI integral gain (pu)

% ============================================================
% 3. Nonlinear dynamic equations (PI regulator integrators)
% ============================================================

% d-axis PI integrator dynamics
f1 = siref_d_c - siL_d_c;           % Current error drives integrator

% q-axis PI integrator dynamics  
f2 = siref_q_c - siL_q_c;           % Current error drives integrator

f = [f1; f2];

% ============================================================
% 4. Compute the Jacobian matrices A and B
% ============================================================

A = jacobian(f, x);  % Partial derivatives of f w.r.t. state vector (zero matrix)
B = jacobian(f, u);  % Partial derivatives of f w.r.t. input vector

% ============================================================
% 5. Output equations (voltage references from PI controllers)
% ============================================================

% d-axis voltage reference: v_d = Ki*Cd + Kp*(iref_d - iL_d)
v_d = ski_inner_d_pu * sCd + skp_inner_d_pu * (siref_d_c - siL_d_c);

% q-axis voltage reference: v_q = Ki*Cq + Kp*(iref_q - iL_q)
v_q = ski_inner_q_pu * sCq + skp_inner_q_pu * (siref_q_c - siL_q_c);

h = [v_d; v_q];                     % Output: voltage references [v_d; v_q]

% ============================================================
% 6. Compute the Jacobian matrices C and D
% ============================================================

C = jacobian(h, x);  % Partial derivatives of h w.r.t. state vector
D = jacobian(h, u);  % Partial derivatives of h w.r.t. input vector

% ============================================================
% 7. Define equilibrium point and nominal parameters
% ============================================================

% Equilibrium state variables (integrator steady-state values)
x_eq = [qd/ki_inner_d_pu; qq/ki_inner_q_pu];  % Normalized integrator states

% Equilibrium input variables
u_eq = [iref_d_c; iref_q_c; iL_d_c; iL_q_c];  % Steady-state currents

% Parameter values (per-unit normalized PI gains)
params_val = [kp_inner_d_pu; ki_inner_d_pu; ...
              kp_inner_q_pu; ki_inner_q_pu];

% ============================================================
% 8. Substitute operating point and compute numerical Jacobians
% ============================================================

A_lin_current = double(subs(A, [x; u; params], [x_eq; u_eq; params_val]));
B_lin_current = double(subs(B, [x; u; params], [x_eq; u_eq; params_val]));
C_lin_current = double(subs(C, [x; u; params], [x_eq; u_eq; params_val]));
D_lin_current = double(subs(D, [x; u; params], [x_eq; u_eq; params_val]));

% ============================================================
% 9. Build the state-space linearized model
% ============================================================

ss_current = ss(A_lin_current, B_lin_current, C_lin_current, D_lin_current);

% ------------------------------------------------------------
% The resulting state-space model (ss_current) represents the
% linearized dynamics of the dual PI current controllers in
% synchronous dq frame.
% 
% Key features:
% - A = 0 (pure integrator dynamics, no state feedback)
% - C matrix contains steady-state integrator contributions (Ki*Cd, Ki*Cq)
% - D matrix captures proportional path gains Kp
% - Essential for current loop impedance modeling and bandwidth analysis
% ------------------------------------------------------------
