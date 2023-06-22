function status_msg = project_repair(project_dir)

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
        reinitialize = input(['Re-initialize project in this directory anyway? This will recreate ' ...
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
    chkdir = load(dir_matfile);
    if ~strcmp(chkdir.project_dir, project_dir)
        bad_dir_matfile = true;
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
if ~isfolder(default.RECONSTRUCTION_DIR)
    mkdir(default.RECONSTRUCTION_DIR)
    added_entities{end + 1} = sprintf('+ %s', default.RECONSTRUCTION_DIR);
end

newline_after_count = 3;
print_project_path = '';

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
    print_project_path = sprintf('+ %s\n', strrep(project_dir, '\', '\\'));
end

if ~isempty(added_entities)
    fprintf('%s\n', default.CWLINE_STYLE);
end

fprintf(print_project_path)
for i = 1 : numel(added_entities)
    fprintf('%-30s', added_entities{i});
    if mod(i, newline_after_count) == 0 && i ~= numel(added_entities)
        fprintf('\n')
    end
end

fprintf('\n%s\n', default.CWLINE_STYLE);

project_dirs_update(missing_dir_lines(i), relocated_dir);

fprintf('Finished. Repair Status: %s\n', ...
    project_dir, status_msg)

end