function [L, R] = thevenin(SCR, XR, V_base, S_nom, f_base)
    % THEVENIN Computes the equivalent Thevenin parameters for a power grid model.
    %
    % INPUTS:
    %   SCR     - Short-Circuit Ratio (dimensionless).
    %   XR      - Reactance-to-Resistance ratio (X/R, dimensionless).
    %   V_base  - Base voltage (V).
    %   S_nom   - Nominal apparent power (VA).
    %   f_base  - Base frequency (Hz).
    %
    % OUTPUT:
    %   L       - Inductance of the equivalent circuit (H).
    %   R       - Resistance of the equivalent circuit (Ω).
    %
    % The function calculates the equivalent grid impedance (Z_grid) using the 
    % short-circuit ratio (SCR) and the X/R ratio, and then derives the 
    % corresponding inductance and resistance values.
    %
    % AUTHOR:
    %   Nicolae Darii (DTU and SGRE)
    %
    % LICENSED UNDER:
    %   MIT License (see LICENSE file in the repository).
    %

    % Compute angular frequency
    omega = 2 * pi * f_base; % rad/s

    % Compute the absolute value of the grid impedance
    Z_grid_abs = V_base^2 / (SCR * S_nom); % Ohm (Ω)

    % Compute reactance (X_L) and resistance (R) based on the X/R ratio
    k = 1 / XR; % Dimensionless (inverse of X/R ratio)
    X_L = Z_grid_abs / sqrt(k^2 + 1); % Reactance (Ω)
    L = X_L / omega; % Inductance (H)
    R = X_L / XR; % Resistance (Ω)

end