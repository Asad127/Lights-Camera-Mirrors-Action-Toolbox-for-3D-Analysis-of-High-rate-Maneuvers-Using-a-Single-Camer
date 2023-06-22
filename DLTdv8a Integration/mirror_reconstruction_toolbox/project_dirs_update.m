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

% Assumed in toolbox path, this contains the MATLAB path of the toolbox. It
% is auto generated upon running `setup_mirror_reconstruction_roolbox.m`.
toolbox = load('toolbox_dir.mat');

% Get project name from new project directory's last part.
[~, new_project_name] = fileparts(new_project_dir);

% Read all the lines and get the one corresponding to the line number.
[projects_file_lines, ~, project_dirs] = project_dirs_read();
num_projects = numel(project_dirs);

% Get line number based on the type of input. If numeric and less than the 
% number of existing projects, set it equal to the target line number.
if isa(project_identifier, 'numeric')
    target_line_num = project_identifier;
    if target_line_num > num_projects
        error('Line number, %d, exceeds total number of existing projects, %d, in "project_dirs.m."', ...
            target_line_num, num_projects ...
        )
    end

% If user provdes the directory, compare against each existing project
% directory, and grab the line number of the line where it matches.
elseif isa(project_identifier, 'char')
    found_project_dir = false;
    for i = 1 : num_projects
        % Check assuming user gave project directory
        if ~strcmp(project_identifier, project_dirs{i})
            [~, curr_project_name] = fileparts(project_dirs{i});
            % Check assuming user gave project name, not full directory
            if ~strcmp(project_identifier, curr_project_name)
                continue
            end
        end
        found_project_dir = true;
        curr_line = i;
        break
    end

    if ~found_project_dir
        error('Provided project directory is not in the list of existing project directories.')
    end
    target_line_num = curr_line;

else
    error(['Unexpected type for argument "project_identifier".\nExpected either a char or numeric, ' ...
        'got %s instead.'], class(project_identifier) ...
    );
end

% Update the target project's line.
projects_file_lines{target_line_num} = sprintf("%s_project_path = '%s';", new_project_name, new_project_dir) ;

% Re-write the file with the updated line.
projects_file = fopen(fullfile(toolbox.TOOLBOX_MATLAB_PATH, 'project_dirs.m'), 'w');
fprintf(projects_file, '%s\n', projects_file_lines{:});

end