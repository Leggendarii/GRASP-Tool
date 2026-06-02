base_setup

% Control Parameters from optimizer!
gains = readtable('greygains.csv');

%% Gain extracted via optimizator
sensitivity = 0; % Sensitivity to all parameters

kp_outer_V_pu = gains.Kp_outer_V*(1+sensitivity/100);
ki_outer_V_pu = gains.Ki_outer_V*(1+sensitivity/100);
kp_outer_P_pu = gains.Kp_outer_P*(1+sensitivity/100);
ki_outer_P_pu = gains.Ki_outer_P*(1+sensitivity/100);
kp_inner_d_pu = gains.Kp_inner_d*(1+sensitivity/100);
ki_inner_d_pu = gains.Ki_inner_d*(1+sensitivity/100);
kp_inner_q_pu = gains.Kp_inner_q*(1+sensitivity/100);
ki_inner_q_pu = gains.Ki_inner_q*(1+sensitivity/100);
kp_pll = gains.Kp_pll*(1+sensitivity/100);
ki_pll = gains.Ki_pll*(1+sensitivity/100);
T1 = gains.T1*(1+sensitivity/100);
T2 = gains.T2*(1+sensitivity/100);

%% Manual Values testing
% kp_outer_V_pu = 2;
% ki_outer_V_pu = 574.37;
% kp_outer_P_pu = 5;
% ki_outer_P_pu = 500; %% Bias
% kp_inner_d_pu = 2.5999;
% ki_inner_d_pu = 2919.2;
% kp_inner_q_pu = 2.5999;
% ki_inner_q_pu = 2919.2;
% kp_pll = 9.3347;
% ki_pll = 3.0008;
% T1 = 1.2896e-5;
% T2 = 0.0035436;