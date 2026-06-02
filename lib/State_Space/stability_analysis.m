function stability_analysis(ss_system)
% STABILITY_ANALYSIS Performs complete modal analysis of state-space system.
%
% INPUTS:
%   ss_system   - State-space model (ss object) with defined StateName property.
%
% OUTPUT:
%   None (displays comprehensive modal analysis results and plots).
%
% AUTHOR:
%   Nicolae Darii - Adapted for VSC stability analysis
% LICENSED UNDER: MIT License
% ============================================================
% 1. INPUT VALIDATION AND STATE NAMES
% ============================================================
n_states = size(ss_system.A, 1);
if isempty(ss_system.StateName)
    warning('StateName property missing. Using generic labels.');
    ss_system.StateName = arrayfun(@(i) sprintf('State_%d', i), 1:n_states, 'UniformOutput', false)';
end
% ============================================================
% 2. POLE PLOT CON LINEE DI DAMPING (SOSTITUITO)
% ============================================================
figure('Name', 'Complete Modal Analysis', 'NumberTitle', 'off');
pzmap(ss_system);  % Plot poli/zeri (ss object)
hold on; grid on;
sgrid;             % Linee ζ (0:0.1:1) e ω_n (0:1:10 rad/s)
% axis equal;

A = ss_system.A;
[V, D] = eig(A);
lambda = diag(D);
wn = abs(imag(lambda));                       % Natural frequencies (rad/s)
zeta = -real(lambda) ./ abs(lambda) * 100;       % Damping ratios IN %

% ============================================================
% 3. LEFT EIGENVECTOR COMPUTATION
% ============================================================
[W, ~] = eig(A.');                      
W = conj(W);                            
% T = W.' * V;                            
% W = W ./ diag(T);     

for i = 1:n_states
    scale = W(:,i).' * V(:,i);
    
    if abs(scale) < 1e-12
        warning('Mode %d poorly conditioned (scale≈0)', i);
        continue;
    end
    
    W(:,i) = W(:,i) / scale;
end
% ============================================================
% 4. CRITICAL MODE (MINIMUM DAMPING)
% ============================================================
[zeta_min, k] = min(zeta);              
v_k = V(:, k);                          
w_k = W(:, k);                          
% Participation factors
p_k = abs(w_k .* v_k);
perc_p = 100 * p_k / sum(p_k);
[~, idx_sorted] = sort(p_k, 'descend');
% ============================================================
% 5. RESULTS TABLES
% ============================================================
stateNames = ss_system.StateName(:);
% Critical mode PF table
PF_critical = table(stateNames(idx_sorted), repmat(zeta_min, n_states, 1), ...
                   repmat(wn(k)/(2*pi), n_states, 1), p_k(idx_sorted), perc_p(idx_sorted), ...
                   'VariableNames', {'State', 'Damping_%', 'Frequency{Hz}', 'PartAbs', 'PartPercent'});
% Eigenvalue table (sorted by frequency)
eigTable = table((1:n_states)', lambda, real(lambda), imag(lambda), wn/(2*pi), zeta, ...
                 'VariableNames', {'Mode', 'Eigenvalue', 'RealPart', 'ImagPart', 'Frequency{Hz}', 'Damping_%'});
eigTable = sortrows(eigTable, 'Frequency{Hz}', 'descend');
% ============================================================
% 6. CONSOLE OUTPUT
% ============================================================
fprintf('\n=== COMPLETE MODAL ANALYSIS ===\n');
fprintf('System order: %d states\n', n_states);
fprintf('Critical mode: #%d (ζ=%.2f%%)\n\n', k, zeta_min);
fprintf('CRITICAL MODE #%d PARTICIPATION FACTORS:\n', k);
disp(PF_critical);
fprintf('\nCOMPLETE EIGENVALUE SPECTRUM:\n');
disp(eigTable);
% Stability assessment
if all(real(lambda) < 0)
    stability_str = 'STABLE';
    stability_color = [0 .6 0];
else
    stability_str = 'UNSTABLE';
    stability_color = [1 0 0];
end
stato_dominante = stateNames{idx_sorted(1)};
perc_dominante = round(perc_p(idx_sorted(1)), 1);
fprintf('\n>>> SUMMARY: %s | Critical ζ=%.2f%% | Dominant: %s (%.1f%%) <<<\n', ...
        stability_str, zeta_min, stato_dominante, perc_dominante);
% ============================================================
% 7. PLOT HIGHLIGHTS (SOPRA LE LINEE DI DAMPING)
% ============================================================
lambda_crit = lambda(k);
plot(real(lambda_crit), imag(lambda_crit), 'ro', 'MarkerSize', 14, ...
     'MarkerFaceColor', stability_color, 'LineWidth', 3);
text(real(lambda_crit)+.02, imag(lambda_crit), ...
     sprintf('Mode #%d\nζ=%.2f%%\n%s', k, zeta_min, stability_str), ...
     'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', 'w');
title(sprintf('Modal Analysis (n=%d, Critical ζ=%.2f%%)', n_states, zeta_min));
xlabel('Real Part [rad/s]'); ylabel('Imag Part [rad/s]');
legend('Poles', sprintf('Critical Mode #%d', k), 'Location', 'best');
hold off;
end
