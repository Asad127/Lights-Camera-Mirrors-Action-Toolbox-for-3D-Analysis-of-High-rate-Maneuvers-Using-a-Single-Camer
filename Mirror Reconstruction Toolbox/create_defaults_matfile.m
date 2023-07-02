function create_defaults_matfile(project_dir)
% Create in a function to prevent current script workspace from leaking
% into the defaults workspace.

if nargin == 0
    project_dir = pwd;
end

% Exclude variable project_dir using regular expression pattern.
exclude_var = '^(?!project_dir$).*$';

run('defaults.m');  % load default values in function workspace
save(fullfile(project_dir, 'defaults.mat'), '-regexp', exclude_var)

end