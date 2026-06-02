function eigenvalue_sensitivity(A_sym, param_names, param_values, gain_patterns)
% EIGENVALUE_SENSITIVITY Computes eigenvalue sensitivity to all parameters (∂ζ/∂p).
%
% INPUTS:
%   A_sym         - Symbolic state matrix (linearized system).
%   param_names   - Cell array of parameter names (matching symbolic variables).
%   param_values  - Nominal parameter values (same length as param_names).
%   gain_patterns - Cell array of gain prefix patterns {'kp_', 'ki_', 'skp_', 'ski_'}
%
% OUTPUT:
%   None (displays comprehensive sensitivity table sorted by frequency).
%
% The function performs finite-difference sensitivity analysis (∂ζ/∂p) for all
% eigenvalues and parameters. Identifies most sensitive parameter per mode and
% controller gains (using customizable gain_patterns). Computation optimized for 
% 26+ parameters in <5 seconds. Results sorted by frequency (high → low).
%
% AUTHOR:
%   Nicolae Darii - VSC eigenvalue sensitivity analysis (modified for original mode numbering)
%
% LICENSED UNDER:
%   MIT License (see LICENSE file in the repository).
%
% ============================================================
% 1. NOMINAL EIGENVALUE COMPUTATION AND SORTING
% ============================================================
fprintf('\n')
fprintf('🔄 Computing nominal eigenvalues (%d states, %d params)...\n', ...
        size(A_sym, 1), length(param_names));
A_num = double(subs(A_sym, param_names, param_values));
[V, D] = eig(A_num);
lambda_num = diag(D);

% SALVA MAPPING ORIGINALI (PRIMA DEL SORTING)
lambda_orig = lambda_num;              % Eigenvalues originali (non ordinati)
orig_mode_nums = (1:length(lambda_num)).';  % Mode 1, 2, ..., n_modes

% SORT BY FREQUENCY (descending) per analisi
freq_hz_orig = abs(imag(lambda_orig)) / (2*pi);
[~, idx_sort] = sort(freq_hz_orig, 'descend');
lambda_num = lambda_num(idx_sort);     % Solo per calcoli: ordinati
orig_mode_nums_sorted = orig_mode_nums(idx_sort);  % ← MAPPING per tabella

zeta_all = -real(lambda_num) ./ abs(lambda_num);  % Damping ratios (su ordinati)
n_modes = length(lambda_num);
n_params = length(param_names);
fprintf('✅ Nominal eigenvalues computed (sorted by f = %.1f → %.1f Hz)\n', ...
        max(abs(imag(lambda_num)) / (2*pi)), min(abs(imag(lambda_num)) / (2*pi)));
    
% ============================================================
% 2. PARAMETER CLASSIFICATION (CONTROLLER GAINS - CUSTOMIZABLE)
% ============================================================
gain_idx = [];
for pattern = gain_patterns
    gain_idx = [gain_idx, find(startsWith(param_names, pattern{1}))];
end
gain_idx = unique(gain_idx);
n_gains = length(gain_idx);
fprintf('📊 Found %d controller gains matching patterns {%s}:\n', n_gains, ...
        strjoin(gain_patterns, ', '));
if n_gains > 0
    fprintf('   %s\n', strjoin(param_names(gain_idx), ', '));
end
% ============================================================
% 3. FINITE-DIFFERENCE SENSITIVITY COMPUTATION
% ============================================================
delta = 1e-6;  % Relative perturbation (optimized for numerical accuracy)
fprintf('🔢 Computing sensitivities (δ=%.0e)...\n', delta);
tic_sens = tic;
table_data = cell(n_modes + 1, 7);
table_data(1, :) = {'Mode', 'λ (re+im)', 'Damping (%)', 'Freq (Hz)', ...
                    'Param Max', '∂ζ/∂p', 'Gain Max'};
