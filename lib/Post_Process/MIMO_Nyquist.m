function MIMO_Nyquist(frequencies, eigenvalues, critical_visible, plot_args, legend_label)
    % MIMO_NYQUIST Plots the Nyquist diagram for a MIMO system's eigenvalues.
    %
    % INPUTS:
    %   frequencies      - Vector of frequency points (not directly used in plotting).
    %   eigenvalues      - 2xN matrix of eigenvalues for each frequency (complex values).
    %   critical_visible - Boolean (1 or 0): show (-1,0) critical point if 1.
    %   plot_args        - (Optional) Struct with plot style fields:
    %                      'style1', 'style2', 'style3', 'style4'.
    %   legend_label     - (Optional) String for legend entry.
    %
    % The function plots the real and imaginary parts of the eigenvalues for a
    % two-input, two-output (2x2) system, showing both positive and negative
    % imaginary parts for symmetry. The critical point (-1,0) can be shown or hidden.
    %
    % AUTHOR:
    %   Nicolae Darii (DTU and Siemens Gamesa)
    %
    % LICENSED UNDER:
    %   MIT License (see LICENSE file in the repository).
    %

    % Set default plot_args if not provided
    if nargin < 4
        plot_args = struct();
    end
    if nargin < 5
        legend_label = '';
    end

    N = length(frequencies); % Number of frequency points

    % Reorder eigenvalues if needed (custom function)
    ordered_eigenvalues = exchange(eigenvalues);

    % Set default plot styles if not provided in plot_args
    if ~isfield(plot_args, 'style1'), plot_args.style1 = '-b'; end
    if ~isfield(plot_args, 'style2'), plot_args.style2 = '-b'; end
    if ~isfield(plot_args, 'style3'), plot_args.style3 = '--b'; end
    if ~isfield(plot_args, 'style4'), plot_args.style4 = '--b'; end

    % Plot the first set of eigenvalues (positive and negative imaginary parts)
    plot(real(ordered_eigenvalues(1, :)), imag(ordered_eigenvalues(1, :)), plot_args.style1, ...
        'LineWidth', 1.5, 'HandleVisibility', 'off');
    hold on;
    plot(real(ordered_eigenvalues(1, :)), -imag(ordered_eigenvalues(1, :)), plot_args.style2, ...
        'LineWidth', 1.5, 'HandleVisibility', 'off');

    % Plot the second set of eigenvalues (positive and negative imaginary parts)
    plot(real(ordered_eigenvalues(2, :)), imag(ordered_eigenvalues(2, :)), plot_args.style3, ...
        'LineWidth', 1.5, 'HandleVisibility', 'off');
    plot(real(ordered_eigenvalues(2, :)), -imag(ordered_eigenvalues(2, :)), plot_args.style4, ...
        'LineWidth', 1.5, 'HandleVisibility', 'off');

    % Semicirconferenza sinistra unitaria (da -i a +i via -1), tratteggiata nera
    th_semi = linspace(pi/2, 3*pi/2, 400);  % 90° a 270°
    x_semi = cos(th_semi);
    y_semi = sin(th_semi);
    plot(x_semi, y_semi, '--k', 'LineWidth', 1.0, 'HandleVisibility', 'off');

    % Optionally plot the critical point (-1, 0) in magenta
    if critical_visible == 1
        plot(-1, 0, 'p', 'MarkerSize', 8, 'Color', "m", "LineWidth", 2, 'HandleVisibility', 'off');
    elseif critical_visible ~= 0
        disp("Input error: 0 to hide the (-1,0) point, 1 to show it")
    end

    % Add a dummy plot for the legend (only this will appear in the legend)
    plot(nan, nan, plot_args.style1, 'LineWidth', 2, 'DisplayName', legend_label);

    % Compute critical frequency
    idx1 = closest_to_left_semicircle(ordered_eigenvalues(1,:));
    idx2 = closest_to_left_semicircle(ordered_eigenvalues(2,:));
    fcrit1 = frequencies(idx1);
    fcrit2 = frequencies(idx2);
    
    % Plot con DisplayName che include fcrit
    plot(real(ordered_eigenvalues(1,idx1)), imag(ordered_eigenvalues(1,idx1)), '*', ...
         'DisplayName', sprintf('fcrit=%.1f Hz', fcrit1));
    hold on;
    plot(real(ordered_eigenvalues(2,idx2)), imag(ordered_eigenvalues(2,idx2)), '*', ...
         'DisplayName', sprintf('fcrit=%.1f Hz', fcrit2));
       
% Set axis labels and title
    xlabel('Re(\lambda)');
    ylabel('Im(\lambda)');
    title('Eigenvalues of MIMO open loop L(S)');
    grid on;
end
