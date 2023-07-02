function [projects_file_lines, project_vars, project_dirs] = project_dirs_read()
% Read the `project_dirs.m` file in the toolbox path. It contains the
% absolute directories of projects setup with `project_setup.m`
% in the form: 
%   {projectName}_project_dir = absolute_project_dir.
%
% The project name is assumed to be the last directory in the project
% directory path. So, D:\toolbox\this_project would have project name as
% "this_project".
%
% TAKES
% =====
% Nothing. The file is on the toolbox path, so as long as the toolbox is
% included on MATLAB path, this should work without input.
%
% RETURNS
% =======
% projects_file_lines:
%   The lines of the project as a cell vector with each line represented as
%   an element of the cell.
% project_vars:
%   The variables that contain the project directories. Part of the
%   variable name is created with the project's name, which is the last
% project_dirs:
%   The absolute paths to the project directories.

% Read the file and get each line.
projects_file_lines = textscan(fopen('project_dirs.m', 'r'), '%s', 'Delimiter', '\n');
projects_file_lines = projects_file_lines{1};
projects_file_num_lines = numel(projects_file_lines);

% Split each line into variable names - project directories/paths.
project_dirs = cell(1, projects_file_num_lines);
project_vars = cell(1, projects_file_num_lines);

for i = 1 : numel(projects_file_lines)
    splits = strsplit(projects_file_lines{i}, ' = ');
    % Get rid of the start and end quotes and the semicolon from 'abc'; to
    % get just abc. Start at 2nd index, end at 3rd last index.
    project_dirs{i} = splits{2}(2 : end - 2);  
    project_vars{i} = splits{1}(2 : end - 2);
end

end