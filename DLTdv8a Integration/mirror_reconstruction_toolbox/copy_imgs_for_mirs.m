%% THIS FUNCTION IS UNUSED.

function copy_imgs_for_mirs(directory, num_copies, img_extension)

% Set defaults.

default = load('defaults.mat');

switch nargin
    case 0
        error('Require directory containing images.')
    case 1
        error('Require the numebr of copies to make.')
    case 2
        img_extension = default.IMG_EXT;
end

% Check if num_copies is valid.
if ismember(num_copies, [0 1 2])
    if num_copies == 0
        fprintf('Got 0 for argument `num_copies`, no copies made.\n')
        return
    else
        fprintf('Creating %d copy/copies of all images...', num_copies)
    end
else
    error('Argument `num_copies` accepts only 1 or 2 corresponding to copies for first and second mirrors.')
end

% Get the list of image files in the directory.
file_list = dir(fullfile(directory, ['*.' img_extension]));

% Iterate over the files and create copies.
for i = 1 : numel(file_list)
    file_name = file_list(i).name;
    file_path = fullfile(directory, file_name);
    
    % Extract the base name and extension.
    [~, base_name, extension] = fileparts(file_path);
    
    % Create copies based on the number of copies required.
    for copy_num = 1 : num_copies
        copy_name = sprintf('%s_mir%d%s', base_name, copy_num, extension);
        copy_path = fullfile(directory, copy_name);
        
        % Copy the file.
        copyfile(file_path, copy_path);
    end
end

fprintf('done.\n')
disp('Frame copies created successfully with suffixes of the form _mir1 and so on.')

end
