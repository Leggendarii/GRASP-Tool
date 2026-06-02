function [Ypp, Ypn, Ynp, Ynn] = dq2pn(Ydd, Ydq, Yqd, Yqq)
    % DQ2PN Converts DQ frame parameters to PN frame parameters.
    %
    % INPUT:
    %   Ydd   - DQ frame element (1,1).
    %   Ydq   - DQ frame element (1,2).
    %   Yqd   - DQ frame element (2,1).
    %   Yqq   - DQ frame element (2,2).
    %
    % OUTPUT:
    %   Ypp   - PN frame element (1,1).
    %   Ypn   - PN frame element (1,2).
    %   Ynp   - PN frame element (2,1).
    %   Ynn   - PN frame element (2,2).
    %
    % AUTHOR:
    %   Nicolae Darii (DTU and Siemens Gamesa)
    %
    % LICENSED UNDER:
    %   MIT License (see LICENSE file in the repository).
    %

    A = 1/sqrt(2) * [1, 1i; 1, -1i];
    A_inv = 1/sqrt(2) * [1, 1; -1i, 1i];

    Y_dq_frame = [Ydd, Ydq; Yqd, Yqq];

    Y_pn_frame = A * Y_dq_frame * A_inv;

    Ypp = Y_pn_frame(1,1);
    Ypn = Y_pn_frame(1,2);
    Ynp = Y_pn_frame(2,1);
    Ynn = Y_pn_frame(2,2);

end
