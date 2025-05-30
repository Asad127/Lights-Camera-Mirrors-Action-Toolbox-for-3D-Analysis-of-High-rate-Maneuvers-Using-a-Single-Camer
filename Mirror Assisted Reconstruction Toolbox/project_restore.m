% Restore a directory as a valid project directory. If the selected 
% directory is not listed in "project_dirs.m", this will create a new 
% project in the chosen directory and enter its path into "project_dirs.m". 
% If the selected directory is listed in "project_dirs.m", this will 
% recover/repair missing files, folders, and paths using the local 
% "defaults.m" if available, otherwise recovers the global defaults 
% configuration from the toolbox source path and uses that for repairs.

fprintf(['Beginning project restoration. This process will repair projects that already ' ...
    'exist in "project_dirs.m",\nor if the selected project directory is not listed in ' ...
    '"project_dirs.m", it will verify project structure\nand reinitialize it. Any missing ' ...
    'paths, files, and folders will be recovered.\n\n'])

project_dir = uigetdir('', ...
    'Choose project directory to restore (i.e., fix missing paths, files, and folders)' ...
);
if ~project_dir
    error('Operation canceled by user.')
end

msg_1 = 'Valid project structure. No restoration needed.';
msg_2 = 'Valid project structure. "project_dir.mat" in project directory had the wrong path - updated.';
msg_3 = 'Valid project structure. Defaults m-file was refreshed per "defaults.m" in toolbox path.';
msg_4 = 'Repaired invalid project structure.';
msg_5 = 'Restoration canceled, nothing changed.';

fprintf('Verifying project structure at:\n\t%s\n', project_dir);

% Check if the project directory exists.
[matched_line_num, matched_line, ~, ~, project_dirs] = project_dirs_match(project_dir);
logicmap = dictionary(["y" "n"], [true false]);

reinitialize = false;  % start from scratch, new paths + repairs
relocate = false;      % update project paths + repairs (if existing path invalid)

if ~matched_line_num
    fprintf(['The selected directory did not match with any listed project directories in "project_dirs.m".' ...
        '\nConsequently, the selected dirpath path will be appended to "project_dirs.m" at the end.\n\n'])
    reinitialize = true;

else
    matched_dir = project_dirs{matched_line_num};
    if isfolder(matched_dir) && ~strcmp(matched_dir, project_dir)
        % If the listed directory exists AND is not the same as the
        % selected directory, we ask if the user wants to relocate it to
        % the selected directory.
        fprintf(['[WARNING] Project with the same name already exists at:\n\t%s\n\t@ Line %d in ' ...
            '"project_dirs.m": %s\n'], ...
            matched_dir, matched_line_num, matched_line{1} ...
        )
        while true
            relocate = input(['[PROMPT] Update existing path to point to selected directory? (y/n, n = ' ...
            'cancel restoration): '], 's' ...
            );
            if ~ismember(relocate, {'y', 'n'})
                fprintf('\n[BAD INPUT] Only "y" (yes) and "n" (no) are accepted inputs (w/o quotes). Please try again.\n\n')
                continue
            end
            relocate = logicmap(relocate);
            break
        end
        
        if ~relocate
            fprintf('Relocation of existing path canceled.\nRestoration Status: %s\n\n', msg_5)
            return
        end

    elseif isfolder(matched_dir) && strcmp(matched_dir, project_dir)
        % User's selected directory has exactly the same path as the listed
        % project. In this case, `project_dirs.m` does not require update.
        fprintf(['Selected directory successfully matched to an existing project directory in "project_dirs.m".' ...
            '\n\tMatched Project: %s\n\t@ Line %d in "project_dirs.m": %s\n'], ...
            matched_dir, matched_line_num, matched_line{1} ...
        )

    else
        % Ask to relocate listed path to selected directory if it is 
        % missing.
        fprintf(['\n\n[INVALID MATCH] A project with the same name is listed in "project_dirs.m", but ' ...
            'appears to be missing.\n\tMatched Project (Missing): %s\n\t@ Line %d in ' ...
            '"project_dirs.m": %s\n'], ...
            duplicate_dir, duplicate_line_num, duplicate_line{1} ...
        )
        while true
            relocate = input(['[PROMPT] Relocating missing path to the selected directory. ' ...
                'Proceed? (y/n, n = cancel restoration): '], 's');
            if ~ismember(relocate, {'y', 'n'})
                fprintf(['\n[BAD INPUT] Only "y" (yes) and "n" (no) are accepted inputs (w/o quotes). ' ...
                    'Please try again.\n'] ...
                )
                continue
            end
            relocate = logicmap(relocate);
            break
        end

        if ~relocate
            fprintf('Relocation of missing path canceled.\nRestoration Status: %s\n', msg_5)
            return
        end        
    end
end

missing_entities = {};
voluntary_entities = {};

dir_matfile = fullfile(project_dir, 'project_dir.mat');
defaults_matfile = fullfile(project_dir, 'defaults.mat');
defaults_mfile = fullfile(project_dir, 'defaults.m');

bad_dir_matfile = false;

% Check for default and this project's directory matfiles. If they are
% missing, it's a good chance this is either not a toolbox-initialized
% project or has been corrupted somhow, officially needing repairs.
if ~isfile(defaults_matfile) || ~isfile(dir_matfile) || ~isfile(defaults_mfile)
    fprintf(['[WARNING] The project is missing core files. Either the provided directory is not a ' ...
        'project, or has been corrupted somehow.\n'] ...
    )
    while true
        reinitialize = input(['Attempt repairs anyway? This fixes missing paths, files, and folders. ' ...
            '(y/n, n = do nothing): '], 's');
        if ~ismember(reinitialize, {'y', 'n'})
            fprintf('[BAD PROMPT] Only "y" (yes) and "n" (no) are accepted inputs. Please try again.\n\t')
            continue
        end
        reinitialize = logicmap(reinitialize);
        break
    end
    if reinitialize == 'n'
        status_msg = msg_5;
        fprintf('Restoration Status: %s\n', status_msg)
        return
    end
