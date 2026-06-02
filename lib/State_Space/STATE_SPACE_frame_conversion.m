%% Symbolic Linearization of Reference Frame Transformation

% ============================================================
% 1. Symbolic definition of states, inputs, and parameters
% ============================================================

% Symbolic variables: dq voltages/currents (sync frame) and converter frame
syms svg_d_s svg_q_s sig_d_s sig_q_s siL_d_s siL_q_s svvsc_d_c svvsc_q_c stheta

% ============================================================
% 2. Definition of state, input, and parameter vectors
% ============================================================

x = zeros(1);                       % No dynamic states (static transformation)

u = [svg_d_s; ...                   % Grid voltage (d-axis, sync frame)
     svg_q_s; ...                   % Grid voltage (q-axis, sync frame)
     sig_d_s; ...                   % Grid current (d-axis, sync frame)
     sig_q_s; ...                   % Grid current (q-axis, sync frame)
     siL_d_s; ...                   % Filter current (d-axis, sync frame)
     siL_q_s; ...                   % Filter current (q-axis, sync frame)
     svvsc_d_c; ...                 % VSC voltage (d-axis, converter frame)
     svvsc_q_c; ...                 % VSC voltage (q-axis, converter frame)
     stheta];                       % Phase angle difference (θ_sync - θ_conv)

% ============================================================
% 3. Dynamic equations (static transformation - no dynamics)
% ============================================================

f = 0;  % No state dynamics (pure algebraic transformation)

% ============================================================
% 4. State-space matrices (static system)
% ============================================================

A = 0;                              % No state dynamics (scalar zero)
B = zeros(1,9);                     % No state input coupling

% ============================================================
% 5. Output equations (reference frame transformation)
% ============================================================

% Park's transformation matrix (from sync to converter frame)
% alpha = -2*pi*50*10e-6;
T = [cos(stheta) sin(stheta); -sin(stheta) cos(stheta)];
% T_d = [cos(alpha) sin(alpha); -sin(alpha) cos(alpha)];

% Transform grid voltages to converter frame
v_g_dq_c = T * [svg_d_s; svg_q_s];

% Transform grid currents to converter frame
i_g_dq_c =  T  * [sig_d_s; sig_q_s];

% Transform filter currents to converter frame
i_L_dq_c =  T * [siL_d_s; siL_q_s];

% Transform VSC voltages from converter to sync frame
v_inv_dq_s =  T^-1 * [svvsc_d_c; svvsc_q_c];

% Complete output vector [vg_dc; vg_qc; ig_dc; ig_qc; iL_dc; iL_qc; vvsc_ds; vvsc_qs]
h = [v_g_dq_c(1); v_g_dq_c(2); i_g_dq_c(1); i_g_dq_c(2); ...
     i_L_dq_c(1); i_L_dq_c(2); v_inv_dq_s(1); v_inv_dq_s(2)];

% ============================================================
% 6. Compute the Jacobian matrices C and D
% ============================================================

C = zeros(8,1);                     % No state output coupling
D = jacobian(h, u);                 % Input-output coupling matrix (transformation Jacobian)

% ============================================================
% 7. Define equilibrium point
% ============================================================

u_eq = [vg_d_s; vg_q_s; ig_d_s; ig_q_s; iL_d_s; iL_q_s; ...
        vvsc_d_c; vvsc_q_c; theta];  % Equilibrium operating point

% ============================================================
% 8. Substitute operating point and compute numerical matrices
% ============================================================

A_lin_current = double(subs(A, u, u_eq));
B_lin_current = double(subs(B, u, u_eq));
C_lin_current = double(subs(C, u, u_eq));
D_lin_current = double(subs(D, u, u_eq));

% ============================================================
% 9. Build the state-space linearized model
% ============================================================

ss_frame = ss(A_lin_current, B_lin_current, C_lin_current, D_lin_current);

% ------------------------------------------------------------
% The resulting state-space model (ss_frame) represents the
% linearized reference frame transformation between synchronous
% (PLL-based) and converter reference frames.
% 
% Key features:
% - D matrix captures trigonometric coupling terms ∂(sin/cos)/∂θ
% - Essential for multi-frame impedance modeling
% - Captures PLL-converter frame angle dynamics impact
% ------------------------------------------------------------

