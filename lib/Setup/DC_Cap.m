function [C, Vdc] = DC_Cap(V_LL, Sn)
    % DC_CAP Calculates the DC-link capacitance for a given line-to-line voltage and apparent power.
    % The function assumes modulation index ma = 1 and 10% ripple in DC voltage.
    %
    % INPUT:
    %   V_LL - Line-to-line RMS voltage (Volts).
    %   Sn   - Apparent power rating (VA).
    %
    % OUTPUT:
    %   C    - Required DC-link capacitance (Farads).
    %   Vdc  - Calculated DC-link voltage (Volts), rounded to two significant digits.
    %
    % AUTHOR:
    %   Nicolae Darii (DTU and Siemens Gamesa)
    %
    % LICENSED UNDER:
    %   MIT License (see LICENSE file in the repository).
    %
    
    % Calculate DC voltage from line-to-line voltage (assuming ma = 1, factor 1.6330)
    Vdc = V_LL * 1.6330;  % sqrt(2)*2/(sqrt(3)*m)
    
    % Round to two significant digits
    function y = round2digit(x)
        % ROUND2DIGIT Rounds x to two significant digits
        n = floor(log10(abs(x)));   % order of magnitude
        y = round(x, -n+1);         % rounding accordingly
    end

    Vdc = round2digit(Vdc);
    
    % Calculate AC current from apparent power and voltage
    Iac = Sn / (V_LL * sqrt(3));
    
    % Calculate DC-link capacitance based on ripple and switching frequency (50 Hz)
    C = Iac / (6 * 50 * 0.1 * Vdc); %10% voltage ripple by design
end
