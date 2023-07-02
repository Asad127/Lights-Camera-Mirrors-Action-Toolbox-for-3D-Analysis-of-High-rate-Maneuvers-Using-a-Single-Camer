%{
Part of: BCT Calibration Prep Scripts (3/3)

This script assumes that you have extracted all the frames from the
calibration video (or some subset of it). 

If this script is called from `calib_extract_vid_frames.m`, variable 
'frames_dir' and 'img_ext' will carry over, in which case we already 
know the directory where frames were extracted and with which extension. 
If this script is run standalone, the user must locate the directory first, 
and the image extension is guessed - first image extension is assumed to be 
the extension for all images and if any file is found whose extension is 
different from the first image's, an error is thrown.

SCRITPS THAT CALL THIS SCRIPT
===========================================================================
+ DIRECTLY
calib_extract_vid_frames.m:
    Extracts the calibration video frames according to some user input 
    such as start and stop times, stored frame img extensions, etc. Then,
    it hands over control to this script to select a subset of calibration
    images.

+ INDIRECTLY
calib_import_media.m:
    If the calibration media is video, imports calibration video into the 
    project folder and converts it to MP4 if needed. Then hands over control
    to `calib_extract_vid_frames.m` for frame extraction, which ultimately 
    calls this script.

FUNCTIONS CALLED
===========================================================================
vid_to_frames.m:
    Extracts video frames based on the arguments provided.

MAJOR DEPENDENCIES
===========================================================================
defaults.m, create_defaults_matfile, and defaults.mat:
    + defaults.m
        contains configurable params as well as constant params.
    + create_defaults_matfile
        creates a "defaults.mat" file using the values defined in `defaults.m`
    + defaults.mat
        defaults.m, but as a .mat file that may be loaded into scripts as a
        struct instead of into the workspace. This lets us load in only the
        defaults required for a script.

    While the default filepaths and directories are completely optional, some
    constants such as supported image extensions, text formats, etc. are 
    required in various scripts. Therefore, it is recommended to at least
    run `create_defaults_matfile.m` prior to running this script.

OPTIONAL DEPENDENCIES
===========================================================================
project_setup.m:
    Creates the project folder with user-specified name and all the
    subdirectories required for this toolbox to function effectively with
    the default file and directory configuration described in `defaults.m`. 
    However, this is only necessary if you wish to use the default structure. 
    These defaults are engaged when a user input is left blank in the command 
    window, or a UI box is canceled. Simply provide the file or directory 
    to avoid using the default.
%}

default = load('defaults.mat');

if isfolder(default.BCT_CALIB_SUBSET_HIST_DIR)
    existing_hist_files = dir(fullfile(default.BCT_CALIB_SUBSET_HIST_DIR, '*.mat'));
    if ~isempty(existing_hist_files)
        while true
            use_older = input('[PROMPT] Re-extract older calibration subset? (y/n): ', 's');
            if ~ismember(use_older, {'y', 'n'})
                fprintf('[BAD INPUT] Unrecognized input. Please enter either "y" or "n" (w/o quotes).')
            end
            break
        end
        if use_older == 'y'
            [older_file, older_dir] = uigetfile( ...
                '*.mat', ...
                'Select an earlier calibration image subset', ...
                default.BCT_CALIB_SUBSET_HIST_DIR ...
            );
            subset_hist = load(fullfile(older_dir, older_file));

            num_calib_imgs = numel(subset_hist.final_calib_img_filepaths);
            [final_calib_imgs_dir, ~, ~] = fileparts(subset_hist.final_calib_img_filepaths{1});

            for i = 1 : num_calib_imgs
                copyfile(subset_hist.img_filepaths{i}, subset_hist.final_calib_img_filepaths{i})
            end

            fprintf('Images are ready for calibration using BCT!\n')
            fprintf('...changing CWD to directory with calibration images...\n')
            cd(default.BCT_CALIB_IMGS_DIR)
            return
            
        else
            fprintf('Not using an older subset. Proceeding as normal.\n')
        end
    end
end

if exist('frame_extension', 'var')
    img_ext = frame_extension;
end

if exist('frames_dir', 'var')
    imgs_dir = frames_dir;
end

fprintf( ...
    ['\n"calib_select_img_subset.m" script is mainly intended to select some extracted frames ' ...
    'from a calibration video, but\nmay be applied to any set of images in a directory. Pick ' ...
    'around 15-30 images/frames for this\nfinal calibration set. Make sure the poses of the ' ...
    'selected frames vary noticeably.\n\n'] ...
);

% Extract subset of frames as the calibration images.
use_ui = true;
switchback = false;

img_filter = cellfun(@(extension) ['*' extension], default.SUPPORTED_IMG_EXTS, 'UniformOutput', false)';

if exist('img_ext', 'var') && exist('imgs_dir', 'var')
    while true
        % We know the specific image format from other script.
        [img_files, ~] = uigetfile( ...
            ['*' img_ext], ...
            'Select subset of calibration images from extracted frames', ...
            imgs_dir, ...
            'MultiSelect', 'on' ...
        );
        if ~isa(img_files, 'cell')
            error('Operation canceled by user.')
        elseif numel(img_files) < default.MIN_CALIB_IMGS
            fprintf('[BAD INPUT] Please provide a minimum of %d images for calibration.', default.MIN_CALIB_IMGS)
        end
        break
    end
