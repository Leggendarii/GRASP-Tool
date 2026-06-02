function bode_plot_full(fd0, Y_cs, Y_gs, type)
    % BODE_PLOT_FULL Generates Bode plots for given admittance matrices.
    %
    % INPUT:
    %   fd0   - Frequency vector.
    %   Y_cs  - Cell array of control system admittance matrices.
    %   Y_gs  - Cell array of grid admittance matrices.
    %   type  - String specifying the type of plot: 
    %           "dq" for direct-quadrature (d-q) frame 
    %           "pn" for positive-negative (p-n) sequence.
    %
    % OUTPUT:
    %   The function generates Bode plots for different components of 
    %   the admittance matrices and displays them using bode_plot_single.
    %
    % DESCRIPTION:
    %   This function processes multiple admittance matrices from both 
    %   control and grid systems, extracts their individual components 
    %   (dd, dq, qd, qq), and then plots their Bode diagrams. Depending 
    %   on the 'type' parameter, it either plots in the d-q frame or the 
    %   p-n sequence frame.
    %
    % AUTHOR:
    %   Nicolae Darii (DTU and Siemens Gamesa)
    %
    % LICENSED UNDER:
    %   MIT License (see LICENSE file in the repository).
    
    % Initialize empty cell arrays for grid and control admittance components
    Ydd_gs = {};
    Ydq_gs = {};
    Yqd_gs = {};
    Yqq_gs = {};

    Ydd_cs = {};
    Ydq_cs = {};
    Yqd_cs = {};
    Yqq_cs = {};

    % Process grid admittance matrices
    for i = 1:length(Y_gs)
        Y_g = Y_gs{i};
        Ydd_g = squeeze(Y_g(1,1,:));
        Ydq_g = squeeze(Y_g(1,2,:));
        Yqd_g = squeeze(Y_g(2,1,:));
        Yqq_g = squeeze(Y_g(2,2,:));

        Ydd_gs = appendCellRow(Ydd_gs, Ydd_g);
        Ydq_gs = appendCellRow(Ydq_gs, Ydq_g);
        Yqd_gs = appendCellRow(Yqd_gs, Yqd_g);
        Yqq_gs = appendCellRow(Yqq_gs, Yqq_g);
    end

    % Process control system admittance matrices
    for i = 1:length(Y_cs)
        Y_c = Y_cs{i};
        Ydd_c = squeeze(Y_c(1,1,:));
        Ydq_c = squeeze(Y_c(1,2,:));
        Yqd_c = squeeze(Y_c(2,1,:));
        Yqq_c = squeeze(Y_c(2,2,:));

        Ydd_cs = appendCellRow(Ydd_cs, Ydd_c);
        Ydq_cs = appendCellRow(Ydq_cs, Ydq_c);
        Yqd_cs = appendCellRow(Yqd_cs, Yqd_c);
        Yqq_cs = appendCellRow(Yqq_cs, Yqq_c);
    end   

    % Generate Bode plots based on the selected type
    if type == "dq"
        bode_plot_single(fd0, Ydd_cs, Ydd_gs, "dd");
        bode_plot_single(fd0, Ydq_cs, Ydq_gs, "dq");
        bode_plot_single(fd0, Yqd_cs, Yqd_gs, "qd");
        bode_plot_single(fd0, Yqq_cs, Yqq_gs, "qq");
    elseif type == "pn"
        bode_plot_single(fd0, Ydd_cs, Ydd_gs, "pp");
        bode_plot_single(fd0, Ydq_cs, Ydq_gs, "pn");
        bode_plot_single(fd0, Yqd_cs, Yqd_gs, "np");
        bode_plot_single(fd0, Yqq_cs, Yqq_gs, "nn");
    else
        disp('Error in Type: select "dq" or "pn"');
    end
end
