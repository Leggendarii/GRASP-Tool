function bode_plot_single(x, A, B, name)
    % BODE_PLOT_SINGLE Plots the magnitude and phase of the system in two subplots.
    %
    % INPUT:
    %   x     - Cell array of frequencies.
    %   A     - Cell array of converter transfer functions.
    %   B     - Cell array of grid transfer functions.
    %   name  - Title name for the plot.
    %
    % OUTPUT:
    %   A figure with two subplots: one for magnitude (dB) and one for phase (rad).
    %
    % AUTHOR:
    %   Nicolae Darii (DTU and Siemens Gamesa)
    %
    % LICENSED UNDER:
    %   MIT License (see LICENSE file in the repository).
    %

    f = x;

    figure
    subplot(2,1,1)
    for i=1:length(A)
        fd0 = f{i};
        GFL = A{i};
        semilogx(fd0, 20*log10(abs(GFL)), 'DisplayName', sprintf('Converter(%d)', i))
        if i == 1
            hold on
        end
    end
    for i = 1:length(B)
        fd0 = f{i};
        Grid = B{i};
        semilogx(fd0, 20*log10(abs(Grid)), 'DisplayName', sprintf('Grid (%d)', i))
    end
    hold off
    xlim([0, max(f{i})])
    ylabel("Magnitude dB")
    xlabel("Frequency Hz")
    legend
    grid on
    title(name + " magnitude")

    subplot(2,1,2)
    for i = 1:length(A)
        fd0 = f{i};
        GFL = A{i};
        semilogx(fd0, angle(GFL), 'DisplayName', sprintf('Converter(%d)', i))
        if i == 1
            hold on
        end
    end
    for i = 1:length(B)
        fd0 = f{i};
        Grid = B{i};
        semilogx(fd0, angle(Grid), 'DisplayName', sprintf('Grid (%d)', i))
    end
    hold off
    xlim([0, max(f{1})])
    ylabel("Angle rad")
    xlabel("Frequency Hz")
    legend
    grid on
    title(name + " phase")
end
