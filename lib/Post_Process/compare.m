function GainsTable = compare(caseName)
    % COMPAREOPTIMIZATIONRESULTS Compares optimized and reference results for a given simulation case.
    %
    % SYNTAX:
    %   GainsTable = CompareOptimizationResults(caseName)
    %
    % INPUT:
    %   caseName - String specifying the name of the optimized case file (without extension),
    %              for example 'resultant_case' corresponding to 'resultant_case.csv'.
    %
    % OUTPUT:
    %   GainsTable - Table comparing original and optimized control gains.
    %
    % DESCRIPTION:
    %   This function performs a comparison between reference and optimized simulation results.
    %   It reads the reference case data and the result file corresponding to the specified case name,
    %   plots the time-domain comparison of representative variables, and constructs a table
    %   comparing original and optimized control loop gains. Optimized parameters are extracted
    %   from "greygains.csv", and the baseline control parameters are taken from "parameters.csv".
    %
    %   The function performs the following steps:
    %     1. Adds data and library paths.
    %     2. Reads and plots the reference and optimized results for key variables.
    %     3. Reads both optimized and original control gains.
    %     4. Builds and displays a comparative table.
    %
    % AUTHOR:
    %   Nicolae Darii (DTU & SGRE)
    %
    % LICENSE:
    %   MIT License (see LICENSE file in the repository).
    %

    %% Add necessary paths
    addpath(genpath('lib'));
    addpath(genpath('data'));

    %% Read reference and optimized case data
    Ref = readtable("reference_case.csv");
    Res = readtable(caseName + ".csv");

    % Assuming 'Time' is the common time vector
    t = Ref.Time;

    %% Plot comparison of results
    figure;

    % Variable 1
    subplot(2,1,1);
    plot(t, Res.Val1, 'LineWidth', 1.5);
    hold on
    plot(t, Ref.Val1, 'LineWidth', 1.5, 'LineStyle', '--');
    xlabel('Time [s]');
    ylabel('Per-unit variable');
    title('Variable 1');
    legend('Optimized', 'Reference');
    grid on;

    % Variable 2
    subplot(2,1,2);
    plot(t, Res.Val2, 'LineWidth', 1.5);
    hold on
    plot(t, Ref.Val2, 'LineWidth', 1.5, 'LineStyle', '--');
    xlabel('Time [s]');
    ylabel('Per-unit variable');
    title('Variable 2');
    legend('Optimized', 'Reference');
    grid on;

    %% Read optimized gains
    found = readtable("greygains.csv");
    kp_outer_V_pu_opt = found.Kp_outer_V;
    ki_outer_V_pu_opt = found.Ki_outer_V;
    kp_outer_P_pu_opt = found.Kp_outer_P;
    ki_outer_P_pu_opt = found.Ki_outer_P;
    kp_inner_d_pu_opt = found.Kp_inner_d;
    ki_inner_d_pu_opt = found.Ki_inner_d;
    kp_inner_q_pu_opt = found.Kp_inner_q;
    ki_inner_q_pu_opt = found.Ki_inner_q;
    kp_pll_opt = found.Kp_pll;
    ki_pll_opt = found.Ki_pll;
    T1_opt = found.T1;
    T2_opt = found.T2;

    %% Read original control parameters
    parameter = readtable("parameters.csv");
    kp_outer_V_pu_orig = parameter.Value(11);
    ki_outer_V_pu_orig = 1 / parameter.Value(12);
    kp_outer_P_pu_orig = parameter.Value(13);
    ki_outer_P_pu_orig = 1 / parameter.Value(14);
    kp_inner_pu_orig   = parameter.Value(15);
    ki_inner_pu_orig   = 1 / parameter.Value(16);
    kp_pll_orig        = parameter.Value(17);
    ki_pll_orig        = 1 / parameter.Value(18);

    %% Build comparative gain table
    Original = [kp_outer_V_pu_orig;
                ki_outer_V_pu_orig;
                kp_outer_P_pu_orig;
                ki_outer_P_pu_orig;
                kp_inner_pu_orig;
                ki_inner_pu_orig;
                kp_inner_pu_orig;
                ki_inner_pu_orig;
                kp_pll_orig;
                ki_pll_orig;
                NaN;
                NaN];

    Optimizator = [kp_outer_V_pu_opt;
                   ki_outer_V_pu_opt;
                   kp_outer_P_pu_opt;
                   ki_outer_P_pu_opt;
                   kp_inner_d_pu_opt;
                   ki_inner_d_pu_opt;
                   kp_inner_q_pu_opt;
                   ki_inner_q_pu_opt;
                   kp_pll_opt;
                   ki_pll_opt;
                   T1_opt;
                   T2_opt];

    RowNames = {'kp_outer_V_pu', 'ki_outer_V_pu', ...
                'kp_outer_DC/P_pu', 'ki_outer_DC/P_pu', ...
                'kp_inner_d_pu', 'ki_inner_d_pu', ...
                'kp_inner_q_pu', 'ki_inner_q_pu', ...
                'kp_pll', 'ki_pll', ...
                'T1', 'T2'};

    GainsTable = table(Original, Optimizator, 'RowNames', RowNames);

    %% Display resulting table
    % disp(GainsTable)
end
