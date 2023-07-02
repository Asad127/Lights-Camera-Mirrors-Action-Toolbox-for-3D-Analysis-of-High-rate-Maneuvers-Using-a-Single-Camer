% After `setup-mirror_reconstruction_toolbox.m` has been run to initialize
% the toolbox, this script can be used to create a project structure in the
% current directory.

fprintf(['Creating a project in the current folder.\nNOTE: You can configure the structure by ' ...
    'editing the toolbox file "defaults.m".\n']);

LAUNCHTIME_DIR = pwd; 

while true
    proj_name = input('[PROMPT] Enter the name of the project: ', 's');
    if isempty(proj_name)
        fprintf('Project name cannot be blank, please try again.\n')
        continue
    end
    % Check for duplicates.
    [duplicate_line_num, duplicate_line, ~, ~, project_dirs] = project_dirs_match(proj_name);
    if duplicate_line_num ~= 0  % equivalent to "if duplicate_line_num"
        fprintf(['[BAD INPUT] Project with the same name already exists at:\n\t%s\n\t@ Line No. ' ...
            '%d in "project_dirs.m": %s\nPlease try again with a unique name.\n'], ...
            project_dirs{duplicate_line_num}, duplicate_line_num, duplicate_line{1} ...
        )
        continue
    end
    break
end

if ~isfolder(proj_name)
    mkdir(proj_name);
    project_dir = dir(proj_name).folder;
    fprintf('Created project folder.\n')
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
default = load('defaults.mat');

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
if ~isfolder(default.EPIPOLAR_DIR)
    mkdir(default.EPIPOLAR_DIR)
    added_entities{end + 1} = sprintf('+ %s', default.EPIPOLAR_DIR);
end


% Append this directory to the list of project directories in 
% `project_dirs.m` located at tolbox source path.
project_dirs_append(project_dir);

%% PRINTOUTS

fprintf('%s\n', default.CWLINE_STYLE);
fprintf('+ %s\n', project_dir);


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

fprintf('\n%s\n', default.CWLINE_STYLE);
fprintf('All done. Import calibration media by running "calib_import_media.m".\n')