close all
clear all
clc

%% Call library
addpath(genpath('lib'));
addpath(genpath('data'));

%% Names setup for the current round

% parameters.csv : file con i dati base
% reference_case.csv: riferimento black box

%% Run the benchamrk case (balck box behaviour in time domain)

base_setup           % Setup nominal parameters
base_case_black    % Run della simulazione blackbox/white standard 

%% FMINCON optimization 
tic

load_system('white_box');
block = 'white_box/Three-Phase V-I Measurement7'; 
set_param(block, 'Commented', 'off'); 

% Nomi dei parametri (per leggibilità nei risultati)
paramNames = {'kp_outer_V_pu', 'ki_outer_V_pu', ...
              'kp_outer_P_pu', 'ki_outer_P_pu', ...
              'kp_inner_d_pu',   'ki_inner_d_pu', ...
              'kp_inner_q_pu',   'ki_inner_q_pu', ...
              'kp_pll',        'ki_pll', ...
              'T1',            'T2'};



%% Limiti inferiori e superiori (stessi del Particle Swarm)
% lb = [0,     0,     0,    0,    0,     0,    0,     0,   5,    3, 1E-6, 1E-6];
lb = [0,     0,     0,    0,    0,     0,    0,     0,   0.5,    1, 1E-6, 1E-6];
% ub_0 = [0.5, 811, 0.46, 1000, 4, 2955, 2.9, 1751, 7, 6.4, 0.333, 0.352];
% ub_0 = [1, 600, 1, 600, 1, 1000, 1, 1000, 2, 2, 0.1, 0.1];
x0 = [0.5, 1, 0.5, 1, 0.5, 100, 0.5, 100, 6, 4, 0.00001, 0.001]; % Caso x
% x0 = [0.5, 6, 0.5, 6, 0.5, 60, 0.5, 60, 6, 4, 0.00001, 0.001]; % Caso x
% ub_0 = [1.5746, 12.308, 0.3363, 0.73773, 2.4372, 59.914, 1.5171, 58.972, 19.801, 5.1625, 0.1, 0.1]; % Caso x+1
ub = [10,  6000,     20,  6000,    20,  6000, 20, 6000,  20,   50, 1, 1];

lb = [0,     0,     0,    0,    0,     0,    0,     0,   0.5,    1, 1E-6, 1E-6];
x0 = [0.5, 1, 0.5, 1, 0.5, 100, 0.5, 100, 6, 4, 0.00001, 0.001]; 
ub = [10,  6000,     20,  6000,    20,  6000, 20, 6000,  20,   50, 1, 1];

%% Scaling
% Punto iniziale (puoi metterlo centrale o derivato da un tuning esistente)
% x0_test = lb + (ub - lb) .* rand(size(lb));
% x0 = test_and_fix_x0(x0_test, lb, ub);
% x0 = ub_0;

[ub_s, lb_s, x0_s, scaleFcn, unscaleFcn] = scale_bounds(ub, lb, x0);

%% Funzione obiettivo: chiama Simulink e calcola il costo
objfun = @(xs) run_simulink_and_compute_cost( ...
    xs, unscaleFcn);

% Nessun vincolo lineare
A = []; b = [];
Aeq = []; beq = [];

% Nessun vincolo non lineare extra (puoi aggiungerli qui)
nonlincon = [];

% % Opzioni fmincon
% options = optimoptions('fmincon', ...
%     'Display', 'iter-detailed', ...    % Output dettagliato
%     'Algorithm', 'sqp', ... % Alternativa: 'sqp'
%     'MaxFunctionEvaluations', 1e4, ...
%     'OptimalityTolerance', 1e-3, ...
%     'StepTolerance', 1e-3 ...
%     );

