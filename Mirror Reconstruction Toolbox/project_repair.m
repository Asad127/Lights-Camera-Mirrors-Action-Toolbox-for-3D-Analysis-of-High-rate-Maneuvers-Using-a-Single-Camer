function status_msg = project_repair(project_dir)

switch nargin
    case 0
        project_dir = uigetdir('', ...
            'Choose existing project directory to repair/re-initialize (i.e., fix missing files and folders)' ...
        );
        if ~project_dir
            error('Operation canceled by user.')
        end
end

% Check if the project directory exists.

msg_1 = 'Valid project structure. No repairs performed.';
msg_2 = 'Valid project structure. "project_dir.mat" in project directory had the wrong path - updated.';
msg_3 = 'Valid project structure. Defaults file was refreshed per "defaults.m" in toolbox path.';
msg_4 = 'Repaired invalid project structure.';
msg_5 = 'Repairs canceled, nothing changed.';

fprintf(['Verifying project structure at:\n\t%s\nNOTE: You can configure the structure by ' ...
    'editing the toolbox file "defaults.m".\n'], project_dir);

added_entities = {};

dir_matfile = fullfile(project_dir, 'project_dir.mat');
defaults_matfile = fullfile(project_dir, 'defaults.mat');

bad_dir_matfile = false;

% Check for default and this project's directory matfiles. If they are
% missing, it's a good chance this is either not a toolbox-initialized
% project or has been corrupted somhow, officially needing repairs.
if ~isfile(defaults_matfile) || ~isfile(dir_matfile)
    fprintf(['The project is missing core files. Either the provided directory is not a ' ...
    'project, or has been corrupted somehow.\n'])
    while true
        reinitialize = input(['Re-initialize project in this directory anyway? This will repair ' ...
            'missing files and folders (y/n, n = do nothing): '], 's');
        if ~ismember(reinitialize, {'y', 'n'})
            fprintf('[BAD PROMPT] Only "y" (yes) and "n" (no) are accepted inputs. Please try again.\n')
            continue
        end
        break
    end
    if reinitialize == 'n'
        status_msg = msg_5;
        fprintf('Repair Status: %s\n', status_msg)
        return
    end
end

if ~isfile(dir_matfile)
    save(dir_matfile, 'project_dir');
    added_entities{end + 1} = sprintf('+ %s', 'project_dir.mat');
else
    % Check if `project_dir.mat` has the same path as the provided project
    % directory. It is possible the project was moved, in which case this
    % would need updating.
    project_dir_matfile = load(dir_matfile);
    saved_project_dir = project_dir_matfile.project_dir;
    if ~strcmp(saved_project_dir, project_dir)
        bad_dir_matfile = true;

        % Append new path if old one does not exist in `project_dirs.m`, 
        % otherwise update old path with the new one.
        [target_line_num, ~, ~, ~, ~] = project_dirs_match(saved_project_dir);
        if ~target_line_num
            project_dirs_append(project_dir);
        else
            project_dirs_update(target_line_num, project_dir);
        end

        % Resave updated `project_dir.mat`.
        save(dir_matfile, 'project_dir');
        added_entities{end + 1} = sprintf('+ %s', 'project_dir.mat');
    end
end

if ~isfile(defaults_matfile)
    create_defaults_matfile(project_dir)
    added_entities{end + 1} = sprintf('+ %s', 'defaults.mat');
else
    while true
        regen_defaults_matfile = input(['Force-replace existing "defaults.mat" file with default ' ...
            'configuration from toolbox path? (y/n): '], 's');
        if ~ismember(regen_defaults_matfile, {'y', 'n'})
            fprintf('[BAD PROMPT] Only "y" (yes) and "n" (no) are accepted inputs. Please try again.\n')
            continue
        end
        break
    end
    if regen_defaults_matfile == 'y'
        create_defaults_matfile(project_dir);
        added_entities{end + 1} = sprintf('+ %s', 'defaults.mat');
    end
end

% Setup the rest of the folder structure.
default = load(fullfile(project_dir, 'defaults.mat'));

calib_base_dir = fullfile(project_dir, default.BCT_CALIB_DIR);
calib_imgs_dir = fullfile(project_dir, default.BCT_CALIB_IMGS_DIR);
calib_frames_dir = fullfile(project_dir, default.BCT_CALIB_FRAMES_DIR);
dltdv_trackfiles_dir = fullfile(project_dir, default.DLTDV_TRACKFILES_DIR);
dltdv_vids_dir = fullfile(project_dir, default.DLTDV_VID_DIR);
dltdv_vid_frames_dir = fullfile(project_dir, default.DLTDV_VID_FRAMES_DIR);
reconstruction_dir = fullfile(project_dir, default.RECONSTRUCTION_DIR);
epipolar_dir = fullfile(project_dir, default.EPIPOLAR_DIR);

if ~isfolder(calib_base_dir)
    mkdir(calib_base_dir);
    added_entities{end + 1} = sprintf('+ %s', default.BCT_CALIB_DIR);
end
if ~isfolder(calib_imgs_dir)
    mkdir(calib_imgs_dir);
    added_entities{end + 1} = sprintf('+ %s', default.BCT_CALIB_IMGS_DIR);
end
if ~isfolder(calib_frames_dir)
    mkdir(calib_frames_dir);
    added_entities{end + 1} = sprintf('+ %s', default.BCT_CALIB_FRAMES_DIR);
end
if ~isfolder(dltdv_trackfiles_dir)
    mkdir(dltdv_trackfiles_dir);
    added_entities{end + 1} = sprintf('+ %s', default.DLTDV_TRACKFILES_DIR);
end
if ~isfolder(dltdv_vids_dir)
    mkdir(dltdv_vids_dir);
    added_entities{end + 1} = sprintf('+ %s', default.PROJECT_VIDS_DIR);
end
if ~isfolder(dltdv_vid_frames_dir)
    mkdir(dltdv_vid_frames_dir);
    added_entities{end + 1} = sprintf('+ %s', default.PROJECT_FRAMES_DIR);
end
if ~isfolder(reconstruction_dir)
    mkdir(reconstruction_dir)
    added_entities{end + 1} = sprintf('+ %s', default.RECONSTRUCTION_DIR);
end
if ~isfolder(epipolar_dir)
    mkdir(default.EPIPOLAR_DIR)
    added_entities{end + 1} = sprintf('+ %s', default.EPIPOLAR_DIR);
end

newline_after_count = 3;

% If nothing was amiss.
if isempty(added_entities)
    if bad_dir_matfile
        status_msg = msg_2;
    elseif regen_defaults_matfile == 'y'
        status_msg = msg_3;
    else
        status_msg = msg_1;
    end

% If things had to be changed.
else
    status_msg = msg_4;
    fprintf('\t%s\n', default.CWLINE_STYLE);
    fprintf('\t+ %s\n', strrep(project_dir, '\', '\\'))
    for i = 1 : numel(added_entities)
        fprintf('%-30s', added_entities{i});
        if mod(i, newline_after_count) == 0 && i ~= numel(added_entities)
            fprintf('\n\t')
        end
    end
fprintf('\n\t%s\n', default.CWLINE_STYLE);
end

fprintf('\tRepair Status: %s\n', status_msg)

end