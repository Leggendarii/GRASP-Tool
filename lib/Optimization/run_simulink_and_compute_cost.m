function J = run_simulink_and_compute_cost(xs, unscaleFcn)
    
    x = unscaleFcn(xs);
    kp_outer_V_pu = x(1);
    ki_outer_V_pu = x(2);
    kp_outer_P_pu = x(3);
    ki_outer_P_pu = x(4);
    kp_inner_d_pu = x(5);
    ki_inner_d_pu = x(6);
    kp_inner_q_pu = x(7);
    ki_inner_q_pu = x(8);
    kp_pll        = x(9);
    ki_pll        = x(10);
    T1            = x(11);
    T2            = x(12);

    % Carica i parametri di base
    % Parameters_Setup_white_box
    base_setup

    % Carica il caso di riferimento (simulazione con parametri ottimali)
    Ref = readtable("reference_case.csv"); % Here put the name of the reference case

    % Imposta i parametri nel workspace per Simulink
    assignin('base', 'kp_outer_V_pu', kp_outer_V_pu);
    assignin('base', 'ki_outer_V_pu', ki_outer_V_pu);
    assignin('base', 'kp_outer_P_pu', kp_outer_P_pu);
    assignin('base', 'ki_outer_P_pu', ki_outer_P_pu);
    assignin('base', 'kp_inner_d_pu', kp_inner_d_pu);
    assignin('base', 'ki_inner_d_pu', ki_inner_d_pu);
    assignin('base', 'kp_inner_q_pu', kp_inner_q_pu);
    assignin('base', 'ki_inner_q_pu', ki_inner_q_pu);
    assignin('base', 'kp_pll', kp_pll);
    assignin('base', 'ki_pll', ki_pll);
    assignin('base', 'T1', T1);
    assignin('base', 'T2', T2);

        % Avvio simulazione con Fast Restart (modello già caricato esternamente)
    try
        [~, simOut] = evalc("sim('white_box', 'SaveOutput', 'on', 'ReturnWorkspaceOutputs', 'on')");
    catch
        % Penalità se la simulazione fallisce
        J = 1e6;
        return;
    end

    t = simOut.tout;
    y1 = simOut.Val1.signals.values;
    y2 = simOut.Val2.signals.values;

    % Calcola l'errore rispetto al riferimento (post transient)
    tol = 1e-8;
    idx = find(abs(t - steady_time) < tol); 

    if isempty(idx)
        J = 1e6; % Penalità se la simulazione non produce dati validi
        return;
    end

    err_Val1 = abs(Ref.Val1(idx:end) - y1(idx:end));
    err_Val2 = abs(Ref.Val2(idx:end) - y2(idx:end));

    J1 = sum(err_Val1.^2);   
    J2 = sum(err_Val2.^2); 
    
    w1 = 1;   % peso maggiore su Val1
    w2 = 1;

    J = w1*J1 + w2*J2;
end
