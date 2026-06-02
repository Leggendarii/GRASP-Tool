%% Closed-loop Matrix Computation for SVD and Eigenvalue Analysis
% This script loads VSC (Voltage Source Converter) and network measurement data,
% computes closed-loop transfer matrices, and analyzes their frequency-domain
% characteristics using:
%   - Bode plots (magnitude/phase response of admittances)
%   - MIMO Nyquist diagrams (stability assessment)
%   - Singular Value Decomposition (SVD) vs. frequency
%
% Purpose:
%   Support small-signal stability studies by visualizing how the converter
%   interacts with the grid across different sampling times.
%
% Data requirement:
%   Measurement data in CSV format containing frequency vectors and
%   admittance matrix elements (dq-frame).

clear all
close all
clc

%% Load required libraries and datasets
addpath(genpath('lib'));   % Analysis, computation, and plotting functions
addpath(genpath('data'));  % Measurement data files

%% Read measurement data from CSV files
% Each CSV file contains:
%   f         : Frequency vector [Hz]
%   Yqq_g ... : Grid admittance components in dq frame
%   Yqq_c ... : Controller admittance components in dq frame
%
%   Subscripts:
%     _g = grid
%     _c = controller
%   Matrix elements:
%     Yqq, Yqd, Ydq, Ydd (dq-frame representation)
%

T1 = readtable("black.csv");
T2 = readtable("grey.csv");

