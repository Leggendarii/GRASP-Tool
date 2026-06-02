%% Symbolic Linearization of PLL (Phase Locked Loop) Dynamics

% ============================================================
% 1. Symbolic definition of states, inputs, and parameters
% ============================================================

% Symbolic variables: measurements and controller gains
syms svpoc_q_c skp_pll ski_pll stheta sFlux_PLL

% ============================================================
% 2. Definition of state, input, and parameter vectors
% ============================================================

x = [stheta; sFlux_PLL];        % State vector: [theta; PLL integrator]
u = svpoc_q_c;                  % Input vector: measured q-axis PoC voltage

params = [skp_pll; ...          % PLL proportional gain
          ski_pll];             % PLL integral gain

% ============================================================
% 3. Nonlinear dynamic equations (PLL model)
% ============================================================

% PLL dynamics: theta_dot = Kp * vq + Ki * flux_PLL
f1 = skp_pll * svpoc_q_c + ski_pll * sFlux_PLL;  % Angular position derivative
f2 = svpoc_q_c;                                  % PLL integrator dynamics
f = [f1; f2];

% ============================================================
% 4. Compute the Jacobian matrices A and B
% ============================================================

A = jacobian(f, x);  % Partial derivatives of f w.r.t. state vector
B = jacobian(f, u);  % Partial derivatives of f w.r.t. input vector

% ============================================================
% 5. Output equations (PLL angular frequency)
% ============================================================

% PLL output frequency (same as theta_dot from control law)
omega = skp_pll * svpoc_q_c + ski_pll * sFlux_PLL;
h = [stheta];  % Output: phase angle theta

% ============================================================
% 6. Compute the Jacobian matrices C and D
% ============================================================

C = jacobian(h, x);  % Partial derivatives of h w.r.t. state vector
D = jacobian(h, u);  % Partial derivatives of h w.r.t. input vector

% ============================================================
% 7. Define equilibrium point and nominal parameters
% ============================================================

% Equilibrium state variables
x_eq = [theta; flux_PLL/ki_pll];  % [equilibrium phase; normalized PLL flux]

% Equilibrium input variable
u_eq = [vpoc_q_c];                % Equilibrium q-axis voltage measurement

% Parameter values at the operating point
params_val = [kp_pll; ki_pll];    % [PLL proportional gain; PLL integral gain]

% ============================================================
% 8. Substitute operating point and compute numerical Jacobians
% ============================================================

A_lin_PLL = double(subs(A, [x; u; params], [x_eq; u_eq; params_val]));
B_lin_PLL = double(subs(B, [x; u; params], [x_eq; u_eq; params_val]));
C_lin_PLL = double(subs(C, [x; u; params], [x_eq; u_eq; params_val]));
D_lin_PLL = double(subs(D, [x; u; params], [x_eq; u_eq; params_val]));

% ============================================================
% 9. Build the state-space linearized model
% ============================================================

ss_PLL = ss(A_lin_PLL, B_lin_PLL, C_lin_PLL, D_lin_PLL);

% ------------------------------------------------------------
% The resulting state-space model (ss_PLL) represents the
% linearized dynamics of the Phase Locked Loop (PLL) around
% the specified operating point. It captures the interaction
% between q-axis voltage measurement and phase angle tracking.
% Ideal for stability analysis in grid-connected converters.
% ------------------------------------------------------------
