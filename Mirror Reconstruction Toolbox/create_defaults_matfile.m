function create_defaults_matfile(project_dir)
% Must be called from within a project root directory. 
% Created as a function to prevent current script workspace from leaking
% into the defaults workspace.

if nargin == 0
    project_dir = pwd;
end

% Exclude variable project_dir using regular expression pattern.
exclude_var = '^(?!project_dir$|exclude_var$).*$';

run(fullfile(project_dir, 'defaults.m'));
save(fullfile(project_dir, 'defaults.mat'), '-regexp', exclude_var)

if nargin == 0
    fprintf(['Generated new "defaults.mat" file from local "defaults.m" file.' ...
        '\n\t%-11s: %s\n\t%-11s: %s\n'], ...
        'Source Path', fullfile(project_dir, 'defaults.m'), ...
        'Destination', fullfile(project_dir, 'defaults.mat') ...
    )
end

end