%% Compute closed-loop matrices and admittances
% The 'compute' function outputs:
%   E, L          : Closed-loop transfer matrices (for Nyquist, SVD, eigenvalue analysis)
%   Y_c_dq, Y_g_dq: Controller and grid admittances in dq frame
%   Y_c_pn, Y_g_pn: Controller and grid admittances in positive/negative-sequence frame
%
% Note:
%   In Luis' dataset, the dq and qd elements are inverted compared to
%   standard ordering — this is corrected internally in 'compute'.
[E,  L,  Y_c_dq,  Y_g_dq,  Y_c_pn,  Y_g_pn] = compute( ...
    T1.f', (T1.Yqq_g'), (T1.Yqd_g'), (T1.Ydq_g'), (T1.Ydd_g'), ...
    T1.f', (T1.Yqq_c'), (T1.Yqd_c'), (T1.Ydq_c'), (T1.Ydd_c'));

[E1, L1, Y_c_dq1, Y_g_dq1, Y_c_pn1, Y_g_pn1] = compute( ...
    T2.f', T2.Yqq_g', T2.Yqd_g', T2.Ydq_g', T2.Ydd_g', ...
    T2.f', T2.Yqq_c', T2.Yqd_c', T2.Ydq_c', T2.Ydd_c');


% Group admittances in cell arrays for multi-case Bode plots
Yc = {Y_c_dq, Y_c_dq1};  % Controller admittances
Yg = {Y_g_dq, Y_g_dq1};  % Grid admittances
f = {T1.f, T2.f};
names = {'Black', 'Grey'};


%% Plot Bode diagrams (magnitude & phase) for controller and grid admittances
bode_plot_full(f, Yc, Yg, 'dq');  % dq-frame Bode plot
visualizza_bene; % Apply custom formatting (e.g., axis labels, grid, font size)

%% Plot MIMO Nyquist diagrams for both sampling times
fig = figure;
MIMO_Nyquist(T2.f, E1,  1, struct('style1','-.r','style2','-.r','style3','r','style4','r'), 'Grey');
hold on
MIMO_Nyquist(T1.f, E,  1, struct('style1','-.b','style2','-.b','style3','b','style4','b'), 'Black');
legend('show');
uniformaFiguraPaper(fig)

%% Calculate and plot Singular Value Decomposition (SVD) vs frequency
% SVD_Calc:
%   For each frequency point, computes the maximum and minimum singular
%   values of the closed-loop matrix. This is useful for stability margins
%   and robust control analysis.


n = size(L, 3);  % numero di frequenze
n1 = size(L1, 3);  % numero di frequenze

t = zeros(2, 2, n);
t1 = zeros(2, 2, n1);
I = eye(2);

for k = 1:n
    t(:,:,k) = inv(I + L(:,:,k)) * L(:,:,k);
end
for k = 1:n1
    t1(:,:,k) = inv(I + L1(:,:,k)) * L1(:,:,k);
end



figure
[max_singular_values_b,  min_singular_values_b]  = SVD_Calc(T1.f', t,  'Black', 1);
hold on
[max_singular_values_g,  min_singular_values_g]  = SVD_Calc(T2.f', t1,  'Grey', 1);


% (Optional) Additional analysis:
%   - Compare gain margin between cases
%   - Mark critical frequencies
%   - Overlay stability thresholds

%% Error in SVG domain

% Dati
f1 = T1.f; f2 = T2.f; 
G1 = t;      % [2,2,length(f1)]
G2 = t1;     % [2,2,length(f2)]

f = logspace(log10(min([f1;f2])), log10(max([f1;f2])), 1000)';

phi = 0 * pi / 180;  % 150° → 2.618 rad
z_shift = exp(-1j * phi);

% Interpolazione TUTTI elementi 2x2 insieme
G1_int = interp1(log10(f1), permute(G1,[3 1 2]), log10(f), 'spline', 0)*z_shift; % [nf,2,2]
G2_int = interp1(log10(f2), permute(G2,[3 1 2]), log10(f), 'spline', 0)*z_shift; % [nf,2,2]

% Riordina e SVD differenza
G1_int = permute(G1_int, [2 3 1]);  % Torna [2,2,nf]
G2_int = permute(G2_int, [2 3 1]);
sigma_delta = zeros(length(f),1);

DeltaG = G2_int- G1_int;

[max_singular_error,  ~]  = SVD_Calc(f, DeltaG,  'Error', 0);
[max_singular_norm,  ~]  = SVD_Calc(f, G1_int,  'Norm', 0);

figure
loglog(f, max_singular_error./max(max_singular_norm) *100, 'DisplayName', 'Grey Error')
xlabel('Frequency (Hz)', 'FontSize', 12)
ylabel('Relative Error (%)', 'FontSize', 12)
title('Relative FD error', 'FontSize', 14)
grid on
legend('Location', 'best')
set(gca, 'FontSize', 12)
xlim([1, 599])
uniformaFiguraPaper(fig)

%% Vector Fitting and State-Space Model Generation
% clc
% close all
closedL = t;
closedf = T1.f;

% Define observation parameters
Tobs = 10.0;           % Observation time in seconds
delta_t = 10E-6;      % Fixed step time in seconds
samples = Tobs / delta_t; % Number of samples

% Frequency-related parameters
Delta_f0 = 1;  % Frequency step in Hertz (Hz)
f1 = (0:samples-1) * Delta_f0; % Frequency vector in Hz
jw1 = 1i * 2 * pi * f1; % Complex frequency vector (s-domain representation)

% Base system frequency
f0 = 50;              % Base frequency in Hz
w = 2 * pi * f0;      % Base angular frequency (rad/s)

% Define fitting parameters
pole_tol = 5E-3;      % Tolerance for pole iterations
degree = 12;          % Order of the first section (number of poles)
fmin = 0.01;           % Minimum frequency for poles (rad/s)
fmax = (2*pi*600);           % Maximum frequency for poles (rad/s)
poles1 = -1 - 1i * linspace(fmin, fmax, degree); % Initial pole guess

% Fit the state-space model using the frequency-domain data
ss_fitted_0 = fitss2(closedL, closedf, poles1, pole_tol, 1);

% Compute the magnitude and phase response using Bode analysis
[Ym_Th_gfl0, Ya_Th_gfl0] = bode(ss_fitted_0, imag(jw1));

% Plot and compare the admittance components
qd0Plot(closedf, jw1, Ym_Th_gfl0, Ya_Th_gfl0, ...
    squeeze(closedL(1,1,:)), ...
    squeeze(closedL(1,2,:)), ...
    squeeze(closedL(2,1,:)), ...
    squeeze(closedL(2,2,:)));

%% Order reduction
% solo per ricavare HSV e info, senza ridurre
[~,info] = balred(ss_fitted_0,1:size(ss_fitted_0.A,1));        % info.hsv contiene HSV [web:11][web:13]

hsv = info.HSV;                                % vettore Hankel singular values
e_rel = cumsum(hsv)/sum(hsv);                  % energia cumulativa

% ord minimo che spiega almeno il 99% dell’energia
ord = find(e_rel >= 0.99,1)

% riduzione vera
% ord = 14 % Bypass
ss_fitted = balred(ss_fitted_0,ord);      % invece di ord fisso = 2 [web:10][web:11]

%% Eig Plotting
% Loading reference state-space system:
load('ss_system.mat')
A_matrix_ss_nomachine = ss_system.A;

eig_ref_nomachine = eig(A_matrix_ss_nomachine);

% Extracting fitted poles:
[poles_fit,zeros_fit]=pzmap(ss_fitted);
set(0, 'defaultAxesFontSize', 14);
set(0, 'DefaultLineLineWidth', 1.5);
figure
plot(real(eig_ref_nomachine),imag(eig_ref_nomachine),'o','DisplayName', 'Grey')
hold on;
plot(real(poles_fit),imag(poles_fit),'x','DisplayName', 'Black Fitted')
xlabel('Real axis')
ylabel('Imaginary axis')
legend('Location', 'best')
grid on
grid minor

%% Stability
clc
stability_analysis(ss_fitted)
save_commandwindow_log()