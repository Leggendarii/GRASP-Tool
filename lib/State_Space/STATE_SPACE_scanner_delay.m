%% Symbolic Linearization of Reference Frame Transformation

% ============================================================
% 1. Symbolic definition of states, inputs, and parameters
% ============================================================

% Symbolic variables: dq voltages/currents (sync frame) and converter frame
syms svpoc_d_s svpoc_q_s sig_d_s sig_q_s

% ============================================================
% 2. Definition of state, input, and parameter vectors
% ============================================================

x = zeros(1);                       % No dynamic states (static transformation)

u = [svpoc_d_s; ...                   % Grid voltage (d-axis, sync frame)
     svpoc_q_s; ...                   % Grid voltage (q-axis, sync frame)
     sig_d_s; ...                   % Grid current (d-axis, sync frame)
     sig_q_s];                       % Phase angle difference (θ_sync - θ_conv)

% ============================================================
% 3. Dynamic equations (static transformation - no dynamics)
% ============================================================

f = 0;  % No state dynamics (pure algebraic transformation)

% ============================================================
% 4. State-space matrices (static system)
% ============================================================

A = 0;                              % No state dynamics (scalar zero)
B = zeros(1,4);                     % No state input coupling

% ============================================================
% 5. Output equations (reference frame transformation)
% ============================================================

% Park's transformation matrix (from sync to converter frame)
alpha = 2*pi*50*10e-6 + angle(vpoc_d_s + 1j*vpoc_q_s);
T_d = [cos(alpha) sin(alpha); -sin(alpha) cos(alpha)];

% Transform grid voltages to converter frame
v_poc_dq_d = [svpoc_d_s; svpoc_q_s];

% Transform grid currents to converter frame
i_g_dq_d = T_d  * [sig_d_s; sig_q_s];

% Complete output vector [vg_dc; vg_qc; ig_dc; ig_qc; iL_dc; iL_qc; vvsc_ds; vvsc_qs]
h = [v_poc_dq_d(1); v_poc_dq_d(2); i_g_dq_d(1); i_g_dq_d(2)];

% ============================================================
% 6. Compute the Jacobian matrices C and D
% ============================================================

C = zeros(4,1);                     % No state output coupling
D = jacobian(h, u);                 % Input-output coupling matrix (transformation Jacobian)

% ============================================================
% 7. Define equilibrium point
% ============================================================

u_eq = [vg_d_s; vg_q_s; ig_d_s; ig_q_s];  % Equilibrium operating point

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

ss_scand = ss(A_lin_current, B_lin_current, C_lin_current, D_lin_current);

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