options = optimoptions('fmincon', ...
    'Display', 'iter-detailed', ...           % Output dettagliato
    'Algorithm', 'interior-point', ...        % Trust region controllato
    'MaxFunctionEvaluations', 1e5, ...        % Budget ampio
    'MaxIterations', 2000, ...                % Molte iterazioni
    'OptimalityTolerance', 1e-3, ...          % Rilassata per esplorazione
    'StepTolerance', 1e-3, ...                % Passi minimi grandi
    'FunctionTolerance', 1e-3, ...            % Cambi f(x) ampi
    'ConstraintTolerance', 1e-2, ...          % Vincoli rilassati
    'FiniteDifferenceStepSize', 1e-2);        % Passi FD grandi per gradienti robusti

% options = optimoptions('fmincon', ...
%     'Display', 'iter-detailed', ...
%     'Algorithm', 'interior-point', ...
%     'MaxFunctionEvaluations', 1e5, ...
%     'MaxIterations', 2000, ...
%     'OptimalityTolerance', 1e-6, ...
%     'StepTolerance', 1e-8, ...
%     'FunctionTolerance', 1e-6, ...
%     'ConstraintTolerance', 1e-6, ...
%     'FiniteDifferenceStepSize', 1e-4);


    %'UseParallel', true, ...           % Se vuoi parallelizzare simulazioni
    
% Esegui ottimizzazione
[xs_opt, fval_opt, exitflag, output] = fmincon( ...
    objfun, x0_s, ...
    A, b, ...
    Aeq, beq, ...
    lb_s, ub_s, ...
    nonlincon, ...
    options);

x_opt = unscaleFcn(xs_opt);

