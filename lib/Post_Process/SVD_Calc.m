function [max_singular_values, min_singular_values] = SVD_Calc(f, L, label, plotting)
    % SVD_CALC Computes the maximum and minimum singular values of a set of matrices.
    %
    % SYNTAX:
    %   [max_singular_values, min_singular_values] = SVD_Calc(f, L, label, plotting)
    %
    % INPUTS:
    %   f        - Vector of frequencies associated with each matrix in L.
    %   L        - 3D tensor of matrices (dimensions: m x p x n), where n is the number of frequency points.
    %   label    - (Optional) String used to annotate plot curves (default: '').
    %   plotting - (Optional) Boolean flag to enable or disable plotting (default: true).
    %
    % OUTPUTS:
    %   max_singular_values - Row vector (1 x n) containing the maximum singular value of each matrix in L.
    %   min_singular_values - Row vector (1 x n) containing the minimum singular value of each matrix in L.
    %
    % DESCRIPTION:
    %   The function performs Singular Value Decomposition (SVD) on each matrix slice L(:,:,k)
    %   and extracts its maximum and minimum singular values. It then computes the condition number
    %   as the ratio between the largest and smallest singular values.
    %
    %   If plotting is enabled, the function produces a log–log plot showing:
    %       - Maximum singular values as a function of frequency.
    %       - Minimum singular values as a function of frequency.
    %       - Condition number curve (dashed line).
    %       - Highlighted points where the condition number exceeds 10³.
    %
    % AUTHOR:
    %   Nicolae Darii (DTU & SGRE)
    %
    % LICENSE:
    %   MIT License (see LICENSE file in the repository).
    %

    % Handle optional arguments
    if nargin < 2
        label = '';
    end
    if nargin < 3
        plotting = true;
    end

    % Number of matrices in the tensor
    n = size(L, 3);

    % Preallocate output vectors
    max_singular_values = zeros(1, n);
    min_singular_values = zeros(1, n);

    % Compute singular values of each matrix
    for k = 1:n
        [~, S, ~] = svd(L(:,:,k));
        singular_values = diag(S);
        max_singular_values(k) = max(singular_values);
        min_singular_values(k) = min(singular_values);
    end

    % Compute condition number per matrix
    cond_number = max_singular_values ./ min_singular_values;

    % Optional plotting
    if plotting
        loglog(f, max_singular_values, 'DisplayName', ['Max \sigma ' label]);
        hold on
        loglog(f, min_singular_values, 'DisplayName', ['Min \sigma ' label]);
        loglog(f, cond_number, '--', 'DisplayName', ['k(\sigma) ' label]);

        % Highlight points with high condition number
        threshold = 1e3;
        idx = find(cond_number > threshold);
        loglog(f(idx), cond_number(idx), 'ro', 'DisplayName', ['k(\sigma) > 10^3 ' label]);

        xlabel('Frequency (Hz)');
        ylabel('Singular values (\sigma) / Condition number k(\sigma)');
        title('Singular values and condition number vs frequency');
        legend('show');
        grid on;
        xlim([min(f), max(f)]);
        hold off;
    end
end
