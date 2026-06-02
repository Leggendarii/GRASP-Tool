function [sistemaf] = BalancedRealization(sistema, toleranciaSV)
% BalancedRealization - Computes a balanced realization of a given system and reduces insignificant states.
%
% Syntax:
%   [sistemaf] = BalancedRealization(sistema, toleranciaSV)
%
% Inputs:
%   sistema      - Original system in state-space representation (ss object).
%   toleranciaSV - Tolerance threshold for singular values to determine which states to eliminate.
%
% Outputs:
%   sistemaf     - Reduced system in state-space representation after eliminating insignificant states.
%
% Description:
%   This function performs the following steps:
%   1. Calculates a balanced realization of the input system, identifying states based on their controllability and observability.
%   2. Determines which states have negligible contribution by comparing their singular values against the specified tolerance.
%   3. Eliminates insignificant states to produce a reduced-order model while preserving the essential dynamics of the system.

    % Step 1: Compute balanced realization of the system
    % The function 'balreal' returns a balanced system and its corresponding singular values (G).
    [sistemabal, G] = balreal(sistema);

    % Step 2: Identify states with singular values below the tolerance
    % The function 'find' selects indices of singular values less than the specified tolerance.
    eliminar = find(G < toleranciaSV);

    % Step 3: Remove insignificant states using model reduction
    % The function 'modred' eliminates states based on the provided indices.
    sistemaf = modred(sistemabal, eliminar, 'del');

    % Output: Reduced system 'sistemaf' with significant states only.
end
