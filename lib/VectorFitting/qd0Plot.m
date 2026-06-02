function qd0Plot(fd0, jw1, Ym_Th, Ya_Th, Yqq, Yqd, Ydq, Ydd)
    % Definir límites del eje x
    low_axis = fd0(1);
    up_axis = fd0(end);

    % Configuraciones globales para las gráficas
    set(0, 'defaultAxesFontSize', 14);
    set(0, 'DefaultLineLineWidth', 1.5);

    % Crear la figura
    figure;

    % Subplot 1: Magnitud de Yqq
    subplot(4, 2, 1);
    semilogx(imag(jw1)/(2*pi), 20*log10(squeeze(Ym_Th(1, 1, :))), 'k');
    hold on;
    semilogx(fd0, 20*log10(abs(Yqq)), 'rx');
    title('Yqq(s)');
    ylabel('Magnitude (dB)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 2: Fase de Yqq
    subplot(4, 2, 3);
    semilogx(imag(jw1)/(2*pi), squeeze(Ya_Th(1, 1, :)), 'k');
    hold on;
    semilogx(fd0, (180/pi) * angle(Yqq), 'rx');
    ylabel('Phase (deg)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 3: Magnitud de Yqd
    subplot(4, 2, 2);
    semilogx(imag(jw1)/(2*pi), 20*log10(squeeze(Ym_Th(1, 2, :))), 'k');
    hold on;
    semilogx(fd0, 20*log10(abs(Yqd)), 'rx');
    legend({'Fitted state-space', 'dq0 measurements'}, 'Location', 'southwest', 'Orientation', 'vertical');
    title('Yqd(s)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 4: Fase de Yqd
    subplot(4, 2, 4);
    semilogx(imag(jw1)/(2*pi), squeeze(Ya_Th(1, 2, :)), 'k');
    hold on;
    semilogx(fd0, (180/pi) * angle(Yqd), 'rx');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 5: Magnitud de Ydq
    subplot(4, 2, 5);
    semilogx(imag(jw1)/(2*pi), 20*log10(squeeze(Ym_Th(2, 1, :))), 'k');
    hold on;
    semilogx(fd0, 20*log10(abs(Ydq)), 'rx');
    title('Ydq(s)');
    ylabel('Magnitude (dB)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 6: Fase de Ydq
    subplot(4, 2, 7);
    semilogx(imag(jw1)/(2*pi), squeeze(Ya_Th(2, 1, :)), 'k');
    hold on;
    semilogx(fd0, (180/pi) * angle(Ydq), 'rx');
    ylabel('Phase (deg)');
    xlabel('Frequency (Hz)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 7: Magnitud de Ydd
    subplot(4, 2, 6);
    semilogx(imag(jw1)/(2*pi), 20*log10(squeeze(Ym_Th(2, 2, :))), 'k');
    hold on;
    semilogx(fd0, 20*log10(abs(Ydd)), 'rx');
    title('Ydd(s)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 8: Fase de Ydd
    subplot(4, 2, 8);
    semilogx(imag(jw1)/(2*pi), squeeze(Ya_Th(2, 2, :)), 'k');
    hold on;
    semilogx(fd0, (180/pi) * angle(Ydd), 'rx');
    xlabel('Frequency (Hz)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Título general
    sgtitle('Frequency Response Plots');
end
