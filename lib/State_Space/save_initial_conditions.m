function save_initial_conditions(output_filename)
% SAVE_INITIAL_CONDITIONS Extracts and saves steady-state initial conditions as individual variables.
%
% INPUTS:
%   output_filename - Filename (without extension) for saving .mat file.
%
% OUTPUT:
%   None (saves .mat file with individual steady-state variables).
%
% The function runs a short simulation of 'small_signal_box' model with SS_Element
% block commented out to obtain steady-state operating conditions. Extracts final
% values from simulation logs and saves them as individual workspace variables
% (not struct) for use in symbolic linearization.
%
% AUTHOR:
%   Nicolae Darii - VSC small-signal analysis framework
%
% LICENSED UNDER:
%   MIT License (see LICENSE file in the repository).
%

% ============================================================
% 1. PATH MANAGEMENT AND FOLDER CREATION
% ============================================================

% Add required libraries
addpath(genpath('lib'));
addpath(genpath('data'));

% Create standardized output folder
folder_path = fullfile('data', 'Initial_Conditions');
if ~exist(folder_path, 'dir')
    mkdir(folder_path);
    fprintf('📁 Created folder: %s\n', folder_path);
end

full_path = fullfile(folder_path, output_filename);
if exist(full_path, 'file')
    fprintf('⚠️  File exists, overwriting: %s\n', full_path);
end

% ============================================================
% 2. SIMULINK MODEL PREPARATION AND EXECUTION
% ============================================================

% Load and prepare small-signal model
load_system('small_signal_box');
block_path = 'small_signal_box/SS_Element';

% Comment out small-signal block to get pure steady-state
set_param(block_path, 'Commented', 'on');

fprintf('🔄 Running steady-state simulation...\n');
tic_sim = tic;

% Run simulation and capture outputs
[~, sim_output] = evalc('sim(''small_signal_box'', ''SaveOutput'', ''on'', ''ReturnWorkspaceOutputs'', ''on'')');

% Clean up
set_param(block_path, 'Commented', 'off');  % Restore block
close_system('small_signal_box', 0);       % Close without saving
sim_time = toc(tic_sim);

fprintf('✅ Simulation completed in %.2f s\n', sim_time);

% ============================================================
% 3. STEADY-STATE EXTRACTION FROM LOGGED SIGNALS
% ============================================================

out = sim_output;  % Rename for clarity

% Extract final values (steady-state) from simulation logs
vpoc_q_c   = out.logsout{1}.Values.Data(end);                    % PoC voltage q (conv frame)
vvsc_d_c   = out.logsout{2}.Values.Data(end, 1);                 % VSC voltage d (conv frame)  
vvsc_q_c   = out.logsout{2}.Values.Data(end, 2);                 % VSC voltage q (conv frame)
vdc_mes    = out.logsout{3}.Values.Data(end);                    % DC voltage measurement
theta      = out.logsout{4}.Values.Data(end);                    % Frame angle difference
Vdc_filt   = out.logsout{5}.Values.Data(end);                    % Filtered DC voltage
ig_d_c     = out.logsout{6}.Values.Data(end, 1);                 % Grid current d (conv frame)
ig_q_c     = out.logsout{6}.Values.Data(end, 2);                 % Grid current q (conv frame)
vpoc_d_c   = out.logsout{7}.Values.Data(end, 1);                 % PoC voltage d (conv frame)
iL_d_c     = out.logsout{8}.Values.Data(end, 1);                 % Filter current d (conv frame)
iL_q_c     = out.logsout{8}.Values.Data(end, 2);                 % Filter current q (conv frame)
ig_d_s     = out.logsout{9}.Values.Data(end, 1);                 % Grid current d (sync frame)
ig_q_s     = out.logsout{9}.Values.Data(end, 2);                 % Grid current q (sync frame)
vpoc_d_s   = out.logsout{10}.Values.Data(end, 1);                % PoC voltage d (sync frame)
vpoc_q_s   = out.logsout{10}.Values.Data(end, 2);                % PoC voltage q (sync frame)
iL_d_s     = out.logsout{11}.Values.Data(end, 1);                % Filter current d (sync frame)
iL_q_s     = out.logsout{11}.Values.Data(end, 2);                % Filter current q (sync frame)
vvsc_d_s   = out.logsout{12}.Values.Data(end, 1);                % VSC voltage d (sync frame)
vvsc_q_s   = out.logsout{12}.Values.Data(end, 2);                % VSC voltage q (sync frame)
vg_d_s     = out.logsout{13}.Values.Data(end, 1);                % Grid voltage d (sync frame)
vg_q_s     = out.logsout{13}.Values.Data(end, 2);                % Grid voltage q (sync frame)
iref_d_c   = out.logsout{14}.Values.Data(end);                   % Current reference d (conv frame)
iref_q_c   = out.logsout{15}.Values.Data(end);                   % Current reference q (conv frame)
pref       = out.logsout{16}.Values.Data(end);                   % Power reference
vdc_ref    = out.logsout{17}.Values.Data(end);                   % DC voltage reference
vpoc_ref   = out.logsout{18}.Values.Data(end);                   % PoC voltage reference

% Extract final state values from xFinal
qd         = out.xFinal{4}.Values.Data;          % Current controller d integrator
qq         = out.xFinal{5}.Values.Data;          % Current controller q integrator
flux_DC    = out.xFinal{6}.Values.Data;          % DC-link controller integrator
flux_PoC   = out.xFinal{7}.Values.Data;          % PoC voltage controller integrator
flux_PLL   = out.xFinal{8}.Values.Data;          % PLL integrator

% ============================================================
% 4. SAVE INDIVIDUAL VARIABLES (NON-STRUCTURED)
% ============================================================

save(full_path, ...
    'vpoc_q_c', 'vdc_mes', 'theta', 'Vdc_filt', ...
    'ig_d_c', 'ig_q_c', 'vpoc_d_c', 'iL_d_c', 'iL_q_c', ...
    'ig_d_s', 'ig_q_s', 'vpoc_d_s', 'vpoc_q_s', ...
    'iL_d_s', 'iL_q_s', 'vvsc_d_s', 'vvsc_q_s', ...
    'vvsc_d_c', 'vvsc_q_c', 'vg_d_s', 'vg_q_s', ...
    'iref_d_c', 'iref_q_c', 'pref', 'vdc_ref', 'vpoc_ref', ...
    'qd', 'qq', 'flux_DC', 'flux_PoC', 'flux_PLL');

fprintf('✅ Steady-state conditions saved: %s\n', full_path);
fprintf('📊 %d variables extracted from simulation logs\n', 29);

end
