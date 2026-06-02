%% Symbolic Linearization of Outer Control Loops (P/V) for a Converter

% ============================================================
% 1. Symbolic definition of states, inputs, and parameters
% ============================================================

% Symbolic variables: references and measurements
syms sVdc_ref sVdc_mes sVpoc_ref svpoc_d_c svpoc_q_c sig_d_c sig_q_c

% Symbolic controller gains (proportional/integral)
syms skp_outer_P_pu ski_outer_P_pu skp_outer_V_pu ski_outer_V_pu

% Symbolic state variables (integrators of outer control loops)
syms sWP sFlux_PoC

% ============================================================
% 2. Definition of state, input, and parameter vectors
% ============================================================

x = [sWP; sFlux_PoC];       % State vector
u = [sVdc_ref; ...          % DC-link voltage reference
     sVdc_mes; ...          % Measured DC-link voltage
     sVpoc_ref; ...         % Voltage reference at PoC (Point of Common Coupling)
     sig_d_c; ...           % Controlled current (d-axis)
     sig_q_c; ...           % Controlled current (q-axis)
     svpoc_d_c; ...         % Measured voltage (d-axis)
     svpoc_q_c];            % Measured voltage (q-axis)

params = [skp_outer_P_pu; ...   % P outer-loop proportional gain
          ski_outer_P_pu; ...   % P outer-loop integral gain
          skp_outer_V_pu; ...   % V outer-loop proportional gain
          ski_outer_V_pu];      % V outer-loop integral gain

% ============================================================
% 3. Nonlinear dynamic equations (simple illustrative example)
% ============================================================

% Magnitude of measured PoC voltage
V_poc_mes = sqrt(svpoc_d_c^2 + svpoc_q_c^2);
% V_poc_mes = svpoc_d_c^2 + svpoc_q_c^2;

% Simplified nonlinear dynamics (for illustration only)
% Represent feedback loops on DC voltage and PoC voltage
f1 = -(sVdc_ref - sVdc_mes);   % DC-link voltage control dynamics
f2 = -(sVpoc_ref - V_poc_mes); % PoC voltage control dynamics
f = [f1; f2];

% ============================================================
% 4. Compute the Jacobian matrices A and B
% ============================================================

A = jacobian(f, x);  % Partial derivatives of f w.r.t. state vector
B = jacobian(f, u);  % Partial derivatives of f w.r.t. input vector

% ============================================================
% 5. Output equations (reference currents)
% ============================================================

% d-axis current reference from outer P/DC voltage controller
i_d_ref = ski_outer_P_pu * sWP ...
           - skp_outer_P_pu * (sVdc_ref - sVdc_mes);

% q-axis current reference from outer V/PoC voltage controller
i_q_ref = ski_outer_V_pu * sFlux_PoC ...
           - skp_outer_V_pu * (sVpoc_ref - V_poc_mes);

% Output vector (current references)
h = [i_d_ref; i_q_ref];

% ============================================================
% 6. Compute the Jacobian matrices C and D
% ============================================================

C = jacobian(h, x);  % Partial derivatives of h w.r.t. state vector
D = jacobian(h, u);  % Partial derivatives of h w.r.t. input vector

% ============================================================
% 7. Define equilibrium point and nominal parameters
% ============================================================

% Equilibrium state variables
x_eq = [flux_DC; flux_PoC/ki_outer_V_pu];

% Equilibrium input variables
u_eq = [vdc_ref; vdc_mes; vpoc_ref; ...
        ig_d_c; ig_q_c; vpoc_d_c; vpoc_q_c];

% Parameter values at the operating point
params_val = [kp_outer_P_pu; ki_outer_P_pu; ...
              kp_outer_V_pu; ki_outer_V_pu];

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

ss_power = ss(A_lin_power, B_lin_power, C_lin_power, D_lin_power);

% ------------------------------------------------------------
% The resulting state-space model (ss_power) represents the
% linearized version of the converter outer control dynamics
% around the specified operating point. It can be used for
% stability analysis, eigenvalue computations, or frequency
% response simulations.
% ------------------------------------------------------------
