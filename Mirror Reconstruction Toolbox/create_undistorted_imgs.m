% Script version of the function undistort_imgs.

default = load('defaults.mat');

OUTPUT_FOLDER_LABELS = {'cam_rect' 'mir1_rect' 'mir2_rect'};

img_filter = cellfun(@(extension) ['*' extension], default.SUPPORTED_IMG_EXTS, 'UniformOutput', false)';

if ~exist('img_filepaths', 'var')  % carries over from `import_media.m`
    while true
        dir_or_files = input(['[PROMPT] Undistort (1) an entire directory of images, or (2) just a ' ...
            'few images? (1 or 2): ']);
        if ~ismember(dir_or_files, [1, 2])
            fprintf('[BAD INPUT] Only 1 or 2 are accepted values. Please try again.\n')
            continue
        end
        break
    end
else
    dir_or_files = 2;
end

if dir_or_files == 1

    imgs_dir = uigetdir('', 'Choose the directory containing the images');

    if ~imgs_dir
        error('Operation canceled by user.')
    end

    % Either ask the user to input image extension, or guess it based on
    % directory contents.
    if default.GUESS_IMG_EXT_WHEN_POSSIBLE
        img_extension = guess_img_extension(imgs_dir, default.SUPPORTED_IMG_EXTS);
        fprintf('Guessed Image Extension: %s\n\n', img_extension)
    else
        img_extension = prompt_img_extension('[PROMPT] Enter the extension of images to undistort: ');
    end

    % Read all image files from the directory.
    img_filepaths = dir(fullfile(imgs_dir, ['*' img_extension]));

    % Get the basenames of the image files and convert from dir struct
    % to standard fullfile format of filepaths (cell row vector).
    img_filepaths = fullfile(imgs_dir, {img_filepaths.name});

    % Sort them to maintain correct sequential ordering.
    if default.FEX_USE_NATSORT
        img_filepaths = natsortfiles(img_filepaths);
    else
        [~, img_basenames, ~] = fileparts(img_filepaths);
        [~, sorted_indices] = sortfiles_formatted(img_basenames);
        img_filepaths = img_filepaths(sorted_indices);
    end

else
    if ~exist('img_filepaths', 'var')  % carries over from `import_media.m`
        [input_imgs, imgs_dir] = uigetfile( ...
            img_filter, ...
            'Select the images to undistort (CTRL + A to select all)', ...
            'MultiSelect', 'on' ...
        );
        if ~isa(input_imgs, 'cell')
            if ~input_imgs
                error('Operation canceled by user.')
            end
            input_imgs = cellstr(input_imgs);  % force single selection to cell
        end
        img_filepaths = cellfun(@(file) fullfile(imgs_dir, file), input_imgs, 'UniformOutput', 'false');
    end
end

num_imgs = numel(img_filepaths);

fprintf('Loading merged BCT calibration parameters file...')
[merged_calib_file, merged_calib_dir] = uigetfile( ...
    ['*' default.BCT_EXT], ...
    'Select the merged BCT calibration parameters file (cancel = use default location)' ...
);

if ~merged_calib_file
    merged_calib_filepath = default.BCT_MERGED_CALIB_PATH;
    if ~isfile(merged_calib_filepath)
        error(['Merged BCT calibration parameters file does not exist at default location:' ...
            '\n\t%s\nPossible Issues:' ...
            '\n\t(1) Merged BCT calibration file was not saved to the default location.' ...
            '\n\t(2) Merged BCT calibration file was not created.' ...
            '\nPossible Solutions:' ...
            '\n\t(1) Use the UI to locate the file wherever it was saved.' ...
            '\n\t(2) Run "calib_process_results.m" before running this script.'], ...
            merged_calib_filepath ...
        )
    end
else
    merged_calib_filepath = fullfile(merged_calib_dir, merged_calib_file);
end

view_params = load(merged_calib_filepath);
view_labels = view_params.view_labels;
view_names = default.VIEW_NAMES_LONG(view_labels);
fprintf('done.\n')

num_views = numel(view_labels);
undistorted_img_folders = default.UNDISTORTED_IMG_FOLDERS(view_labels);

total_imgs = num_views * num_imgs;
img_counter = 1;

st = dbstack;
bar = waitbar( ...
    0, ...
    sprintf('Undistorting images (%d views): %d/%d', num_views, img_counter, total_imgs), ...
    'Name', st(1).name ...
);

fprintf('%d image(s) over %d views ==> %d * %d = %d undistortions.\n\n', ...
    num_imgs, num_views, num_imgs, num_views, total_imgs ...
)

for j = 1 : num_views
    k = view_labels(j);
    dist_coefs = view_params.(sprintf('kc_%d', k));
    intrinsics = view_params.(sprintf('KK_%d', k));

    fprintf('|-- View No. %d/%d - Undistorting w.r.t %s View --|\n', j, num_views, view_names{j})

    undistorted_imgs_dir = fullfile(imgs_dir, undistorted_img_folders{j});
    
    if ~isfolder(undistorted_imgs_dir)
        mkdir(undistorted_imgs_dir);
    end

    fprintf('Undistorting %d image(s)...', num_imgs);
    for i = 1 : num_imgs

        img = imread(img_filepaths{i});
        dims = size(img);

        if ndims(img) == 2
            % Image is grayscale.
            undistorted_img = undistort_img_gray(img, dist_coefs, intrinsics);
        elseif ndims(img) == 3 && dims(3) == 3
            % Image is RGB.
            undistorted_img = undistort_img(img, dist_coefs, intrinsics);
        end

        [~, img_name, img_ext] = fileparts(img_filepaths{i});

        % Creating a filepath.
        undistorted_img_file = [img_name img_ext];
        undistorted_img_filepath = fullfile(undistorted_imgs_dir, undistorted_img_file);

        imwrite(undistorted_img, undistorted_img_filepath);

        waitbar( ...
            img_counter/total_imgs, ...
            bar, ...
            sprintf('Undistorting images (%d views): %d/%d', num_views, img_counter, total_imgs) ...
        );

        img_counter = img_counter + 1;
    end
    fprintf('done.\n\t%-20s: %s\n\t%-20s: %s\n\n', ...
        'Source Imgs Dir', imgs_dir, ...
        'Undistorted Imgs Dir', undistorted_imgs_dir ...
    )
end

waitbar( ...
    1, ...
    'Finished!' ...
);
pause(1);
close(bar)

if dir_or_files == 1
    fprintf('All selected images have been undistorted w.r.t. all %d views.\n\n', num_views)
elseif dir_or_files == 2
    fprintf('All images in the directory have been undistorted w.r.t. all %d views.\n\n', num_views)
end

fprintf(['\nNEXT STEPS: Manually Marking Points For Reconstruction\n\n- Run "point_marker.m" and ' ...
    'mark target points on object of interest over all views in a single image.\n\n'] ...
)