%% Parameters Initialization
parameter = readtable("parameters.csv");

%%%%%%%%%%%%%% Performance Selection %%%%%%%%%%%% (Here you decide!)
Grid_SCR = 3; 
Grid_XR = 7;

V_step_time = 6;                 % Voltage ref step time (s)
P_step_time = 2;                   % Power ref step time (s)
V_finalvalue = 0.95;               % Voltage ref final value (pu)
P_finalvalue = 0.5;                % Power ref final value (pu)

Tobs = 10;                         % Total simulation time (s)
steady_time = 1;                 % Instant where the steady state starts (s)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Nominal Values
Ts = parameter.Value(1)*10^-6;     % Sample time (s)
f_base = parameter.Value(2);       % Base frequency (Hz)
V_base = parameter.Value(3)*10^3;  % Base voltage (L-L RMS) (V)
P_base = parameter.Value(4)*10^6;  % Base power (W)

% VSC Parameters
L_vsc = parameter.Value(5);        % VSC inductance (H)
C_filt = parameter.Value(6);       % Filter capacitance (F)
R_vsc = parameter.Value(7);        % VSC resistance (Ohm)
R_filt = parameter.Value(8);       % Filter resistance (Ohm)
[C_dc, V_dc] = DC_Cap(V_base, P_base);       % DC capacitor and voltage (F, V)
% 
% C_dc = parameter.Value(21);
% V_dc = parameter.Value(22);

t_charge = 0.5;                    % DC capacitor voltage setup time (s)
I_charge = C_dc * V_dc / t_charge; % Curent necessary to reac 1pu Vdc (A)

% Grid Parameters (3 per statcom)
[L_grid, R_grid] = thevenin(Grid_SCR, Grid_XR, V_base, P_base, f_base);  % Thevenin equivalent parameters

% L_grid = parameter.Value(9);        % VSC inductance (H)
% R_grid = parameter.Value(10);  

% Base values calculation
omega_b = 2 * pi * f_base;        % Base angular frequency (rad/s)
Z_base = V_base^2 / P_base;       % Base impedance (Ohm)
L_base = Z_base / omega_b;        % Base inductance (H)
C_base = 1 / (Z_base * omega_b);  % Base capacitance (F)



