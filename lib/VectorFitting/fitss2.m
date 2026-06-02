function fitted_ss = fitss2(Yqd0_full, fd0, poles1, pole_tol, red_mode)
    
    % fitss2: Version 2 of the function that generates a 
    % state-space model using vector fitting

    % Inputs descritption:
    % - Yqd0_full is the [2, 2, fd0] matrix with all the frequency (Hz) measurements.
    % - fd0 is a 1xfd0 real-positive vector which contains the frequency measurements in Hz.
    % - poles1 are the starting complex poles for the fitting process.
    % - pole_tol is the convergence tolerance for the pole iteration.
    % - red_mode is the reduced-order methodology for the fitted state-space:
    % - 1 -> State-space balanced realization (BR) [default].
    % - 2 -> State-space by singular value descomposition (SVC).

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   %% Validate dimensions of Yqd0_full

    dimensions = size(Yqd0_full);
    if numel(dimensions) ~= 3 || dimensions(1) ~= 2 || dimensions(2) ~= 2 || dimensions(3) ~= length(fd0)
        error('Input Yqd0_full must have dimensions [2, 2, fd0]. Simulation stopped.');
    end

    %% Validate weight

    % - weight is the 1xfd0 matrix that contains the weighted vector (1 by default)
    weight=linspace(1, 1, length(fd0)); % Vector de ponderacion

    %% Set vector fitting options

    opts.relax = 1; % Allow relaxation for non-triviality constraint
    opts.stable = 1; % Force poles stability
    opts.asymp = 2; % Include D and E in the fitting
    opts.skip_pole = 0; % Do not skip pole identification
    opts.skip_res = 0; % Do not skip residue identification
    opts.cmplx_ss = 0; % Use real-valued state-space models
    opts.spy1 = 0; % Disable first fitting stage plot
    opts.spy2 = 0; % Enable magnitude fitting plot
    opts.logx = 1; % Logarithmic x-axis for frequency
    opts.logy = 1; % Logarithmic y-axis for magnitude
    opts.errplot = 1; % Include error deviation in plots
    opts.phaseplot = 0; % Disable phase plot
    opts.legend = 1; % Include legends in plots

     %% Extract submatrices

    % Extract Yqq, Yqd, Ydq, Ydd as 1xfd0 vectors directly
    % Yqq = transpose(squeeze(Yqd0_full(1,1,:))); % Maintain dimensions 1xfd0
    % Yqd = transpose(squeeze(Yqd0_full(1,2,:))); % Maintain dimensions 1xfd0
    % Ydq = transpose(squeeze(Yqd0_full(2,1,:))); % Maintain dimensions 1xfd0
    % Ydd = transpose(squeeze(Yqd0_full(2,2,:))); % Maintain dimensions 1xfd0
    
    Ydd = transpose(squeeze(Yqd0_full(1,1,:))); % Maintain dimensions 1xfd0
    Ydq = transpose(squeeze(Yqd0_full(1,2,:))); % Maintain dimensions 1xfd0
    Yqd = transpose(squeeze(Yqd0_full(2,1,:))); % Maintain dimensions 1xfd0
    Yqq = transpose(squeeze(Yqd0_full(2,2,:))); % Maintain dimensions 1xfd0
    
    %% Perform vector fitting for each subsystem

    % Extract subsystems from the input 2x2xfd0 Yqd0_full array
    % Yqq fitting
    system1 = PCCF1(Ydd, 1i*2*pi*fd0, poles1, weight, pole_tol, red_mode, opts);

    % Yqd fitting   
    system2 = PCCF1(Ydq, 1i*2*pi*fd0, poles1, weight, pole_tol, red_mode, opts);

    % Ydq fitting
    system3 = PCCF1(Yqd, 1i*2*pi*fd0, poles1, weight, pole_tol, red_mode, opts);

    % Ydd fitting
    system4 = PCCF1(Yqq, 1i*2*pi*fd0, poles1, weight, pole_tol, red_mode, opts);

    %% Build unified MIMO state-space matrices

    % Construct the A matrix
    Afull = blkdiag(system1.A, system2.A, system3.A, system4.A);

    % Construct the B matrix with zero-padding
    Bfull = [system1.B, zeros(size(system1.B));
             zeros(size(system2.B)), system2.B;
             system3.B, zeros(size(system3.B));
             zeros(size(system4.B)), system4.B];

    % Construct the C matrix with zero-padding
    Cfull = [system1.C, system2.C, zeros(size(system3.C)), zeros(size(system4.C));
             zeros(size(system1.C)), zeros(size(system2.C)), system3.C, system4.C];

    % Construct the D matrix
    Dfull = [system1.D, system2.D;
             system3.D, system4.D];

    %% Define state-space model

    % No state names provided as per instruction
    % fitted_ss = ss(Afull, Bfull, Cfull, Dfull, ...
    %                'StateName', {}, 'inputname', {'vq_fit', 'vd_fit'}, ...
    %                'outputname', {'iq_fit', 'id_fit'});
    % 
    fitted_ss = ss(Afull, Bfull, Cfull, Dfull, ...
               'StateName', {}, 'inputname', {'vd_fit', 'vq_fit'}, ...
               'outputname', {'id_fit', 'iq_fit'});

    %% Check system stability
    
    % Stop simulation if the system is unstable
    if ~isstable(fitted_ss)
        error('The fitted state-space model is unstable. Simulation stopped.');
    end
end
