function project_dirs_update(project_identifier, new_project_dir)
% Re-write an existing line of the m-script `project_dirs.m`, which
% contains all the projects setup with `setup_project_structure.m`. Each
% line corresponds to the absolute directory path for an existing project,
% stored within a variable named after the project's name (last directory
% in the path).
%
% Thus, the variable also needs to be updated on a project rename. To do
% this, it is assumed that the last directory in the path is the project's
% name, as it is assumed also at project setup.
%
% TAKES
% =====
% project_identifier (numeric OR character vector, required):
%   The line number, project name, or directory path in `project_dirs.m` 
%   that identifies the project directory you want to update. Essentially, 
%   this identifies the old or current project path, and ultimately the 
%   line we need to change in the script.
% new_project_dir (char vector):
%   The updated path of the project.

switch nargin
    case 0
        err_msg = [ ...
            'Require the line number (from "project_dirs.m") corresponding to the project directory' ...
            'to update,\nOR the full project directory itself, OR the project name (i.e., the last ' ...
            'part of\n its directory path).\nRequire the updated path for the project.' ...
        ];
        error(err_msg)
    case 1
        error('Require the new project directory.')
end

if isa(project_identifier, 'cell')
        error(['Unexpected type for argument "project_identifier".\nExpected either a char or numeric, ' ...
            'got %s instead.'], class(project_identifier) ...
    );
end

% Assumed in toolbox path, this contains the MATLAB path of the toolbox. It
% is auto generated upon running `setup_mirror_reconstruction_roolbox.m`.
toolbox = load('toolbox.mat');

% Get project name from new project directory's last part.
[~, new_project_name] = fileparts(new_project_dir);

% `project_dirs_match.m` internally calls `project_dirs_read.m` and returns 
% its output as well (to avoid potential misinputs/desyncs).
[target_line_num, ~, projects_file_lines, ~, ~] = project_dirs_match(project_identifier);

% Update the target project's line.
projects_file_lines{target_line_num} = sprintf("%s_project_path = '%s';", new_project_name, new_project_dir) ;

% Re-write the file with the updated line.
projects_file = fopen(fullfile(toolbox.TOOLBOX_MATLAB_PATH, 'project_dirs.m'), 'w');
fprintf(projects_file, '%s\n', projects_file_lines{:});

end