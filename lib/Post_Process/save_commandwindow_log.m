function save_commandwindow_log()
% SAVE_COMMANDWINDOW_LOG Salva tutto il contenuto ATTUALE della Command Window 
% in data/last_log.txt (sovrascrive sempre)
%
% Uso: save_commandwindow_log()
% Output: data/last_log.txt con TUTTO il testo Command Window

    % Crea cartella 'data'
    if ~exist('data', 'dir'), mkdir('data'); end
    
    filename = fullfile('data', 'last_log.txt');
    
    % METODO 1: Prova API moderna (se disponibile)
    try
        cw = matlab.desktop.commandwindow.CommandWindow.getInstance;
        lines = cw.getLines;
        log_text = strjoin(lines, newline);
        write_log(log_text, filename);
        fprintf('💾 Salvato con API moderna: %s (%.0f righe)\n', filename, length(lines));
        return;
    catch
        % Fallback se API non disponibile
    end
    
    % METODO 2: Simulazione Ctrl+A + Ctrl+C (universale)
    try
        import java.awt.Robot;
        import java.awt.event.KeyEvent;
        rob = Robot;
        
        % Clicca nella Command Window e seleziona tutto (Ctrl+A)
        commandwindow;  % Focus Command Window
        pause(0.2);
        rob.keyPress(KeyEvent.VK_CONTROL);
        rob.keyPress(KeyEvent.VK_A);
        rob.keyRelease(KeyEvent.VK_A);
        rob.keyRelease(KeyEvent.VK_CONTROL);
        pause(0.3);
        
        % Copia (Ctrl+C)
        rob.keyPress(KeyEvent.VK_CONTROL);
        rob.keyPress(KeyEvent.VK_C);
        rob.keyRelease(KeyEvent.VK_C);
        rob.keyRelease(KeyEvent.VK_CONTROL);
        pause(0.5);
        
        % Incolla negli appdata (clipboard)
        log_text = clipboard('paste');
        write_log(log_text, filename);
        fprintf('💾 Salvato con Ctrl+A/C: %s\n', filename);
        
    catch ME
        warning('Metodi automatici falliti: %s. Usa diary manualmente.', ME.message);
        fprintf('❌ Prova: diary %s\n ...comandi...\n diary off\n', filename);
    end
end

function write_log(text, filename)
    fid = fopen(filename, 'w', 'n', 'UTF-8');
    if fid ~= -1
        fprintf(fid, '%s', text);
        fclose(fid);
    end
end
