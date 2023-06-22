function project_dirs_delete(project_identifier)
% This function deletes the relevant lines corresponding to project paths
% from `project_dirs.m`. The relevant projects may be in various formats.
% 90% of the code is just input checks. If anything fails, an error is
% thrown and nothing is deleted.
%
% TAKES 
% =====
% project_identifier:
%   The line number, project name, or directory path in `project_dirs.m` 
%   that identifies the project directoru to delete. May also be a cell
%   array where all elements represnent either numerics or chars. Note for
%   cell array inputs, no distinction is required between directories and
%   names as the implementation checks for both by first treating input as
%   an absolute path, and only if that fails, as the project name.
%
% RETURNS
% =======
% Nothing. It simply modifies `project_dirs.m` in the toolbox path.

switch nargin
    case 0
        err_msg = [ ...
            'Require the line number (from "project_dirs.m") corresponding to the project directory' ...
            'to update, \nOR the project name (i.e., the last part of its directory path).' ...
            '\nRequire the updated path for the project.' ...
        ];
        error(err_msg)
end

% Assumed in toolbox path, this contains the MATLAB path of the toolbox. It
% is auto generated upon running `setup_mirror_reconstruction_roolbox.m`.
toolbox = load('toolbox_dir.mat');  

% Read all the lines and get the one corresponding to the line number.
[projects_file_lines, ~, project_dirs] = project_dirs_read();
num_projects = numel(project_dirs);

% Get line number based on the type of input. If numeric and less than the 
% number of existing projects, set it equal to the target line number.
if isa(project_identifier, 'numeric')
    missing = project_identifier;
    if missing > num_projects
        error('Line number, %d, exceeds total number of existing projects, %d, in "project_dirs.m."', ...
            missing, num_projects ...
        )
    end

% If user provdes the directory, compare against each existing project
% directory, and grab the line number of the line where it matches.
elseif isa(project_identifier, 'char')
    found_project_dir = false;
    for i = 1 : numel(project_dirs)
        % Check assuming user gave project directory
        if ~strcmp(project_identifier, project_dirs{i})
            [~, curr_project_name] = fileparts(project_dirs{i});
            % Check assuming user gave project name, not full directory
            if ~strcmp(project_identifier, curr_project_name)
                continue
            end
        end
        found_project_dir = true;
        missing = i;
        break
    end

    if ~found_project_dir
        error('Provided project directory is not in the list of existing project directories.')
    end

elseif isa(project_identifier, 'cell')
    % Check if each element of the cell is either a char or an numeric. We
    % don't need to distinguiish between project names and full dirs, as 
    % the strcmp loop checks first for full dir, and then for project name. 

    % Check all numerics.
    identifier_has_all_numerics = true;
    for i = 1 : numel(project_identifier)
        if ~isa(project_identifier{i}, 'numeric')
            identifier_has_all_numerics = false;
            break
        end
    end

    % Check all chars.
    identifier_has_all_chars = true;
    for i = 1 : numel(project_identifier)
        if ~isa(project_identifier{i}, 'char')
            identifier_has_all_chars = false;
            break
        end
    end
    
    % Did it have neither type for all elements? If so, error out.
    if ~any(identifier_has_all_chars, identifier_has_all_numerics)
        err_msg = sprintf(['Mixed data types in given cell array of project identifiers.\nFunction ' ...
            'expects a cell array containing only numerics or chars, e.g., {1, 5, 7} or {"D:\\project1, ' ...
            '"D:\\project3"}, etc.'] ...
        );
        error(err_msg)
    end
    
    % All elements are numeric, but they are a cell array right now, so we
    % cannot index into the corresponding line numbers. Covert to mat, and
    % check that none of them is a line number beyond the existing lines in
    % `project_dirs.m`, which corresponds to the total number of projects.
    if identifier_has_all_numerics
        missing = cell2mat(project_identifier);
        for i = 1 : numel(missing)
            if missing(i) > num_projects
                err_msg = sprintf(['One (possibly more) elements of the given cell array contain a ' ...
                    'numeric value that references an empty line\nin "project_dirs.m". This usually ' ...
                    'means that the line number was GREATER than the number of existing projects.'] ...
                );
                error(err_msg)
            end
        end
    
    % All elments are chars. Look for matches in `project_dirs.m` and get 
    % the corresponding line numbers in a vector.
    else
        missing = zeros(1, project_identifier);
        % Loop over the identifier cell array.
        for i = 1 : numel(project_identifier)
            found_project_dir = false;
            % Loop over all the existing projects in `project_dirs.m`.
            for j = 1 : num_projects
                % Check, assuming user gave project directory.
                if ~strcmp(project_identifier, project_dirs{i})
                    [~, curr_project_name] = fileparts(project_dirs{i});
                    % Check, assuming user gave project name, not full dir
                    if ~strcmp(project_identifier, curr_project_name)
                        continue
                    end
                end
                % If a match is found, store the current line number, set
                % the found flag, and break out of file searching loop.
                curr_line = j;
                found_project_dir = true;
                break
            end
            % Did we find a match? If no, error out because it was missing.
            % If we did, add the line number to the array of missing
            % project line numbers.
            if ~found_project_dir
                error('One (possibly more) provided project directories/names are not "project_dirs.mat".')
            end
            missing(i) = curr_line;
        end
    end

else
    error(['Unexpected type for argument "project_identifier".\nExpected either a char, numeric, or ' ...
        'a cell containing chars or numerics, got %s instead.'], class(project_identifier) ...
    );
end

% Now we have the line numbers, we can delete the corresponding lines and
% re-write the `project_dirs.m` file.
projects_file_lines(missing) = [];  % delete the relevant rows

% Re-write the file with the updated line.
projects_file = fopen(fullfile(toolbox.TOOLBOX_MATLAB_PATH, 'project_dirs.m'), 'w');
fprintf(projects_file, '%s\n', projects_file_lines{:});

end