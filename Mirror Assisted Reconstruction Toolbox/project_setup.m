% After `setup-mirror_reconstruction_toolbox.m` has been run to initialize
% the toolbox, this script can be used to create a project structure in the
% current directory.

fprintf('Creating a project in the current folder...\n');

LAUNCHTIME_DIR = pwd;
toolbox = load('toolbox.mat');
TOOLBOX_MATLAB_PATH = toolbox.TOOLBOX_MATLAB_PATH;

overwrite_missing_path = false;
logicmap = dictionary(["y" "n"], [true false]);
while true
    project_name = input('[PROMPT] Enter the name of the project: ', 's');
    if isempty(project_name)
        fprintf('\nProject name cannot be blank, please try again.\n')
        continue
    end

    % Check for duplicates.
    fprintf('\nChecking for duplicate project names...')
    [duplicate_line_num, duplicate_line, ~, ~, project_dirs] = project_dirs_match(project_name);
    
    if ~duplicate_line_num
        fprintf('all good.\n')
    else
        duplicate_dir = project_dirs{duplicate_line_num};
        if isfolder(duplicate_dir)
            fprintf(['\n[DUPLICATE FOUND] Project with the same name already exists at:\n\t%s' ...
                '\n\t@ Line %d in "project_dirs.m": %s\nPlease provide a unique name for the new ' ...
                'project, or rename the existing project with "project_rename.m", and try again.\n'], ...
                duplicate_dir, duplicate_line_num, duplicate_line{1} ...
            )
            continue
        else
            % Ask to overwrite duplicate path if it does not exist.
            fprintf(['\n[MISSING DUPLICATE] A project with the same name is listed in "project_dirs.m", but ' ...
                'appears to be missing.\n\tListed Duplicate (Missing): %s\n\t@ Line %d in ' ...
                '"project_dirs.m": %s\n'], ...
                duplicate_dir, duplicate_line_num, duplicate_line{1} ...
            )
            while true
                overwrite_missing_path = input('[PROMPT] Overwriting the missing listed path. Proceed? (y/n): ', 's');
                if ~ismember(overwrite_missing_path, {'y', 'n'})
                    fprintf(['\n[BAD INPUT] Only "y" (yes) and "n" (no) are accepted inputs (w/o quotes). ' ...
                        'Please try again.\n'] ...
                    )
                    continue
                end
                overwrite_missing_path = logicmap(overwrite_missing_path);
                break
            end
    
            if ~overwrite_missing_path
                fprintf(['[RETRY] Please provide a unique name for the project, or delete the listed ' ...
                    'missing path with "project_dirs_delete.m" and try again.\nYou may also relocate ' ...
                    'the missing path if it has been misplaced with "project_dirs_relocate_missing.m", ' ...
                    'rename it with\n"project_rename.m", and then try again.\n\n'] ...
                )
                continue
            end
        end
    end
    break
end

if ~isfolder(project_name)
    mkdir(project_name);
    project_dir = dir(project_name).folder;
    fprintf('Done creating project folder.\n\n')
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

if ~isfile('defaults.m')
    % Copy the global defaults file (toolbox path) to the project path.
    copyfile(fullfile(TOOLBOX_MATLAB_PATH, 'defaults.m'), fullfile(project_dir, 'defaults.m'));
    added_entities{end + 1} = sprintf('+ %s', 'defaults.m');
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
if ~isfolder(default.MEDIA_DIR)
    mkdir(default.MEDIA_DIR)
    added_entities{end + 1} = sprintf('+ %s', default.MEDIA_DIR);
end
if ~isfolder(default.VIDS_DIR)
    mkdir(default.VIDS_DIR);
    added_entities{end + 1} = sprintf('+ %s', default.VIDS_DIR);
end
if ~isfolder(default.VID_FRAMES_DIR)
    mkdir(default.VID_FRAMES_DIR);
    added_entities{end + 1} = sprintf('+ %s', default.VID_FRAMES_DIR);
end
if ~isfolder(default.IMGS_DIR)
    mkdir(default.IMGS_DIR)
    added_entities{end + 1} = sprintf('+ %s', default.IMGS_DIR);
end
if ~isfolder(default.RECONSTRUCTION_DIR)
    mkdir(default.RECONSTRUCTION_DIR)
    added_entities{end + 1} = sprintf('+ %s', default.RECONSTRUCTION_DIR);
end
if ~isfolder(default.EPIPOLAR_DIR)
    mkdir(default.EPIPOLAR_DIR)
    added_entities{end + 1} = sprintf('+ %s', default.EPIPOLAR_DIR);
end

% Update existing path (if duplicate and chose to overwrite) or append this 
% directory path (if unique) to the list of project directories in 
% `project_dirs.m` located at the toolbox source path.
if overwrite_missing_path
    project_dirs_update(duplicate_line_num, project_dir);
    fprintf('\n%-34s: %s\n%-34s: %s', ...
        'Listed Duplicate Project (Missing)', duplicate_dir, ...
        'Replaced With New Project Path', project_dir ...
    )
else
    project_dirs_append(project_dir);
end

%% PRINTOUTS

fprintf('%s\n', default.CWLINE_STYLE);
fprintf('+ %s\n', project_dir);

newline_after_count = 3;
if isempty(added_entities)
    fprintf('Project structure was according to defaults already. Nothing was changed.\n')
else
    for i = 1 : numel(added_entities)
        fprintf('%-30s', added_entities{i});
        if mod(i, newline_after_count) == 0 && i ~= numel(added_entities)
            fprintf('\n')
        end
    end
end

fprintf('\n%s\n', default.CWLINE_STYLE);
fprintf(['All done. You can configure non-path related settings for the project at any time ' ...
    'by editing\n"defaults.m" in the project root directory.\n\nNEXT STEPS: Prepare Calibration ' ...
    'Media\n\n- Import calibration media (images/video) to project directory by running ' ...
    '"calib_import_media.m". \n\n\to If calibration video already in project directory (video ' ...
    'must be mp4; convert if needed with\n \t  "convert_vid_to_mp4.m"), directly extract frames ' ...
    'by running "calib_extract_vid_frames.m" and\n\t  select final image subset for calibration ' ...
    'by running "calib_select_img_subset.m".\n\n\to If calibration images already in project ' ...
    'directory, rename them sequentially with\n\t  "imgs_sequential_rename.m", then head to the ' ...
    'images directory and run BCT with "calib_gui.m".\n\n'] ...
)