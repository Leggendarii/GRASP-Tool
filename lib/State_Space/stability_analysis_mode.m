function stability_analysis_mode(ss_system, mode_number)
% STABILITY_ANALYSIS_MODE Performs modal analysis and participation factors for a specific mode.
%
% INPUTS:
%   ss_system   - State-space model (ss object) with defined StateName property.
%   mode_number - Mode index (1-based) to analyze (must be between 1 and n_states).
%
% OUTPUT:
%   None (displays results and plots pole-zero map).
%
% The function performs complete modal analysis for the specified mode including:
% - Eigenvalue computation (damping ratio ζ, natural frequency)
% - Right/left eigenvectors normalization
% - Participation factors (absolute and normalized percentages)
% - Stability assessment and dominant state identification
% - Pole-zero map visualization with mode highlighting
%
% AUTHOR:
%   Nicolae Darii - Adapted for VSC stability analysis
%
% LICENSED UNDER:
%   MIT License (see LICENSE file in the repository).
%

% ============================================================
% 1. INPUT VALIDATION
% ============================================================

n_states = size(ss_system.A, 1);
if mode_number < 1 || mode_number > n_states
    error('Mode number must be between 1 and %d (n_states = %d)', n_states, n_states);
end

if isempty(ss_system.StateName)
    warning('StateName property missing. Generic state labels will be used.');
    ss_system.StateName = arrayfun(@(i) sprintf('State_%d', i), 1:n_states, 'UniformOutput', false)';
end

% ============================================================
% 2. POLE-ZERO MAP VISUALIZATION
% ============================================================

figure('Name', sprintf('Modal Analysis - Mode %d', mode_number), 'NumberTitle', 'off');
pzmap(ss_system);
hold on;
grid on;

% ============================================================
% 3. EIGENVALUE ANALYSIS
% ============================================================

A = ss_system.A;
[V, D] = eig(A);                    % Right eigenvectors [V], eigenvalues [D]
lambda = diag(D);                   % Eigenvalues
wn = abs(lambda);                   % Natural frequencies (rad/s)
zeta = -real(lambda) ./ wn * 100;         % Damping ratios

% ============================================================
% 4. LEFT EIGENVECTOR COMPUTATION AND NORMALIZATION
% ============================================================

[W, ~] = eig(A.');                  % Left eigenvectors (A^T)
W = conj(W);                        % Complex conjugate
T = W.' * V;                        % Modal matrix normalization
W = W ./ diag(T);                   % Normalize using biorthogonality

% ============================================================
% 5. SELECT SPECIFIED MODE AND COMPUTE PARTICIPATION FACTORS
% ============================================================

k = mode_number;
zeta_k = zeta(k);
v_k = V(:, k);                      % Right eigenvector (mode k)
w_k = W(:, k);                      % Left eigenvector (mode k)

% Participation factors: |w_ki * v_ik|
p_k = abs(w_k .* v_k);
perc_p = 100 * p_k / sum(p_k);      % Normalized percentages

% Sort by participation magnitude (descending)
[~, idx_sorted] = sort(p_k, 'descend');

% ============================================================
% 6. RESULTS TABLE GENERATION
% ============================================================

stateNames = ss_system.StateName(:);
PF_table = table(stateNames(idx_sorted), ...
                repmat(zeta_k, numel(p_k), 1), ...
                repmat(wn(k)/(2*pi), numel(p_k), 1), ...
                p_k(idx_sorted), perc_p(idx_sorted), ...
                'VariableNames', {'State', 'Damping_ζ', 'Frequency{Hz}', 'PartAbs', 'PartPercent'});

% ============================================================
% 7. CONSOLE OUTPUT
% ============================================================

fprintf('\n');
fprintf('=== MODAL ANALYSIS RESULTS - MODE %d ===\n', k);
fprintf('Eigenvalue: λ = %.4f ± j%.4f rad/s\n', real(lambda(k)), imag(lambda(k)));
fprintf('Damping ratio: ζ = %.4f\n', zeta_k);
fprintf('Natural frequency: f_n = %.2f Hz\n', wn(k)/(2*pi));
fprintf('\nParticipation Factors:\n');
disp(PF_table);

% Dominant state identification
stato_dominante = stateNames{idx_sorted(1)};
perc_dominante = round(perc_p(idx_sorted(1)), 1);
freq_str = sprintf('%.2f Hz', wn(k)/(2*pi));

% Stability assessment
if real(lambda(k)) < 0
    stability_str = 'STABLE';
    stability_color = 'green';
else
    stability_str = 'UNSTABLE';
    stability_color = 'red';
end

fprintf('\n');
fprintf('>>> SUMMARY: Mode %d is %s (ζ = %.4f) <<<\n', k, stability_str, zeta_k);
fprintf('Frequency: %s | Dominant state: "%s" (%.1f%% participation)\n', ...
        freq_str, stato_dominante, perc_dominante);

% ============================================================
% 8. MODE HIGHLIGHTING ON POLE-ZERO MAP
% ============================================================

lambda_k = lambda(k);
plot(real(lambda_k), imag(lambda_k), 'ro', 'MarkerSize', 12, 'MarkerFaceColor', stability_color, 'LineWidth', 2);
text(real(lambda_k)+0.02, imag(lambda_k), sprintf(' Mode %d\nζ=%.3f', k, zeta_k), ...
     'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', 'w');

legend('Poles', sprintf('Mode %d (ζ=%.3f)', k, zeta_k), 'Location', 'best');
title(sprintf('Pole-Zero Map - Mode %d Analysis (ζ=%.3f, f=%.2f Hz)', k, zeta_k, wn(k)/(2*pi)));
hold off;

end
