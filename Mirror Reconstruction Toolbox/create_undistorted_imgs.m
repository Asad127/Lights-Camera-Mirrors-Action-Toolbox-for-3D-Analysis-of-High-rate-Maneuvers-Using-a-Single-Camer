% Script version of the function undistort_imgs.

default = load('defaults.mat');

OUTPUT_FOLDER_LABELS = {'cam_rect' 'mir1_rect' 'mir2_rect'};

img_filter = cellfun(@(extension) ['*' extension], default.SUPPORTED_IMG_EXTS, 'UniformOutput', false)';

while true
    dir_or_files = input(['[PROMPT] Would you like to undistort (1) an entire directory of images, ' ...
        'or (2) just a few images? (enter 1 or 2): ']);
    if ~ismember(dir_or_files, {1, 2})
        fprintf('[BAD PROMPT] Only 1 or 2 are accepted values. Please try again.\n')
        continue
    end
    break
end

if dir_or_files == 1
    img_dir = uigetdir('', 'Choose the directory containing the images');
    if ~img_dir
        error('Operation canceled by user.')
    end
    % Either ask the user to input image extension, or guess it based on
    % directory contents.
    img_extension = guess_img_extension(img_dir, default.SUPPORTED_IMG_EXTS);
    fprintf('Guessed Image Extension: %s\n', img_extension)
    
    % Read all image files from the directory.
    img_filepaths = dir(fullfile(img_dir, ['*' img_extension]));

    % Get the basenames of the image files and convert from dir struct
    % to standard fullfile format of filepaths (cell row vector).
    img_filepaths = fullfile(img_dir, {img_filepaths.name});

    % Sort them to maintain correct sequential ordering.
    if default.FEX_USE_NATSORT
        img_filepaths = natsortfiles(img_filepaths);
    else
        [~, img_basenames, ~] = fileparts(img_filepaths);
        [~, sorted_indices] = sortfiles_formatted(img_basenames);
        img_filepaths = img_filepaths(sorted_indices);
    end

else
    [input_imgs, img_dir] = uigetfile( ...
        img_filter, ...
        'Select the images to undistort (CTRL + A to select all)', ...
        'MultiSelect', 'on' ...
    );
    if ~input_imgs
        error('Operation canceled by user.')
    end
    img_filepaths = cellfun(@(file) fullfile(img_dir, file), input_imgs, 'UniformOutput', 'false');
end

[view_params_file, view_params_dir] = uigetfile( ...
    ['*' default.BCT_EXT], ...
    'Select the merged BCT calibration parameters file (cancel = use default location)' ...
);

if ~view_params_file
    view_params_filepath = default.BCT_MERGED_CALIB_PATH;
else
    view_params_filepath = fullfile(view_params_dir, view_params_file);
end

view_params = load(view_params_file);

view_labels = view_params.view_labels;
num_views = numel(view_labels);
output_folders = default.UNDISTORTED_FRAME_FOLDERS{view_labels};

total_imgs = num_views * numel(img_filepaths);
img_counter = 1;

st = dbstack;
bar = waitbar( ...
    0, ...
    sprintf('Undistorting %s-view images: %d/%d', num_views, img_counter, total_imgs), ...
    'Name', st(1).name ...
);

for j = 1 : num_views
    k = view_labels(j);
    dist_coefs = view_params.(sprintf('kc_%d', k));
    intrinsics = view_params.(sprintf('KK_%d', k));

    fprintf('Undistorting %s images...\n', default.VIEW_NAMES_LONG{j})
    
    for j = 1 : numel(img_filepaths)
        img = imread(img_filepaths{j});
        undistorted_img = undistort_img(img);

        [~, img_name, img_ext] = fileparts(img_filepaths{j});
        imwrite(undistorted_img, fullfile(img_dir, output_folders{j}, [img_name '_' output_folders{j} img_ext]));
       
        waitbar( ...
            img_counter/total_imgs, ...
            bar, ...
            sprintf('Undistorting %s-view images: %d/%d', num_views, img_counter, total_imgs) ...
        );
        
        img_counter = img_counter + 1;
    end
    fprintf('done.\n')
end

waitbar( ...
    1, ...
    'Finished!', ...
    'Name', st(1).name ...
);
pause(1);
close(bar);