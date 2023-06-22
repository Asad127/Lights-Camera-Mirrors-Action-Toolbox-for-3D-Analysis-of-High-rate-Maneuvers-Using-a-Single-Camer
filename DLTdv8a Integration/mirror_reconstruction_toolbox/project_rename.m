% Rename an existing project.

CW_MAX_DISPLAYABLE_PROJECTS = 15;

[~, ~, project_dirs] = project_dirs_read();
num_projects = numel(project_dirs);

if num_projects < CW_MAX_DISPLAYABLE_PROJECTS
    numbered_list = num2cell(1 : 1 : num_projects);
    numbered_projects = cell(1, num_projects);
    for i = 1 : num_projects
        numbered_projects{i} = sprintf('%d: %s', numbered_list{i}, project_dirs{i});
    end
    fmt = ['Existing projects in format (lineNumber: projectDir):\n\t' repmat('%s\n\t', 1, num_projects - 1), '%s\n'];
    fprintf(fmt, numbered_projects{:})
else
    fprintf(['Too many existing projects to display in command window. Go to toolbox directory, ' ...
        'open "project_dirs.m",\n and note either the line number or the path of the project you ' ...
        'want to rename from there.\n'])
end

% Prompt either the line number (in "project_dirs.m") and allow switch to 
% UI to get the directory of the project that we want to rename.
while true
    switchback = false;
    target_line_num = input(['[PROMPT] Enter the line number of the project you want to rename ' ...
        '(blank = use UI  to locate dir): ']);
    if isempty(target_line_num)
        while true
            curr_project_dir = uigetdir('', ['Choose project directory to rename (cancel = enter line ' ...
                'numbers instead)']);
            if ~curr_project_dir
                switchback = true;
                break
            end
            % Check if selected directory is an existing project path.
            found_project_dir = false;
            for  i = 1 : numel(project_dirs)
                if ~strcmp(curr_project_dir, project_dirs{i})
                    continue
                end
                found_project_dir = true;
                target_line_num = i;
                break
            end
            if found_project_dir
                warn_msg = sprintf( ...
                    ['Selected directory is not recorded as a project path in "project_dirs.m".' ...
                    '\nVerify and try again.\n'] ...
                );
                warning(warn_msg)
            end
        end
    else
        if target_line_num > num_projects
            error('Line number, %d, exceeds total number of existing projects, %d, in "project_dirs.m."', ...
                target_line_num, ...
                num_projects ...
            )
        end
        curr_project_dir = project_dirs{target_line_num};  % get corresponding project directory
    end
    
    % Switch back to command window and line number input.
    if switchback
        continue
    end
    break
end

[curr_project_parents, curr_project_name] = fileparts(curr_project_dir);

fprintf('Current Project Name: %s\n', curr_project_name)

new_project_name = input('[PROMPT] Enter the new project name: ', 's');
new_project_dir = fullfile(curr_project_parents, new_project_name);

% Update project paths file.
project_dirs_update(target_line_num, new_project_dir)

% Rename project
movefile(curr_project_dir, new_project_dir);  

% Create a new project_dir.mat file within the renamed project directory to
% reflect the name change.
project_dir = new_project_dir;
save(fullfile(new_project_dir, 'project_dir.mat'), 'project_dir')  % replaces existing