function [project_dirs, missing_dirs, missing_dir_lines] = project_dirs_verify()
% Verify existence of the paths in `project_dirs.m`.

[~, ~, project_dirs] = project_dirs_read();

missing_dirs = {};       % directory from the project file project_dirs.m
missing_dir_lines = [];  % line in the project file project_dirs.m

% Get the missing directories and their line numbers / indices from the
% `project_dirs.m` file.

for i = 1 : numel(project_dirs)
    p = project_dirs{i};
    if ~isfolder(p)
        missing_dirs{end + 1} = p;
        missing_dir_lines(end + 1) = i;
    end
end

fmt = ['The following project paths do not exist:\n\t' repmat('%s\n\t', 1, numel(missing_dirs) - 1), '%s\n'];
fprintf(fmt, missing_dirs{:});

end