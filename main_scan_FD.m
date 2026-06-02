% %% Technical University of Catalonia (UPC)
% %% Higher Technical School of Industrial Engineering of Barcelona (ETSEIB)
% %% Centre of Technological Innovation in Static Converters and Drives (CITCEA)
% %% Doctoral Program in Electrical Engineering
% %% Developed by: Luis Angel Garcia Reyes, MSc
% %% Q&A please mail to: luis.reyes@upc.edu
% 
% %% How to use the "Stability and Interaction assessment in
% %% frequency-Domain (SIaD)" tool for modern power systems 

clear all;
close all;
clc;

% Aggiungi librerie
addpath(genpath('lib'));
addpath(genpath('data'));

%% Select the simulink model to scan

program = 'white_box.slx';
model = 'white_box';
params_command = 'Parameters_Setup_grey_box;';

%%
% Parametri simulazione
Tinit = 5;  % Selezione steady state
fs = 1;     % Sampling frequency dello scanner
delta_t = 10e-6; % Simulation timestep
fd0 = unique(round(logspace(0,log10(600),100))); % Vettore lin-log delle freqquenze 

% Parametri stato stabile e perturbazioni (come nel codice originale)
f0 = 50; % Frequenza fondamentale
w = 2*pi*f0;
Sbase = 14E6;
Vbase = 0.69E3;
Vpeak = (Vbase/sqrt(3))*sqrt(2);
Vq_ss = 0;
Vd_ss = 0;
Ipeak = Sbase/Vpeak;
Iq_ss = 0;
Id_ss = 0;
Vperturbation = 0.02;  % Ampiezza perturbazione
Iperturbation = 0.03;

% Opzionale per modello lineare
samples = 10000;
jw1 = 1i*2*pi*(logspace(0,log10(1/delta_t),samples));

% Opzioni scanner
ss_cal = 1;
scanner_type = 1;
signal_type = 1;
scanner_selector = 2;
linear = 0;
%%

% Esecuzione comando parametri in base a input
eval(params_command);

% Hard bypass the step and magnitude time
V_step_time = 100;                 % Voltage ref step time (s)
P_step_time = 1.5;                   % Power ref step time (s)
P_finalvalue = 0.486;                % Power ref final value (pu)

Ts = delta_t;
Tobs = 10;

%%

% Caricamento modello simulink e lancio FDScanning
load_system(program);
block = [model '/SIaD Tool'];
set_param(block, 'Commented', 'off');

%%
FDScanning;
close_system(program, 0);

%% Salvataggio risultati (da invertire in questa fase gia per migliorare la cosa)
name = input('Enter the file name (without extension): ', 's');
T = table(fd0', Ydd1', Ydq1', Yqd1', Yqq1', Ydd2', Ydq2', Yqd2', Yqq2', ...
    'VariableNames', {'f', 'Ydd_c', 'Ydq_c', 'Yqd_c', 'Yqq_c', ...
                      'Ydd_g', 'Ydq_g', 'Yqd_g', 'Yqq_g'});

if ~exist('data', 'dir')
    mkdir('data');
end

writetable(T, fullfile('data', name + ".csv"));
