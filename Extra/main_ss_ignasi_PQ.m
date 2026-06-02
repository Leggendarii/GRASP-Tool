%%
clear all;
close all;
clc;

addpath(genpath('lib'));
addpath(genpath('data'));

%% Definizione simbolica variabili di stato e ingresso
syms Id1 Iq1 Id2 Iq2 Id3 Iq3 Vd Vq Vd_cap Vq_cap Id_c Iq_c Vd_c Vq_c X1_pll Theta_pll ...
     Freq_pll Phi_pc_p Phi_pc_q Phi_cc_d Phi_cc_q Id_star Iq_star Ud_c Uq_c Ud_s Uq_s ...
     R1 L1 R2 L2 R3 C3 WN Kp_pc Ki_pc Kp_cc Ki_cc Kp_pll Ki_pll Ed Eq Pref Qref 

%% Vettore stato, algebraico e ingresso
x = [Id1; Iq1; Id2; Iq2; Vd_cap; Vq_cap; Phi_pc_p; Phi_pc_q; Phi_cc_d; Phi_cc_q; X1_pll; Theta_pll]; 
y = [Id3; Iq3; Vd; Vq; Id_c; Iq_c; Vd_c; Vq_c; Freq_pll; Id_star; Iq_star; Ud_c; Uq_c; Ud_s; Uq_s];
params = [R1; L1; R2; L2; R3; C3; WN; Kp_pc; Ki_pc; Kp_cc; Ki_cc; Kp_pll; Ki_pll; Ed; Eq; Pref; Qref];  
  

%% Equazioni differenziali e algebraicali non lineari 
f1 = (WN/L1)*(-R1*Id1 + L1*Iq1 + Ud_s - Vd);
f2 = (WN/L1)*(-L1*Id1 - R1*Iq1 + Uq_s - Vq);
f3 = (WN/L2)*(-R2*Id2 + L2*Iq2 + Vd - Ed);
f4 = (WN/L2)*(-L2*Id2 - R2*Iq2 + Vq - Eq);
f5 = WN*(Vq_cap +  1/C3*Id3);
f6 = WN*(-Vd_cap + 1/C3*Iq3);
f7 = Pref - Vd_c*Id_c+Vq_c*Iq_c;
f8 = Vq_c*Id_c-Vd_c*Iq_c - Qref;
f9 = Id_star - Id_c;
f10 = Iq_star - Iq_c;
f11 = Vq_c;
f12 = Freq_pll;

f = [f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12];

%%
g1 = (Vd - Vd_cap)/R3 - Id3;
g2 = (Vq - Vq_cap)/R3 - Iq3;
g3 = (Id2 + Id3) - Id1;
g4 = (Iq2 + Iq3) - Iq1;
g5 = Kp_pll * Vq_c + Ki_pll * X1_pll - Freq_pll;
g6 = Kp_pc * (Pref - (Vd_c*Id_c+Vq_c*Iq_c)) + Ki_pc * Phi_pc_p - Id_star; 
g7 = Kp_pc * (Vq_c*Id_c-Vd_c*Iq_c - Qref) + Ki_pc * Phi_pc_q - Iq_star;
g8 = Kp_cc*(Id_star-Id_c) + Ki_cc*Phi_cc_d - Ud_c;
g9 = Kp_cc*(Iq_star-Iq_c) + Ki_cc*Phi_cc_q - Uq_c;
g10 = cos(Theta_pll)*Vd  + sin(Theta_pll)*Vq - Vd_c;
g11 = -sin(Theta_pll)*Vd + cos(Theta_pll)*Vq - Vq_c;
g12 = cos(Theta_pll)*Id2  + sin(Theta_pll)*Iq2 - Id_c;
g13 = -sin(Theta_pll)*Id2 + cos(Theta_pll)*Iq2 - Iq_c;
g14 = cos(Theta_pll)*Ud_c - sin(Theta_pll)*Uq_c - Ud_s;
g15 = sin(Theta_pll)*Ud_c + cos(Theta_pll)*Uq_c - Uq_s;
g = [g1, g2, g3, g4, g5, g6, g7, g8, g9, g10, g11, g12, g13, g14, g15];


%% Calcolo matrice Jacobiana rispetto allo stato (A) e ingresso (B)
A_xx = jacobian(f, x);
A_xy = jacobian(f, y);
A_yx = jacobian(g, x);
A_yy = jacobian(g, y);

disp("Matrica A simbolica: ")
A_sys = A_xx - (A_xy * inv(A_yy) * A_yx);
disp(A_sys)

%% 
ignasi_initialvalues

x_eq = [id1; iq1; id2; iq2; vd_cap; vq_cap; phi_pc_p; phi_pc_q; phi_cc_d; phi_cc_q; x1_pll; theta_pll]; 

y_eq = [id3; iq3; vd; vq; id_c; iq_c; vd_c; vq_c; freq_pll; id_star; iq_star; ud_c; uq_c; ud_s; uq_s];

params_eq = [r1; l1; r2; l2; r3; c3; wN; kp_pc; ki_pc; kp_cc; ki_cc; kp_pll; ki_pll; ed; eq; pref; qref];


 %%
% Sostituzione nelle matrici jacobiane per ottenere matrici linearizzate numeriche

disp("Debug vettore derivate F:")
f_lin = double(subs(f, [x; y; params], [x_eq; y_eq; params_eq])); % steady state proof
disp(f_lin')
disp("Debug vettore derivate G:")
g_lin = double(subs(g, [x; y; params], [x_eq; y_eq; params_eq])); % steady state proof
disp(g_lin')

A_lin = double(subs(A_sys, [x; y; params], [x_eq; y_eq; params_eq]));
B_lin = zeros(length(A_lin),0);
C_lin = zeros(length(A_lin),0);
D_lin = 0;


ss_full = ss(A_lin, B_lin, C_lin, D_lin);

ss_full.StateName = {'id1', 'iq1', 'id2', 'iq2', 'vd_cap', 'vq_cap', 'phi_pc_p', 'phi_pc_q', 'phi_cc_d', 'phi_cc_q', 'x1_pll', 'theta_pll'}; %% aggiunto
%%
stability_analysis(ss_full) % Full stability analyis with worst mode selection and PF

stability_analysis_mode(ss_full, 1) % Investigation PF for specific mode