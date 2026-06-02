%% Symbolic Linearization of Grid Dynamics (RL Filter)

% ============================================================
% 1. Symbolic definition of states, inputs, and parameters
% ============================================================

% Symbolic variables: currents, voltages (dq frame), and grid parameters
syms sig_d_s sig_q_s svvsc_d_s svvsc_q_s svg_d_s svg_q_s somega sL_grid sR_grid somega_b

% ============================================================
% 2. Definition of state, input, and parameter vectors
% ============================================================

x = [sig_d_s; sig_q_s];             % State vector: grid currents [id; iq]
u = [svvsc_d_s; ...                 % VSC output voltage (d-axis)
     svvsc_q_s; ...                 % VSC output voltage (q-axis)
     svg_d_s; ...                   % Grid voltage (d-axis)
     svg_q_s];                      % Grid voltage (q-axis)

params = [sL_grid; ...              % Grid inductance (pu)
          sR_grid; ...              % Grid resistance (pu)
          somega_b; ...             % Base angular frequency
          somega];                   % Operating angular frequency

% ============================================================
% 3. Nonlinear dynamic equations (grid RL circuit in dq frame)
% ============================================================

% d-axis current dynamics: L*di_d/dt = v_vsc_d - v_g_d - R*i_d + ω*L*i_q
f1 = (svvsc_d_s - svg_d_s - sR_grid*sig_d_s + somega*sL_grid*sig_q_s) * somega_b / sL_grid;

% q-axis current dynamics: L*di_q/dt = v_vsc_q - v_g_q - R*i_q - ω*L*i_d
f2 = (svvsc_q_s - svg_q_s - sR_grid*sig_q_s - somega*sL_grid*sig_d_s) * somega_b / sL_grid;

f = [f1; f2];

% ============================================================
% 4. Compute the Jacobian matrices A and B
% ============================================================

A = jacobian(f, x);  % Partial derivatives of f w.r.t. state vector
B = jacobian(f, u);  % Partial derivatives of f w.r.t. input vector

% ============================================================
% 5. Output equations (grid currents)
% ============================================================

h = [sig_d_s; sig_q_s];  % Output: measured grid currents [id; iq]

% ============================================================
% 6. Compute the Jacobian matrices C and D
% ============================================================

C = jacobian(h, x);  % Partial derivatives of h w.r.t. state vector
D = jacobian(h, u);  % Partial derivatives of h w.r.t. input vector

% ============================================================
% 7. Define equilibrium point and nominal parameters
% ============================================================

% Equilibrium state variables
x_eq = [ig_d_s; ig_q_s];            % Steady-state grid currents

% Equilibrium input variables
u_eq = [vvsc_d_s; vvsc_q_s; ...     % Steady-state VSC voltages
        vg_d_s; vg_q_s];            % Steady-state grid voltages

% Parameter values (per-unit normalized)
params_val = [L_grid/L_base; ...    % Normalized grid inductance
              R_grid/Z_base; ...    % Normalized grid resistance
              omega_b; ...          % Base frequency (rad/s)
              1];                    % Normalized operating frequency

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

ss_grid = ss(A_lin_grid, B_lin_grid, C_lin_grid, D_lin_grid);

% ------------------------------------------------------------
% The resulting state-space model (ss_grid) represents the
% linearized dynamics of the grid-side RL filter in synchronous
% dq reference frame. Captures cross-coupling terms (ωL) and
% per-unit normalization (ω_b/L_base scaling).
% 
% Essential for converter-grid impedance modeling and stability
% analysis in weak grid conditions (low SCR).
% ------------------------------------------------------------
