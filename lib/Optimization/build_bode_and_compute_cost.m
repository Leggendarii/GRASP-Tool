function J = build_bode_and_compute_cost(kp_outer_V_pu, ki_outer_V_pu, ...
    kp_outer_P_pu, ki_outer_P_pu, kp_inner_d_pu, ki_inner_d_pu, kp_inner_q_pu, ki_inner_q_pu, kp_pll, ki_pll, T1, T2)

    %% Setup parameters
    base_setup

    P_finalvalue = 0.0;  
    name = sprintf('P%.1f', P_finalvalue);
    name = strrep(name, '.', ',');  % P0.9 → P0,9
    load(name)  % Aggiorna con variabili di stato


    %% Setup reference
    filename = 'black_statcom_modified.csv';
    
    data = readtable(filename);
    w_Hz = data{:,1};  

    phi = 180 * pi / 180;  % 150° → 2.618 rad

    z_shift = exp(-1j * phi);
    
    % 4 FRD dai dati CSV (colonne 2,3,4,5)
    frd_qq = frd(data{:,5}, w_Hz, 'FrequencyUnit', 'Hz') * z_shift;  % dd
    frd_dq = frd(data{:,4}, w_Hz, 'FrequencyUnit', 'Hz');  % dq  
    frd_qd = frd(data{:,3}, w_Hz, 'FrequencyUnit', 'Hz');  % qd
    frd_dd = frd(data{:,2}, w_Hz, 'FrequencyUnit', 'Hz') * z_shift;  % qq

    %% Build all the state space elements
    STATE_SPACE_power_control_dq;   %% ss_power
    STATE_SPACE_current_control     %% ss_current
    STATE_SPACE_DC_control          %% ss_dc
    STATE_SPACE_filterscan          %% ss_filter
    STATE_SPACE_frame_conversion    %% ss_frame
    % STATE_SPACE_gridscan          %% ss_grid
    STATE_SPACE_laglead             %% ss_laglead
    STATE_SPACE_PLL_dq_omega_output %% ss_PLL
    
    % Power
    ss_power.StateName = {'Flux_DC', 'Flux_PoC'};
    ss_power.InputName = {'Vdc_ref', 'Vdc_mes_filt', 'Vpoc_ref', 'ig_d_c', 'ig_q_c', 'vpoc_d_c', 'vpoc_q_c'};
    ss_power.OutputName = {'iref_d_c', 'iref_q_c'};
    
    % PLL
    ss_PLL.StateName = {'theta', 'Flux_PLL'};
    ss_PLL.InputName = {'vpoc_q_c'};
    ss_PLL.OutputName = {'theta'};
    
    % laglead
    ss_laglead.StateName = {'Flux_laglead'};
    ss_laglead.InputName = {'Vdc_mes'};
    ss_laglead.OutputName = {'Vdc_mes_filt'};
    
    % Frame conversion
    ss_frame.InputName = {'vpoc_d_s', 'vpoc_q_s', 'ig_d_s', 'ig_q_s', 'iL_d_s', 'iL_q_s', 'vvsc_d_c', 'vvsc_q_c', 'theta'};
    ss_frame.OutputName = {'vpoc_d_c', 'vpoc_q_c', 'ig_d_c', 'ig_q_c', 'iL_d_c', 'iL_q_c', 'vvsc_d_s', 'vvsc_q_s'};
    
    % Filter
    % ss_filter.StateName = {'iL_d_s', 'iL_q_s', 'vpoc_d_s', 'vpoc_q_s'};
    ss_filter.StateName = {'iL_d_s', 'iL_q_s', 'vpoc_d_s', 'vpoc_q_s', 'ig_d_s', 'ig_q_s'};
    ss_filter.InputName = {'vvsc_d_s', 'vvsc_q_s', 'vg_d_s', 'vg_q_s'};
    ss_filter.OutputName = {'iL_d_s', 'iL_q_s', 'vpoc_d_s', 'vpoc_q_s', 'ig_d_s', 'ig_q_s'};  %% maybe consider vdgrid vqgrid const
    
    % DC Dyin
    ss_dc.StateName = {'Vdc_mes'};
    ss_dc.InputName = {'P_ref', 'ig_d_c', 'ig_q_c', 'vpoc_d_c', 'vpoc_q_c'};
    ss_dc.OutputName = {'Vdc_mes'};
    
    % Current Controller
    ss_current.StateName = {'Cd', 'Cq'};
    ss_current.InputName = {'iref_d_c', 'iref_q_c', 'iL_d_c', 'iL_q_c'};
    ss_current.OutputName = {'vvsc_d_c', 'vvsc_q_c'};
    
    ss_system = connect(ss_power, ss_PLL, ss_laglead, ss_frame , ss_filter, ss_dc, ss_current,...
        {'P_ref', 'Vpoc_ref', 'Vdc_ref', 'vg_d_s', 'vg_q_s'}, ... % Ingressi di ss_P_I
        {'iL_d_s', 'iL_q_s', 'ig_d_s', 'ig_q_s', 'vpoc_d_s', 'vpoc_q_s', 'Vdc_mes', 'vvsc_d_s', 'vvsc_q_s'}); % Uscite system

    ss_tf = tf(ss_system)*(1/Z_base);

    %% Compute cost
    w_Hz_vec = w_Hz(:);
    
     % 1: dd
    sys_dd = ss_tf('ig_d_s', 'vg_d_s');
    
    % 2: dq  
    sys_dq = ss_tf('ig_q_s', 'vg_d_s');
    
    % 3: qd
    sys_qd = ss_tf('ig_d_s', 'vg_q_s');
    
    % 4: qq
    sys_qq = ss_tf('ig_q_s', 'vg_q_s');

    
    % Calcolo risposte
    complex_csv_dd = squeeze(frd_dd.Response); complex_ss_dd = squeeze(freqresp(sys_dd, w_Hz_vec*2*pi));
    complex_csv_dq = squeeze(frd_dq.Response); complex_ss_dq = squeeze(freqresp(sys_dq, w_Hz_vec*2*pi));
    complex_csv_qd = squeeze(frd_qd.Response); complex_ss_qd = squeeze(freqresp(sys_qd, w_Hz_vec*2*pi));
    complex_csv_qq = squeeze(frd_qq.Response); complex_ss_qq = squeeze(freqresp(sys_qq, w_Hz_vec*2*pi));
    
    % ERRORI RELATIVI GLOBALI (norma vettoriale)
    error_dd = norm(complex_ss_dd - complex_csv_dd) / norm(complex_csv_dd);
    error_dq = norm(complex_ss_dq - complex_csv_dq) / norm(complex_csv_dq);
    error_qd = norm(complex_ss_qd - complex_csv_qd) / norm(complex_csv_qd);
    error_qq = norm(complex_ss_qq - complex_csv_qq) / norm(complex_csv_qq);

    J = error_dd + error_qd*(1) + error_dq*(1) + error_qq;
end
