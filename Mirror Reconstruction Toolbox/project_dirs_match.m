function [matched_line_nums, matched_lines, projects_file_lines, ...
    project_vars, project_dirs] = project_dirs_match(project_identifier)

% Given a project identifier, this function matches it to an existing
% project path in `project_dirs.m` in the toolbox's source directory and
% returns the corresponding line number(s), line(s), along with the three
% outputs of `project_dirs_read.m`, i.e., the textscan of "project_dirs.m",
% and the split components on each of its lines: project_vars (name of 
% variable containing the absolute path) and project_dirs (absolute path to 
% project directory).
%
% This is helpful for a number of path-related operations. Further, the
% reason for returning the outputs of `project_dirs_read.m` is to ensure
% misinputs don't happen. Also note that line numbers are accepted as
% identifiers and the script checks if the provided line number exceeds the
% total lines in `project_dirs.m`.
%
% TAKES 
% =====
% project_identifier:
%   The line number, project name, or directory path in `project_dirs.m` 
%   that identifies the project directory. May also be a cell array where 
%   all elements represnent either numerics or chars. Note for cell array 
%   inputs, no distinction is required between directories and names as the 
%   implementation checks for both by first treating input as an absolute 
%   path, and only if that fails, as the project name.
%
% RETURNS
% =======
% matched_line_nums (scalar or vector):
%   The line numbers in "project_dirs.m" that match the project identifier.
%   Is 0 if no matches are found.
% matched_lines (cell array):
%   Contents of the matched lines. If input is a single project identifier,
%   then this is a 1x1 cell containing the corresponding line from
%   "project_dirs.m". Otherwise, it's a cell vector containing all lines
%   corresponding to the cell array of project identifiers at input. Is
%   empty if no matches are found.
% projects_file_lines:
%   The lines of the project as a cell vector with each line represented as
%   an element of the cell.
% project_vars:
%   The variables that contain the project directories. Part of the
%   variable name is created with the project's name, which is the last
% project_dirs:
%   The absolute paths to the project directories.

% Read all the lines and get the one corresponding to the line number.
[projects_file_lines, project_vars, project_dirs] = project_dirs_read();
num_projects = numel(project_dirs);

% Get line number based on the type of input. If numeric and less than the 
% number of existing projects, set it equal to the target line number.
if isa(project_identifier, 'numeric')
    matched_line_nums = project_identifier;
    if matched_line_nums > num_projects
        error('Line number, %d, exceeds total number of existing projects, %d, in "project_dirs.m."', ...
            matched_line_nums, num_projects ...
        )
    end

% If user provides a character vector, it may be either a name or a dir. 
% Compare against each existing project directory line-by-line. If at any 
% given path, the user input is not matched to a directory, try matching it
% using the name as the reference instead before moving to the next path. 
% Grab the line number of the path where it matches.
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
        matched_line_nums = i;
        break
    end

    if ~found_project_dir
        matched_line_nums = 0;
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
        matched_line_nums = cell2mat(project_identifier);
        for i = 1 : numel(matched_line_nums)
            if matched_line_nums(i) > num_projects
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
        matched_line_nums = zeros(1, numel(project_identifier));
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
                matched_line_nums = 0;
            end
            matched_line_nums(i) = curr_line;
        end
    end

else
    error(['Unexpected type for argument "project_identifier".\nExpected either a char, numeric, or ' ...
        'a cell containing chars or numerics, got %s instead.'], class(project_identifier) ...
    );
end

% If no matches were found, matched_line_nums is 0, and on that basis, we
% will set matched_lines to an empty character as well.
if ~matched_line_nums
    matched_lines = '';
    return
end

% If we did find a match or matches, we grab the corresponding lines from
% the matfile.
matched_lines = projects_file_lines(matched_line_nums);

end