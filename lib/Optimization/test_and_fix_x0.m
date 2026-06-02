function x0_valid = test_and_fix_x0(x0_test, lb, ub)
    max_attempts = 50;
    
    fprintf('🧪 Test punto iniziale x0...\n');
    
    for attempt = 1:max_attempts
        fprintf('Tentativo %d: ', attempt);
        
        try
            % Testa run_simulink_and_compute_cost
            cost = run_simulink_and_compute_cost( ...
                x0_test(1), x0_test(2), x0_test(3), x0_test(4), x0_test(5), ...
                x0_test(6), x0_test(7), x0_test(8), x0_test(9), x0_test(10), ...
                x0_test(11), x0_test(12));
            
            % Verifica costo valido
            if ~isnan(cost) && isfinite(cost) && cost > 0
                fprintf('✓ OK! Costo = %.4f\n', cost);
                x0_valid = x0_test;
                return;
            else
                fprintf('✗ Costo non valido (%.4f)\n', cost);
            end
            
        catch ME
            fprintf('✗ CRASH: %s\n', ME.message);
        end
        
        % Genera nuovo x0 random
        x0_test = lb + (ub - lb) .* rand(size(lb));
    end
    
    error('❌ Tutti i %d tentativi falliti! Non trovato x0 valido.', max_attempts);
end