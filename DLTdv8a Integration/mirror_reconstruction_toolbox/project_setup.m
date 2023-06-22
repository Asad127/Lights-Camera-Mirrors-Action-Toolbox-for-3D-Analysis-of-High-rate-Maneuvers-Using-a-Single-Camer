% This script should be the first to run. Ideally, you would run it in an 
% empty directory where the entire project would be stored.
clear
close all

fprintf(['Creating a project in the current folder.\nNOTE: You can configure the structure by ' ...
    'editing the toolbox file "defaults.m".\n']);

LAUNCHTIME_DIR = pwd; 

while true
    proj_name = input('[PROMPT] Enter the name of the project: ', 's');
    if isempty(proj_name)
        fprintf('Project name cannot be blank, please try again.\n')
        continue
    end
    break
end

% [~, ~, existing_project_dirs] = project_dirs_read();
project_already_exists = false;
if ~isfolder(proj_name)
    mkdir(proj_name);
    project_dir = dir(proj_name).folder;
    fprintf('Created project folder.\n')
else
    project_already_exists = true;
    project_dir = dir(proj_name).folder;
    fprintf('Project already exists at:\n\t%s.\nChecking basic folder structure regardless.\n', project_dir)
end

if project_already_exists
    project_dir = dir(proj_name).folder;
    fprintf(['Project already exists at:\n\t%s\n(1) Pick a different name.' ...
        '\n(2) To move the existing project to this directory or another, run "project_move.m".' ...
        '\n(3) To delete the existing project, run "project_delete.m".' ...
        '\n(4) To rename the existing project, run "project_rename.m".' ...
        '\n(5) To verify project structure and restore any missing files, run "project_repair.m".'], project_dir)
    return
end
fprintf('...changing CWD to project folder...\n')
cd(project_dir);

added_entities = {};

% Create a mat file containing this project directory, and one containing
% the default configuration params defined in `defaults.m`.
if ~isfile('project_dir.mat')
    save('project_dir.mat', 'project_dir');
    added_entities{end + 1} = sprintf('+ %s', 'project_dir.mat');
end

if ~isfile('defaults.mat')
    create_defaults_matfile(project_dir);
    added_entities{end + 1} = sprintf('+ %s', 'defaults.mat');
end

% Setup the rest of the folder structure.
default = load('defaults.mat', 'BCT_CALIB_DIR', 'BCT_CALIB_IMGS_DIR', ...
    'BCT_CALIB_FRAMES_DIR', 'BCT_CALIB_SUBSET_HIST_DIR', 'DLTDV_TRACKFILES_DIR', ...
    'DLTDV_VID_DIR', 'DLTDV_VID_FRAMES_DIR', 'CWLINE_STYLE');

if ~isfolder(default.BCT_CALIB_DIR)
    mkdir(default.BCT_CALIB_DIR);
    added_entities{end + 1} = sprintf('+ %s', default.BCT_CALIB_DIR);
end
if ~isfolder(default.BCT_CALIB_IMGS_DIR)
    mkdir(default.BCT_CALIB_IMGS_DIR);
    added_entities{end + 1} = sprintf('+ %s', default.BCT_CALIB_IMGS_DIR);
end
if ~isfolder(default.BCT_CALIB_FRAMES_DIR)
    mkdir(default.BCT_CALIB_FRAMES_DIR);
    added_entities{end + 1} = sprintf('+ %s', default.BCT_CALIB_FRAMES_DIR);
end
if ~isfolder(default.DLTDV_TRACKFILES_DIR)
    mkdir(default.DLTDV_TRACKFILES_DIR);
    added_entities{end + 1} = sprintf('+ %s', default.DLTDV_TRACKFILES_DIR);
end
if ~isfolder(default.DLTDV_VID_DIR)
    mkdir(default.DLTDV_VID_DIR);
    added_entities{end + 1} = sprintf('+ %s', default.DLTDV_VID_DIR);
end
if ~isfolder(default.DLTDV_VID_FRAMES_DIR)
    mkdir(default.DLTDV_VID_FRAMES_DIR);
    added_entities{end + 1} = sprintf('+ %s', default.DLTDV_VID_FRAMES_DIR);
end
if ~isfolder(default.RECONSTRUCTION_DIR)
    mkdir(default.RECONSTRUCTION_DIR)
    added_entities{end + 1} = sprintf('+ %s', default.RECONSTRUCTION_DIR);
end

fprintf('%s\n', default.CWLINE_STYLE);

if ~project_already_exists
    fprintf('+ %s\n', project_dir);
end

newline_after_count = 3;
if isempty(added_entities)
    fprintf("Project structure was according to defaults already. Nothing was changed.\n")
else
    for i = 1 : numel(added_entities)
        fprintf('%-30s', added_entities{i});
        if mod(i, newline_after_count) == 0 && i ~= numel(added_entities)
            fprintf('\n')
        end
    end
end

% if you don't want to automatically enter project folder, uncomment this
if project_already_exists
    cd(LAUNCHTIME_DIR);
end
% cd ..

project_dirs_append(project_dir);

fprintf('\n%s\n', default.CWLINE_STYLE);
fprintf('All done. Import calibration media by running "calib_import_media.m".\n')

clear