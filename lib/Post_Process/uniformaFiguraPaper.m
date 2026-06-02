function uniformaFiguraPaper(fig)
    % Dimensione desiderata dell'area plot (interna) in cm
    contentWidth = 8.5;
    contentHeight = 6.5;

    % Trova tutti gli assi
    ax = findall(fig, 'type', 'axes');
    if isempty(ax)
        warning('Nessun asse trovato nella figura.');
        return;
    end

    % Trova asse principale (più grande)
    posList = zeros(length(ax),1);
    for k = 1:length(ax)
        p = get(ax(k), 'Position');
        posList(k) = p(3)*p(4);
    end
    [~, mainIdx] = max(posList);
    mainAx = ax(mainIdx);

    % Imposta normalizzato per calcolare TightInset
    set(mainAx, 'Units', 'normalized');
    drawnow;
    tightInset = get(mainAx, 'TightInset');

    % Margine aggiuntivo per compensare tick label (in normalized units)
    extraMarginNorm = 0.01;

    % Margini normalizzati + margine minimo di sicurezza
    leftNorm   = max(tightInset(1) + extraMarginNorm, 0);
    bottomNorm = max(tightInset(2) + extraMarginNorm, 0);
    rightNorm  = max(tightInset(3) + extraMarginNorm, 0);
    topNorm    = max(tightInset(4) + extraMarginNorm, 0);

    % Area normalizzata disponibile per il contenuto
    widthNorm = 1 - leftNorm - rightNorm;
    heightNorm = 1 - bottomNorm - topNorm;

    % Margini in cm (proporzionali alla dimensione interna)
    leftCM   = (leftNorm   / widthNorm)  * contentWidth;
    rightCM  = (rightNorm  / widthNorm)  * contentWidth;
    bottomCM = (bottomNorm / heightNorm) * contentHeight;
    topCM    = (topNorm    / heightNorm) * contentHeight;

    % 🔽 CORREZIONE FINALE per evitare tagli
    extraPaddingLeft   = 0.3;
    extraPaddingBottom = 0.3;
    extraPaddingRight  = 0.2;
    extraPaddingTop    = 0.2;

    leftCM   = leftCM   + extraPaddingLeft;
    bottomCM = bottomCM + extraPaddingBottom;
    rightCM  = rightCM  + extraPaddingRight;
    topCM    = topCM    + extraPaddingTop;

    % Dimensione totale della figura
    figWidth = contentWidth + leftCM + rightCM;
    figHeight = contentHeight + bottomCM + topCM;

    % Posiziona e centra la figura
    set(fig, 'Units', 'centimeters', 'Position', [5, 5, figWidth, figHeight]);
    movegui(fig, 'center');

    % Imposta la posizione normalizzata dell'asse principale
    newAxPos = [leftCM / figWidth, bottomCM / figHeight, ...
                contentWidth / figWidth, contentHeight / figHeight];
    set(mainAx, 'Units', 'normalized', 'Position', newAxPos);

    % Stile asse principale
    set(mainAx, 'FontName', 'Times New Roman', 'FontSize', 11, ...
        'LineWidth', 1, 'TickLabelInterpreter', 'latex', ...
        'Box', 'on', 'Layer', 'top');

    % Stile altri assi
    for k = 1:length(ax)
        if k ~= mainIdx
            set(ax(k), 'FontName', 'Times New Roman', 'FontSize', 8, ...
                'LineWidth', 1, 'TickLabelInterpreter', 'latex', ...
                'Box', 'on', 'Layer', 'top');
        end
    end

    % Imposta dimensioni corrette per esportazione
    set(fig, 'PaperUnits', 'centimeters');
    set(fig, 'PaperPosition', [0 0 figWidth figHeight]);
    set(fig, 'PaperSize', [figWidth figHeight]);
end
