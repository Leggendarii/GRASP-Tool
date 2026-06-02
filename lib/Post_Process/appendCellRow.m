function C = appendCellRow(C, varargin)
    % APPENDCELLROW Appends new elements as rows to an existing cell array.
    %
    % INPUT:
    %   C        - Existing cell array to which new rows will be added.
    %   varargin - A series of variable input arguments, which are converted 
    %              into a column cell array and appended to C.
    %
    % OUTPUT:
    %   C - Updated cell array with the new elements added as rows.
    %
    % DESCRIPTION:
    %   This function takes an existing cell array C and one or more additional
    %   inputs (varargin). It converts these inputs into a column cell array 
    %   and vertically concatenates them to C, returning the updated cell array.
    %
    % AUTHOR:
    %   Nicolae Darii (DTU and Siemens Gamesa)
    %
    % LICENSED UNDER:
    %   MIT License (see LICENSE file in the repository).
    
    % Convert inputs into a column cell array and concatenate vertically
    C = [C; varargin(:)];
end