else 
    % Don't know image extension specifically, check for all fmts.
    [img_files, imgs_dir] = uigetfile( ...
        img_filter, ...
        'Select subset of calibration images (extension dropdown on bottom-right)', ...
        'MultiSelect', 'on' ...
    );
    [~, ~, img_ext] = fileparts(img_files{1});
end

img_filepaths = fullfile(imgs_dir, img_files);

%% FURTHER PROCESSING 
% Rename images using a basename with a common string part and a unique
% numeric part for BCT. That is, [frame_20, frame_100, frame_60] would be 
% sorted first (uigetfiles does this automatically) to [frame_20, frame_60, 
% frame_100] and then renamed to [Image1, Image2, Image3] and so on.

final_calib_imgs_dir = uigetdir( ...
    '', ...
    'Choose directory to copy subset of calibration images to (cancel = use default location)' ...
);

if ~final_calib_imgs_dir
    final_calib_imgs_dir = default.BCT_CALIB_IMGS_DIR;
    if ~isfolder(final_calib_imgs_dir)
        fprintf( ...
            ['[WARNING] The default directory for calibration images was not found ' ...
            'and had to be created. This likely\nmeans that the project structure ' ...
            'was not setup correctly. Please run `project_setup.m` and\n' ...
            'ensure that the relevant default folder is being created.\n'] ...
        )
        mkdir(final_calib_imgs_dir)
    end
end

final_calib_img_files = cell(1, numel(img_files));
final_calib_img_filepaths = cell(1, numel(img_files));
for i = 1 : numel(img_filepaths)
    % Get one of the selected images
    img_filepath = img_filepaths{i};

    % Define the full path of the destination file where it will be copied
    % to. Renaming happens in this step as well.
    final_calib_img_filepaths{i} = fullfile( ...
        final_calib_imgs_dir, ...
        sprintf( ...
            default.BCT_CALIB_IMGNAME_FMT, ...
            i, ...
            img_ext ...
        ) ...
    );

    % For history saving, grab the saved image's final filename.
    [~, final_calib_img_base, final_calib_img_ext] = fileparts(final_calib_img_filepaths{i});
    final_calib_img_files{i} = fullfile([final_calib_img_base final_calib_img_ext]);
    
    % Copy the original image to calibration image directory with new name.
    copyfile(img_filepath, final_calib_img_filepaths{i});
end

%% History Saving

% Store the subset of selected images for calibration, generally frames from 
% a calibration video, per their original filenames and the renamed ones for
% the final set.
curr_time = datetime('now', 'Format', 'yyyy-MM-dd-HH-mm-ss_');

if ~isfolder(default.BCT_CALIB_SUBSET_HIST_DIR)
    mkdir(default.BCT_CALIB_SUBSET_HIST_DIR)
end

hist_file = sprintf('@%scalib_img_subset%s', curr_time, default.BCT_EXT);
hist_filepath = fullfile(default.BCT_CALIB_SUBSET_HIST_DIR, hist_file);

txthist_file = fopen('.calib_frames.txt', 'w');
fprintf( ...
    txthist_file, ...
    ['[%s]\n\nValues in this file relate the sorted (per uigetfiles), and renamed final set ' ...
    'of\ncalibration images to their original filenames. This is meant purely for debugging.\n\n' ...
    'Original Imgs Dir = %s\nFinal Imgs Dir = %s\n\n' ...
    '%-20s | %-20s || %-20s | %-20s\n'], ...
    datetime('now'), strrep(imgs_dir, '\', '\\'), strrep(final_calib_imgs_dir, '\', '\\'), ...
    'Original Img Name', 'Final Img Name', 'Original Img Name', 'Final Img Name' ...
);

% Combine selected and saved images into a single array, such that
% [originalImg1 finalImg1 originalImg2 finalImg2] and so on.
img_files_together = [img_files; final_calib_img_files];
img_files_together = reshape(img_files_together, 1, []);

% Define the number of elements (as pairs) that we will show on a single
% line. A total of 4 elements means we have 2 pairs of corresponding image
% names. Also, especially for the final batch of elements, it is possible
% we run out of pairs before we finish that line. To account for that, we
% calculate the minimum of the number of elements in the combined array and
% the otherwise complete endpoint assuming full row is filled. That way, we
% keep all 4 wherever possible, and only revert to 2 elements otherwise.
num_elems_per_line = 4;
num_elems_per_line_per_img = 2;
num_elems_total = numel(img_files_together);
num_lines = ceil(numel(img_files) / num_elems_per_line_per_img);
filenames_this_line = cell(1, num_elems_per_line);

for i = 1 : num_lines
    start_idx = num_elems_per_line*(i-1) + 1;
    end_idx = min(i * num_elems_per_line, num_elems_total);

    filenames_this_line(:) = img_files_together(start_idx : end_idx);
    num_elems_this_line = numel(filenames_this_line);

    if num_elems_this_line < num_elems_per_line
        end_idx{1, end_idx : end+(num_elems_per_line - num_elems_this_line) + 2} = '';
    end

    fprintf(txthist_file, '%-20s | %-20s || %-20s | %-20s\n', filenames_this_line{:});
    
    if num_elems_this_line < num_elems_per_line
        fprintf(txthist_file, '\n');
    end
end

fclose(txthist_file);

save(hist_filepath, 'img_filepaths', 'final_calib_img_filepaths');

fprintf('Images are ready for calibration using BCT!\n')
fprintf('...changing CWD to directory with calibration images...\n')
cd(default.BCT_CALIB_IMGS_DIR)