% Conversione risultati in struttura leggibile
bestParams = cell2struct(num2cell(x_opt'), paramNames, 2);

% Mostra risultati
disp('Optimal parameters found with fmincon:');
disp(bestParams);
disp(['Objective value: ', num2str(fval_opt)]);
toc


%% Last simulation round

% Assegna i parametri ottimali al workspace di Simulink
assignin('base', 'kp_outer_V_pu', bestParams.kp_outer_V_pu);
assignin('base', 'ki_outer_V_pu', bestParams.ki_outer_V_pu);
assignin('base', 'kp_outer_P_pu', bestParams.kp_outer_P_pu);
assignin('base', 'ki_outer_P_pu', bestParams.ki_outer_P_pu);
assignin('base', 'kp_inner_d_pu', bestParams.kp_inner_d_pu);
assignin('base', 'ki_inner_d_pu', bestParams.ki_inner_d_pu);
assignin('base', 'kp_pll', bestParams.kp_pll);
assignin('base', 'ki_pll', bestParams.ki_pll);

assignin('base', 'T1', bestParams.T1);
assignin('base', 'T2', bestParams.T2);

assignin('base', 'kp_inner_q_pu', bestParams.kp_inner_q_pu);
assignin('base', 'ki_inner_q_pu', bestParams.ki_inner_q_pu);

% (Riassegna anche tutti gli altri parametri fissi se necessario, come fatto nella funzione)

% Lancia la simulazione con i parametri ottimali
[~, simOut] = evalc("sim('white_box', 'SaveOutput', 'on', 'ReturnWorkspaceOutputs', 'on')");
close_system('white_box', 0); % chiude senza salvare

% Estrai i risultati
t = simOut.tout;
Val1 = simOut.Val1.signals.values;
Val2 = simOut.Val2.signals.values;

%% Comparision with original case

T = readtable("reference_case.csv");
% T1 = readtable("resultant_case.csv");

% Visualizza i risultati
figure;
subplot(2,1,1);
plot(t, Val1, 'LineWidth', 1.5);
hold on
plot(t, T.Val1, 'LineWidth', 1.5,'LineStyle','--')
xlabel('Time [s]');
ylabel('Per-unit varaible');
title('Variable 1');
legend('Optimized', 'Reference');
grid on;

subplot(2,1,2);
plot(t, Val2, 'LineWidth', 1.5);
hold on 
plot(t, T.Val2, 'LineWidth', 1.5,'LineStyle','--')
xlabel('Time [s]');
ylabel('Per-unit varaible');
title('Variable 2');
legend('Optimized', 'Reference');
grid on;

%% Save time domain grey box response
T = table(t, Val1, Val2, 'VariableNames', {'Time', 'Val1', 'Val2'});

% Crea la cartella 'data' se non esiste
if ~exist('data', 'dir')
    mkdir('data');
end

writetable(T, fullfile('data', 'resultant_case.csv'));
disp("---")
disp("Grey Box responce extracted and saved")
disp("---")

%% Print gains
% Recupera i gains originali
parameter = readtable("parameters.csv");
kp_outer_V_pu_orig = parameter.Value(11);
ki_outer_V_pu_orig = 1/parameter.Value(12);
kp_outer_P_pu_orig = parameter.Value(13);
ki_outer_P_pu_orig = 1/parameter.Value(14);
kp_inner_pu_orig = parameter.Value(15);
ki_inner_pu_orig = 1/parameter.Value(16);
kp_pll_orig = parameter.Value(17);
ki_pll_orig = 1/parameter.Value(18);

% Recupera i gains ottimizzati
kp_outer_V_pu_opt = bestParams.kp_outer_V_pu;
ki_outer_V_pu_opt = bestParams.ki_outer_V_pu;
kp_outer_P_pu_opt = bestParams.kp_outer_P_pu;
ki_outer_P_pu_opt = bestParams.ki_outer_P_pu;
kp_inner_d_pu_opt = bestParams.kp_inner_d_pu;
ki_inner_d_pu_opt = bestParams.ki_inner_d_pu;
kp_inner_q_pu_opt = bestParams.kp_inner_q_pu;
ki_inner_q_pu_opt = bestParams.ki_inner_q_pu;
kp_pll_opt = bestParams.kp_pll;
ki_pll_opt = bestParams.ki_pll;
T1_opt = bestParams.T1;
T2_opt = bestParams.T2;


% Salva i gains in un file CSV
gainsTable = table( kp_outer_V_pu_opt, ki_outer_V_pu_opt, ...
                    kp_outer_P_pu_opt, ki_outer_P_pu_opt, ...
                    kp_inner_d_pu_opt,   ki_inner_d_pu_opt, ...
                    kp_inner_q_pu_opt,   ki_inner_q_pu_opt, ...
                    kp_pll_opt,        ki_pll_opt, ...
                    T1_opt,            T2_opt,       ...
                    'VariableNames', {'Kp_outer_V', 'Ki_outer_V', ...
                                      'Kp_outer_P', 'Ki_outer_P', ...
                                      'Kp_inner_d',   'Ki_inner_d', ...
                                      'Kp_inner_q',   'Ki_inner_q', ...
                                      'Kp_pll',     'Ki_pll', ...
                                      'T1',     'T2'});

if ~exist('data', 'dir')
    mkdir('data');
end

name = 'greygains';
writetable(gainsTable, fullfile('data', name + ".csv"));

disp("---")
disp("Grey Box equivalent gains saved")
disp("---")

% Creo la tabella originale e ottimizzata
Original = [kp_outer_V_pu_orig; ki_outer_V_pu_orig; kp_outer_P_pu_orig; ki_outer_P_pu_orig; ...
            kp_inner_pu_orig; ki_inner_pu_orig; kp_inner_pu_orig; ki_inner_pu_orig; kp_pll_orig; ki_pll_orig; NaN; NaN];

Optimizator = [kp_outer_V_pu_opt; ki_outer_V_pu_opt; kp_outer_P_pu_opt; ki_outer_P_pu_opt; ...
               kp_inner_d_pu_opt; ki_inner_d_pu_opt; kp_inner_q_pu_opt; ki_inner_q_pu_opt; kp_pll_opt; ki_pll_opt; T1_opt; T2_opt];

% Nomi delle righe
RowNames = {'kp_outer_V_pu', 'ki_outer_V_pu', 'kp_outer_DC/P_pu', 'ki_outer_DC/P_pu', ...
            'kp_inner_d_pu', 'ki_inner_d_pu', 'kp_inner_q_pu', 'ki_inner_q_pu' 'kp_pll', 'ki_pll', 'T1', 'T2'};

% Costruisco la tabella
GainsTable = table(Original, Optimizator, 'RowNames', RowNames);


% Stampa la tabella
disp(GainsTable)