end

if ~isfile(dir_matfile)
    save(dir_matfile, 'project_dir');
    missing_entities{end + 1} = sprintf('+ %s', 'project_dir.mat');
else
    % Check if `project_dir.mat` has the same path as the provided project
    % directory. It is possible the project was moved, in which case this
    % would need updating.
    project_dir_matfile = load(dir_matfile);
    saved_project_dir = project_dir_matfile.project_dir;
    if ~strcmp(saved_project_dir, project_dir)
        bad_dir_matfile = true;

        % Resave updated `project_dir.mat`.
        save(dir_matfile, 'project_dir');
        voluntary_entities{end + 1} = sprintf('+ %s', 'project_dir.mat');
    end
end

if ~isfile(defaults_mfile)
    recover_defaults_mfile(project_dir);
    missing_entities{end + 1} = sprintf('+ %s', 'defaults.m');
else
    while true
        regen_defaults_mfile = input(['[PROMPT] Force-replace existing "defaults.m" file with global ' ...
            'version from toolbox path? (y/n): '], 's' ...
        );
        if ~ismember(regen_defaults_mfile, {'y', 'n'})
            fprintf('[BAD PROMPT] Only "y" (yes) and "n" (no) are accepted inputs. Please try again.\n')
            continue
        end
        break
    end
    if regen_defaults_mfile == 'y'
        create_defaults_matfile(project_dir);
        voluntary_entities{end + 1} = sprintf('+ %s', 'defaults.m');
    end
end

if ~isfile(defaults_matfile)
    create_defaults_matfile(project_dir)
    missing_entities{end + 1} = sprintf('+ %s', 'defaults.mat');
end

% Setup the rest of the folder structure.
default = load(fullfile(project_dir, 'defaults.mat'));

calib_base_dir = fullfile(project_dir, default.BCT_CALIB_DIR);
calib_imgs_dir = fullfile(project_dir, default.BCT_CALIB_IMGS_DIR);
calib_frames_dir = fullfile(project_dir, default.BCT_CALIB_FRAMES_DIR);
dltdv_trackfiles_dir = fullfile(project_dir, default.DLTDV_TRACKFILES_DIR);
media_dir = fullfile(project_dir, default.MEDIA_DIR);
vids_dir = fullfile(project_dir, default.VIDS_DIR);
vid_frames_dir = fullfile(project_dir, default.VID_FRAMES_DIR);
imgs_dir = fullfile(project_dir, default.IMGS_DIR);
reconstruction_dir = fullfile(project_dir, default.RECONSTRUCTION_DIR);
epipolar_dir = fullfile(project_dir, default.EPIPOLAR_DIR);

if ~isfolder(calib_base_dir)
    mkdir(calib_base_dir);
    missing_entities{end + 1} = sprintf('+ %s', default.BCT_CALIB_DIR);
end
if ~isfolder(calib_imgs_dir)
    mkdir(calib_imgs_dir);
    missing_entities{end + 1} = sprintf('+ %s', default.BCT_CALIB_IMGS_DIR);
end
if ~isfolder(calib_frames_dir)
    mkdir(calib_frames_dir);
    missing_entities{end + 1} = sprintf('+ %s', default.BCT_CALIB_FRAMES_DIR);
end
if ~isfolder(dltdv_trackfiles_dir)
    mkdir(dltdv_trackfiles_dir);
    missing_entities{end + 1} = sprintf('+ %s', default.DLTDV_TRACKFILES_DIR);
end
if ~isfolder(media_dir)
    mkdir(media_dir)
    missing_entities{end + 1} = sprintf('+ %s', default.MEDIA_DIR);
end
if ~isfolder(vids_dir)
    mkdir(vids_dir);
    missing_entities{end + 1} = sprintf('+ %s', default.VIDS_DIR);
end
if ~isfolder(vid_frames_dir)
    mkdir(vid_frames_dir);
    missing_entities{end + 1} = sprintf('+ %s', default.VID_FRAMES_DIR);
end
if ~isfolder(imgs_dir)
    mkdir(imgs_dir)
    missing_entities{end + 1} = sprintf('+ %s', default.IMGS_DIR);
end
if ~isfolder(reconstruction_dir)
    mkdir(reconstruction_dir)
    missing_entities{end + 1} = sprintf('+ %s', default.RECONSTRUCTION_DIR);
end
if ~isfolder(epipolar_dir)
    mkdir(epipolar_dir)
    missing_entities{end + 1} = sprintf('+ %s', default.EPIPOLAR_DIR);
end

% If nothing was amiss.
if isempty(missing_entities)
    if bad_dir_matfile
        status_msg = msg_2;
    elseif regen_defaults_mfile == 'y'
        status_msg = msg_3;
    else
        status_msg = msg_1;
    end

% If things had to be changed.
else
    status_msg = msg_4;
end

total_entities = [voluntary_entities missing_entities];
newline_after_count = 3;

fprintf('%s\n', default.CWLINE_STYLE);
fprintf('+ %s\n', project_dir)
for i = 1 : numel(total_entities)
    fprintf('%-30s', total_entities{i});
    if mod(i, newline_after_count) == 0 && i ~= numel(total_entities)
        fprintf('\n')
    end
end
fprintf('\n%s\n', default.CWLINE_STYLE);

if relocate
    project_dirs_update(matched_line_num, project_dir);
elseif reinitialize
    project_dirs_append(project_dir);
end

fprintf('Restoration Status: %s\n\n', status_msg)