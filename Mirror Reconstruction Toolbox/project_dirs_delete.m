function project_dirs_delete(project_identifier)
% This function deletes the relevant lines corresponding to project paths
% from `project_dirs.m`. The relevant projects may be in various formats.
% 90% of the code is just input checks. If anything fails, an error is
% thrown and nothing is deleted.
%
% Note that whatever the format of the project identifier, it is always
% converted to a line number (if not already in that form) to actually 
% delete the line from `project_dirs.m`.
%
% TAKES 
% =====
% project_identifier:
%   The line number, project name, or directory path in `project_dirs.m` 
%   that identifies the project directory to delete. May also be a cell
%   array where all elements represent either numerics or chars. Note for
%   cell array inputs, no distinction is required between directories and
%   names as the implementation checks for both by first treating input as
%   an absolute path, and only if that fails, as the project name.
%
% RETURNS
% =======
% Nothing. It simply modifies `project_dirs.m` in the toolbox path.

switch nargin
    case 0
        err_msg = [ ...
            'Require the line number (from "project_dirs.m") corresponding to the project directory' ...
            'to update, \nOR the project name (i.e., the last part of its directory path).' ...
            '\nRequire the updated path for the project.' ...
        ];
        error(err_msg)
end

% Assumed in toolbox path, this contains the MATLAB path of the toolbox. It
% is auto generated upon running `setup_mirror_reconstruction_toolbox.m`.
toolbox = load('toolbox.mat');  

% project_dirs_match.m internally calls `project_dirs_read.m` and returns
% its output as well (to avoid potential misinputs/desyncs).
[lines_to_delete, ~, projects_file_lines, ~, ~] = project_dirs_match(project_identifier);

% Now we have the line numbers, we can delete the corresponding lines and
% re-write the `project_dirs.m` file.
projects_file_lines(lines_to_delete) = [];  % delete the relevant rows

% Re-write the file with the updated line.
projects_file = fopen(fullfile(toolbox.TOOLBOX_MATLAB_PATH, 'project_dirs.m'), 'w');
fprintf(projects_file, '%s\n', projects_file_lines{:});
fclose(projects_file);

end