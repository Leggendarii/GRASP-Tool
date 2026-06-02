% 1. Definizione simbolica (aggiunto theta)
syms vd_Meas vq_Meas id_Meas iq_Meas id_L iq_L theta
syms xp_vd xp_vq xp_id xp_iq xp_idL xp_iqL 

% Vettori di stato e ingressi (theta è l'ultimo ingresso)
x = [xp_vd; xp_vq; xp_id; xp_iq; xp_idL; xp_iqL];
u = [vd_Meas; vq_Meas; id_Meas; iq_Meas; id_L; iq_L; theta]; 


THETA = theta + 2*pi*50*Ts;
% 2. Matrice di Rotazione (Grid Frame -> Conv Frame)
T = [cos(THETA)  sin(THETA); 
    -sin(THETA) cos(THETA)];

% Rotazione di tutte le coppie di misura in ingresso
v_meas_rot = T * [vd_Meas; vq_Meas];
i_meas_rot = T * [id_Meas; iq_Meas];
i_L_rot    = T * [id_L; iq_L];

% Vettore degli ingressi ruotati (nel Converter Frame)
u_rot = [v_meas_rot; i_meas_rot; i_L_rot];

% 3. Equazioni Differenziali (Padé 1° Ordine applicato ai segnali ruotati)
f = -(2/Ts) * x + (4/Ts) * u_rot;
A = jacobian(f, x);
B = jacobian(f, u); % MATLAB deriverà automaticamente anche rispetto a theta!

% 4. Uscita Grezza del Ritardo 
h = x - u_rot;
C = jacobian(h, x);
D = jacobian(h, u);

% 5. Punti di Equilibrio
% Ingressi all'equilibrio (Misure in Grid Frame + Angolo)
u_eq = [vdCapac1; vqCapac1; idOut1; iqOut1; idInduct1; iqInduct1; Theta0];

% Per calcolare x_eq, dobbiamo prima ruotare gli ingressi di equilibrio con Theta0
T_eq = [cos(Theta0)  sin(Theta0); 
       -sin(Theta0) cos(Theta0)];
   
u_rot_eq = [T_eq * [vdCapac1; vqCapac1]; 
            T_eq * [idOut1; iqOut1]; 
            T_eq * [idInduct1; iqInduct1]];

% All'equilibrio (f=0), gli stati Padé valgono il doppio dell'ingresso ruotato
x_eq = 2 * u_rot_eq; 

% Visualize
disp('Matrice A:'), disp(A)
disp('Matrice B:'), disp(B)
disp('Matrice C:'), disp(C)
disp('Matrice D:'), disp(D)

% Jacobian substitution
A_lin_delay = double(subs(A, [x; u], [x_eq; u_eq]));
B_lin_delay = double(subs(B, [x; u], [x_eq; u_eq]));
C_lin_delay = double(subs(C, [x; u], [x_eq; u_eq]));
D_lin_delay = double(subs(D, [x; u], [x_eq; u_eq]));

% Build state space
ss_delay = ss(A_lin_delay, B_lin_delay, C_lin_delay, D_lin_delay);

% 
% syms vd_Meas vq_Meas id_Meas iq_Meas theta s id_L iq_L
% 
% % Input output and params
% x = zeros(1);
% u = [vd_Meas; vq_Meas; id_Meas; iq_Meas; id_L; iq_L; theta];
% 
% % Differential equations
% f = 0;
% 
% % Calculate Jacobian output wrt state (A) and input (B)
% A = 0;
% B = zeros(1,size(u,1));
% % Output function
% 
% alpha= (theta);
% T_delay = [cos(alpha) sin(alpha); -sin(alpha) cos(alpha)];
% beta = 2*pi*50*Ts;  %%%%%%%%%%%%%%%%%%%%%%
% T_delay2 = [cos(beta) sin(beta); -sin(beta) cos(beta)];
% 
% v_m_dq_delayed =  T_delay2* T_delay * [vd_Meas; vq_Meas];
% v_m_d_delayed = v_m_dq_delayed(1); % voltage seen by the PLL, not real, but delayed
% v_m_q_delayed = v_m_dq_delayed(2); % voltage seen by the PLL, not real, but delayed
% 
% i_m_dq_delayed =  T_delay2 * T_delay *[id_Meas; iq_Meas];
% i_m_d_delayed = i_m_dq_delayed(1); % voltage seen by the PLL, not real, but delayed
% i_m_q_delayed = i_m_dq_delayed(2); % voltage seen by the PLL, not real, but delayed
% 
% i_L_dq_delayed =  T_delay2 * T_delay *[id_L; iq_L];
% i_L_d_delayed = i_L_dq_delayed(1); % voltage seen by the PLL, not real, but delayed
% i_L_q_delayed = i_L_dq_delayed(2); % voltage seen by the PLL, not real, but delayed
% 
% h = [v_m_d_delayed; v_m_q_delayed; i_m_d_delayed; i_m_q_delayed; i_L_d_delayed; i_L_q_delayed]; % vd_grid_c vq_grid_c id_c iq_c vd_inv_s vq_inv_s
% 
% % Calculate Jacobian output wrt state (C) and input (D)
% C = zeros(6,1);
% D = jacobian(h, u);
% 
% % Visualize
% disp('Matrice A:'), disp(A)
% disp('Matrice B:'), disp(B)
% disp('Matrice C:'), disp(C)
% disp('Matrice D:'), disp(D)
% 
% % Eq values and params
% u_eq = [vdCapac1; vqCapac1; idOut1; iqOut1; idInduct1; iqInduct1; Theta0]; % vd_grid vq_grid id iq
% 
% % Jacobian substitution
% A_lin_delay = double(subs(A, u, u_eq));
% B_lin_delay = double(subs(B, u, u_eq));
% C_lin_delay = double(subs(C, u, u_eq));
% D_lin_delay = double(subs(D, u, u_eq));
% 
% % Build space state
% ss_delay = ss(A_lin_delay, B_lin_delay, C_lin_delay, D_lin_delay);