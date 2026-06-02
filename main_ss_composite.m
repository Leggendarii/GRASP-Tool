% clear all;
close all;
clc;

% Aggiungi librerie
addpath(genpath('lib'));
addpath(genpath('data'));

%% Grid Setup
Parameters_Setup_grey_box

% Hard bypass the step and magnitude time
V_step_time = 100;                 % Voltage ref step time (s)
V_finalvalue = 1;                  % Voltage ref final value (pu)
P_initialvalue = 0;                % Power ref intial value (pu)
P_step_time = 1;                   % Power ref step time (s)
P_step = 0;                        % Small signal step


P_finalvalue = 0.486;                %%%% Power ref final value (pu)

%% AUTO-GENERA NAME (con VIRGOLA)
name = sprintf('P%.1f', P_finalvalue);
name = strrep(name, '.', ',');  % P0.9 → P0,9
% name = "P0,9";

%% Save or call the initial conditions
save_initial_conditions(name)   %%% SBLOCCA QUESTO PER GENERARE NUOVI PUNTI %%%
load(name)  % Aggiorna con variabili di stato

%% Build all the state space elements
STATE_SPACE_power_control_dq;   %% ss_power
STATE_SPACE_current_control     %% ss_current
STATE_SPACE_DC_control          %% ss_dc
STATE_SPACE_filter              %% ss_filter
STATE_SPACE_frame_conversion    %% ss_frame
STATE_SPACE_grid                %% ss_grid
STATE_SPACE_laglead             %% ss_laglead
STATE_SPACE_PLL_dq_omega_output %% ss_PLL

%% Label the blocks and predefine the direct connections
% Power
ss_power.StateName = {'Flux_DC', 'Flux_PoC'};
ss_power.InputName = {'Vdc_ref', 'Vdc_mes_filt', 'Vpoc_ref', 'ig_d_c', 'ig_q_c', 'vpoc_d_c', 'vpoc_q_c'};
ss_power.OutputName = {'iref_d_c', 'iref_q_c'};

% PLL
ss_PLL.StateName = {'theta', 'Flux_PLL'};
ss_PLL.InputName = {'vpoc_q_c'};
ss_PLL.OutputName = {'theta'};

% laglead
ss_laglead.StateName = {'Flux_laglead'};
ss_laglead.InputName = {'Vdc_mes'};
ss_laglead.OutputName = {'Vdc_mes_filt'};

% Grid 
ss_grid.StateName = {'ig_d_s', 'ig_q_s'};
ss_grid.InputName = {'vpoc_d_s', 'vpoc_q_s', 'vg_d_s', 'vg_q_s'};
ss_grid.OutputName = {'ig_d_s', 'ig_q_s'};  %% maybe consider vdgrid vqgrid const

% Frame conversion
ss_frame.InputName = {'vpoc_d_s', 'vpoc_q_s', 'ig_d_s', 'ig_q_s', 'iL_d_s', 'iL_q_s', 'vvsc_d_c', 'vvsc_q_c', 'theta'};
ss_frame.OutputName = {'vpoc_d_c', 'vpoc_q_c', 'ig_d_c', 'ig_q_c', 'iL_d_c', 'iL_q_c', 'vvsc_d_s', 'vvsc_q_s'};

% Filter
ss_filter.StateName = {'iL_d_s', 'iL_q_s', 'vpoc_d_s', 'vpoc_q_s'};
ss_filter.InputName = {'vvsc_d_s', 'vvsc_q_s', 'ig_d_s', 'ig_q_s'};
ss_filter.OutputName = {'iL_d_s', 'iL_q_s', 'vpoc_d_s', 'vpoc_q_s'};  %% maybe consider vdgrid vqgrid const

% DC Dyin
ss_dc.StateName = {'Vdc_mes'};
ss_dc.InputName = {'P_ref', 'ig_d_c', 'ig_q_c', 'vpoc_d_c', 'vpoc_q_c'};
ss_dc.OutputName = {'Vdc_mes'};

% Current Controller
ss_current.StateName = {'Cd', 'Cq'};
ss_current.InputName = {'iref_d_c', 'iref_q_c', 'iL_d_c', 'iL_q_c'};
ss_current.OutputName = {'vvsc_d_c', 'vvsc_q_c'};

%% Connect
ss_system = connect(ss_power, ss_PLL, ss_grid, ss_laglead, ss_frame , ss_filter, ss_dc, ss_current,...
    {'P_ref', 'Vpoc_ref', 'Vdc_ref', 'vg_d_s', 'vg_q_s'}, ... % Ingressi di ss_P_I
    {'ig_d_s', 'ig_q_s', 'iL_d_s', 'iL_q_s', 'vpoc_d_s', 'vpoc_q_s', 'Vdc_mes', 'vvsc_d_s', 'vvsc_q_s'}); % Uscite system

%% Stability study
stability_analysis(ss_system)
% stability_analysis_mode(ss_system, 3)

% hold on
% main_ss_direct

save(fullfile('data', 'ss_system.mat'), 'ss_system')
save_commandwindow_log()

% Test EMT
P_step = 0.05;                     %%% Change small signal active power step
V_finalvalue = 0.99;            %%% Change final value voltage reference

P_step_time = 10; 
V_step_time = 10; 
Tobs = 20;

storage = P_finalvalue;
P_initialvalue = storage;
P_finalvalue = P_step;  

load_system('small_signal_box');
block = 'small_signal_box/SS_Element'; 
set_param(block, 'Commented', 'off'); 

[~, out] = evalc("sim('small_signal_box', 'SaveOutput', 'on', 'ReturnWorkspaceOutputs', 'on')");

save_commandwindow_log()

%% Test svd
% 
% 
% % Vettore di frequenze (rad/s)
% w = unique(round(logspace(0,log10(600),100)))*2*pi;
% 
% % Risposta in frequenza: H(jw) di dimensione [Ny, Nu, lunghezza(w)]
% H = freqresp(ss_system, w);
% 
% % Loop per SVD per ogni frequenza
% sigma_max = zeros(size(w));
% for i = 1:length(w)
%     [U, S, V] = svd(squeeze(H(:,:,i)));  % SVD della matrice 2D Ny x Nu
%     sigma_max(i) = max(diag(S));         % Valore singolare massimo
% end
% 
% % Plot
% % max_sig = m
% loglog(w/(2*pi), log10(sigma_max));
% % xlim([1, 600]);
% xlabel('Frequenza [Hz]'); ylabel('σ_max [dB]');

