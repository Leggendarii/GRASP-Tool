
% Control Parameters
kp_outer_V_pu = parameter.Value(11);
ki_outer_V_pu = 1/parameter.Value(12);
kp_outer_P_pu = parameter.Value(13);
ki_outer_P_pu = 1/parameter.Value(14);
kp_inner_pu = parameter.Value(15);
ki_inner_pu = 1/parameter.Value(16);
kp_pll = parameter.Value(17);
ki_pll = 1/parameter.Value(18);
T1 = 1;
T2 = 1;

%% Save simulation 0 as reference file

% Simulation setup, start and closing
load_system('black_box');
block = 'black_box/Three-Phase V-I Measurement7'; 
set_param(block, 'Commented', 'off'); 
[~, simOut] = evalc("sim('black_box', 'SaveOutput', 'on', 'ReturnWorkspaceOutputs', 'on');");
close_system('black_box', 0); % chiude senza salvare

t = simOut.tout;                % tempo (assunto comune ai due segnali)
y1 = simOut.Val1.signals.values;     % primo segnale
y2 = simOut.Val2.signals.values;     % secondo segnale

data = [t y1 y2];             % matrice: tempo, segnale1, segnale2

T = table(t, y1, y2, 'VariableNames', {'Time', 'Val1', 'Val2'});

% Crea la cartella 'data' se non esiste
if ~exist('data', 'dir')
    mkdir('data');
end

writetable(T, fullfile('data', 'reference_case.csv'));
disp("---")
disp("Black Box responce extracted and saved")
disp("---")