for i = 1:n_modes
    lambda0 = lambda_num(i);               % Usa lambda ordinato per calcoli
    sigma0 = real(lambda0); 
    omega0 = abs(imag(lambda0));
    zeta0 = -sigma0 / sqrt(sigma0^2 + omega0^2);
    f_hz = omega0 / (2*pi);
    
    orig_mode_id = orig_mode_nums_sorted(i);  % ← Mode ORIGINALE per colonna 1
    
    fprintf('  Mode %d (%.1f Hz): ', orig_mode_id, f_hz);
    
    % Compute ∂ζ/∂p for ALL parameters
    sens_zeta = zeros(1, n_params);
    for p = 1:n_params
        pert_params = param_values;
        pert_params(p) = pert_params(p) * (1 + delta);
        
        A_pert = double(subs(A_sym, param_names, pert_params));
        lambda_pert = eig(A_pert);
        
        % Match perturbed eigenvalue to ORIGINAL (non ordinato!)
        [~, idx_match] = min(abs(lambda_pert - lambda_orig(orig_mode_id)));
        sigma_pert = real(lambda_pert(idx_match));
        omega_pert = abs(imag(lambda_pert(idx_match)));
        zeta_pert = -sigma_pert / sqrt(sigma_pert^2 + omega_pert^2);
        
        sens_zeta(p) = (zeta_pert - zeta0) / (delta * param_values(p));
    end
    
    % 1) MOST SENSITIVE PARAMETER (overall)
    [~, max_idx] = max(abs(sens_zeta));
    param_max = param_names{max_idx};
    sens_val = sens_zeta(max_idx);
    
    % 2) MOST SENSITIVE GAIN
    if n_gains > 0
        sens_gains = sens_zeta(gain_idx);
        [~, max_gain_idx] = max(abs(sens_gains));
        gain_max_idx = gain_idx(max_gain_idx);
        gain_max = param_names{gain_max_idx};
        sens_gain = sens_zeta(gain_max_idx);
        gain_dir = direction_symbol(sens_gain);
    else
        gain_max = 'None'; 
        gain_dir = '';
    end
    
    % Fill table row CON MODE ORIGINALE
    table_data{i+1, 1} = sprintf('Mode %d', orig_mode_id);  % ← ORIGINALE!
    table_data{i+1, 2} = sprintf('%.3f%+.3fi', real(lambda0), imag(lambda0));
    table_data{i+1, 3} = sprintf('%.2f%%', zeta0*100);
    table_data{i+1, 4} = sprintf('%.1f', f_hz);
    table_data{i+1, 5} = sprintf('%s=%.3g', param_max, param_values(max_idx));
    table_data{i+1, 6} = sprintf('%+.4f %s', sens_val, direction_symbol(sens_val));
    table_data{i+1, 7} = sprintf('%s %s', gain_max, gain_dir);
    
    fprintf('%.1f%% done\n', 100*i/n_modes);
end
sens_time = toc(tic_sens);
% ============================================================
% 4. RESULTS TABLE AND SUMMARY
% ============================================================
mode_sensitivity_table = cell2table(table_data(2:end, :), ...
    'VariableNames', table_data(1, :));
fprintf('\n');
fprintf('=== EIGENVALUE SENSITIVITY ANALYSIS ===\n');
fprintf('⏱️  Computation: %.2f s | %d modes × %d params\n', sens_time, n_modes, n_params);
fprintf('📈 Modes sorted by frequency (high → low) | Original numbering preserved\n');
fprintf('🎛️  Gain patterns: {%s}\n\n', strjoin(gain_patterns, ', '));
disp(mode_sensitivity_table);
% ============================================================
% 5. CRITICAL MODE SUMMARY (MINIMUM DAMPING)
% ============================================================
[zeta_min, crit_mode_idx_sorted] = min(zeta_all);  % idx nel sorting
crit_mode_idx_orig = orig_mode_nums_sorted(crit_mode_idx_sorted);  % ← ORIGINALE!
crit_table_idx = crit_mode_idx_sorted;             % per table_data (sorted)

if n_modes > 0
    crit_sens_str = split(string(table_data{crit_table_idx + 1, 6}), " ");
    crit_sens = str2double(crit_sens_str{1});
    crit_param = table_data{crit_table_idx + 1, 5};
    crit_gain = table_data{crit_table_idx + 1, 7};
    crit_freq = str2double(table_data{crit_table_idx + 1, 4});
    
    fprintf('\n');
    fprintf('🎯 CRITICAL MODE SUMMARY (Mode #%d - MINIMUM DAMPING):\n', crit_mode_idx_orig);
    fprintf('   ζ_min = %.2f%% | f = %.1f Hz\n', zeta_min*100, crit_freq);
    fprintf('   Most sensitive: %s | ∂ζ/∂p = %+.4f\n', crit_param, crit_sens);
    fprintf('   Most sensitive gain: %s\n', crit_gain);
    
    % Stability warning
    if zeta_min < 0.05
        fprintf('⚠️  WARNING: Very low damping detected (ζ < 5%%)\n');
    elseif real(lambda_num(crit_mode_idx_sorted)) >= 0
        fprintf('🚨 CRITICAL: UNSTABLE MODE DETECTED (Re(λ) ≥ 0)\n');
    end
end
end

function dir = direction_symbol(sens)
% DIRECTION_SYMBOL Returns damping direction indicator (↑ζ or ↓ζ).
    if sens > 0
        dir = '↑ζ';   % Parameter increase → damping increase
    else
        dir = '↓ζ';   % Parameter increase → damping decrease
    end
end
