% Add to path, add the toolbox path to defaults.m, and generate
% `project_dirs.mat` file. This should be the very first script to run
% after downloading the toolbox if you intend to use it anywhere on your
% system. Only call it from within the toolbox and nowhere else.
% Additionally, paths in project_dirs.mat will be verified and missing
% paths will have to be relocated (or deleted).

clear
close all

disp('=====================================================================================================')
disp('|           VIRTUAL-CAMERA (MIRROR) BASED 3D RECONSTRUCTION WITH NON-LINEAR LEAST SQUARES           |')
disp('=====================================================================================================')
disp('|                   Intended for use with DLTdv8a and Bouguet Calibration Toolbox                   |')
disp('|                           Supports up to 3 views : 1 camera, 2 mirrors                            |')
disp('=====================================================================================================')

% This script might be called from outside the toolbox directory. Since
% the user is supposed to be inside the toolbox directory, if we have the
% toolbox on path, we can actually save the launchtime directory, jump to
% the toolbox directory, and then jump back.

% We prompt before doing the jump, just in case
LAUNCHTIME_DIR = pwd;
announcements = {};

% Check if toolbox already exists on MATLAB path.
matlab_path = path();
paths = strsplit(matlab_path, ';');
curr_toolbox_matlab_path = '';

for i = 1 : numel(paths)

    [~, dirname] = fileparts(paths(i));
    if ~strcmp(dirname, 'Mirror Assisted Reconstruction Toolbox')
        continue
    end

    curr_toolbox_matlab_path = paths{i};

    if ~isfolder(curr_toolbox_matlab_path)
        fprintf(['A previous iteration of the Mirror Reconstruction Toolbox is on MATLAB path, ' ...
            'but the directory does\nnot exist:\n\t%s\n\n'], curr_toolbox_matlab_path ...
        )

        while true
            choice = input('[PROMPT] Reset path and reinitialize to current directory? (y/n): ', 's');
            if ~ismember(choice, {'y', 'n'})
                fprintf(['\n[BAD INPUT] Only "y" (yes) and "n" (no) are accepted inputs (w/o quotes).' ...
                    'Please try again.\n'] ...
                )
                continue
            end
            break
        end

        if choice == 'y'
            rmpath(curr_toolbox_matlab_path);
            curr_toolbox_matlab_path = '';
        else
            error(sprintf(['Operation canceled by user.\nIt is still recommended to remove the faulty path ' ...
                'manually as the toolbox will not function till then.']))
        end

    else
        announcements{end + 1} = '- Mirror reconstruction toolbox already in MATLAB path.';
    end

    break

end

% If the toolbox does exist on MATLAB and path and the working directory
% is not the toolbox directory, ask the user to jump to it directly.
if ~isempty(curr_toolbox_matlab_path) && ~strcmp(curr_toolbox_matlab_path, LAUNCHTIME_DIR)
    while true
        fprintf('HELP: Mirror Reconstruction Toolbox is already on the MATLAB path.\n')
        jump_to_dir = input('[PROMPT] Jump to its directory? Will jump back once done (y/n): ', 's');
        if ~ismember(jump_to_dir, {'y', 'n'})
            fprintf('\n[BAD INPUT] Only "y" (yes) and "n" (no) are accepted inputs. Please try again.\n')
            continue
        end
        break
    end
    if jump_to_dir == 'y'
        fprintf('\n...temporarily changing CWD to MATLAB toolbox path...\n\n');
        cd(curr_toolbox_matlab_path);
    else
        error('Please move to the toolbox directory before attempting toolbox initialization.')
    end
end

% Confirm from the user if they are in the project directory.
if isempty(curr_toolbox_matlab_path)
    while true
        user_in_toolbox_dir = input(['[PROMPT] Are you currently in the mirror reconstruction toolbox' ...
            ' source directory? (y/n): '], 's');
        if ~ismember(user_in_toolbox_dir, {'y', 'n'})
            fprintf('\n[BAD PROMPT] Only "y" (yes) and "n" (no) are accepted inputs. Please try again.\n')
            continue
        end
        break
    end
    if user_in_toolbox_dir == 'n'
        error('Please move to the toolbox directory manually before attempting toolbox initialization.')
    end
