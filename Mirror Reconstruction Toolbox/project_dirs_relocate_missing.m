% Does the project directories file exist? If not, we can't proceed.
toolbox_dir = load('toolbox_dir.mat');
TOOLBOX_MATLAB_PATH = toolbox_dir.TOOLBOX_MATLAB_PATH;
if ~isfile(fullfile(TOOLBOX_MATLAB_PATH, 'project_dirs.m'))
    err_msg = sprintf([ ...
        'The file containing project paths (project_dirs.m) does not exist.' ...
        '\nIt was likely never generated in the first place. To generate it, please run ' ...
        '"setup_mirror_reconstruction_toolbox.m"\nin the toolbox source directory.']);
    error(err_msg)
end

fprintf(['Please note that no actual data is deleted with this script. The only file this ' ...
    'script modifies is\n"project_dirs.m" that contains paths to projects initiated with ' ...
    '"project_setup.m". If these paths\ndo not exist on the computer, they are ' ...
    'classified as missing and this script simply relocates and\noptionally removes them ' ...
    'from "project_dirs.m".\n\n'] ...
)

% Verify existing paths to project directories.
fprintf('Verifying directories listed in "project_dirs.m"...');
[project_dirs, missing_dirs, missing_dir_lines] = project_dirs_verify();

% No missing projects, good to go!
if numel(missing_dirs) == 0
    fprintf('done. None missing!\n');
    return
end

% Relocate and/or delete missing projects.
while true
    delete_all_missing = input(['[PROMPT] Delete all missing project directories without relocating? ' ...
        '(y/n, n = relocate missing): '], 's' ...
    );
    if ~ismember(delete_all_missing, {'y', 'n'})
        fprintf('[BAD PROMPT] Only "y" (yes) and "n" (no) are accepted inputs. Please try again.\n')
        continue
    end
    break
end

if delete_all_missing == 'y'
    project_dirs_delete(missing_dir_lines);  % delete the relevant rows
    fprintf('Verified paths to project directories and deleted all the missing ones.\n')
    return
end

% Begin relocation. The user has the option to skip relocating a project;
% those dirs and their line nums will go into the following empties.
skipped_dir_lines = [];  
skipped_dirs = {};   
fprintf('Relocating missing project directories...\n\n')
for i = 1 : numel(missing_dirs)
    skip_this_path = false;
    fprintf('(%d) Relocating %s...', i, missing_dirs{i});
    while true
        relocated_dir = uigetdir( ...
            '', ...
            sprintf('Relocate project path "%s" (cancel = skip this)', missing_dirs{i}) ...
        );

        if ~relocated_dir
            skip_this_path = true;
            break
        end

        status = check_relocated_dir(relocated_dir);
        if strcmp(status, 'Repairs canceled, nothing changed.')
            % If user cancels the operation from within project_repair.m, 
            % means they might want to reselect the directory for this path
            fprintf('Reattempting relocation...\n')
            continue
        end
        break
    end

    if skip_this_path
        skipped_dir_lines(end+1) = missing_dir_lines(i);
        skipped_dirs{end+1} = missing_dirs{i};
        fprintf('Relocation skipped.\n\n')
        continue
    end

    % Update the old directory path with the new one. Only do
    % this if not deleting, obviously, which is why this is
    % after all the conditionals that continue. Remove it from
    % missing files list as well.
    fprintf(['Relocation successful.\n\tOld Path: %s\n\tNew Path: %s\n\t' ...
        'Updated "project_dirs.m" accordingly.\n\n'], missing_dirs{i}, relocated_dir ...
    )
    project_dirs_update(missing_dir_lines(i), relocated_dir);
end

% Keep or delete those still missing (relocation canceled for these).
if isempty(skipped_dirs)
    fprintf('Verified paths to project directories: \n\tRelocated = %d/%d | Still Missing = %d.\n', ...
        numel(missing_dirs) - numel(skipped_dirs), numel(missing_dirs), numel(skipped_dirs) ...
    )
    return
end

while true
    delete_unrelocated = input('[PROMPT] Delete unrelocated project directories? (y/n): ', 's');
    if ~ismember(delete_unrelocated, {'y', 'n'})
        fprintf('[BAD PROMPT] Only "y" (yes) and "n" (no) are accepted inputs. Please try again.\n')
        continue
    end
    break
end

if delete_unrelocated == 'n'
    fprintf('Verified paths to project directories: \n\tRelocated = %d/%d | Still Missing = %d\n', ...
        numel(missing_dirs) - numel(skipped_dirs), numel(missing_dirs), numel(skipped_dirs) ...
    )
    return
end

project_dirs_delete(skipped_dir_lines);
fprintf('Deleted the following project directories from file:\n\t');
fprintf([repmat('%s\n\t', 1, numel(skipped_dirs)) '%s\n\n'], skipped_dirs{:})
fprintf('Verified paths to project directories: Relocated = %d/%d | Deleted = %d\n', ...
    numel(missing_dirs) - numel(skipped_dirs), numel(missing_dirs), numel(skipped_dirs) ...
);


function status_msg = check_relocated_dir(project_dir)

msg_1 = 'Valid project structure. No repairs performed.';
msg_2 = 'Valid project structure. "project_dir.mat" in project directory had the wrong path - updated.';
msg_3 = 'Valid project structure. Defaults file was refreshed per "defaults.m" in toolbox path.';
msg_4 = 'Complete. Repaired invalid project structure.';
msg_5 = 'Repairs canceled, nothing changed.';

fprintf('Verifying project structure...')

added_entities = {};

dir_matfile = fullfile(project_dir, 'project_dir.mat');
defaults_matfile = fullfile(project_dir, 'defaults.mat');

bad_dir_matfile = false;

% Check for default and this project's directory matfiles. If they are
% missing, it's a good chance this is either not a toolbox-initialized
% project or has been corrupted somhow, officially needing repairs.
if ~isfile(defaults_matfile) || ~isfile(dir_matfile)
    fprintf(['\n\t[WARNING] The relocated directory is missing core project files. Either the provided directory ' ...
        'is not a project, or has been corrupted somehow.\n\t'])
    while true
        reinitialize = input(['Re-initialize project in this directory anyway? This will repair ' ...
            'missing files and folders (y/n, n = do nothing): '], 's');
        if ~ismember(reinitialize, {'y', 'n'})
            fprintf('\t[BAD PROMPT] Only "y" (yes) and "n" (no) are accepted inputs. Please try again.\n')
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
        
        % Update `project_dir.mat`.
        save(dir_matfile, 'project_dir');
        added_entities{end + 1} = sprintf('+ %s', 'project_dir.mat');
    end
end

if ~isfile(defaults_matfile)
    create_defaults_matfile(project_dir)
    added_entities{end + 1} = sprintf('+ %s', 'defaults.mat');
else
    while true
        fprintf('\n\t')
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

% If structure was valid and/or only the logged project path was wrong.
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