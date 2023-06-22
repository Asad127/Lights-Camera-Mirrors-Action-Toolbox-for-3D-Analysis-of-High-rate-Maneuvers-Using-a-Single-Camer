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
fprintf('Beginning mirror reconstruction toolbox initialization.\n')

% This script might be called from outside the toolbox directory. Since 
% the user is supposed to be inside the toolbox directory, if we have the
% toolbox on path, we can actually save the launchtime directory, jump to
% the toolbox directory, and then jump back. 

% We prompt before doing the jump, just in case 
LAUNCHTIME_DIR = pwd;
added_entities = {};

% Check if toolbox already exists on MATLAB path.
matlab_path = path();
paths = strsplit(matlab_path, ';');
curr_toolbox_matlab_path = '';
for i = 1 : numel(paths)
    [~, dirname] = fileparts(paths(i));
    if ~strcmp(dirname, 'mirror_reconstruction_toolbox')
        continue
    end
    curr_toolbox_matlab_path = paths{i};
    added_entities{end + 1} = '- Mirror reconstruction toolbox already in MATLAB path.';
    break
end

% If the toolbox does exist on MATLAB and path and the working directory
% is not the toolbox directory, ask the user to jump to it directly. 
% Prompt is just in case the toolbox path ahs been changed, the user is
% already in the new path and trying to update the path to the toolbox.
if ~isempty(curr_toolbox_matlab_path) && ~strcmp(curr_toolbox_matlab_path, LAUNCHTIME_DIR)
    while true
        jump_to_dir = input('Toolbox already on MATLAB path. Do you want to jump to its directory? (y/n): ', 's');
        if ~ismember(jump_to_dir, {'y', 'n'})
            fprintf('[BAD PROMPT] Only "y" (yes) and "n" (no) are accepted inputs. Please try again.\n')
            continue
        end
        break
    end
    if jump_to_dir == 'y'
        fprintf('...temporarily changing CWD to MATLAB toolbox path...\n');
        cd(curr_toolbox_matlab_path);
    else
        error('Please move to the toolbox directory manually before attempting toolbox initialization.')
    end
end

% Confirm from the user if they are in the project directory.
if isempty(curr_toolbox_matlab_path)
    while true
        user_in_toolbox_dir = input(['[PROMPT] Are you currently in the mirror reconstruction toolbox' ...
            ' source directory? (y/n): '], 's');
        if ~ismember(user_in_toolbox_dir, {'y', 'n'})
            fprintf('[BAD PROMPT] Only "y" (yes) and "n" (no) are accepted inputs. Please try again.\n')
            continue
        end
        break
    end
    if user_in_toolbox_dir == 'n'
        error('Please move to the toolbox directory manually before attempting toolbox initialization.')
    end
end

curr_dir = pwd;

if isempty(curr_toolbox_matlab_path)
    path(curr_dir, matlab_path);
    added_entities{end + 1} = '+ Added mirror reconstruction toolbox to MATLAB path.';
end

% Save the toolbox's directory as a loadable variable on the path.
if ~isfile('toolbox_dir.mat')
    TOOLBOX_MATLAB_PATH = curr_dir;
    save('toolbox_dir.mat', 'TOOLBOX_MATLAB_PATH');
end

if ~isfile('project_dirs.m')
    % Create the project file if it does not exist, but write nothing to it.
    project_dirs_file = fopen('project_dirs.m', 'w');
    fclose(project_dirs_file);
    added_entities{end + 1} = [ ...
        '+ Project Paths (project_dirs.m): Created an m-script for ' ...
        'keeping track of project locations.' ...
    ];
