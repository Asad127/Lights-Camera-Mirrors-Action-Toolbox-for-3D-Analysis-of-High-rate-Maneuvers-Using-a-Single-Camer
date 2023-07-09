function recover_defaults_mfile(project_dir)
% Reset the state of the defaults.m file to the global one defined
% in the toolbox path.

if nargin == 0
    project_dir = pwd;
end

toolbox = load('toolbox.mat');

copyfile(fullfile(toolbox.TOOLBOX_MATLAB_PATH, 'defaults.m'), fullfile(project_dir, 'defaults.m'))

if nargin == 0
    fprintf(['Recovered "defaults.m" from toolbox path into local project directory.' ...
        '\n\t%-11s: %s\n\t%-11s: %s\n'], ...
        'Source Path', fullfile(toolbox.TOOLBOX_MATLAB_PATH, 'defaults.m'), ...
        'Destination', fullfile(project_dir, 'defaults.m') ...
    )
end

end