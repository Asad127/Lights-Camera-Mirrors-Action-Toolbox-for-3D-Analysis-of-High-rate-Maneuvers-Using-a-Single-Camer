function project_dirs_append(project_dir)
% Append an absolute path to a directory to `project_dirs.m`. Run in a
% function to avoid workspace merging.

% Assumed in toolbox path, this contains the MATLAB path of the toolbox. It
% is auto generated upon running `setup_mirror_reconstruction_roolbox.m`.
toolbox = load('toolbox.mat');

projects_file = fopen(fullfile(toolbox.TOOLBOX_MATLAB_PATH, 'project_dirs.m'), 'a');
[~, project_name] = fileparts(project_dir);
project_name = strrep(project_name, '\', '\\');

fprintf(projects_file, "%s_project_dir = '%s';\n", project_name, project_dir);
fclose(projects_file);

end