%% Technical University of Catalonia (UPC)
%% Higher Technical School of Industrial Engineering of Barcelona (ETSEIB)
%% Centre of Technological Innovation in Static Converters and Drives (CITCEA)
%% Doctoral Program in Electrical Engineering
%% Developed by: Luis Angel Garcia Reyes, MSc
%% Frequency domain scanning tool (FDs) for modern power systems 

% GNU General Public License v3.0 (GPL-3.0)
% Copyright (C) 2025 Luis Angel Garcia Reyes, UPC-MSCA-ADOreD
% Email: luis.reyes@upc.edu
% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the 
% Free Software Foundation, either version 3 of the License, or (at your 
% option) any later version.
% This program is distributed in the hope that it will be useful, but 
% WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
% or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
% for more details.
% You should have received a copy of the GNU General Public License along 
% with this program. If not, see <https://www.gnu.org/licenses/>.

% This work has received funding from the ADOreD project
% under the European Union’s Horizon Europe Research and 
% Innovation Programme under the Marie Skłodowska-Curie 
% Grant Agreement No. 101073554.

%% Preliminar parameters based on the simulation settings

fd=0; % set initial disturbance frequency
fsampling=round(1/delta_t); % Sampling frequency for the simulation 
Tobs0=1/fs; % Total time window
t_w1=Tinit; % Starting time window
t_w2=Tinit+Tobs0; % Ending time window
Tobs=t_w2; % Full observation time
dist_time_ss=Tobs+10000; % No disturbance for calculating the steady state
dist_time_f=Tinit-0.8; % effective disturbance time for the scanner
time_vector=(t_w1:delta_t:t_w2)'; % Time vector for the disturbance
samples_window=length(time_vector); % Ensure samples is an integer
Rsource=1E-6; % Fundamental series resistance (suggested to avoid errors)
phi=(2/3)*pi; % Phase of 120º between phases
Vdist_value=Vperturbation*Vpeak; % Voltage disturbance value
Idist_value=Iperturbation*Ipeak; % Current disturbance value
dist_time=dist_time_ss; % Set the first disturbance time for steady state
% Logic to determine the ss_type
if Vq_ss == 0 && Vd_ss == 0
    Vss_type = 1; % Three-phase ss voltage source
else
    Vss_type = 2; % dq0 to ABC ss voltage source
end
if Iq_ss == 0 && Id_ss == 0
    Iss_type = 1; % Three-phase ss current source
else
    Iss_type = 2; % dq0 to ABC ss current source
end

%% Signal disturbance development with multi-sine and random binary strategies

disp('SIaD Tool is starting...')
disp('---')
fprintf('Simulation set with %s perturbation, %s signal, %s frame.\n', ...
    choose(scanner_type, 'voltage', 'current'), ...
    choose(signal_type, 'single-tone', 'PRBS', 'multi-tone'), ...
    choose(scanner_selector, 'ABC', 'dq0', '0pn'));