else
    while true
        verify_project_dirs_file = input(['[PROMPT] Project Paths (project_dirs.m) already exists. ' ...
            'Verify paths? (y/n): '], 's' ...
        );
        if ~ismember(verify_project_dirs_file, {'y', 'n'})
            fprintf('[BAD PROMPT] Only "y" (yes) and "n" (no) are accepted inputs. Please try again.\n')
            continue
        end
        break
    end

    if verify_project_dirs_file == 'n'
        added_entities{end + 1} = '- Project Paths (project_dirs.m): Unchanged as it already exists.';
    else
        [project_dirs, missing_dirs, missing_dir_lines] = project_dirs_verify();

        % No missing projects, good to go!
        if numel(missing_dirs) == 0
            added_entities{end + 1} = ['+ Project Paths (project_dirs.m): Verified existing project ' ...
                'paths. None missing!'
            ];
                
        
        % Either relocate or delete missing projects.
        else
            while true
                relocate = input(['[PROMPT] Relocate missing projects? (y/n, n = delete from project ' ...
                    'paths list): '], 's');
                if ~ismember(relocate, {'y', 'n'})
                    fprintf(['[BAD PROMPT] Only "y" (yes) and "n" (no) are accepted inputs. Please try ' ...
                        'again.\n'])
                    continue
                end
                break
            end 
    
            if relocate == 'n'
                project_dirs_delete(missing_dir_lines)  % delete the relevant rows
                added_entities{end + 1} = ...
                    '+ Project Paths (project_dirs.m): Verified and deleted missing project directories.';
            
            else
                % Make a copy of missing lines. In the copy, we will delete
                % lines corresponding to relocated dirs AFTER all the 
                % missing directories have been accounted for. Once we're
                % done, all the un-relocated project dirs w ill be deleted.
                %
                % We can't delete WITHIN the loop since that would mean the 
                % indices corresponding to different line numbers change, 
                % and we don't want to get into that mess.
                lines_to_delete = missing_dir_lines;
                dirs_to_delete = missing_dirs;
                for i = 1 : numel(missing_dirs)
                    delete_this_path = false;
                    fprintf('Relocating "%s"...\n', missing_dirs{i});
                    while true
                        relocated_dir = uigetdir( ...
                            '', ...
                            sprintf('Relocate "%s" (cancel = delete this project path)', missing_dirs{i}) ...
                        );
        
                        if ~relocated_dir
                            delete_this_path = true;
                            break
                        end

                        status = project_repair(relocated_dir);
                        if strcmp(status, 'Repairs canceled, nothing changed.')
                            % If user cancels the operation, means they might
                            % want to reselect the directory for this path.
                            fprintf('Reattempting relocation of "%s"...\n', missing_dirs{i})
                            continue
                        end
                    end
                    % Delete path if not relocating.
                    if delete_this_path
                        fprintf('Relocation for %s was canceled, keeping it to delete.\n', missing_dirs{i})
                        continue
                    end
                    % Update the old directory path with the new one. Only do
                    % this if not deleting, obviously, which is why this is
                    % after all the conditionals that continue. Remove it from
                    % missing files list as well.
                    fprintf(['Relocation successful.\nOld Path: %s\nNew Path: %s\n"project_dirs.m" ' ...
                        'updated accordingly.'], missing_dirs{i} ...
                    )
                    lines_to_delete(i) = [];
                    dirs_to_delete(i) = [];
                    project_dirs_update(missing_dir_lines(i), relocated_dir);
                end
                % Delete those still missing (relocation canceled for these).
                fprintf('Deleted the following project directories from file:\n\t');
                fprintf([repmat('%s\n\t', 1, numel(dirs_to_delete)) '%s\n'], dirs_to_delete{:})
                added_entities{end + 1} = '+ Verified and relocated/deleted project directories.';
                project_dirs_delete(lines_to_delete);
            end
        end
    end
end

% Head back to the launchtime directory.
if ~strcmp(LAUNCHTIME_DIR, curr_dir)
    fprintf('...changing CWD back to the original directory...\n');
    cd(LAUNCHTIME_DIR)
end

fmt = ['Mirror Reconstruction Toolbox initialized:\n\t' repmat('%s\n\t', 1, numel(added_entities) - 1), '%s\n'];
fprintf(fmt, added_entities{:});
fprintf('Next Steps: Move to any directory and call `project_setup.m` to begin!\n') 