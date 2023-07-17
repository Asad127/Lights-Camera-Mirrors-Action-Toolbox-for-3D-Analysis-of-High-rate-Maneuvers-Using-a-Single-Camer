%{
Part of: BCT Calibration Prep Scripts (1/3)

If you have calibration images, this is the only script you need to run. If 
you have calibration video, this is the first of 3 scripts to fully process
and extract calibration images from video, ready for BCT.

This script assumes that the defaults.mat file has been created, the 
calibration media has not been manually imported into the project, and 
optionally that the project structure has been set up according to defaults 
(only for default pathing). Essentially, this script starts the project 
from scratch. To setup project structure according to defaults, run 
`project_setup.m`.

SCRITPS CALLED
===========================================================================
+ DIRECTLY
calib_extract_vid_frames.m:
    To extract the calibration video frames according to some user input 
    such as start and stop times, stored frame img extensions, etc.

+ INDIRECTLY
calib_select_img_subset.m:
    To choose specific frames from the extracted frames for calibration,
    rename them sequentially, and store them in a separate directory or the
    default directory designated for final set of calibration images.

FUNCTIONS CALLED
===========================================================================
convert_vid_to_mp4.m:
    If the imported calibration video is not an MP4 file but is still one
    of the accepted formats by MATLAB's VideoReader, this function is
    called to re-encode the video as a separate MP4 file. This MP4 video is
    then moved to the porject directory (moved, not copied!)

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
required in various scripts. Therefore, it is recommended to at least run
`create_defaults_matfile.m` prior to running this script.

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

fprintf('Importing calibration media...\n')

while true
    calib_img_or_vid = input( ...
        '[PROMPT] Do you have calibration images or video? ("i" = imgs, "v" = vid): ', 's');
    if ~ismember(calib_img_or_vid, {'i', 'v'})
        fprintf('\n[BAD INPUT] Only "i" and "v" (no quotes) are accepted. Please try again.\n')
        continue
    end
    break
end

if calib_img_or_vid == 'i'

    % Transpose the resulting cell vector to get cell column vectors as 
    % needed by UI filters.
    img_filter = cellfun(@(extension) ['*' extension], default.SUPPORTED_IMG_EXTS, 'UniformOutput', false)';

    while true
        fprintf('\nChoosing images to import...')
        % Get the source images. Their names may be in ANY text format.
        [src_files, src_dir] = uigetfile( ...
            img_filter, ...
            'Select all calibration images to import (extension dropdown on bottom-right)', ...
            'MultiSelect', 'on' ...
        );
    
        if ~isa(src_files, 'cell')
            if ~src_files
                error('Operation canceled by user.')
            end
            src_files = cellstr(src_files);  % force convert single selection to cell
        end
    
        if numel(src_files) < default.MIN_CALIB_IMGS
            fprintf('\n[BAD INPUT] Please provide a minimum of %d images for calibration.\n', ...
                default.MIN_CALIB_IMGS ...
            )
            continue
        end
    
        src_filepaths = fullfile(src_dir, src_files);
        fprintf('done.\n')
        break
    end
    
    % Get the directory to copy images to.
    fprintf('Choosing directory to import the images into...')
    calib_imgs_dir = uigetdir( ...
        '', ...
        'Choose directory to import the calibration images into (cancel = use default directory)' ...
    );

    if ~calib_imgs_dir
        calib_imgs_dir = default.BCT_CALIB_IMGS_DIR;
        if ~isfolder(calib_imgs_dir)
            warn_msg = sprintf( ...
                ['[WARNING] The default directory for calibration images was not found and had to be ' ...
                'created. This likely\nmeans that the project structure was not setup correctly. Please ' ...
                'run "project_setup.m" and\nensure that the relevant default folder is being created.\n'] ...
            );
            warning(warn_msg);
            mkdir(calib_imgs_dir)
        end
    end
    fprintf('done.\n')

    calib_imgs_dir = dir(calib_imgs_dir).folder;

    % uigetfile with MultiSelect sorts the resulting cell array w.r.t. 
    % platform explorer sort - no need for sequential rename.
    
    fprintf('Checking uniform extension...')
    % First, check for multiple extensions
    src_first_img_ext = nan;
    for i = 1 : numel(src_filepaths)
        src_filepath = src_filepaths{i};
        [~, ~, src_ext] = fileparts(src_filepath);

        % Check for multiple image extensions.
        if isnan(src_first_img_ext)
            src_first_img_ext = src_ext;
        elseif src_ext ~= src_first_img_ext
            error(['Multiple image extensions encountered. Make sure all selected images have the ' ...
                'same extension.'] ...
            );
        end 
    end
    fprintf('all good.\n')

    % Now, we know all images are the same format, so copy them over.
    fprintf('Importing images to selected directory...')
    copy_path_conflict = false;
    for i = 1 : numel(src_filepaths)
        src_filepath = src_filepaths{i};
        [~, ~, src_ext] = fileparts(src_filepath);

        calib_img_file = sprintf(default.IMGNAME_FMT, i, src_ext);
        calib_img_filepath = fullfile(calib_imgs_dir, calib_img_file);

        if strcmp(src_filepath, calib_img_filepath)
            copy_path_conflict = true;
            continue
        end
        copyfile(src_filepath, calib_img_filepath);
    end
    
    fprintf('done.\n\n\t%-17s: %s\n\t%-17s: %s\n\n', ...
        'Source Imgs Dir', src_dir, 'Imported Imgs Dir', calib_imgs_dir ...
    )

    if copy_path_conflict
        fprintf(['[WARNING] Attempted to copy one or more files onto themselves.\n' ...
            'Copy instruction was skipped for these paths.\n\n'])
    end

    fprintf('Images are ready for BCT calibration.\n')
    fprintf('...changing CWD to directory with calibration images...\n\n')

    cd(calib_imgs_dir);
    
    fprintf(['NEXT STEPS: Calibration\n\n- Assuming you have Bouguet Calibration Toolbox (BCT) on MATLAB path, run ' ...
        '"calib_gui.m" from command window.\n\n'] ...
    )

elseif calib_img_or_vid == 'v'
    
    mp4_conversion_applied = false;

    fprintf('\nLoading video of calibration checker pattern...')
    % Transpose the resulting cell vector to get cell column vectors as 
    % needed by UI filters.
    vid_filter = cellfun(@(extension) ['*' extension], default.SUPPORTED_VID_EXTS, 'UniformOutput', false)';
    [src_file, src_dir] = uigetfile( ...
        vid_filter, ...
        'Locate the calibration video to import (extension dropdown on bottom-right)' ...
    );
    
    if ~src_file
        error('Operation canceled by user.')
    end

    fprintf('done.\n')
    
    src_filepath = fullfile(src_dir, src_file);

    % Need extension to check and re-adjust filename format.
    [~, ~, src_ext] = fileparts(src_filepath);

    % If video extension is not MP4, create a re-encoded MP4 copy of it in
    % the same directory and copy that to calibration directory instead.
    if ~strcmp(src_ext, default.VID_EXT)
        mp4_conversion_applied = true;
        mp4_src_filepath = fullfile(src_dir, ['converted' default.VID_EXT]);

        fprintf('Converting video to MP4...');
        convert_vid_to_mp4(src_filepath, mp4_src_filepath);

        fprintf("done.\n\n\t%-15s: %s\n\t%-15s: %s\n\n", ...
            'Source Video', abspath(src_filepath), ...
            'Converted Video', abspath(mp4_src_filepath) ...
        )

        % Switch source to the converted video. This ensures the original
        % video remains unaffected.
        src_filepath = mp4_src_filepath;
    end

    [calib_vid_file, calib_vid_dir] = uiputfile( ...
        default.VID_EXT, ...
        'Choose location to import calibration video into (cancel = use default location)', ...
        [default.BCT_CALIB_VID_BASE default.VID_EXT] ...
    );

    if ~calib_vid_file
        calib_vid_filepath = default.BCT_CALIB_VID_PATH;
    else
        calib_vid_filepath = fullfile(calib_vid_dir, calib_vid_file);
    end

    if mp4_conversion_applied

        % Move the converted source file and rename it
        if ~strcmp(src_filepath, calib_vid_filepath)
            movefile(src_filepath, calib_vid_filepath);
            calib_vid_filepath = abspath(calib_vid_filepath);
            fprintf(['Imported MP4-converted copy of original video to project directory.' ...
                '\n\n\t%-14s: %s\n\t%-14s: %s\n\n'], ...
                'Source Video', src_filepath, 'Imported Video', calib_vid_filepath ...
            )

        else
            fprintf(['[WARNING] Move Path Conflict: Attempted to copy file or directory onto itself.\n' ...
                'Move instruction was skipped.\n\n'] ...
            )
        end

    else

        % Copy the original source file and rename it
        if ~strcmp(src_filepath, calib_vid_filepath)
            copyfile(src_filepath, calib_vid_filepath);
            calib_vid_filepath = abspath(calib_vid_filepath);
            fprintf('Imported video to project directory.\n\n\t%-14s: %s\n\t%-14s: %s\n\n', ...
                'Source Video', src_filepath, 'Imported Video', calib_vid_filepath ...
            )

        else
            fprintf(['[WARNING] Copy Path Conflict: Attempted to copy file or directory onto itself.\n' ...
                'Copy instruction was skipped.\n\n'] ...
            )
        end

    end
    
    fprintf('...launching "calib_extract_vid_frames.m" (calibration video frame extraction)...\n\n')
    run('calib_extract_vid_frames.m');
end