switch signal_type
    case 1
        % No actions
    case 2
        % RBS or PRBS signals perturbation strategy
        % Voltage perturbation
        V_rbs_ex = idinput([samples_window, 3], 'prbs', [], [0, Vdist_value]); % RBS generation signals
        Vsignal_dist1 = [time_vector, V_rbs_ex(:, 1)]; % 2-dimension disturbance vector in q [time,rbs signal] 
        Vsignal_dist2 = [time_vector, V_rbs_ex(:, 2)]; % 2-dimension disturbance vector in d [time,rbs signal]
        Vsignal_dist3 = [time_vector, V_rbs_ex(:, 3)]; % 2-dimension disturbance vector in d [time,rbs signal]
        % Current perturbation
        I_rbs_ex = idinput([samples_window, 3], 'prbs', [], [-Idist_value, Idist_value]); % RBS generation signals
        Isignal_dist1 = [time_vector, I_rbs_ex(:, 1)]; % 2-dimension disturbance vector in q [time,rbs signal] 
        Isignal_dist2 = [time_vector, I_rbs_ex(:, 2)]; % 2-dimension disturbance vector in d [time,rbs signal]
        Isignal_dist3 = [time_vector, I_rbs_ex(:, 3)]; % 2-dimension disturbance vector in d [time,rbs signal]
    case 3
        % Cosenoidal signals perturbation strategy
        freq_multiples = [1, 2, 3, 4, 5, 6, 7, 8]; % Multiples of the base frequency
        specific_freqs = fd0; % If non-empty, this overrides freq_multiples
        % Combine into a 2-dimensional vector [time, signal]
        Vdisturbance_signal = multisine(specific_freqs, fsampling, samples_window, ...
              'PhaseResponse', 'Schroeder', ... %  Schroeder phases
              'Normalise', true, ...            % Norm of the signal
              'StartAtZero', false);             % Initialize in a zero-crossing point
        Idisturbance_signal=Vdisturbance_signal;
        Vsignal_dist1 = [time_vector, Vdist_value*(Vdisturbance_signal)']; % a-signal
        Vsignal_dist2=Vsignal_dist1; % b-signal
        Vsignal_dist3=Vsignal_dist1; % c-signal
        Isignal_dist1 = [time_vector, Idist_value*Idisturbance_signal']; % a-signal
        Isignal_dist2=Isignal_dist1; % b-signal
        Isignal_dist3=Isignal_dist1; % c-signal
end

%% Subsystem subblocks identification and assignment

tic % clock start
FD_Scanner=[model, '/SIaD Tool/Frequency Scanner']; 
Normal_State=[model, '/SIaD Tool/Normal State'];
SS_Meas=[model, '/SIaD Tool/Steady State'];
Sys1_Meas=[model, '/SIaD Tool/System 1'];
Sys1_Meas_ABC=[model, '/SIaD Tool/System 1/ABC Sequence'];
Sys1_Meas_dq0=[model, '/SIaD Tool/System 1/dq0 Sequence'];
Sys1_Meas_0pn=[model, '/SIaD Tool/System 1/0pn Sequence'];
Sys2_Meas=[model, '/SIaD Tool/System 2'];
Sys2_Meas_ABC=[model, '/SIaD Tool/System 2/ABC Sequence'];
Sys2_Meas_dq0=[model, '/SIaD Tool/System 2/dq0 Sequence'];
Sys2_Meas_0pn=[model, '/SIaD Tool/System 2/0pn Sequence'];
voltage_type=[model, '/SIaD Tool/Frequency Scanner/Voltage Strategy']; 
current_type=[model, '/SIaD Tool/Frequency Scanner/Current Strategy'];
ABC_V_scanner=[model, '/SIaD Tool/Frequency Scanner/Voltage Strategy/ABCdisturbance']; 
qd0_V_scanner=[model, '/SIaD Tool/Frequency Scanner/Voltage Strategy/qd0disturbance'];
pn0_V_scanner=[model, '/SIaD Tool/Frequency Scanner/Voltage Strategy/pn0disturbance'];
ABC_I_scanner=[model, '/SIaD Tool/Frequency Scanner/Current Strategy/ABCdisturbance2']; 
qd0_I_scanner=[model, '/SIaD Tool/Frequency Scanner/Current Strategy/qd0disturbance2'];
pn0_I_scanner=[model, '/SIaD Tool/Frequency Scanner/Current Strategy/pn0disturbance2'];
multi_tone_V_ABC=[model, '/SIaD Tool/Frequency Scanner/Voltage Strategy/ABCdisturbance/Multi-tone'];
single_tone_V_ABC=[model, '/SIaD Tool/Frequency Scanner/Voltage Strategy/ABCdisturbance/Single-tone'];
multi_tone_I_ABC=[model, '/SIaD Tool/Frequency Scanner/Current Strategy/ABCdisturbance2/Multi-tone'];
single_tone_I_ABC=[model, '/SIaD Tool/Frequency Scanner/Current Strategy/ABCdisturbance2/Single-tone'];
multi_tone_V_qd0=[model, '/SIaD Tool/Frequency Scanner/Voltage Strategy/qd0disturbance/Multi-tone'];
single_tone_V_qd0=[model, '/SIaD Tool/Frequency Scanner/Voltage Strategy/qd0disturbance/Single-tone'];
multi_tone_I_qd0=[model, '/SIaD Tool/Frequency Scanner/Current Strategy/qd0disturbance2/Multi-tone'];
single_tone_I_qd0=[model, '/SIaD Tool/Frequency Scanner/Current Strategy/qd0disturbance2/Single-tone'];
multi_tone_V_0pn=[model, '/SIaD Tool/Frequency Scanner/Voltage Strategy/pn0disturbance/Multi-tone'];
single_tone_V_0pn=[model, '/SIaD Tool/Frequency Scanner/Voltage Strategy/pn0disturbance/Single-tone'];
multi_tone_I_0pn=[model, '/SIaD Tool/Frequency Scanner/Current Strategy/pn0disturbance2/Multi-tone'];
single_tone_I_0pn=[model, '/SIaD Tool/Frequency Scanner/Current Strategy/pn0disturbance2/Single-tone'];

%% Steady state calculation stage

if ss_cal==1
set_param(FD_Scanner, 'Commented', 'on');
set_param(Normal_State, 'Commented', 'off');
set_param(SS_Meas, 'Commented', 'off');
set_param(Sys1_Meas, 'Commented', 'on');
set_param(Sys2_Meas, 'Commented', 'on');
disp('SIaD Tool is obtaining the steady state...')
disp('---')
[~, out] = evalc("sim(program)");
Vd_ss=out.Vdq_ss(end-10,1);
Vq_ss=out.Vdq_ss(end-10,2);
Id_ss=out.Idq_ss(end-10,1);
Iq_ss=out.Idq_ss(end-10,2);
dist_time=dist_time_f;
switch scanner_selector
    case 1
                td1=find((out.tout)>=t_w1,1); % t1 time window
                td2=find((out.tout)>=t_w2,1); % t2 time window
                % System 1
                va_ss1=out.Vabc_ss(td1:td2,1);
                vb_ss1=out.Vabc_ss(td1:td2,2);
                vc_ss1=out.Vabc_ss(td1:td2,3);
                ia_ss1=out.Iabc_ss(td1:td2,1);
                ib_ss1=out.Iabc_ss(td1:td2,2);
                ic_ss1=out.Iabc_ss(td1:td2,3);
                % System 2
                va_ss2=va_ss1;
                vb_ss2=vb_ss1;
                vc_ss2=vc_ss1;
                ia_ss2=ia_ss1;
                ib_ss2=ib_ss1;
                ic_ss2=ic_ss1;
                
    case 2
                td1=find((out.tout)>=t_w1,1); % t1 time window
                td2=find((out.tout)>=t_w2,1); % t2 time window
                % System 1
                vq_ss1=out.Vdq_ss(td1:td2,2);
                vd_ss1=out.Vdq_ss(td1:td2,1);
                iq_ss1=out.Idq_ss(td1:td2,2);
                id_ss1=out.Idq_ss(td1:td2,1);
                % System 2
                vq_ss2=vq_ss1;
                vd_ss2=vd_ss1;
                iq_ss2=iq_ss1;
                id_ss2=id_ss1;
    case 3
                td1=find((out.tout)>=t_w1,1); % t1 time window
                td2=find((out.tout)>=t_w2,1); % t2 time window
                % System 1
                v0_ss1=out.V0pn_ss(td1:td2,1);
                vp_ss1=out.V0pn_ss(td1:td2,2);
                vn_ss1=out.V0pn_ss(td1:td2,3);
                i0_ss1=out.I0pn_ss(td1:td2,1);
                ip_ss1=out.I0pn_ss(td1:td2,2);
                in_ss1=out.I0pn_ss(td1:td2,3);
                % System 2
                v0_ss2=v0_ss1;
                vp_ss2=vp_ss1;
                vn_ss2=vn_ss1;
                i0_ss2=i0_ss1;
                ip_ss2=ip_ss1;
                in_ss2=in_ss1;
end
end

%% Comprehensive frequency scanning tool methodology (abs, dq0, pn0)

set_param(FD_Scanner, 'Commented', 'off');
set_param(Normal_State, 'Commented', 'on');
set_param(SS_Meas, 'Commented', 'on');
set_param(Sys1_Meas, 'Commented', 'off');
set_param(Sys2_Meas, 'Commented', 'off');
disp('SIaD Tool is running the system identification process...')
disp('---')
switch scanner_selector
    %% ABC Scanner
    case 1
        set_param(ABC_V_scanner, 'Commented', 'off');
        set_param(qd0_V_scanner, 'Commented', 'on');
        set_param(pn0_V_scanner, 'Commented', 'on');
        set_param(ABC_I_scanner, 'Commented', 'off');
        set_param(qd0_I_scanner, 'Commented', 'on');
        set_param(pn0_I_scanner, 'Commented', 'on');
        set_param(Sys1_Meas_ABC, 'Commented', 'off');
        set_param(Sys1_Meas_dq0, 'Commented', 'on');
        set_param(Sys1_Meas_0pn, 'Commented', 'on');
        set_param(Sys2_Meas_ABC, 'Commented', 'off');
        set_param(Sys2_Meas_dq0, 'Commented', 'on');
        set_param(Sys2_Meas_0pn, 'Commented', 'on');
        if scanner_type==1
            set_param(voltage_type, 'Commented', 'off');
            set_param(current_type, 'Commented', 'on');
            if signal_type==1
                set_param(multi_tone_V_ABC, 'Commented', 'on');
                set_param(single_tone_V_ABC, 'Commented', 'off');
                dist_value_a=0;
                dist_value_b=0;
                dist_value_c=0;
            else
                set_param(multi_tone_V_ABC, 'Commented', 'off');
                set_param(single_tone_V_ABC, 'Commented', 'on');
                dist_value_a=zeros(samples_window,2);
                dist_value_b=zeros(samples_window,2);
                dist_value_c=zeros(samples_window,2);
            end
            if ss_cal~=1
                [~, out] = evalc("sim(program)");
                td1=find((out.tout)>=t_w1,1); % t1 time window
                td2=find((out.tout)>=t_w2,1); % t2 time window
                % System 1
                va_ss1=out.Vabc1(td1:td2,1);
                vb_ss1=out.Vabc1(td1:td2,2);
                vc_ss1=out.Vabc1(td1:td2,3);
                ia_ss1=out.Iabc1(td1:td2,1);
                ib_ss1=out.Iabc1(td1:td2,2);
                ic_ss1=out.Iabc1(td1:td2,3);
                % System 2
                va_ss2=out.Vabc2(td1:td2,1);
                vb_ss2=out.Vabc2(td1:td2,2);
                vc_ss2=out.Vabc2(td1:td2,3);
                ia_ss2=out.Iabc2(td1:td2,1);
                ib_ss2=out.Iabc2(td1:td2,2);
                ic_ss2=out.Iabc2(td1:td2,3);
                dist_time=dist_time_f;
            end
            if signal_type==1
                for n=1:length(fd0)
                    fd=fd0(n);
                    % a-injection
                    dist_value_a=Vdist_value;
                    dist_value_b=0;
                    dist_value_c=0;
                    [~, out] = evalc("sim(program)");
                    % Vector windowed extraction
                    % System 1
                    va_1=out.Vabc1(td1:td2,1);
                    vb_1=out.Vabc1(td1:td2,2);
                    vc_1=out.Vabc1(td1:td2,3);
                    ia_1=out.Iabc1(td1:td2,1);
                    ib_1=out.Iabc1(td1:td2,2);
                    ic_1=out.Iabc1(td1:td2,3);
                    Va_1=fft(va_1-va_ss1)/length(va_1);
                    Vb_1=fft(vb_1-vb_ss1)/length(vb_1);
                    Vc_1=fft(vc_1-vc_ss1)/length(vc_1);
                    Ia_1=fft(ia_1-ia_ss1)/length(ia_1);
                    Ib_1=fft(ib_1-ib_ss1)/length(ib_1);
                    Ic_1=fft(ic_1-ic_ss1)/length(ic_1);
                    % System 2
                    va_2=out.Vabc2(td1:td2,1);
                    vb_2=out.Vabc2(td1:td2,2);
                    vc_2=out.Vabc2(td1:td2,3);
                    ia_2=out.Iabc2(td1:td2,1);
                    ib_2=out.Iabc2(td1:td2,2);
                    ic_2=out.Iabc2(td1:td2,3);
                    Va_2=fft(va_2-va_ss2)/length(va_2);
                    Vb_2=fft(vb_2-vb_ss2)/length(vb_2);
                    Vc_2=fft(vc_2-vc_ss2)/length(vc_2);
                    Ia_2=fft(ia_2-ia_ss2)/length(ia_2);
                    Ib_2=fft(ib_2-ib_ss2)/length(ib_2);
                    Ic_2=fft(ic_2-ic_ss2)/length(ic_2);
                    wd=round(fd/fs)+1;
                    % System 1
                    Yaa_1=Ia_1(wd)/Va_1(wd);
                    Yba_1=Ib_1(wd)/Va_1(wd);
                    Yca_1=Ic_1(wd)/Va_1(wd);
                    % System 2
                    Yaa_2=Ia_2(wd)/Va_2(wd);
                    Yba_2=Ib_2(wd)/Va_2(wd);
                    Yca_2=Ic_2(wd)/Va_2(wd);
                    % b-injection
                    dist_value_a=0;
                    dist_value_b=Vdist_value;
                    dist_value_c=0;
                    [~, out] = evalc("sim(program)");
                    % System 1
                    va_1=out.Vabc1(td1:td2,1);
                    vb_1=out.Vabc1(td1:td2,2);
                    vc_1=out.Vabc1(td1:td2,3);
                    ia_1=out.Iabc1(td1:td2,1);
                    ib_1=out.Iabc1(td1:td2,2);
                    ic_1=out.Iabc1(td1:td2,3);
                    Va_1=fft(va_1-va_ss1)/length(va_1);
                    Vb_1=fft(vb_1-vb_ss1)/length(vb_1);
                    Vc_1=fft(vc_1-vc_ss1)/length(vc_1);
                    Ia_1=fft(ia_1-ia_ss1)/length(ia_1);
                    Ib_1=fft(ib_1-ib_ss1)/length(ib_1);
                    Ic_1=fft(ic_1-ic_ss1)/length(ic_1);
                    % System 2
                    va_2=out.Vabc2(td1:td2,1);
                    vb_2=out.Vabc2(td1:td2,2);
                    vc_2=out.Vabc2(td1:td2,3);
                    ia_2=out.Iabc2(td1:td2,1);
                    ib_2=out.Iabc2(td1:td2,2);
                    ic_2=out.Iabc2(td1:td2,3);
                    Va_2=fft(va_2-va_ss2)/length(va_2);
                    Vb_2=fft(vb_2-vb_ss2)/length(vb_2);
                    Vc_2=fft(vc_2-vc_ss2)/length(vc_2);
                    Ia_2=fft(ia_2-ia_ss2)/length(ia_2);
                    Ib_2=fft(ib_2-ib_ss2)/length(ib_2);
                    Ic_2=fft(ic_2-ic_ss2)/length(ic_2);
                    % System 1
                    Yab_1=Ia_1(wd)/Vb_1(wd);
                    Ybb_1=Ib_1(wd)/Vb_1(wd);
                    Ycb_1=Ic_1(wd)/Vb_1(wd);
                    % System 2
                    Yab_2=Ia_2(wd)/Vb_2(wd);
                    Ybb_2=Ib_2(wd)/Vb_2(wd);
                    Ycb_2=Ic_2(wd)/Vb_2(wd);
                    % c-injection
                    dist_value_a=0;
                    dist_value_b=0;
                    dist_value_c=Vdist_value;
                    [~, out] = evalc("sim(program)");
                    % System 1
                    va_1=out.Vabc1(td1:td2,1);
                    vb_1=out.Vabc1(td1:td2,2);
                    vc_1=out.Vabc1(td1:td2,3);
                    ia_1=out.Iabc1(td1:td2,1);
                    ib_1=out.Iabc1(td1:td2,2);
                    ic_1=out.Iabc1(td1:td2,3);
                    Va_1=fft(va_1-va_ss1)/length(va_1);
                    Vb_1=fft(vb_1-vb_ss1)/length(vb_1);
                    Vc_1=fft(vc_1-vc_ss1)/length(vc_1);
                    Ia_1=fft(ia_1-ia_ss1)/length(ia_1);
                    Ib_1=fft(ib_1-ib_ss1)/length(ib_1);
                    Ic_1=fft(ic_1-ic_ss1)/length(ic_1);
                    % System 2
                    va_2=out.Vabc2(td1:td2,1);
                    vb_2=out.Vabc2(td1:td2,2);
                    vc_2=out.Vabc2(td1:td2,3);
                    ia_2=out.Iabc2(td1:td2,1);
                    ib_2=out.Iabc2(td1:td2,2);
                    ic_2=out.Iabc2(td1:td2,3);
                    Va_2=fft(va_2-va_ss2)/length(va_2);
                    Vb_2=fft(vb_2-vb_ss2)/length(vb_2);
                    Vc_2=fft(vc_2-vc_ss2)/length(vc_2);
                    Ia_2=fft(ia_2-ia_ss2)/length(ia_2);
                    Ib_2=fft(ib_2-ib_ss2)/length(ib_2);
                    Ic_2=fft(ic_2-ic_ss2)/length(ic_2);
                    % System 1
                    Yac_1=Ia_1(wd)/Vc_1(wd);
                    Ybc_1=Ib_1(wd)/Vc_1(wd);
                    Ycc_1=Ic_1(wd)/Vc_1(wd);
                    Yabc_1=[Yaa_1 Yab_1 Yac_1
                          Yba_1 Ybb_1 Ybc_1
                          Yca_1 Ycb_1 Ycc_1];
                    Y_abc1(:,:,n)=Yabc_1;
                    % System 2
                    Yac_2=Ia_2(wd)/Vc_2(wd);
                    Ybc_2=Ib_2(wd)/Vc_2(wd);
                    Ycc_2=Ic_2(wd)/Vc_2(wd);
                    Yabc_2=[Yaa_2 Yab_2 Yac_2
                            Yba_2 Ybb_2 Ybc_2
                            Yca_2 Ycb_2 Ycc_2];
                    Y_abc2(:,:,n)=Yabc_2;
                end
                % Ya=squeeze(Y_abc_1(1,1,:));
                % Yb=squeeze(Y_abc_1(2,2,:));
                % Yc=squeeze(Y_abc_1(3,3,:));
            else
                % a-injection
                dist_value_a=Vsignal_dist1;
                dist_value_b=[Vsignal_dist1(:,1),zeros(samples_window,1)];
                dist_value_c=[Vsignal_dist1(:,1),zeros(samples_window,1)];
                [~, out] = evalc("sim(program)");
                % Vector windowed extraction
                % System 1
                va_1=out.Vabc1(td1:td2,1);
                vb_1=out.Vabc1(td1:td2,2);
                vc_1=out.Vabc1(td1:td2,3);
                ia_1=out.Iabc1(td1:td2,1);
                ib_1=out.Iabc1(td1:td2,2);
                ic_1=out.Iabc1(td1:td2,3);
                Va_1=fft(va_1-va_ss1)/length(va_1);
                Vb_1=fft(vb_1-vb_ss1)/length(vb_1);
                Vc_1=fft(vc_1-vc_ss1)/length(vc_1);
                Ia_1=fft(ia_1-ia_ss1)/length(ia_1);
                Ib_1=fft(ib_1-ib_ss1)/length(ib_1);
                Ic_1=fft(ic_1-ic_ss1)/length(ic_1);
                % System 2
                va_2=out.Vabc2(td1:td2,1);
                vb_2=out.Vabc2(td1:td2,2);
                vc_2=out.Vabc2(td1:td2,3);
                ia_2=out.Iabc2(td1:td2,1);
                ib_2=out.Iabc2(td1:td2,2);
                ic_2=out.Iabc2(td1:td2,3);
                Va_2=fft(va_2-va_ss2)/length(va_2);
                Vb_2=fft(vb_2-vb_ss2)/length(vb_2);
                Vc_2=fft(vc_2-vc_ss2)/length(vc_2);
                Ia_2=fft(ia_2-ia_ss2)/length(ia_2);
                Ib_2=fft(ib_2-ib_ss2)/length(ib_2);
                Ic_2=fft(ic_2-ic_ss2)/length(ic_2);
                % System 1
                Yaa_1=Ia_1./Va_1;
                Yba_1=Ib_1./Va_1;
                Yca_1=Ic_1./Va_1;
                % System 2
                Yaa_2=Ia_2./Va_2;
                Yba_2=Ib_2./Va_2;
                Yca_2=Ic_2./Va_2;
                % b-injection
                dist_value_b=Vsignal_dist2;
                dist_value_a=[Vsignal_dist2(:,1),zeros(samples_window,1)];
                dist_value_c=[Vsignal_dist2(:,1),zeros(samples_window,1)];
                [~, out] = evalc("sim(program)");
                % System 1
                va_1=out.Vabc1(td1:td2,1);
                vb_1=out.Vabc1(td1:td2,2);
                vc_1=out.Vabc1(td1:td2,3);
                ia_1=out.Iabc1(td1:td2,1);
                ib_1=out.Iabc1(td1:td2,2);
                ic_1=out.Iabc1(td1:td2,3);
                Va_1=fft(va_1-va_ss1)/length(va_1);
                Vb_1=fft(vb_1-vb_ss1)/length(vb_1);
                Vc_1=fft(vc_1-vc_ss1)/length(vc_1);
                Ia_1=fft(ia_1-ia_ss1)/length(ia_1);
                Ib_1=fft(ib_1-ib_ss1)/length(ib_1);
                Ic_1=fft(ic_1-ic_ss1)/length(ic_1);
                % System 2
                va_2=out.Vabc2(td1:td2,1);
                vb_2=out.Vabc2(td1:td2,2);
                vc_2=out.Vabc2(td1:td2,3);
                ia_2=out.Iabc2(td1:td2,1);
                ib_2=out.Iabc2(td1:td2,2);
                ic_2=out.Iabc2(td1:td2,3);
                Va_2=fft(va_2-va_ss2)/length(va_2);
                Vb_2=fft(vb_2-vb_ss2)/length(vb_2);
                Vc_2=fft(vc_2-vc_ss2)/length(vc_2);
                Ia_2=fft(ia_2-ia_ss2)/length(ia_2);
                Ib_2=fft(ib_2-ib_ss2)/length(ib_2);
                Ic_2=fft(ic_2-ic_ss2)/length(ic_2);
                % System 1
                Yab_1=Ia_1./Vb_1;
                Ybb_1=Ib_1./Vb_1;
                Ycb_1=Ic_1./Vb_1;
                % System 2
                Yab_2=Ia_2./Vb_2;
                Ybb_2=Ib_2./Vb_2;
                Ycb_2=Ic_2./Vb_2;
                % c-injection
                dist_value_c=Vsignal_dist3;
                dist_value_a=[Vsignal_dist3(:,1),zeros(samples_window,1)];
                dist_value_b=[Vsignal_dist3(:,1),zeros(samples_window,1)];
                [~, out] = evalc("sim(program)");
                % System 1
                va_1=out.Vabc1(td1:td2,1);
                vb_1=out.Vabc1(td1:td2,2);
                vc_1=out.Vabc1(td1:td2,3);
                ia_1=out.Iabc1(td1:td2,1);
                ib_1=out.Iabc1(td1:td2,2);
                ic_1=out.Iabc1(td1:td2,3);
                Va_1=fft(va_1-va_ss1)/length(va_1);
                Vb_1=fft(vb_1-vb_ss1)/length(vb_1);
                Vc_1=fft(vc_1-vc_ss1)/length(vc_1);
                Ia_1=fft(ia_1-ia_ss1)/length(ia_1);
                Ib_1=fft(ib_1-ib_ss1)/length(ib_1);
                Ic_1=fft(ic_1-ic_ss1)/length(ic_1);
                % System 2
                va_2=out.Vabc2(td1:td2,1);
                vb_2=out.Vabc2(td1:td2,2);
                vc_2=out.Vabc2(td1:td2,3);
                ia_2=out.Iabc2(td1:td2,1);
                ib_2=out.Iabc2(td1:td2,2);
                ic_2=out.Iabc2(td1:td2,3);
                Va_2=fft(va_2-va_ss2)/length(va_2);
                Vb_2=fft(vb_2-vb_ss2)/length(vb_2);
                Vc_2=fft(vc_2-vc_ss2)/length(vc_2);
                Ia_2=fft(ia_2-ia_ss2)/length(ia_2);
                Ib_2=fft(ib_2-ib_ss2)/length(ib_2);
                Ic_2=fft(ic_2-ic_ss2)/length(ic_2);
                % System 1
                Yac_1=Ia_1./Vc_1;
                Ybc_1=Ib_1./Vc_1;
                Ycc_1=Ic_1./Vc_1;
                % System 2
                Yac_2=Ia_2./Vc_2;
                Ybc_2=Ib_2./Vc_2;
                Ycc_2=Ic_2./Vc_2;
                for n=1:length(Ycc_1)
                    Y_abc1(:,:,n)=[Yaa_1(n) Yab_1(n) Yac_1(n)
                                    Yba_1(n) Ybb_1(n) Ybc_1(n)
                                    Yca_1(n) Ycb_1(n) Ycc_1(n)];
                    Y_abc2(:,:,n)=[Yaa_2(n) Yab_2(n) Yac_2(n)
                                    Yba_2(n) Ybb_2(n) Ybc_2(n)
                                    Yca_2(n) Ycb_2(n) Ycc_2(n)];
                end
                fvec=(1:samples_window)*fs;
                f_lim=find((fvec)>=fd0(end),1);
                Y_abc1=Y_abc1(:,:,1:f_lim);
                Y_abc2=Y_abc2(:,:,1:f_lim);
                fd0=fvec(1:f_lim);
            end
        else
            set_param(voltage_type, 'Commented', 'on');
            set_param(current_type, 'Commented', 'off');
            if signal_type==1
                set_param(multi_tone_I_ABC, 'Commented', 'on');
                set_param(single_tone_I_ABC, 'Commented', 'off');
                dist_value_a=0;
                dist_value_b=0;
                dist_value_c=0;
            else
                set_param(multi_tone_I_ABC, 'Commented', 'off');
                set_param(single_tone_I_ABC, 'Commented', 'on');
                dist_value_a=zeros(samples_window,2);
                dist_value_b=zeros(samples_window,2);
                dist_value_c=zeros(samples_window,2);
            end
            if ss_cal~=1
                [~, out] = evalc("sim(program)");
                td1=find((out.tout)>=t_w1,1); % t1 time window
                td2=find((out.tout)>=t_w2,1); % t2 time window
                % System 1
                va_ss1=out.Vabc1(td1:td2,1);
                vb_ss1=out.Vabc1(td1:td2,2);
                vc_ss1=out.Vabc1(td1:td2,3);
                ia_ss1=out.Iabc1(td1:td2,1);
                ib_ss1=out.Iabc1(td1:td2,2);
                ic_ss1=out.Iabc1(td1:td2,3);
                % System 2
                va_ss2=out.Vabc2(td1:td2,1);
                vb_ss2=out.Vabc2(td1:td2,2);
                vc_ss2=out.Vabc2(td1:td2,3);
                ia_ss2=out.Iabc2(td1:td2,1);
                ib_ss2=out.Iabc2(td1:td2,2);
                ic_ss2=out.Iabc2(td1:td2,3);
                dist_time=dist_time_f;
            end
            if signal_type==1
                for n=1:length(fd0)
                    fd=fd0(n);
                    % a-injection
                    dist_value_a=Idist_value;
                    dist_value_b=0;
                    dist_value_c=0;
                    [~, out] = evalc("sim(program)");
                    % Vector windowed extraction
                    % System 1
                    va_1=out.Vabc1(td1:td2,1);
                    vb_1=out.Vabc1(td1:td2,2);
                    vc_1=out.Vabc1(td1:td2,3);
                    ia_1=out.Iabc1(td1:td2,1);
                    ib_1=out.Iabc1(td1:td2,2);
                    ic_1=out.Iabc1(td1:td2,3);
                    Va_a1=fft(va_1-va_ss1)/length(va_1);
                    Vb_a1=fft(vb_1-vb_ss1)/length(vb_1);
                    Vc_a1=fft(vc_1-vc_ss1)/length(vc_1);
                    Ia_a1=fft(ia_1-ia_ss1)/length(ia_1);
                    Ib_a1=fft(ib_1-ib_ss1)/length(ib_1);
                    Ic_a1=fft(ic_1-ic_ss1)/length(ic_1);
                    %System 2
                    va_2=out.Vabc2(td1:td2,1);
                    vb_2=out.Vabc2(td1:td2,2);
                    vc_2=out.Vabc2(td1:td2,3);
                    ia_2=out.Iabc2(td1:td2,1);
                    ib_2=out.Iabc2(td1:td2,2);
                    ic_2=out.Iabc2(td1:td2,3);
                    Va_a2=fft(va_2-va_ss2)/length(va_2);
                    Vb_a2=fft(vb_2-vb_ss2)/length(vb_2);
                    Vc_a2=fft(vc_2-vc_ss2)/length(vc_2);
                    Ia_a2=fft(ia_2-ia_ss2)/length(ia_2);
                    Ib_a2=fft(ib_2-ib_ss2)/length(ib_2);
                    Ic_a2=fft(ic_2-ic_ss2)/length(ic_2);
                    % b-injection
                    dist_value_a=0;
                    dist_value_b=Idist_value;
                    dist_value_c=0;
                    [~, out] = evalc("sim(program)");
                    % System 1
                    va_1=out.Vabc1(td1:td2,1);
                    vb_1=out.Vabc1(td1:td2,2);
                    vc_1=out.Vabc1(td1:td2,3);
                    ia_1=out.Iabc1(td1:td2,1);
                    ib_1=out.Iabc1(td1:td2,2);
                    ic_1=out.Iabc1(td1:td2,3);
                    Va_b1=fft(va_1-va_ss1)/length(va_1);
                    Vb_b1=fft(vb_1-vb_ss1)/length(vb_1);
                    Vc_b1=fft(vc_1-vc_ss1)/length(vc_1);
                    Ia_b1=fft(ia_1-ia_ss1)/length(ia_1);
                    Ib_b1=fft(ib_1-ib_ss1)/length(ib_1);
                    Ic_b1=fft(ic_1-ic_ss1)/length(ic_1);
                    % System 2
                    va_2=out.Vabc2(td1:td2,1);
                    vb_2=out.Vabc2(td1:td2,2);
                    vc_2=out.Vabc2(td1:td2,3);
                    ia_2=out.Iabc2(td1:td2,1);
                    ib_2=out.Iabc2(td1:td2,2);
                    ic_2=out.Iabc2(td1:td2,3);
                    Va_b2=fft(va_2-va_ss2)/length(va_2);
                    Vb_b2=fft(vb_2-vb_ss2)/length(vb_2);
                    Vc_b2=fft(vc_2-vc_ss2)/length(vc_2);
                    Ia_b2=fft(ia_2-ia_ss2)/length(ia_2);
                    Ib_b2=fft(ib_2-ib_ss2)/length(ib_2);
                    Ic_b2=fft(ic_2-ic_ss2)/length(ic_2);
                    % c-injection
                    dist_value_a=0;
                    dist_value_b=0;
                    dist_value_c=Idist_value;
                    [~, out] = evalc("sim(program)");
                    % System 1
                    va_1=out.Vabc1(td1:td2,1);
                    vb_1=out.Vabc1(td1:td2,2);
                    vc_1=out.Vabc1(td1:td2,3);
                    ia_1=out.Iabc1(td1:td2,1);
                    ib_1=out.Iabc1(td1:td2,2);
                    ic_1=out.Iabc1(td1:td2,3);
                    Va_c1=fft(va_1-va_ss1)/length(va_1);
                    Vb_c1=fft(vb_1-vb_ss1)/length(vb_1);
                    Vc_c1=fft(vc_1-vc_ss1)/length(vc_1);
                    Ia_c1=fft(ia_1-ia_ss1)/length(ia_1);
                    Ib_c1=fft(ib_1-ib_ss1)/length(ib_1);
                    Ic_c1=fft(ic_1-ic_ss1)/length(ic_1);
                    % System 2
                    va_2=out.Vabc2(td1:td2,1);
                    vb_2=out.Vabc2(td1:td2,2);
                    vc_2=out.Vabc2(td1:td2,3);
                    ia_2=out.Iabc2(td1:td2,1);
                    ib_2=out.Iabc2(td1:td2,2);
                    ic_2=out.Iabc2(td1:td2,3);
                    Va_c2=fft(va_2-va_ss2)/length(va_2);
                    Vb_c2=fft(vb_2-vb_ss2)/length(vb_2);
                    Vc_c2=fft(vc_2-vc_ss2)/length(vc_2);
                    Ia_c2=fft(ia_2-ia_ss2)/length(ia_2);
                    Ib_c2=fft(ib_2-ib_ss2)/length(ib_2);
                    Ic_c2=fft(ic_2-ic_ss2)/length(ic_2);
                    wd=round(fd/fs)+1;
                    % System 1
                    Vabc1=[Va_a1(wd) Va_b1(wd) Va_c1(wd)
                           Vb_a1(wd) Vb_b1(wd) Vb_c1(wd)
                           Vc_a1(wd) Vc_b1(wd) Vc_c1(wd)];
                    Iabc1=[Ia_a1(wd) Ia_b1(wd) Ia_c1(wd)
                           Ib_a1(wd) Ib_b1(wd) Ib_c1(wd)
                           Ic_a1(wd) Ic_b1(wd) Ic_c1(wd)];
                    Z_abc1(:,:,n)=Vabc1*inv(Iabc1);
                    % System 2
                    Vabc2=[Va_a2(wd) Va_b2(wd) Va_c2(wd)
                           Vb_a2(wd) Vb_b2(wd) Vb_c2(wd)
                           Vc_a2(wd) Vc_b2(wd) Vc_c2(wd)];
                    Iabc2=[Ia_a2(wd) Ia_b2(wd) Ia_c2(wd)
                           Ib_a2(wd) Ib_b2(wd) Ib_c2(wd)
                           Ic_a2(wd) Ic_b2(wd) Ic_c2(wd)];
                    Z_abc2(:,:,n)=Vabc2*inv(Iabc2);
                end
                % Za=squeeze(Z_abc1(1,1,:));
                % Zb=squeeze(Z_abc1(2,2,:));
                % Zc=squeeze(Z_abc1(3,3,:));
            else
                % a-injection
                dist_value_a=Isignal_dist1;
                dist_value_b=[Isignal_dist1(:,1),zeros(samples_window,1)];
                dist_value_c=[Isignal_dist1(:,1),zeros(samples_window,1)];
                [~, out] = evalc("sim(program)");
                % Vector windowed extraction
                % System 1
                va_1=out.Vabc1(td1:td2,1);
                vb_1=out.Vabc1(td1:td2,2);
                vc_1=out.Vabc1(td1:td2,3);
                ia_1=out.Iabc1(td1:td2,1);
                ib_1=out.Iabc1(td1:td2,2);
                ic_1=out.Iabc1(td1:td2,3);
                Va_a1=fft(va_1-va_ss1)/length(va_1);
                Vb_a1=fft(vb_1-vb_ss1)/length(vb_1);
                Vc_a1=fft(vc_1-vc_ss1)/length(vc_1);
                Ia_a1=fft(ia_1-ia_ss1)/length(ia_1);
                Ib_a1=fft(ib_1-ib_ss1)/length(ib_1);
                Ic_a1=fft(ic_1-ic_ss1)/length(ic_1);
                %System 2
                va_2=out.Vabc2(td1:td2,1);
                vb_2=out.Vabc2(td1:td2,2);
                vc_2=out.Vabc2(td1:td2,3);
                ia_2=out.Iabc2(td1:td2,1);
                ib_2=out.Iabc2(td1:td2,2);
                ic_2=out.Iabc2(td1:td2,3);
                Va_a2=fft(va_2-va_ss2)/length(va_2);
                Vb_a2=fft(vb_2-vb_ss2)/length(vb_2);
                Vc_a2=fft(vc_2-vc_ss2)/length(vc_2);
                Ia_a2=fft(ia_2-ia_ss2)/length(ia_2);
                Ib_a2=fft(ib_2-ib_ss2)/length(ib_2);
                Ic_a2=fft(ic_2-ic_ss2)/length(ic_2);
                % b-injection
                dist_value_b=Isignal_dist2;
                dist_value_a=[Isignal_dist2(:,1),zeros(samples_window,1)];
                dist_value_c=[Isignal_dist2(:,1),zeros(samples_window,1)];
                [~, out] = evalc("sim(program)");
                % System 1
                va_1=out.Vabc1(td1:td2,1);
                vb_1=out.Vabc1(td1:td2,2);
                vc_1=out.Vabc1(td1:td2,3);
                ia_1=out.Iabc1(td1:td2,1);
                ib_1=out.Iabc1(td1:td2,2);
                ic_1=out.Iabc1(td1:td2,3);
                Va_b1=fft(va_1-va_ss1)/length(va_1);
                Vb_b1=fft(vb_1-vb_ss1)/length(vb_1);
                Vc_b1=fft(vc_1-vc_ss1)/length(vc_1);
                Ia_b1=fft(ia_1-ia_ss1)/length(ia_1);
                Ib_b1=fft(ib_1-ib_ss1)/length(ib_1);
                Ic_b1=fft(ic_1-ic_ss1)/length(ic_1);
                % System 2
                va_2=out.Vabc2(td1:td2,1);
                vb_2=out.Vabc2(td1:td2,2);
                vc_2=out.Vabc2(td1:td2,3);
                ia_2=out.Iabc2(td1:td2,1);
                ib_2=out.Iabc2(td1:td2,2);
                ic_2=out.Iabc2(td1:td2,3);
                Va_b2=fft(va_2-va_ss2)/length(va_2);
                Vb_b2=fft(vb_2-vb_ss2)/length(vb_2);
                Vc_b2=fft(vc_2-vc_ss2)/length(vc_2);
                Ia_b2=fft(ia_2-ia_ss2)/length(ia_2);
                Ib_b2=fft(ib_2-ib_ss2)/length(ib_2);
                Ic_b2=fft(ic_2-ic_ss2)/length(ic_2);
                % c-injection
                dist_value_c=Isignal_dist3;
                dist_value_a=[Isignal_dist3(:,1),zeros(samples_window,1)];
                dist_value_b=[Isignal_dist3(:,1),zeros(samples_window,1)];
                [~, out] = evalc("sim(program)");
                % System 1
                va_1=out.Vabc1(td1:td2,1);
                vb_1=out.Vabc1(td1:td2,2);
                vc_1=out.Vabc1(td1:td2,3);
                ia_1=out.Iabc1(td1:td2,1);
                ib_1=out.Iabc1(td1:td2,2);
                ic_1=out.Iabc1(td1:td2,3);
                Va_c1=fft(va_1-va_ss1)/length(va_1);
                Vb_c1=fft(vb_1-vb_ss1)/length(vb_1);
                Vc_c1=fft(vc_1-vc_ss1)/length(vc_1);
                Ia_c1=fft(ia_1-ia_ss1)/length(ia_1);
                Ib_c1=fft(ib_1-ib_ss1)/length(ib_1);
                Ic_c1=fft(ic_1-ic_ss1)/length(ic_1);
                % System 2
                va_2=out.Vabc2(td1:td2,1);
                vb_2=out.Vabc2(td1:td2,2);
                vc_2=out.Vabc2(td1:td2,3);
                ia_2=out.Iabc2(td1:td2,1);
                ib_2=out.Iabc2(td1:td2,2);
                ic_2=out.Iabc2(td1:td2,3);
                Va_c2=fft(va_2-va_ss2)/length(va_2);
                Vb_c2=fft(vb_2-vb_ss2)/length(vb_2);
                Vc_c2=fft(vc_2-vc_ss2)/length(vc_2);
                Ia_c2=fft(ia_2-ia_ss2)/length(ia_2);
                Ib_c2=fft(ib_2-ib_ss2)/length(ib_2);
                Ic_c2=fft(ic_2-ic_ss2)/length(ic_2);
            for n=1:length(Ic_c1)
                % System 1
                Vabc1=[Va_a1(n) Va_b1(n) Va_c1(n)
                       Vb_a1(n) Vb_b1(n) Vb_c1(n)
                       Vc_a1(n) Vc_b1(n) Vc_c1(n)];
                Iabc1=[Ia_a1(n) Ia_b1(n) Ia_c1(n)
                       Ib_a1(n) Ib_b1(n) Ib_c1(n)
                       Ic_a1(n) Ic_b1(n) Ic_c1(n)];
                Z_abc1(:,:,n)=Vabc1*inv(Iabc1);
                % System 2
                Vabc2=[Va_a2(n) Va_b2(n) Va_c2(n)
                       Vb_a2(n) Vb_b2(n) Vb_c2(n)
                       Vc_a2(n) Vc_b2(n) Vc_c2(n)];
                Iabc2=[Ia_a2(n) Ia_b2(n) Ia_c2(n)
                       Ib_a2(n) Ib_b2(n) Ib_c2(n)
                       Ic_a2(n) Ic_b2(n) Ic_c2(n)];
                Z_abc2(:,:,n)=Vabc2*inv(Iabc2);
            end
            % Frequency limits
            fvec=(1:samples_window)*fs;
            f_lim=find((fvec)>=fd0(end),1);
            Z_abc1=Z_abc1(:,:,1:f_lim);
            Z_abc2=Z_abc2(:,:,1:f_lim);
            fd0=fvec(1:f_lim);
            end
        end
        switch linear
            case 1
                if scanner_type==1
                    ABCPlot(fd0, Y_abc1, Yphases, jw1);
                    ABCPlot(fd0, Y_abc2, Yphases, jw1);
                    fprintf('SIaD Tool finished. Results stored in Y_abc1 and Y_abc2.\n');
                else
                    ABCPlot(fd0, Z_abc1, Zphases, jw1);
                    ABCPlot(fd0, Z_abc2, Zphases, jw1);
                    fprintf('SIaD Tool finished. Results stored in Z_abc2 and Z_abc2.\n');
                end
            case 0
                if scanner_type==1
                    ABCPlot2(fd0, Y_abc1);
                    ABCPlot2(fd0, Y_abc2);
                    fprintf('SIaD Tool finished. Results stored in Y_abc1 and Y_abc2.\n');
                else
                    ABCPlot2(fd0, Z_abc1);
                    ABCPlot2(fd0, Z_abc2);
                    fprintf('SIaD Tool finished. Results stored in Z_abc2 and Z_abc2.\n');
                end
        end
    %% qd0 Scanner
    case 2
        set_param(ABC_V_scanner, 'Commented', 'on');
        set_param(qd0_V_scanner, 'Commented', 'off');
        set_param(pn0_V_scanner, 'Commented', 'on');
        set_param(ABC_I_scanner, 'Commented', 'on');
        set_param(qd0_I_scanner, 'Commented', 'off');
        set_param(pn0_I_scanner, 'Commented', 'on');
        set_param(Sys1_Meas_ABC, 'Commented', 'on');
        set_param(Sys1_Meas_dq0, 'Commented', 'off');
        set_param(Sys1_Meas_0pn, 'Commented', 'on');
        set_param(Sys2_Meas_ABC, 'Commented', 'on');
        set_param(Sys2_Meas_dq0, 'Commented', 'off');
        set_param(Sys2_Meas_0pn, 'Commented', 'on');
        if scanner_type==1
            set_param(voltage_type, 'Commented', 'off');
            set_param(current_type, 'Commented', 'on');
                if signal_type==1
                    set_param(multi_tone_V_qd0, 'Commented', 'on');
                    set_param(single_tone_V_qd0, 'Commented', 'off');
                    dist_value_q=0;
                    dist_value_d=0;
                else
                    set_param(multi_tone_V_qd0, 'Commented', 'off');
                    set_param(single_tone_V_qd0, 'Commented', 'on');
                    dist_value_q=zeros(samples_window,2);
                    dist_value_d=zeros(samples_window,2);
                end
                if ss_cal~=1
                [~, out] = evalc("sim(program)");
                td1=find((out.tout)>=t_w1,1); % t1 time window
                td2=find((out.tout)>=t_w2,1); % t2 time window
                % System 1
                vq_ss1=out.Vqd1(td1:td2,1);
                vd_ss1=out.Vqd1(td1:td2,2);
                iq_ss1=out.Iqd1(td1:td2,1);
                id_ss1=out.Iqd1(td1:td2,2);
                % System 2
                vq_ss2=out.Vqd2(td1:td2,1);
                vd_ss2=out.Vqd2(td1:td2,2);
                iq_ss2=out.Iqd2(td1:td2,1);
                id_ss2=out.Iqd2(td1:td2,2);
                dist_time=dist_time_f;
                end
                if signal_type==1
                            for n=1:length(fd0)
                                fd=fd0(n); % Frequency value
                                % q-injection
                                clear dist_value_q dist_value_d act
                                dist_value_q=Vdist_value; % q disturbance
                                dist_value_d=0.0; % d disturbance
                                [~, out] = evalc("sim(program)");
                                % System 1
                                vq_1=out.Vqd1(td1:td2,1);
                                iq_1=out.Iqd1(td1:td2,1);
                                id_1=out.Iqd1(td1:td2,2);
                                Vq_1=fft(vq_1-vq_ss1)/length(vq_1);
                                Iq_1=fft(iq_1-iq_ss1)/length(iq_1);
                                Id_1=fft(id_1-id_ss1)/length(id_1);
                                % System 2
                                vq_2=out.Vqd2(td1:td2,1);
                                iq_2=out.Iqd2(td1:td2,1);
                                id_2=out.Iqd2(td1:td2,2);
                                Vq_2=fft(vq_2-vq_ss2)/length(vq_2);
                                Iq_2=fft(iq_2-iq_ss2)/length(iq_2);
                                Id_2=fft(id_2-id_ss2)/length(id_2);
                                wd=round(fd/fs)+1;
                                % System 1
                                Ydq1(:,n)=Id_1(wd)/Vq_1(wd);
                                Yqq1(:,n)=Iq_1(wd)/Vq_1(wd);
                                % System 2
                                Ydq2(:,n)=Id_2(wd)/Vq_2(wd);
                                Yqq2(:,n)=Iq_2(wd)/Vq_2(wd);
                                % d-injection
                                clear dist_value_q dist_value_d act
                                dist_value_q=0.0; % q disturbance
                                dist_value_d=Vdist_value; % d disturbance
                                [~, out] = evalc("sim(program)");
                                % System 1
                                vd_1=out.Vqd1(td1:td2,2);
                                iq_1=out.Iqd1(td1:td2,1);
                                id_1=out.Iqd1(td1:td2,2);
                                Vd_1=fft(vd_1-vd_ss1)/length(vd_1);
                                Iq_1=fft(iq_1-iq_ss1)/length(iq_1);
                                Id_1=fft(id_1-id_ss1)/length(id_1);
                                % System 2
                                vd_2=out.Vqd2(td1:td2,2);
                                iq_2=out.Iqd2(td1:td2,1);
                                id_2=out.Iqd2(td1:td2,2);
                                Vd_2=fft(vd_2-vd_ss2)/length(vd_2);
                                Iq_2=fft(iq_2-iq_ss2)/length(iq_2);
                                Id_2=fft(id_2-id_ss2)/length(id_2);
                                % System 1
                                Yqd1(:,n)=Iq_1(wd)/Vd_1(wd);
                                Ydd1(:,n)=Id_1(wd)/Vd_1(wd);
                                % System 2
                                Yqd2(:,n)=Iq_2(wd)/Vd_2(wd);
                                Ydd2(:,n)=Id_2(wd)/Vd_2(wd);
                            end
                else
                    % q-injection
                    clear dist_value_q dist_value_d act
                    dist_value_q=Vsignal_dist1;
                    dist_value_d=[Vsignal_dist1(:,1),zeros(samples_window,1)];
                    [~, out] = evalc("sim(program)");
                    % System 1
                    vq_1=out.Vqd1(td1:td2,1);
                    iq_1=out.Iqd1(td1:td2,1);
                    id_1=out.Iqd1(td1:td2,2);
                    Vq_1=fft(vq_1-vq_ss1)/length(vq_1);
                    Iq_1=fft(iq_1-iq_ss1)/length(iq_1);
                    Id_1=fft(id_1-id_ss1)/length(id_1);
                    % System 2
                    vq_2=out.Vqd2(td1:td2,1);
                    iq_2=out.Iqd2(td1:td2,1);
                    id_2=out.Iqd2(td1:td2,2);
                    Vq_2=fft(vq_2-vq_ss2)/length(vq_2);
                    Iq_2=fft(iq_2-iq_ss2)/length(iq_2);
                    Id_2=fft(id_2-id_ss2)/length(id_2);
                    % System 1
                    Yqq1=Iq_1./Vq_1;
                    Ydq1=Id_1./Vq_1;
                    % System 2
                    Yqq2=Iq_2./Vq_2;
                    Ydq2=Id_2./Vq_2;
                    % d-injection
                    clear dist_value_q dist_value_d act
                    dist_value_d=Vsignal_dist1;
                    dist_value_q=[Vsignal_dist1(:,1),zeros(samples_window,1)];
                    [~, out] = evalc("sim(program)");
                    % System 1
                    vd_1=out.Vqd1(td1:td2,2);
                    iq_1=out.Iqd1(td1:td2,1);
                    id_1=out.Iqd1(td1:td2,2);
                    Vd_1=fft(vd_1-vd_ss1)/length(vd_1);
                    Iq_1=fft(iq_1-iq_ss1)/length(iq_1);
                    Id_1=fft(id_1-id_ss1)/length(id_1);
                    % System 2
                    vd_2=out.Vqd2(td1:td2,2);
                    iq_2=out.Iqd2(td1:td2,1);
                    id_2=out.Iqd2(td1:td2,2);
                    Vd_2=fft(vd_2-vd_ss2)/length(vd_2);
                    Iq_2=fft(iq_2-iq_ss2)/length(iq_2);
                    Id_2=fft(id_2-id_ss2)/length(id_2);
                    % System 1
                    Ydd1=Id_1./Vd_1;
                    Yqd1=Iq_1./Vd_1;
                    % System 2
                    Ydd2=Id_2./Vd_2;
                    Yqd2=Iq_2./Vd_2;
                    % Frequency limits
                    fvec=(1:samples_window)*fs;
                    f_lim=find((fvec)>=fd0(end),1);
                    % System 1
                    Yqq1=Yqq1(1:f_lim);
                    Yqd1=Yqd1(1:f_lim);
                    Ydq1=Ydq1(1:f_lim);
                    Ydd1=Ydd1(1:f_lim);
                    % System 2
                    Yqq2=Yqq2(1:f_lim);
                    Yqd2=Yqd2(1:f_lim);
                    Ydq2=Ydq2(1:f_lim);
                    Ydd2=Ydd2(1:f_lim);
                    fd0=fvec(1:f_lim);
                end
        else
            set_param(voltage_type, 'Commented', 'on');
            set_param(current_type, 'Commented', 'off');
            if signal_type==1
                set_param(multi_tone_I_qd0, 'Commented', 'on');
                set_param(single_tone_I_qd0, 'Commented', 'off');
                dist_value_q=0;
                dist_value_d=0;
            else
                set_param(multi_tone_I_qd0, 'Commented', 'off');
                set_param(single_tone_I_qd0, 'Commented', 'on');
                dist_value_q=zeros(samples_window,2);
                dist_value_d=zeros(samples_window,2);
            end
            if ss_cal~=1
                [~, out] = evalc("sim(program)");
                td1=find((out.tout)>=t_w1,1); % t1 time window
                td2=find((out.tout)>=t_w2,1); % t2 time window
                % System 1
                vq_ss1=out.Vqd1(td1:td2,1);
                vd_ss1=out.Vqd1(td1:td2,2);
                iq_ss1=out.Iqd1(td1:td2,1);
                id_ss1=out.Iqd1(td1:td2,2);
                % System 2
                vq_ss2=out.Vqd2(td1:td2,1);
                vd_ss2=out.Vqd2(td1:td2,2);
                iq_ss2=out.Iqd2(td1:td2,1);
                id_ss2=out.Iqd2(td1:td2,2);
                dist_time=dist_time_f;
            end
            if signal_type==1
                for n=1:length(fd0)
                    fd=fd0(n);
                    % q-injection
                    dist_value_q=Idist_value;
                    dist_value_d=0;
                    [~, out] = evalc("sim(program)");
                    % System 1
                    vq_1=out.Vqd1(td1:td2,1);
                    vd_1=out.Vqd1(td1:td2,2);
                    iq_1=out.Iqd1(td1:td2,1);
                    id_1=out.Iqd1(td1:td2,2);
                    Vq_q1=fft(vq_1-vq_ss1)/length(vq_1);
                    Vd_q1=fft(vd_1-vd_ss1)/length(vd_1);
                    Iq_q1=fft(iq_1-iq_ss1)/length(iq_1);
                    Id_q1=fft(id_1-id_ss1)/length(id_1);
                    % System 2
                    vq_2=out.Vqd2(td1:td2,1);
                    vd_2=out.Vqd2(td1:td2,2);
                    iq_2=out.Iqd2(td1:td2,1);
                    id_2=out.Iqd2(td1:td2,2);
                    Vq_q2=fft(vq_2-vq_ss2)/length(vq_2);
                    Vd_q2=fft(vd_2-vd_ss2)/length(vd_2);
                    Iq_q2=fft(iq_2-iq_ss2)/length(iq_2);
                    Id_q2=fft(id_2-id_ss2)/length(id_2);
                    % d-injection
                    dist_value_d=Idist_value;
                    dist_value_q=0;
                    [~, out] = evalc("sim(program)");
                    % System 1
                    vq_1=out.Vqd1(td1:td2,1);
                    vd_1=out.Vqd1(td1:td2,2);
                    iq_1=out.Iqd1(td1:td2,1);
                    id_1=out.Iqd1(td1:td2,2);
                    Vq_d1=fft(vq_1-vq_ss1)/length(vq_1);
                    Vd_d1=fft(vd_1-vd_ss1)/length(vd_1);
                    Iq_d1=fft(iq_1-iq_ss1)/length(iq_1);
                    Id_d1=fft(id_1-id_ss1)/length(id_1);
                    % System 2
                    vq_2=out.Vqd2(td1:td2,1);
                    vd_2=out.Vqd2(td1:td2,2);
                    iq_2=out.Iqd2(td1:td2,1);
                    id_2=out.Iqd2(td1:td2,2);
                    Vq_d2=fft(vq_2-vq_ss2)/length(vq_2);
                    Vd_d2=fft(vd_2-vd_ss2)/length(vd_2);
                    Iq_d2=fft(iq_2-iq_ss2)/length(iq_2);
                    Id_d2=fft(id_2-id_ss2)/length(id_2);
                    % qd and dd Admitance calculation in FD
                    wd=round(fd/fs)+1;
                    % System 1
                    Vqd1=[Vq_q1(wd) Vq_d1(wd)
                          Vd_q1(wd) Vd_d1(wd)];
                    Iqd1=[Iq_q1(wd) Iq_d1(wd)
                          Id_q1(wd) Id_d1(wd)];
                    Z_qd1=Vqd1*inv(Iqd1);
                    Zqq1(:,n)=Z_qd1(1,1);
                    Zqd1(:,n)=Z_qd1(1,2);
                    Zdq1(:,n)=Z_qd1(2,1);
                    Zdd1(:,n)=Z_qd1(2,2);
                    % System 2
                    Vqd2=[Vq_q2(wd) Vq_d2(wd)
                          Vd_q2(wd) Vd_d2(wd)];
                    Iqd2=[Iq_q2(wd) Iq_d2(wd)
                          Id_q2(wd) Id_d2(wd)];
                    Z_qd2=Vqd2*inv(Iqd2);
                    Zqq2(:,n)=Z_qd2(1,1);
                    Zqd2(:,n)=Z_qd2(1,2);
                    Zdq2(:,n)=Z_qd2(2,1);
                    Zdd2(:,n)=Z_qd2(2,2);
                end
            else
                % q-injection
                dist_value_q=Isignal_dist1;
                dist_value_d=[Isignal_dist1(:,1),zeros(samples_window,1)];
                [~, out] = evalc("sim(program)");
                % System 1
                vq_1=out.Vqd1(td1:td2,1);
                vd_1=out.Vqd1(td1:td2,2);
                iq_1=out.Iqd1(td1:td2,1);
                id_1=out.Iqd1(td1:td2,2);
                Vq_q1=fft(vq_1-vq_ss1)/length(vq_1);
                Vd_q1=fft(vd_1-vd_ss1)/length(vd_1);
                Iq_q1=fft(iq_1-iq_ss1)/length(iq_1);
                Id_q1=fft(id_1-id_ss1)/length(id_1);
                % System 2
                vq_2=out.Vqd2(td1:td2,1);
                vd_2=out.Vqd2(td1:td2,2);
                iq_2=out.Iqd2(td1:td2,1);
                id_2=out.Iqd2(td1:td2,2);
                Vq_q2=fft(vq_2-vq_ss2)/length(vq_2);
                Vd_q2=fft(vd_2-vd_ss2)/length(vd_2);
                Iq_q2=fft(iq_2-iq_ss2)/length(iq_2);
                Id_q2=fft(id_2-id_ss2)/length(id_2);
                % d-injection
                dist_value_d=Isignal_dist1;
                dist_value_q=[Isignal_dist1(:,1),zeros(samples_window,1)];
                [~, out] = evalc("sim(program)");
                % System 1
                vq_1=out.Vqd1(td1:td2,1);
                vd_1=out.Vqd1(td1:td2,2);
                iq_1=out.Iqd1(td1:td2,1);
                id_1=out.Iqd1(td1:td2,2);
                Vq_d1=fft(vq_1-vq_ss1)/length(vq_1);
                Vd_d1=fft(vd_1-vd_ss1)/length(vd_1);
                Iq_d1=fft(iq_1-iq_ss1)/length(iq_1);
                Id_d1=fft(id_1-id_ss1)/length(id_1);
                % System 2
                vq_2=out.Vqd2(td1:td2,1);
                vd_2=out.Vqd2(td1:td2,2);
                iq_2=out.Iqd2(td1:td2,1);
                id_2=out.Iqd2(td1:td2,2);
                Vq_d2=fft(vq_2-vq_ss2)/length(vq_2);
                Vd_d2=fft(vd_2-vd_ss2)/length(vd_2);
                Iq_d2=fft(iq_2-iq_ss2)/length(iq_2);
                Id_d2=fft(id_2-id_ss2)/length(id_2);
            for n=1:length(Id_d1)
                % System 1
                Vqd1=[Vq_q1(n) Vq_d1(n)
                      Vd_q1(n) Vd_d1(n)];
                Iqd1=[Iq_q1(n) Iq_d1(n)
                      Id_q1(n) Id_d1(n)];
                Z_qd1=Vqd1*inv(Iqd1);
                Zqq1(:,n)=Z_qd1(1,1);
                Zqd1(:,n)=Z_qd1(1,2);
                Zdq1(:,n)=Z_qd1(2,1);
                Zdd1(:,n)=Z_qd1(2,2);
                % System 2
                Vqd2=[Vq_q2(n) Vq_d2(n)
                      Vd_q2(n) Vd_d2(n)];
                Iqd2=[Iq_q2(n) Iq_d2(n)
                      Id_q2(n) Id_d2(n)];
                Z_qd2=Vqd2*inv(Iqd2);
                Zqq2(:,n)=Z_qd2(1,1);
                Zqd2(:,n)=Z_qd2(1,2);
                Zdq2(:,n)=Z_qd2(2,1);
                Zdd2(:,n)=Z_qd2(2,2);
            end
            % Frequency limits
            fvec=(1:samples_window)*fs;
            f_lim=find((fvec)>=fd0(end),1);
            % System 1
            Zqq1=Zqq1(1:f_lim);
            Zqd1=Zqd1(1:f_lim);
            Zdq1=Zdq1(1:f_lim);
            Zdd1=Zdd1(1:f_lim);
            % System 2
            Zqq2=Zqq2(1:f_lim);
            Zqd2=Zqd2(1:f_lim);
            Zdq2=Zdq2(1:f_lim);
            Zdd2=Zdd2(1:f_lim);
            fd0=fvec(1:f_lim);
            end
        end
            switch linear
                case 1
                    if scanner_type==1
                    qd0Plot(fd0, jw1, Ym_RLC, Ya_RLC, Yqq1, Yqd1, Ydq1, Ydd1);
                    qd0Plot(fd0, jw1, Ym_RLC, Ya_RLC, Yqq2, Yqd2, Ydq2, Ydd2);
                    fprintf('SIaD Tool finished.\n');
                    fprintf('Results stored in Yqq1, Yqd1, Ydq1 and Ydd1.\n');
                    fprintf('Results stored in Yqq2, Yqd2, Ydq2 and Ydd2.\n');
                    else
                    qd0Plot(fd0, jw1, Zm_RLC, Za_RLC, Zqq1, Zqd1, Zdq1, Zdd1);
                    qd0Plot(fd0, jw1, Zm_RLC, Za_RLC, Zqq2, Zqd2, Zdq2, Zdd2);
                    fprintf('SIaD Tool finished.\n');
                    fprintf('Results stored in Zqq1, Zqd1, Zdq1 and Zdd1.\n');
                    fprintf('Results stored in Zqq2, Zqd2, Zdq2 and Zdd2.\n');
                    end
                case 0
                    if scanner_type==1
                    qd0Plot2(fd0, Yqq1, Yqd1, Ydq1, Ydd1);
                    qd0Plot2(fd0, Yqq2, Yqd2, Ydq2, Ydd2);
                    fprintf('SIaD Tool finished.\n');
                    fprintf('Results stored in Yqq1, Yqd1, Ydq1 and Ydd1.\n');
                    fprintf('Results stored in Yqq2, Yqd2, Ydq2 and Ydd2.\n');
                    else
                    qd0Plot2(fd0, Zqq1, Zqd1, Zdq1, Zdd1);
                    qd0Plot2(fd0, Zqq2, Zqd2, Zdq2, Zdd2);
                    fprintf('SIaD Tool finished.\n');
                    fprintf('Results stored in Zqq1, Zqd1, Zdq1 and Zdd1.\n');
                    fprintf('Results stored in Zqq2, Zqd2, Zdq2 and Zdd2.\n');
                    end
            end
    %% pn0 Scanner
    case 3
        set_param(ABC_V_scanner, 'Commented', 'on');
        set_param(qd0_V_scanner, 'Commented', 'on');
        set_param(pn0_V_scanner, 'Commented', 'off');
        set_param(ABC_I_scanner, 'Commented', 'on');
        set_param(qd0_I_scanner, 'Commented', 'on');
        set_param(pn0_I_scanner, 'Commented', 'off');
        set_param(Sys1_Meas_ABC, 'Commented', 'on');
        set_param(Sys1_Meas_dq0, 'Commented', 'on');
        set_param(Sys1_Meas_0pn, 'Commented', 'off');
        set_param(Sys2_Meas_ABC, 'Commented', 'on');
        set_param(Sys2_Meas_dq0, 'Commented', 'on');
        set_param(Sys2_Meas_0pn, 'Commented', 'off');
        if scanner_type==1
            set_param(voltage_type, 'Commented', 'off');
            set_param(current_type, 'Commented', 'on');
            if signal_type==1
                set_param(multi_tone_V_0pn, 'Commented', 'on');
                set_param(single_tone_V_0pn, 'Commented', 'off');
                dist_value_0=0;
                dist_value_p=0;
                dist_value_n=0;
            else
                set_param(multi_tone_V_0pn, 'Commented', 'off');
                set_param(single_tone_V_0pn, 'Commented', 'on');
                dist_value_0=zeros(samples_window,2);
                dist_value_p=zeros(samples_window,2);
                dist_value_n=zeros(samples_window,2);
            end
            if ss_cal~=1
                [~, out] = evalc("sim(program)");
                td1=find((out.tout)>=t_w1,1); % t1 time window
                td2=find((out.tout)>=t_w2,1); % t2 time window
                % System 1
                v0_ss1=out.V0pn1(td1:td2,1);
                vp_ss1=out.V0pn1(td1:td2,2);
                vn_ss1=out.V0pn1(td1:td2,3);
                i0_ss1=out.I0pn1(td1:td2,1);
                ip_ss1=out.I0pn1(td1:td2,2);
                in_ss1=out.I0pn1(td1:td2,3);
                % System 2
                v0_ss2=out.V0pn2(td1:td2,1);
                vp_ss2=out.V0pn2(td1:td2,2);
                vn_ss2=out.V0pn2(td1:td2,3);
                i0_ss2=out.I0pn2(td1:td2,1);
                ip_ss2=out.I0pn2(td1:td2,2);
                in_ss2=out.I0pn2(td1:td2,3);
                dist_time=dist_time_f;
            end
            if signal_type==1
                for n=1:length(fd0)
                    fd=fd0(n);
                    % p-injection
                    dist_value_p=Vdist_value;
                    dist_value_n=0;
                    dist_value_0=0;
                    [~, out] = evalc("sim(program)");
                    % Vector windowed extraction
                    % System 1
                    v0_1=out.V0pn1(td1:td2,1);
                    vp_1=out.V0pn1(td1:td2,2);
                    vn_1=out.V0pn1(td1:td2,3);
                    i0_1=out.I0pn1(td1:td2,1);
                    ip_1=out.I0pn1(td1:td2,2);
                    in_1=out.I0pn1(td1:td2,3);
                    V0_1=fft(v0_1-v0_ss1)/length(v0_1);
                    Vp_1=fft(vp_1-vp_ss1)/length(vp_1);
                    Vn_1=fft(vn_1-vn_ss1)/length(vn_1);
                    I0_1=fft(i0_1-i0_ss1)/length(i0_1);
                    Ip_1=fft(ip_1-ip_ss1)/length(ip_1);
                    In_1=fft(in_1-in_ss1)/length(in_1);
                    % System 2
                    v0_2=out.V0pn2(td1:td2,1);
                    vp_2=out.V0pn2(td1:td2,2);
                    vn_2=out.V0pn2(td1:td2,3);
                    i0_2=out.I0pn2(td1:td2,1);
                    ip_2=out.I0pn2(td1:td2,2);
                    in_2=out.I0pn2(td1:td2,3);
                    V0_2=fft(v0_2-v0_ss2)/length(v0_2);
                    Vp_2=fft(vp_2-vp_ss2)/length(vp_2);
                    Vn_2=fft(vn_2-vn_ss2)/length(vn_2);
                    I0_2=fft(i0_2-i0_ss2)/length(i0_2);
                    Ip_2=fft(ip_2-ip_ss2)/length(ip_2);
                    In_2=fft(in_2-in_ss2)/length(in_2);
                    wd=round(fd/fs)+1;
                    % System 1
                    Y_0p0_1=I0_1(wd)/Vp_1(wd);
                    Y_pp0_1=Ip_1(wd)/Vp_1(wd);
                    Y_np0_1=In_1(wd)/Vp_1(wd);
                    Ypp1(:,n)=Y_pp0_1;
                    Ynp1(:,n)=Y_np0_1;
                    % System 2
                    Y_0p0_2=I0_2(wd)/Vp_2(wd);
                    Y_pp0_2=Ip_2(wd)/Vp_2(wd);
                    Y_np0_2=In_2(wd)/Vp_2(wd);
                    Ypp2(:,n)=Y_pp0_2;
                    Ynp2(:,n)=Y_np0_2;
                    % n-injection
                    dist_value_p=0;
                    dist_value_n=Vdist_value;
                    dist_value_0=0;
                    [~, out] = evalc("sim(program)");
                    % System 1
                    v0_1=out.V0pn1(td1:td2,1);
                    vp_1=out.V0pn1(td1:td2,2);
                    vn_1=out.V0pn1(td1:td2,3);
                    i0_1=out.I0pn1(td1:td2,1);
                    ip_1=out.I0pn1(td1:td2,2);
                    in_1=out.I0pn1(td1:td2,3);
                    V0_1=fft(v0_1-v0_ss1)/length(v0_1);
                    Vp_1=fft(vp_1-vp_ss1)/length(vp_1);
                    Vn_1=fft(vn_1-vn_ss1)/length(vn_1);
                    I0_1=fft(i0_1-i0_ss1)/length(i0_1);
                    Ip_1=fft(ip_1-ip_ss1)/length(ip_1);
                    In_1=fft(in_1-in_ss1)/length(in_1);
                    % System 2
                    v0_2=out.V0pn2(td1:td2,1);
                    vp_2=out.V0pn2(td1:td2,2);
                    vn_2=out.V0pn2(td1:td2,3);
                    i0_2=out.I0pn2(td1:td2,1);
                    ip_2=out.I0pn2(td1:td2,2);
                    in_2=out.I0pn2(td1:td2,3);
                    V0_2=fft(v0_2-v0_ss2)/length(v0_2);
                    Vp_2=fft(vp_2-vp_ss2)/length(vp_2);
                    Vn_2=fft(vn_2-vn_ss2)/length(vn_2);
                    I0_2=fft(i0_2-i0_ss2)/length(i0_2);
                    Ip_2=fft(ip_2-ip_ss2)/length(ip_2);
                    In_2=fft(in_2-in_ss2)/length(in_2);
                    % System 1
                    Y_0n0_1=I0_1(wd)/Vn_1(wd);
                    Y_pn0_1=Ip_1(wd)/Vn_1(wd);
                    Y_nn0_1=In_1(wd)/Vn_1(wd);
                    Ypn1(:,n)=Y_pn0_1;
                    Ynn1(:,n)=Y_nn0_1;
                    % System 2
                    Y_0n0_2=I0_2(wd)/Vn_2(wd);
                    Y_pn0_2=Ip_2(wd)/Vn_2(wd);
                    Y_nn0_2=In_2(wd)/Vn_2(wd);
                    Ypn2(:,n)=Y_pn0_2;
                    Ynn2(:,n)=Y_nn0_2;
                    % 0-injection
                    dist_value_p=0;
                    dist_value_n=0;
                    dist_value_0=Vdist_value;
                    [~, out] = evalc("sim(program)");
                    % System 1
                    v0_1=out.V0pn1(td1:td2,1);
                    vp_1=out.V0pn1(td1:td2,2);
                    vn_1=out.V0pn1(td1:td2,3);
                    i0_1=out.I0pn1(td1:td2,1);
                    ip_1=out.I0pn1(td1:td2,2);
                    in_1=out.I0pn1(td1:td2,3);
                    V0_1=fft(v0_1-v0_ss1)/length(v0_1);
                    Vp_1=fft(vp_1-vp_ss1)/length(vp_1);
                    Vn_1=fft(vn_1-vn_ss1)/length(vn_1);
                    I0_1=fft(i0_1-i0_ss1)/length(i0_1);
                    Ip_1=fft(ip_1-ip_ss1)/length(ip_1);
                    In_1=fft(in_1-in_ss1)/length(in_1);
                    % System 2
                    v0_2=out.V0pn2(td1:td2,1);
                    vp_2=out.V0pn2(td1:td2,2);
                    vn_2=out.V0pn2(td1:td2,3);
                    i0_2=out.I0pn2(td1:td2,1);
                    ip_2=out.I0pn2(td1:td2,2);
                    in_2=out.I0pn2(td1:td2,3);
                    V0_2=fft(v0_2-v0_ss2)/length(v0_2);
                    Vp_2=fft(vp_2-vp_ss2)/length(vp_2);
                    Vn_2=fft(vn_2-vn_ss2)/length(vn_2);
                    I0_2=fft(i0_2-i0_ss2)/length(i0_2);
                    Ip_2=fft(ip_2-ip_ss2)/length(ip_2);
                    In_2=fft(in_2-in_ss2)/length(in_2);
                     % System 1
                    Y_000_1=I0_1(wd)/V0_1(wd);
                    Y_p00_1=Ip_1(wd)/V0_1(wd);
                    Y_n00_1=In_1(wd)/V0_1(wd);
                    Y_0pn1=[Y_000_1 Y_0p0_1 Y_0n0_1
                             Y_p00_1 Y_pp0_1 Y_pn0_1
                             Y_n00_1 Y_np0_1 Y_nn0_1];
                    Y_0pn1(:,:,n)=Y_0pn1;
                    % System 2
                    Y_000_2=I0_2(wd)/V0_2(wd);
                    Y_p00_2=Ip_2(wd)/V0_2(wd);
                    Y_n00_2=In_2(wd)/V0_2(wd);
                    Y_0pn_2=[Y_000_2 Y_0p0_2 Y_0n0_2
                             Y_p00_2 Y_pp0_2 Y_pn0_2
                             Y_n00_2 Y_np0_2 Y_nn0_2];
                    Y_0pn2(:,:,n)=Y_0pn_2;
                end
            else
                % p-injection
                dist_value_p=Vsignal_dist1;
                dist_value_n=[Vsignal_dist1(:,1),zeros(samples_window,1)];
                dist_value_0=[Vsignal_dist1(:,1),zeros(samples_window,1)];
                [~, out] = evalc("sim(program)");
                 % System 1
                v0_1=out.V0pn1(td1:td2,1);
                vp_1=out.V0pn1(td1:td2,2);
                vn_1=out.V0pn1(td1:td2,3);
                i0_1=out.I0pn1(td1:td2,1);
                ip_1=out.I0pn1(td1:td2,2);
                in_1=out.I0pn1(td1:td2,3);
                V0_1=fft(v0_1-v0_ss1)/length(v0_1);
                Vp_1=fft(vp_1-vp_ss1)/length(vp_1);
                Vn_1=fft(vn_1-vn_ss1)/length(vn_1);
                I0_1=fft(i0_1-i0_ss1)/length(i0_1);
                Ip_1=fft(ip_1-ip_ss1)/length(ip_1);
                In_1=fft(in_1-in_ss1)/length(in_1);
                % System 2
                v0_2=out.V0pn2(td1:td2,1);
                vp_2=out.V0pn2(td1:td2,2);
                vn_2=out.V0pn2(td1:td2,3);
                i0_2=out.I0pn2(td1:td2,1);
                ip_2=out.I0pn2(td1:td2,2);
                in_2=out.I0pn2(td1:td2,3);
                V0_2=fft(v0_2-v0_ss2)/length(v0_2);
                Vp_2=fft(vp_2-vp_ss2)/length(vp_2);
                Vn_2=fft(vn_2-vn_ss2)/length(vn_2);
                I0_2=fft(i0_2-i0_ss2)/length(i0_2);
                Ip_2=fft(ip_2-ip_ss2)/length(ip_2);
                In_2=fft(in_2-in_ss2)/length(in_2);
                % System 1
                Y0p1=I0_1./Vp_1;
                Ypp1=Ip_1./Vp_1;
                Ynp1=In_1./Vp_1;
                % System 2
                Y0p2=I0_2./Vp_2;
                Ypp2=Ip_2./Vp_2;
                Ynp2=In_2./Vp_2;
                % n-injection
                dist_value_n=Vsignal_dist2;
                dist_value_p=[Vsignal_dist2(:,1),zeros(samples_window,1)];
                dist_value_0=[Vsignal_dist2(:,1),zeros(samples_window,1)];
                [~, out] = evalc("sim(program)");
                 % System 1
                v0_1=out.V0pn1(td1:td2,1);
                vp_1=out.V0pn1(td1:td2,2);
                vn_1=out.V0pn1(td1:td2,3);
                i0_1=out.I0pn1(td1:td2,1);
                ip_1=out.I0pn1(td1:td2,2);
                in_1=out.I0pn1(td1:td2,3);
                V0_1=fft(v0_1-v0_ss1)/length(v0_1);
                Vp_1=fft(vp_1-vp_ss1)/length(vp_1);
                Vn_1=fft(vn_1-vn_ss1)/length(vn_1);
                I0_1=fft(i0_1-i0_ss1)/length(i0_1);
                Ip_1=fft(ip_1-ip_ss1)/length(ip_1);
                In_1=fft(in_1-in_ss1)/length(in_1);
                % System 2
                v0_2=out.V0pn2(td1:td2,1);
                vp_2=out.V0pn2(td1:td2,2);
                vn_2=out.V0pn2(td1:td2,3);
                i0_2=out.I0pn2(td1:td2,1);
                ip_2=out.I0pn2(td1:td2,2);
                in_2=out.I0pn2(td1:td2,3);
                V0_2=fft(v0_2-v0_ss2)/length(v0_2);
                Vp_2=fft(vp_2-vp_ss2)/length(vp_2);
                Vn_2=fft(vn_2-vn_ss2)/length(vn_2);
                I0_2=fft(i0_2-i0_ss2)/length(i0_2);
                Ip_2=fft(ip_2-ip_ss2)/length(ip_2);
                In_2=fft(in_2-in_ss2)/length(in_2);
                % System 1
                Y0n1=I0_1./Vn_1;
                Ypn1=Ip_1./Vn_1;
                Ynn1=In_1./Vn_1;
                % System 1
                Y0n2=I0_2./Vn_2;
                Ypn2=Ip_2./Vn_2;
                Ynn2=In_2./Vn_2;
                % 0-injection
                dist_value_0=Vsignal_dist3;
                dist_value_p=[Vsignal_dist3(:,1),zeros(samples_window,1)];
                dist_value_n=[Vsignal_dist3(:,1),zeros(samples_window,1)];
                [~, out] = evalc("sim(program)");
                 % System 1
                v0_1=out.V0pn1(td1:td2,1);
                vp_1=out.V0pn1(td1:td2,2);
                vn_1=out.V0pn1(td1:td2,3);
                i0_1=out.I0pn1(td1:td2,1);
                ip_1=out.I0pn1(td1:td2,2);
                in_1=out.I0pn1(td1:td2,3);
                V0_1=fft(v0_1-v0_ss1)/length(v0_1);
                Vp_1=fft(vp_1-vp_ss1)/length(vp_1);
                Vn_1=fft(vn_1-vn_ss1)/length(vn_1);
                I0_1=fft(i0_1-i0_ss1)/length(i0_1);
                Ip_1=fft(ip_1-ip_ss1)/length(ip_1);
                In_1=fft(in_1-in_ss1)/length(in_1);
                % System 2
                v0_2=out.V0pn2(td1:td2,1);
                vp_2=out.V0pn2(td1:td2,2);
                vn_2=out.V0pn2(td1:td2,3);
                i0_2=out.I0pn2(td1:td2,1);
                ip_2=out.I0pn2(td1:td2,2);
                in_2=out.I0pn2(td1:td2,3);
                V0_2=fft(v0_2-v0_ss2)/length(v0_2);
                Vp_2=fft(vp_2-vp_ss2)/length(vp_2);
                Vn_2=fft(vn_2-vn_ss2)/length(vn_2);
                I0_2=fft(i0_2-i0_ss2)/length(i0_2);
                Ip_2=fft(ip_2-ip_ss2)/length(ip_2);
                In_2=fft(in_2-in_ss2)/length(in_2);
                % System 1
                Y001=I0_1./V0_1;
                Yp01=Ip_1./V0_1;
                Yn01=In_1./V0_1;
                % System 1
                Y002=I0_2./V0_2;
                Yp02=Ip_2./V0_2;
                Yn02=In_2./V0_2;
                for n=1:length(Yn01)
                    Y_0pn1(:,:,n)=[Y001(n) Y0p1(n) Y0n1(n)
                                   Yp01(n) Ypp1(n) Ypn1(n)
                                   Yn01(n) Ynp1(n) Ynn1(n)];
                    Y_0pn2(:,:,n)=[Y002(n) Y0p2(n) Y0n2(n)
                                   Yp02(n) Ypp2(n) Ypn2(n)
                                   Yn02(n) Ynp2(n) Ynn2(n)];
                end
                % Frequency limits
                fvec=(1:samples_window)*fs;
                f_lim=find((fvec)>=fd0(end),1);
                Y_0pn1=Y_0pn1(:,:,1:f_lim);
                Y_0pn2=Y_0pn2(:,:,1:f_lim);
                Ypp1=Ypp1(1:f_lim);
                Ypn1=Ypn1(1:f_lim);
                Ynp1=Ynp1(1:f_lim);
                Ynn1=Ynn1(1:f_lim);
                Ypp2=Ypp2(1:f_lim);
                Ypn2=Ypn2(1:f_lim);
                Ynp2=Ynp2(1:f_lim);
                Ynn2=Ynn2(1:f_lim);
                fd0=fvec(1:f_lim);
            end
        else
            set_param(voltage_type, 'Commented', 'on');
            set_param(current_type, 'Commented', 'off');
            if signal_type==1
                set_param(multi_tone_I_0pn, 'Commented', 'on');
                set_param(single_tone_I_0pn, 'Commented', 'off');
                dist_value_0=0;
                dist_value_p=0;
                dist_value_n=0;
            else
                set_param(multi_tone_I_0pn, 'Commented', 'off');
                set_param(single_tone_I_0pn, 'Commented', 'on');
                dist_value_0=zeros(samples_window,2);
                dist_value_p=zeros(samples_window,2);
                dist_value_n=zeros(samples_window,2);
            end
            if ss_cal~=1
                [~, out] = evalc("sim(program)");
                td1=find((out.tout)>=t_w1,1); % t1 time window
                td2=find((out.tout)>=t_w2,1); % t2 time window
                % System 1
                v0_ss1=out.V0pn1(td1:td2,1);
                vp_ss1=out.V0pn1(td1:td2,2);
                vn_ss1=out.V0pn1(td1:td2,3);
                i0_ss1=out.I0pn1(td1:td2,1);
                ip_ss1=out.I0pn1(td1:td2,2);
                in_ss1=out.I0pn1(td1:td2,3);
                % System 2
                v0_ss2=out.V0pn2(td1:td2,1);
                vp_ss2=out.V0pn2(td1:td2,2);
                vn_ss2=out.V0pn2(td1:td2,3);
                i0_ss2=out.I0pn2(td1:td2,1);
                ip_ss2=out.I0pn2(td1:td2,2);
                in_ss2=out.I0pn2(td1:td2,3);
                dist_time=dist_time_f;
            end
            if signal_type==1
                for n=1:length(fd0)
                    fd=fd0(n);
                    % p-injection
                    dist_value_p=Vdist_value;
                    dist_value_n=0;
                    dist_value_0=0;
                    [~, out] = evalc("sim(program)");
                    % System 1
                    v0_1=out.V0pn1(td1:td2,1);
                    vp_1=out.V0pn1(td1:td2,2);
                    vn_1=out.V0pn1(td1:td2,3);
                    i0_1=out.I0pn1(td1:td2,1);
                    ip_1=out.I0pn1(td1:td2,2);
                    in_1=out.I0pn1(td1:td2,3);
                    V0_p_1=fft(v0_1-v0_ss1)/length(v0_1);
                    Vp_p_1=fft(vp_1-vp_ss1)/length(vp_1);
                    Vn_p_1=fft(vn_1-vn_ss1)/length(vn_1);
                    I0_p_1=fft(i0_1-i0_ss1)/length(i0_1);
                    Ip_p_1=fft(ip_1-ip_ss1)/length(ip_1);
                    In_p_1=fft(in_1-in_ss1)/length(in_1);
                    % System 2
                    v0_2=out.V0pn2(td1:td2,1);
                    vp_2=out.V0pn2(td1:td2,2);
                    vn_2=out.V0pn2(td1:td2,3);
                    i0_2=out.I0pn2(td1:td2,1);
                    ip_2=out.I0pn2(td1:td2,2);
                    in_2=out.I0pn2(td1:td2,3);
                    V0_p_2=fft(v0_2-v0_ss2)/length(v0_2);
                    Vp_p_2=fft(vp_2-vp_ss2)/length(vp_2);
                    Vn_p_2=fft(vn_2-vn_ss2)/length(vn_2);
                    I0_p_2=fft(i0_2-i0_ss2)/length(i0_2);
                    Ip_p_2=fft(ip_2-ip_ss2)/length(ip_2);
                    In_p_2=fft(in_2-in_ss2)/length(in_2);
                    % n-injection
                    dist_value_p=0;
                    dist_value_n=Vdist_value;
                    dist_value_0=0;
                    [~, out] = evalc("sim(program)");
                    % System 1
                    v0_1=out.V0pn1(td1:td2,1);
                    vp_1=out.V0pn1(td1:td2,2);
                    vn_1=out.V0pn1(td1:td2,3);
                    i0_1=out.I0pn1(td1:td2,1);
                    ip_1=out.I0pn1(td1:td2,2);
                    in_1=out.I0pn1(td1:td2,3);
                    V0_n_1=fft(v0_1-v0_ss1)/length(v0_1);
                    Vp_n_1=fft(vp_1-vp_ss1)/length(vp_1);
                    Vn_n_1=fft(vn_1-vn_ss1)/length(vn_1);
                    I0_n_1=fft(i0_1-i0_ss1)/length(i0_1);
                    Ip_n_1=fft(ip_1-ip_ss1)/length(ip_1);
                    In_n_1=fft(in_1-in_ss1)/length(in_1);
                    % System 2
                    v0_2=out.V0pn2(td1:td2,1);
                    vp_2=out.V0pn2(td1:td2,2);
                    vn_2=out.V0pn2(td1:td2,3);
                    i0_2=out.I0pn2(td1:td2,1);
                    ip_2=out.I0pn2(td1:td2,2);
                    in_2=out.I0pn2(td1:td2,3);
                    V0_n_2=fft(v0_2-v0_ss2)/length(v0_2);
                    Vp_n_2=fft(vp_2-vp_ss2)/length(vp_2);
                    Vn_n_2=fft(vn_2-vn_ss2)/length(vn_2);
                    I0_n_2=fft(i0_2-i0_ss2)/length(i0_2);
                    Ip_n_2=fft(ip_2-ip_ss2)/length(ip_2);
                    In_n_2=fft(in_2-in_ss2)/length(in_2);
                    % 0-injection
                    dist_value_p=0;
                    dist_value_n=0;
                    dist_value_0=Vdist_value;
                    [~, out] = evalc("sim(program)");
                    % System 1
                    v0_1=out.V0pn1(td1:td2,1);
                    vp_1=out.V0pn1(td1:td2,2);
                    vn_1=out.V0pn1(td1:td2,3);
                    i0_1=out.I0pn1(td1:td2,1);
                    ip_1=out.I0pn1(td1:td2,2);
                    in_1=out.I0pn1(td1:td2,3);
                    V0_0_1=fft(v0_1-v0_ss1)/length(v0_1);
                    Vp_0_1=fft(vp_1-vp_ss1)/length(vp_1);
                    Vn_0_1=fft(vn_1-vn_ss1)/length(vn_1);
                    I0_0_1=fft(i0_1-i0_ss1)/length(i0_1);
                    Ip_0_1=fft(ip_1-ip_ss1)/length(ip_1);
                    In_0_1=fft(in_1-in_ss1)/length(in_1);
                    % System 2
                    v0_2=out.V0pn2(td1:td2,1);
                    vp_2=out.V0pn2(td1:td2,2);
                    vn_2=out.V0pn2(td1:td2,3);
                    i0_2=out.I0pn2(td1:td2,1);
                    ip_2=out.I0pn2(td1:td2,2);
                    in_2=out.I0pn2(td1:td2,3);
                    V0_0_2=fft(v0_2-v0_ss2)/length(v0_2);
                    Vp_0_2=fft(vp_2-vp_ss2)/length(vp_2);
                    Vn_0_2=fft(vn_2-vn_ss2)/length(vn_2);
                    I0_0_2=fft(i0_2-i0_ss2)/length(i0_2);
                    Ip_0_2=fft(ip_2-ip_ss2)/length(ip_2);
                    In_0_2=fft(in_2-in_ss2)/length(in_2);
                    wd=round(fd/fs)+1;
                    % System 1
                    V0pn1=[V0_0_1(wd) V0_p_1(wd) V0_n_1(wd)
                           Vp_0_1(wd) Vp_p_1(wd) Vp_n_1(wd)
                           Vn_0_1(wd) Vn_p_1(wd) Vn_n_1(wd)];
                    I0pn1=[I0_0_1(wd) I0_p_1(wd) I0_n_1(wd)
                           Ip_0_1(wd) Ip_p_1(wd) Ip_n_1(wd)
                           In_0_1(wd) In_p_1(wd) In_n_1(wd)];
                    Z_0pn_1=V0pn1*inv(I0pn1);
                    Zpp1(:,n)=Z_0pn_1(2,2);
                    Zpn1(:,n)=Z_0pn_1(2,3);
                    Znp1(:,n)=Z_0pn_1(3,2);
                    Znn1(:,n)=Z_0pn_1(3,3);
                    Z_0pn1(:,:,n)=Z_0pn_1;
                    % System 2
                    V0pn2=[V0_0_2(wd) V0_p_2(wd) V0_n_2(wd)
                           Vp_0_2(wd) Vp_p_2(wd) Vp_n_2(wd)
                           Vn_0_2(wd) Vn_p_2(wd) Vn_n_2(wd)];
                    I0pn2=[I0_0_2(wd) I0_p_2(wd) I0_n_2(wd)
                           Ip_0_2(wd) Ip_p_2(wd) Ip_n_2(wd)
                           In_0_2(wd) In_p_2(wd) In_n_2(wd)];
                    Z_0pn_2=V0pn2*inv(I0pn2);
                    Zpp2(:,n)=Z_0pn_2(2,2);
                    Zpn2(:,n)=Z_0pn_2(2,3);
                    Znp2(:,n)=Z_0pn_2(3,2);
                    Znn2(:,n)=Z_0pn_2(3,3);
                    Z_0pn2(:,:,n)=Z_0pn_2;
                end
            else
                % p-injection
                dist_value_p=Vsignal_dist1;
                dist_value_n=[Vsignal_dist1(:,1),zeros(samples_window,1)];
                dist_value_0=[Vsignal_dist1(:,1),zeros(samples_window,1)];
                [~, out] = evalc("sim(program)");
                 % system 1
                v0_1=out.V0pn1(td1:td2,1);
                vp_1=out.V0pn1(td1:td2,2);
                vn_1=out.V0pn1(td1:td2,3);
                i0_1=out.I0pn1(td1:td2,1);
                ip_1=out.I0pn1(td1:td2,2);
                in_1=out.I0pn1(td1:td2,3);
                % FFT of the time-windowed signals
                V0_p_1=fft(v0_1-v0_ss1)/length(v0_1);
                Vp_p_1=fft(vp_1-vp_ss1)/length(vp_1);
                Vn_p_1=fft(vn_1-vn_ss1)/length(vn_1);
                I0_p_1=fft(i0_1-i0_ss1)/length(i0_1);
                Ip_p_1=fft(ip_1-ip_ss1)/length(ip_1);
                In_p_1=fft(in_1-in_ss1)/length(in_1);
                % System 2
                v0_2=out.V0pn2(td1:td2,1);
                vp_2=out.V0pn2(td1:td2,2);
                vn_2=out.V0pn2(td1:td2,3);
                i0_2=out.I0pn2(td1:td2,1);
                ip_2=out.I0pn2(td1:td2,2);
                in_2=out.I0pn2(td1:td2,3);
                V0_p_2=fft(v0_2-v0_ss2)/length(v0_2);
                Vp_p_2=fft(vp_2-vp_ss2)/length(vp_2);
                Vn_p_2=fft(vn_2-vn_ss2)/length(vn_2);
                I0_p_2=fft(i0_2-i0_ss2)/length(i0_2);
                Ip_p_2=fft(ip_2-ip_ss2)/length(ip_2);
                In_p_2=fft(in_2-in_ss2)/length(in_2);
                % n-injection
                dist_value_n=Vsignal_dist2;
                dist_value_p=[Vsignal_dist2(:,1),zeros(samples_window,1)];
                dist_value_0=[Vsignal_dist2(:,1),zeros(samples_window,1)];
                [~, out] = evalc("sim(program)");
                 % System 1
                v0_1=out.V0pn1(td1:td2,1);
                vp_1=out.V0pn1(td1:td2,2);
                vn_1=out.V0pn1(td1:td2,3);
                i0_1=out.I0pn1(td1:td2,1);
                ip_1=out.I0pn1(td1:td2,2);
                in_1=out.I0pn1(td1:td2,3);
                V0_n_1=fft(v0_1-v0_ss1)/length(v0_1);
                Vp_n_1=fft(vp_1-vp_ss1)/length(vp_1);
                Vn_n_1=fft(vn_1-vn_ss1)/length(vn_1);
                I0_n_1=fft(i0_1-i0_ss1)/length(i0_1);
                Ip_n_1=fft(ip_1-ip_ss1)/length(ip_1);
                In_n_1=fft(in_1-in_ss1)/length(in_1);
                % System 2
                v0_2=out.V0pn2(td1:td2,1);
                vp_2=out.V0pn2(td1:td2,2);
                vn_2=out.V0pn2(td1:td2,3);
                i0_2=out.I0pn2(td1:td2,1);
                ip_2=out.I0pn2(td1:td2,2);
                in_2=out.I0pn2(td1:td2,3);
                V0_n_2=fft(v0_2-v0_ss2)/length(v0_2);
                Vp_n_2=fft(vp_2-vp_ss2)/length(vp_2);
                Vn_n_2=fft(vn_2-vn_ss2)/length(vn_2);
                I0_n_2=fft(i0_2-i0_ss2)/length(i0_2);
                Ip_n_2=fft(ip_2-ip_ss2)/length(ip_2);
                In_n_2=fft(in_2-in_ss2)/length(in_2);
                % 0-injection
                dist_value_0=Vsignal_dist3;
                dist_value_p=[Vsignal_dist3(:,1),zeros(samples_window,1)];
                dist_value_n=[Vsignal_dist3(:,1),zeros(samples_window,1)];
                [~, out] = evalc("sim(program)");
                 % system 1
                v0_1=out.V0pn1(td1:td2,1);
                vp_1=out.V0pn1(td1:td2,2);
                vn_1=out.V0pn1(td1:td2,3);
                i0_1=out.I0pn1(td1:td2,1);
                ip_1=out.I0pn1(td1:td2,2);
                in_1=out.I0pn1(td1:td2,3);
                V0_0_1=fft(v0_1-v0_ss1)/length(v0_1);
                Vp_0_1=fft(vp_1-vp_ss1)/length(vp_1);
                Vn_0_1=fft(vn_1-vn_ss1)/length(vn_1);
                I0_0_1=fft(i0_1-i0_ss1)/length(i0_1);
                Ip_0_1=fft(ip_1-ip_ss1)/length(ip_1);
                In_0_1=fft(in_1-in_ss1)/length(in_1);
                % System 2
                v0_2=out.V0pn2(td1:td2,1);
                vp_2=out.V0pn2(td1:td2,2);
                vn_2=out.V0pn2(td1:td2,3);
                i0_2=out.I0pn2(td1:td2,1);
                ip_2=out.I0pn2(td1:td2,2);
                in_2=out.I0pn2(td1:td2,3);
                V0_0_2=fft(v0_2-v0_ss2)/length(v0_2);
                Vp_0_2=fft(vp_2-vp_ss2)/length(vp_2);
                Vn_0_2=fft(vn_2-vn_ss2)/length(vn_2);
                I0_0_2=fft(i0_2-i0_ss2)/length(i0_2);
                Ip_0_2=fft(ip_2-ip_ss2)/length(ip_2);
                In_0_2=fft(in_2-in_ss2)/length(in_2);
            for n=1:length(In_0_1)
                % System 1
                    V0pn1=[V0_0_1(n) V0_p_1(n) V0_n_1(n)
                           Vp_0_1(n) Vp_p_1(n) Vp_n_1(n)
                           Vn_0_1(n) Vn_p_1(n) Vn_n_1(n)];
                    I0pn1=[I0_0_1(n) I0_p_1(n) I0_n_1(n)
                           Ip_0_1(n) Ip_p_1(n) Ip_n_1(n)
                           In_0_1(n) In_p_1(n) In_n_1(n)];
                    Z_0pn_1=V0pn1*inv(I0pn1);
                    Z_0pn1(:,:,n)=Z_0pn_1;
                    Zpp1(:,n)=Z_0pn_1(2,2);
                    Zpn1(:,n)=Z_0pn_1(2,3);
                    Znp1(:,n)=Z_0pn_1(3,2);
                    Znn1(:,n)=Z_0pn_1(3,3);
                % System 2
                    V0pn2=[V0_0_2(n) V0_p_2(n) V0_n_2(n)
                           Vp_0_2(n) Vp_p_2(n) Vp_n_2(n)
                           Vn_0_2(n) Vn_p_2(n) Vn_n_2(n)];
                    I0pn2=[I0_0_2(n) I0_p_2(n) I0_n_2(n)
                           Ip_0_2(n) Ip_p_2(n) Ip_n_2(n)
                           In_0_2(n) In_p_2(n) In_n_2(n)];
                    Z_0pn_2=V0pn2*inv(I0pn2);
                    Z_0pn2(:,:,n)=Z_0pn_2;
                    Zpp2(:,n)=Z_0pn_2(2,2);
                    Zpn2(:,n)=Z_0pn_2(2,3);
                    Znp2(:,n)=Z_0pn_2(3,2);
                    Znn2(:,n)=Z_0pn_2(3,3);
            end
            % Frequency limits
            fvec=(1:samples_window)*fs;
            f_lim=find((fvec)>=fd0(end),1);
            Z_0pn1=Z_0pn1(:,:,1:f_lim);
            Z_0pn2=Z_0pn2(:,:,1:f_lim);
            Zpp1=Zpp1(1:f_lim);
            Zpn1=Zpn1(1:f_lim);
            Znp1=Znp1(1:f_lim);
            Znn1=Znn1(1:f_lim);
            Zpp2=Zpp2(1:f_lim);
            Zpn2=Zpn2(1:f_lim);
            Znp2=Znp2(1:f_lim);
            Znn2=Znn2(1:f_lim);
            fd0=fvec(1:f_lim);
            end
        end
        switch linear
            case 1
                if scanner_type==1
                    pn0Plot(fd0, jw1, Ym_RLC1, Ya_RLC1, Ypp1, Ypn1, Ynp1, Ynn1);
                    pn0Plot(fd0, jw1, Ym_RLC2, Ya_RLC2, Ypp2, Ypn2, Ynp2, Ynn2);
                    fprintf('SIaD Tool finished.\n');
                    fprintf('Results stored in Ypp1, Ypn1, Ynp1 and Ynn1.\n');
                    fprintf('Results stored in Ypp2, Ypn2, Ynp2 and Ynn2.\n');
                else
                    pn0Plot(fd0, jw1, Zm_RLC1, Za_RLC1, Zpp1, Zpn1, Znp1, Znn1);
                    pn0Plot(fd0, jw1, Zm_RLC2, Za_RLC2, Zpp2, Zpn2, Znp2, Znn2);
                    fprintf('SIaD Tool finished.\n');
                    fprintf('Results stored in Zpp1, Zpn1, Znp1 and Znn1.\n');
                    fprintf('Results stored in Zpp2, Zpn2, Znp2 and Znn2.\n');
                end
            case 0
                if scanner_type==1
                    pn0Plot2(fd0, Ypp1, Ypn1, Ynp1, Ynn1);
                    pn0Plot2(fd0, Ypp2, Ypn2, Ynp2, Ynn2);
                    fprintf('SIaD Tool finished.\n');
                    fprintf('Results stored in Ypp1, Ypn1, Ynp1 and Ynn1.\n');
                    fprintf('Results stored in Ypp2, Ypn2, Ynp2 and Ynn2.\n');
                else
                    pn0Plot2(fd0, Zpp1, Zpn1, Znp1, Znn1);
                    pn0Plot2(fd0, Zpp2, Zpn2, Znp2, Znn2);
                    fprintf('SIaD Tool finished.\n');
                    fprintf('Results stored in Zpp1, Zpn1, Znp1 and Znn1.\n');
                    fprintf('Results stored in Zpp2, Zpn2, Znp2 and Znn2.\n');
                end
        end
end
toc
disp('---')

function out = choose(index, varargin)
    if index >= 1 && index <= numel(varargin)
        out = varargin{index};
    else
        out = 'desconocido';
    end
end


function y = multisine( frequencyLimits, fs, Ns, varargin )
%%% Multisine: a function to generate a multi-sine signal with various
%%% properties, most notably phase distribution to minimise crest-factor.

% Author: Ben Holmes, adapted from a pseudonoise signal by Maarten van
% Walstijn.
% Date: 2019/01/09
% License: All rights reserved. (until the code is cleaned up)

% Inputs
% Required:
%   - frequencyLimits: the boundaries between which all sine components
%   will fall. Each sine will fall at multiples of f0=fs/Ns, which the
%   frequency limits will be rounded to.

%   - fs: sampling frequency.

%   - Ns: signal length in samples. It is recommended for multiple periods
%   of the signal to use repmat instead of a high value of Ns as the
%   Schroeder phases are slow to calculate, and increasing Ns will increase
%   the density of sine wave components.

% Other parameters:
%   - MagnitudeResponse: the amplitude of the sine wave components. Zero
%   values should be used for all magnitudes outside of the frequency
%   limits. Default is a flat response.

%   - PhaseResponse: Either a string to select "Schroeder",
%   "NormallyDistributed", or "ZeroValued" for the different phase options,
%   or a vector of the desired phase values. Default is "Schroeder".

%   - StartAtZero: a boolean flag to indicate whether to wrap the signal
%   such that it starts at the lowest gradient zero crossing. Default true.

%   - Normalise: a boolean flag that indicates whether to normalise the
%   signal to a peak value of 1. Default true.

%   - TimeDomain: a boolean flag that indicates whether to generate the
%   signal in the time domain or frequency domain. Default false. Used for
%   debugging the IFFT.

%   - InitialPhase: a scalar element that sets the first value of the
%   Schroeder phases, ignored for other settings. Default 0.

% Output
%   y: the multi-sine output signal.

%% Input parsing

p = inputParser;

is2ElementPositiveVector =@(x) isnumeric(x) && any(size(x) == 1)...
                                            && any(size(x) == 2)...
                                            && ~any(x < 0);
                                        
addRequired(p, 'frequencyLimits', is2ElementPositiveVector);

isPositiveScalarInteger =@(x) isnumeric(x) && isscalar(x) && (round(x) == x) && x > 0;

addRequired(p, 'fs', isPositiveScalarInteger);
addRequired(p, 'Ns', isPositiveScalarInteger);

addParameter(p, 'MagnitudeResponse', false, @(x) isnumeric(x) && any(size(x) == 1) && ~any(x < 0) && sum(x)>0)

addParameter(p, 'PhaseResponse', 'Schroeder', @(x) ischar(x) || isnumeric(x))

addParameter(p, 'StartAtZero', true, @(x) islogical(x) && isscalar(x));

addParameter(p, 'Normalise', true, @(x) islogical(x) && isscalar(x));

addParameter(p, 'TimeDomain', false, @(x) islogical(x) && isscalar(x));

addParameter(p, 'InitialPhase', 0, @(x) isnumeric(x) && isscalar(x));
         
parse(p, frequencyLimits, fs, Ns, varargin{:});

%% Find frequency indices

f0 = fs/Ns;

% DC is in bin 1 so everything must start at 2
fInds = 1 + round(frequencyLimits./f0);

if any(fInds > Ns/2)
    error('Frequency limits must be beneath Nyquist.');
end

indexVector = fInds(1):fInds(2);

NN = length(indexVector);

%% Find amplitude response

if ~any(p.Results.MagnitudeResponse)
    mag = zeros(1, Ns);
    mag(indexVector) = 1./length(indexVector);
else
    if length(p.Results.MagnitudeResponse) ~= Ns
        error('Magnitude response must be the same length as the desired signal.');
    end
    
    mag = p.Results.MagnitudeResponse.^2;
    
    % Find indices at which no components should be present.
    fullIndices = (1:Ns);
    zeroValueIndices = fullIndices;
    zeroValueIndices(indexVector) = [];
    
    if any(mag(zeroValueIndices))
        warning('Non-zero magnitude values present outside of frequency limits.');
        mag(zeroValueIndices) = zeros(size(zeroValueIndices));
    end
    
    
    if sum(mag(indexVector)) ~= 1
        mag(indexVector) = mag(indexVector)./sum(mag(indexVector));
    end
end

%% Find phase response

if ischar(p.Results.PhaseResponse)
    switch p.Results.PhaseResponse
        case 'Schroeder'
            phase = schroederPhases(NN, Ns, indexVector, mag, p.Results.InitialPhase);
        case 'ZeroPhase'
            phase = zeros(1, Ns);
        case 'NormalDistribution'
            phase = randn(1, Ns);
        otherwise
            error('Phase Response string must be Schroeder, ZeroPhase, or NormalDistribution.');
    end
else
    phase = p.Results.PhaseResponse;
    if ~any(size(phase) == 1) || ~any(size(phase) == Ns)
        error('Phase response must be Ns x 1.');
    end
end


%% Generate multisine signal

% Switch between time and frequency domain generation
if p.Results.TimeDomain
    y = zeros(1, Ns);
    t = (0:Ns-1)./fs;
    for nn=1:NN
        mm = indexVector(nn);
        y = y + sqrt(mag(mm)/2)*cos(2*pi*f0*(mm-1)*t + phase(mm));
    end
else
    % Frequency domain representation
    Y = sqrt(mag/2).*exp(sqrt(-1).*phase);

    % IFFT to time domain
    y = ifft(forceFFTSymmetry(Y))*(Ns/2);
end

%% Normalise peak abs value to 1

if p.Results.Normalise
    y = y./max(abs(y));
end

%% Find zero crossing closest to zero 

% Heuristic method of finding minimum gradient zero crossing
if p.Results.StartAtZero
    ySign = y>0;

    zeroInds = find((ySign(2:end) ~= ySign(1:end-1)));

    % Find the index with the smallest gradient around the zero crossing.
    zeroGrad = zeros(1,length(zeroInds));
    for nn=1:length(zeroInds)
        zeroGrad(nn) = abs(y(zeroInds(nn)) - y(zeroInds(nn)+1));
    end
    [~, minInd] = min(zeroGrad);

    yWrapped = [y(zeroInds(minInd):end) y(1:zeroInds(minInd)-1)];

    y = yWrapped;
end

end

function phase = schroederPhases(nComponents, Ns, indexVector, magnitude, p1)
% Generate phases as defined in "Synthesis of Low-Peak-Factor Signals and
% Binary Sequences With Low Autocorrelation" by M. R. Schroeder

% Preallocate vector
phase = zeros(1, Ns);

% Bin 1 is DC, so bin 2 is the phase of the first component
phase(2) = p1;

% Iterate over phase values using Schroeder's algorithm
for nn=2:nComponents
    ll=1:(nn-1);
    phase(indexVector(nn)) = phase(2) -2*pi*sum((nn-ll).*magnitude(indexVector(ll)));
end

end

function Y = forceFFTSymmetry(X)
% forceFFTSymmetry  A function to force conjugate symmetry on an FFT such that when an
% IFFT is performed the result is a real signal.

% The function has been written to replace MATLAB's ifft(X,'symmetric'), as this function
% is not compatible with MATLAB Coder.
  
Y = X;
XStartFlipped = fliplr(X(2:floor(end/2)));
Y(ceil(end/2)+2:end) = real(XStartFlipped) - sqrt(complex(-1))*imag(XStartFlipped);

end

function ABCPlot(fd0, Yabc, Yphases, jw1)
    % ABCPlot: Generates a 6x3 frequency response plot.
    %
    % Input parameters:
    % - fd0: Vector of scanned frequencies (Hz)
    % - Yabc: 3x3xn matrix with scanned responses
    % - Yphases: 3x3xm matrix with theoretical responses
    % - jw1: Vector of theoretical frequencies in the complex domain

    % Define x-axis limits
    low_axis = fd0(1);
    up_axis = fd0(end);

    % Global plot settings
    set(0, 'defaultAxesFontSize', 14);
    set(0, 'DefaultLineLineWidth', 1.5);

    % Create figure
    figure;

    % Iterate over row and column combinations (3x3)
    for i = 1:3
        for j = 1:3
            % Extract scanned and theoretical responses for current position
            Ya_scan = squeeze(Yabc(i, j, :));       % Scanned response (vector)
            Yphase_theo = squeeze(Yphases(i, j, :)); % Theoretical response (vector)

            % Subplot indices
            mag_idx = 2*(i-1) * 3 + j;   % Magnitude index
            phase_idx = mag_idx + 3;    % Phase index

            % Subplot for magnitude
            subplot(6, 3, mag_idx);
            semilogx(imag(jw1)/(2*pi), 20*log10(abs(Yphase_theo)), 'k'); % Theoretical response
            hold on;
            semilogx(fd0, 20*log10(abs(Ya_scan)), 'rx'); % Measured response
%             title(['Y_{', char(64+i), char(64+j), '}(s) Magnitude']);
            ylabel('Magnitude (dB)');
            xlim([low_axis up_axis]);
            grid on; grid minor;

            % Subplot for phase
            subplot(6, 3, phase_idx);
            semilogx(imag(jw1)/(2*pi), (180/pi)*angle(Yphase_theo), 'k'); % Theoretical response
            hold on;
            semilogx(fd0, (180/pi)*angle(Ya_scan), 'rx'); % Measured response
%             title(['Y_{', char(64+i), char(64+j), '}(s) Phase']);
            ylabel('Phase (deg)');
            xlabel('Frequency (Hz)');
            xlim([low_axis up_axis]);
            grid on; grid minor;
        end
    end
end

function ABCPlot2(fd0, Yabc)
    % ABCPlot2: Generates a 6x3 plot of scanned frequency responses.
    %
    % Input parameters:
    % - fd0: Vector of scanned frequencies (Hz)
    % - Yabc: 3x3xn matrix with scanned responses

    % Define x-axis limits
    low_axis = fd0(1);
    up_axis = fd0(end);

    % Global plot settings
    set(0, 'defaultAxesFontSize', 14);
    set(0, 'DefaultLineLineWidth', 1.5);

    % Create figure
    figure;

    % Iterate over row and column combinations (3x3)
    for i = 1:3
        for j = 1:3
            % Extract scanned response for current position
            Ya_scan = squeeze(Yabc(i, j, :)); % Scanned response (vector)
            
            % Ensure Ya_scan is a column vector
            Ya_scan = Ya_scan(:);

            % Subplot indices
            mag_idx = 2*(i-1) * 3 + j;   % Magnitude index
            phase_idx = mag_idx + 3;    % Phase index

            % Subplot for magnitude
            subplot(6, 3, mag_idx);
            semilogx(fd0, 20*log10(abs(Ya_scan)), 'r-'); % Measured response
            title(['Y_{', char(64+i), char(64+j), '}(s) Magnitude']);
            ylabel('Magnitude (dB)');
            xlim([low_axis up_axis]);
            grid on; grid minor;

            % Subplot for phase
            subplot(6, 3, phase_idx);
            semilogx(fd0, (180/pi)*angle(Ya_scan), 'r-'); % Measured response
            title(['Y_{', char(64+i), char(64+j), '}(s) Phase']);
            ylabel('Phase (deg)');
            xlabel('Frequency (Hz)');
            xlim([low_axis up_axis]);
            grid on; grid minor;
        end
    end

    % Overall title for all subplots
    sgtitle('Frequency Response Plots (Scanned Data)');
end

function qd0Plot(fd0, jw1, Ym_Th, Ya_Th, Yqq, Yqd, Ydq, Ydd)
    % Limits of x axis
    low_axis = fd0(1);
    up_axis = fd0(end);

    % Global configurations
    set(0, 'defaultAxesFontSize', 14);
    set(0, 'DefaultLineLineWidth', 1.5);

    % Create figure
    figure;

    % Subplot 1: Magnitude of Yqq
    subplot(4, 2, 1);
    semilogx(imag(jw1)/(2*pi), 20*log10(squeeze(Ym_Th(1, 1, :))), 'k');
    hold on;
    semilogx(fd0, 20*log10(abs(Yqq)), 'rx');
    title('Yqq(s)');
    ylabel('Magnitude (dB)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 2: Phase of Yqq
    subplot(4, 2, 3);
    semilogx(imag(jw1)/(2*pi), squeeze(Ya_Th(1, 1, :)), 'k');
    hold on;
    semilogx(fd0, (180/pi) * angle(Yqq), 'rx');
    ylabel('Phase (deg)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 3: Magnitude de Yqd
    subplot(4, 2, 2);
    semilogx(imag(jw1)/(2*pi), 20*log10(squeeze(Ym_Th(1, 2, :))), 'k');
    hold on;
    semilogx(fd0, 20*log10(abs(Yqd)), 'rx');
    legend({'Linear: state space model', 'dq0: Frequency scan'}, 'Location', 'southwest', 'Orientation', 'vertical');
    title('Yqd(s)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 4: Phase de Yqd
    subplot(4, 2, 4);
    semilogx(imag(jw1)/(2*pi), squeeze(Ya_Th(1, 2, :)), 'k');
    hold on;
    semilogx(fd0, (180/pi) * angle(Yqd), 'rx');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 5: Magnitude de Ydq
    subplot(4, 2, 5);
    semilogx(imag(jw1)/(2*pi), 20*log10(squeeze(Ym_Th(2, 1, :))), 'k');
    hold on;
    semilogx(fd0, 20*log10(abs(Ydq)), 'rx');
    title('Ydq(s)');
    ylabel('Magnitude (dB)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 6: Phase de Ydq
    subplot(4, 2, 7);
    semilogx(imag(jw1)/(2*pi), squeeze(Ya_Th(2, 1, :)), 'k');
    hold on;
    semilogx(fd0, (180/pi) * angle(Ydq), 'rx');
    ylabel('Phase (deg)');
    xlabel('Frequency (Hz)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 7: Magnitude de Ydd
    subplot(4, 2, 6);
    semilogx(imag(jw1)/(2*pi), 20*log10(squeeze(Ym_Th(2, 2, :))), 'k');
    hold on;
    semilogx(fd0, 20*log10(abs(Ydd)), 'rx');
    title('Ydd(s)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 8: Phase de Ydd
    subplot(4, 2, 8);
    semilogx(imag(jw1)/(2*pi), squeeze(Ya_Th(2, 2, :)), 'k');
    hold on;
    semilogx(fd0, (180/pi) * angle(Ydd), 'rx');
    xlabel('Frequency (Hz)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Title
    sgtitle('Frequency Response Plots');
end

function qd0Plot2(fd0, Yqq, Yqd, Ydq, Ydd)
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
    semilogx(fd0, 20*log10(abs(Yqq)), 'r-'); % Respuesta medida
    title('Yqq(s)');
    ylabel('Magnitude (dB)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 2: Fase de Yqq
    subplot(4, 2, 3);
    semilogx(fd0, (180/pi) * angle(Yqq), 'r-'); % Respuesta medida
    ylabel('Phase (deg)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 3: Magnitud de Yqd
    subplot(4, 2, 2);
    semilogx(fd0, 20*log10(abs(Yqd)), 'r-'); % Respuesta medida
    legend({'qd frequency scan'}, 'Location', 'southwest', 'Orientation', 'vertical');
    title('Yqd(s)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 4: Fase de Yqd
    subplot(4, 2, 4);
    semilogx(fd0, (180/pi) * angle(Yqd), 'r-'); % Respuesta medida
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 5: Magnitud de Ydq
    subplot(4, 2, 5);
    semilogx(fd0, 20*log10(abs(Ydq)), 'r-'); % Respuesta medida
    title('Ydq(s)');
    ylabel('Magnitude (dB)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 6: Fase de Ydq
    subplot(4, 2, 7);
    semilogx(fd0, (180/pi) * angle(Ydq), 'r-'); % Respuesta medida
    ylabel('Phase (deg)');
    xlabel('Frequency (Hz)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 7: Magnitud de Ydd
    subplot(4, 2, 6);
    semilogx(fd0, 20*log10(abs(Ydd)), 'r-'); % Respuesta medida
    title('Ydd(s)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 8: Fase de Ydd
    subplot(4, 2, 8);
    semilogx(fd0, (180/pi) * angle(Ydd), 'r-'); % Respuesta medida
    xlabel('Frequency (Hz)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Título general
    sgtitle('Frequency Response Plots');
end

function pn0Plot(fd0, jw1, Ym_Th, Ya_Th, Ypp, Ypn, Ynp, Ynn)
    % Definir límites del eje x
    low_axis = fd0(1);
    up_axis = fd0(end);

    % Configuraciones globales para las gráficas
    set(0, 'defaultAxesFontSize', 14);
    set(0, 'DefaultLineLineWidth', 1.5);

    % Crear la figura
    figure;

    % Subplot 1: Magnitud de Ypp
    subplot(4, 2, 1);
    semilogx(imag(jw1)/(2*pi), 20*log10(squeeze(Ym_Th(1, 1, :))), 'k');
    hold on;
    semilogx(fd0, 20*log10(abs(Ypp)), 'rx');
    title('Ypp(s)');
    ylabel('Magnitude (dB)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 2: Fase de Ypp
    subplot(4, 2, 3);
    semilogx(imag(jw1)/(2*pi), squeeze(Ya_Th(1, 1, :)), 'k');
    hold on;
    semilogx(fd0, (180/pi) * angle(Ypp), 'rx');
    ylabel('Phase (deg)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 3: Magnitud de Ypn
    subplot(4, 2, 2);
    semilogx(imag(jw1)/(2*pi), 20*log10(squeeze(Ym_Th(1, 2, :))), 'k');
    hold on;
    semilogx(fd0, 20*log10(abs(Ypn)), 'rx');
    legend({'Linear: state space model', 'pn0: Frequency scan'}, 'Location', 'southwest', 'Orientation', 'vertical');
    title('Ypn(s)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 4: Fase de Ypn
    subplot(4, 2, 4);
    semilogx(imag(jw1)/(2*pi), squeeze(Ya_Th(1, 2, :)), 'k');
    hold on;
    semilogx(fd0, (180/pi) * angle(Ypn), 'rx');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 5: Magnitud de Ynp
    subplot(4, 2, 5);
    semilogx(imag(jw1)/(2*pi), 20*log10(squeeze(Ym_Th(2, 1, :))), 'k');
    hold on;
    semilogx(fd0, 20*log10(abs(Ynp)), 'rx');
    title('Ynp(s)');
    ylabel('Magnitude (dB)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 6: Fase de Ynp
    subplot(4, 2, 7);
    semilogx(imag(jw1)/(2*pi), squeeze(Ya_Th(2, 1, :)), 'k');
    hold on;
    semilogx(fd0, (180/pi) * angle(Ynp), 'rx');
    ylabel('Phase (deg)');
    xlabel('Frequency (Hz)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 7: Magnitud de Ynn
    subplot(4, 2, 6);
    semilogx(imag(jw1)/(2*pi), 20*log10(squeeze(Ym_Th(2, 2, :))), 'k');
    hold on;
    semilogx(fd0, 20*log10(abs(Ynn)), 'rx');
    title('Ynn(s)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 8: Fase de Ynn
    subplot(4, 2, 8);
    semilogx(imag(jw1)/(2*pi), squeeze(Ya_Th(2, 2, :)), 'k');
    hold on;
    semilogx(fd0, (180/pi) * angle(Ynn), 'rx');
    xlabel('Frequency (Hz)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Título general
    sgtitle('Frequency Response Plots');
end

function pn0Plot2(fd0, Ypp, Ypn, Ynp, Ynn)
    % Definir límites del eje x
    low_axis = fd0(1);
    up_axis = fd0(end);

    % Configuraciones globales para las gráficas
    set(0, 'defaultAxesFontSize', 14);
    set(0, 'DefaultLineLineWidth', 1.5);

    % Crear la figura
    figure;

    % Subplot 1: Magnitud de Ypp
    subplot(4, 2, 1);
    semilogx(fd0, 20*log10(abs(Ypp)), 'r-'); % Respuesta medida
    title('Ypp(s)');
    ylabel('Magnitude (dB)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 2: Fase de Ypp
    subplot(4, 2, 3);
    semilogx(fd0, (180/pi) * angle(Ypp), 'r-'); % Respuesta medida
    ylabel('Phase (deg)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 3: Magnitud de Ypn
    subplot(4, 2, 2);
    semilogx(fd0, 20*log10(abs(Ypn)), 'r-'); % Respuesta medida
    legend({'pn0: Frequency scan'}, 'Location', 'southwest', 'Orientation', 'vertical');
    title('Ypn(s)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 4: Fase de Ypn
    subplot(4, 2, 4);
    semilogx(fd0, (180/pi) * angle(Ypn), 'r-'); % Respuesta medida
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 5: Magnitud de Ynp
    subplot(4, 2, 5);
    semilogx(fd0, 20*log10(abs(Ynp)), 'r-'); % Respuesta medida
    title('Ynp(s)');
    ylabel('Magnitude (dB)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 6: Fase de Ynp
    subplot(4, 2, 7);
    semilogx(fd0, (180/pi) * angle(Ynp), 'r-'); % Respuesta medida
    ylabel('Phase (deg)');
    xlabel('Frequency (Hz)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 7: Magnitud de Ynn
    subplot(4, 2, 6);
    semilogx(fd0, 20*log10(abs(Ynn)), 'r-'); % Respuesta medida
    title('Ynn(s)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Subplot 8: Fase de Ynn
    subplot(4, 2, 8);
    semilogx(fd0, (180/pi) * angle(Ynn), 'r-'); % Respuesta medida
    xlabel('Frequency (Hz)');
    xlim([low_axis up_axis]);
    grid on; grid minor;

    % Título general
    sgtitle('Frequency Response Plots');
end
