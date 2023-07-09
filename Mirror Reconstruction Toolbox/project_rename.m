% Rename an existing project. 90% of this script is just input and matching
% with the list of existing projects. The project to be renamed may be
% identified with the line number in "project_dirs.m", the absolute path to
% its directory, or the name of the project (last component of absolute
% path).

CW_MAX_DISPLAYABLE_PROJECTS = 50;

[~, ~, project_dirs] = project_dirs_read();
num_projects = numel(project_dirs);

if num_projects < CW_MAX_DISPLAYABLE_PROJECTS
    numbered_list = num2cell(1 : 1 : num_projects);
    numbered_projects = cell(1, num_projects);
    for i = 1 : num_projects
        numbered_projects{i} = sprintf('%d: %s', numbered_list{i}, project_dirs{i});
    end
    fmt = [ ...
        'Existing projects in format (line number : project dir):\n\t', ...
        repmat('%s\n\t', 1, num_projects - 1), ...
        '%s\n'
    ];
    fprintf(fmt, numbered_projects{:})
else
    fprintf(['Too many existing projects to display in command window. Go to toolbox directory, ' ...
        'open "project_dirs.m",\n and note either the line number, name, or path of the project you ' ...
        'want to rename from there.\n'])
end

% Prompt either the line number (in "project_dirs.m") and allow switch to 
% UI to get the directory of the project that we want to rename.
fprintf(['\nHELP: Identify an existing project in "project_dirs.m" by providing one of:' ...
    '\n\t- Line Number: The line number corresponding to a project entry in "project_dirs.m", e.g., 1' ...
    '\n\t- Absolute Path: The full path to the project directory, as in "project_dirs.m", e.g., D:\\checker' ...
    '\n\t- Name: The last directory in absolute path of the project in "project_dirs.m", e.g., checker\n'] ...
)

% Parse inputs and match project identifiers supplied by the user
while true
    switchback = false;
    target_project_identifier = input(['[PROMPT] Enter project identifier here (blank = use UI to ' ...
        'locate dir): '], 's' ...
    );
    fprintf('\n')
    if isempty(target_project_identifier)  % switch to UI
        fprintf('...switching to UI input...\n')
        while true
            target_project_identifier = uigetdir('', ['Choose project directory to rename (cancel = ' ...
                'enter line numbers instead)'] ...
            );

            if ~target_project_identifier
                switchback = true;
                break
            end

            % Parse UI input.
            % Check if selected directory is an existing project path.
            fprintf('Matching identifier with existing projects in "project_dirs.m"...\n')
            [target_line_num, target_line, ~, ~, project_dirs] = project_dirs_match(target_project_identifier);
            if ~target_line_num
                fprintf( ...
                    ['[BAD IPUT] Selected directory is not recorded as a project path in "project_dirs.m".' ...
                    '\nVerify and try again.\n\n'] ...
                );
                continue
            end
            break
        end
    
    % Parse command window input.
    else
        fprintf('Matching identifier with existing projects in "project_dirs.m"...\n')
        
        target_line_num = str2double(target_project_identifier);
        % If input is convertible to numeric, then it's a line number.
        if ~isnan(target_line_num)

            % Check if the line number exceeds the number of projects. This
            % functionality is included in project_dirs_match, but it's
            % faster to just do it here.
            if target_line_num > num_projects
                fprintf(['[BAD INPUT] Line number (%d) exceeds total number of existing projects (%d) in ' ...
                    '"project_dirs.m."\nPlease select a valid line number and try again.\n\n'], ...
                    target_line_num, num_projects ...
                )
                continue
            end
            break

        % Otherwise, assume it is either a name or a full directory.
        else
            [target_line_num, ~, ~, ~, ~] = project_dirs_match(target_project_identifier);
            if ~target_line_num
                fprintf(['[BAD INPUT] Provided name/directory does not exist in "project_dirs.m". Please ' ...
                    'verify and try again.\n\n'])
                continue
            end
        end
        target_project_identifier = project_dirs{target_line_num};  % get corresponding project directory
    end
    
    % Switch back to command window and line number input.
    if switchback
        fprintf('...switching to Command Window input...')
        continue
    end
    break
end

fprintf('Match found:\n\t@ Line %d in "project_dirs.m": %s\n\n', target_line_num, ...
    project_dirs{target_line_num} ...
)

% Begin renaming process
[curr_project_parents, curr_project_name] = fileparts(target_project_identifier);
fprintf('Current Project Name: %s\n', curr_project_name)

while true
    new_project_name = input('[PROMPT] Enter the new project name: ', 's');
    if isempty(new_project_name)
        fprintf('Project name cannot be blank, please try again.\n')
        continue
    end
    % Check for duplicates.
    [duplicate_line_num, duplicate_line, ~, ~, ~] = project_dirs_match(new_project_name);
    if duplicate_line_num ~= 0  % equivalent to "if duplicate_line_num"
        fprintf(['[BAD INPUT] Project with the same name already exists at:\n\t%s\n\t@ Line ' ...
            '%d in "project_dirs.m": %s\nPlease try again with a unique name.\n'], ...
            project_dirs{duplicate_line_num}, duplicate_line_num, duplicate_line{1} ...
        )
        continue
    end
    break
end

new_project_dir = fullfile(curr_project_parents, new_project_name);

% Update project paths file.
project_dirs_update(target_line_num, new_project_dir)

% Rename project
movefile(target_project_identifier, new_project_dir);  

% Create a new project_dir.mat file within the renamed project directory to
% reflect the name change.
project_dir = new_project_dir;
save(fullfile(new_project_dir, 'project_dir.mat'), 'project_dir')  % replaces existing