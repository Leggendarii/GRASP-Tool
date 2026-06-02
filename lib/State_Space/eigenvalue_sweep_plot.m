function eigenvalue_sweep_plot(A_sym, param_names, param_values, param_sweep_name)
% EIGENVALUE_SWEEP_PLOT Generates eigenvalue loci plot for parameter sweep analysis.
%
% INPUTS:
%   A_sym          - Symbolic state matrix (from linearization)
%   param_names    - Cell array of parameter names (must match symbolic variables)
%   param_values   - Nominal parameter values (same length as param_names)
%   param_sweep_name - Name of parameter to sweep (string, must exist in param_names)
%
% OUTPUT:
%   None (generates eigenvalue loci plot with color-coded trajectories)
%
% The function performs parameter sweep and plots eigenvalue trajectories with 
% smooth blue→red color gradient. Modes ordered by frequency (Mode 1 = highest f).
%
% AUTHOR:
%   Nicolae Darii - VSC stability sensitivity analysis
%
% LICENSED UNDER:
%   MIT License (see LICENSE file in the repository).

% ============================================================
% 1. PARAMETER INDEX AND SWEEP RANGE
% ============================================================
param_idx = find(strcmp(param_names, param_sweep_name));
p_nom = param_values(param_idx);
p_range = linspace(0.01*p_nom, 2*p_nom, 100);  % 1% to +100%
n_states = size(A_sym,1);
all_lambda = NaN(length(p_range), n_states);

% ============================================================
% 2. EIGENVALUE COMPUTATION SWEEP
% ============================================================
for i = 1:length(p_range)
    sweep_params = param_values;
    sweep_params(param_idx) = p_range(i);
    A_sweep = double(subs(A_sym, param_names, sweep_params));
    all_lambda(i,:) = eig(A_sweep);
end

% ============================================================
% 3. EIGENvalue LOCI PLOT (NO LINE INTERPOLATION)
% ============================================================
figure;
hold on;

% Colormap: BLUE → RED (coerente con colorbar)
cmap = [linspace(0,1,length(p_range))', ...    % R
        0.2*linspace(0,1,length(p_range))', ...% G
        linspace(1,0,length(p_range))'];       % B
colormap(cmap);

% Normalized param for color indexing
p_norm = (p_range - p_range(1)) / (p_range(end) - p_range(1));  % 0→1

% Plotta SOLO punti, nessuna interpolazione tra autovalori consecutivi
for state = 1:n_states
    re = real(all_lambda(:,state));
    im = imag(all_lambda(:,state));
    for i = 1:length(p_range)
        frac = p_norm(i);
        color = [frac, 0.2*frac, 1-frac];  % coerente con cmap
        plot(re(i), im(i), 'o', ...
            'MarkerSize', 4, ...
            'MarkerFaceColor', color, ...
            'MarkerEdgeColor', 'none');
    end
end

% Nominal operating point marker
[~, nom_idx] = min(abs(p_range - p_nom));
scatter(real(all_lambda(nom_idx,:)), imag(all_lambda(nom_idx,:)), 80, 'y', ...
    '^', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5, 'DisplayName', 'Nominal');

% ★ STABILITY CROSSING LINE (y-axis at x=0)
xline(0, '--k', 'Stability Boundary', 'LineWidth', 2);

% Parameter colorbar (coerente con colormap)
h = colorbar;
clim([p_range(1), p_range(end)]);
h.Label.String = sprintf('%s', param_sweep_name);
h.Label.Interpreter = 'none';

% Professional formatting
xlabel('Real part σ [rad/s]', 'FontSize', 14);
ylabel('Imaginary part ω [rad/s]', 'FontSize', 14);
title(sprintf('Eigenvalue Loci - %s', param_sweep_name), ...
      'Interpreter', 'none', 'FontSize', 16);
grid on; box on; axis equal;

% ★ MODE LABELS (high freq = Mode 1, low freq = Mode n)
nom_idx_label = round(length(p_range)/2);
for state = 1:n_states
    re = real(all_lambda(nom_idx_label,state));
    im = imag(all_lambda(nom_idx_label,state));
    text(re+0.1, im, sprintf('M%d', state), ...
         'FontSize', 10, 'FontWeight', 'bold');
end

fprintf('\n')
fprintf('✅ Plot: %s (blue=1%% → red=200%%, ^ = nominal)\n', param_sweep_name);
fprintf('   Modes ordered: Mode 1 = highest freq → Mode %d = lowest freq\n', n_states);
end