end

% Assuming current directory is toolbox path.
curr_dir = pwd;
if ~isfile(fullfile(curr_dir, 'defaults.m'))
    error(['An important toolbox script (%s) does not exist in the current directory. Please ensure you ' ...
        'are in the\ntoolbox source directory. If you are sure that is not the issue, consider ' ...
        'creating a fresh clone of the Mirror\nReconstruction Toolbox from GitHub.'], 'defaults.m' ...
    )
end

toolbox_dir = curr_dir;

if ~isempty(curr_toolbox_matlab_path) && strcmp(curr_toolbox_matlab_path, toolbox_dir)
    fprintf(['NOTE: Since the toolbox already exists on the path, you are likely trying to (1) ' ...
        'recreate missing\ninitialization files, or (2) reset the path. Note that the latter does ' ...
        'not affect the file containing\nexisting project paths (project_dirs.m), which may only be ' ...
        'deleted manually.\n\n'])

    while true
        choice = input('[PROMPT] Enter 1 or 2 corresponding to your desired operation: ');
        if ~ismember(choice, [1 2])
            fprintf('\n[BAD INPUT] Only "1" or "2" (w/o quotes) are accepted inputs. Please try again.\n')
            continue
        end
        break
    end
    if choice == 2
        rmpath(curr_toolbox_matlab_path);
        delete toolbox.mat
        fprintf(['\nPaths have been reset. The script will now exit.\nYou can initialize the toolbox ' ...
            'again by moving to its directory and running:\n\t"setup_mirror_reconstruction_toolbox.m"\n\n'] ...
        )
        cd(LAUNCHTIME_DIR)
        return
    end

end

% If toolbox was not already on path, add it to path and save it.
if isempty(curr_toolbox_matlab_path)
    path(toolbox_dir, matlab_path);
    savepath
    announcements{end + 1} = '+ Added mirror reconstruction toolbox to MATLAB path.';
end

% Save the toolbox's directory as a loadable variable on the path.
if ~isfile('toolbox.mat')
    TOOLBOX_MATLAB_PATH = toolbox_dir;
    save('toolbox.mat', 'TOOLBOX_MATLAB_PATH');
    announcements{end + 1} = '+ Created matfile "toolbox.mat" to store toolbox path.';
else
    toolbox = load('toolbox.mat');

    if ~strcmp(toolbox_dir, toolbox.TOOLBOX_MATLAB_PATH)
        announcements{end + 1} = ['o Toolbox Path File (toolbox.mat): Updated to match the current ' ...
            'toolbox path.'];
    else
        announcements{end + 1} = ['- Toolbox Path File (toolbox.mat): Unchanged as it already exists ' ...
            'and the toolbox paths match.'];
    end

end

% Create the project file if it does not exist, but write nothing to it.
if ~isfile('project_dirs.m')
    project_dirs_file = fopen('project_dirs.m', 'w');
    fclose(project_dirs_file);
    announcements{end + 1} = '+ Created m-script "project_dirs.m" to keep track of project locations.';
else
    announcements{end + 1} = '- Project Paths (project_dirs.m): Unchanged as it already exists.';
end

fmt = ['\nMirror Reconstruction Toolbox initialized:\n\t' repmat('%s\n\t', 1, numel(announcements) - 1), '%s\n\n'];
fprintf(fmt, announcements{:});

% Head back to the launchtime directory.
if ~strcmp(LAUNCHTIME_DIR, toolbox_dir)
    fprintf('...changing CWD back to the original directory...\n\n');
    cd(LAUNCHTIME_DIR)
end

fprintf('NEXT STEPS:\n- Move to any directory and call `project_setup.m` to begin.\n\n')