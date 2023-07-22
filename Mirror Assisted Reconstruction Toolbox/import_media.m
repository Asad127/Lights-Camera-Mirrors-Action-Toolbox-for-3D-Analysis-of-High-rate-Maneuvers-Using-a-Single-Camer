% Process a video containing tracked points from DLTdv8a for 3D
% reconstruction of the tracked 2D points. Imports video, converts it to 
% mp4 if any other format, and asks where to put it in the project dir (or 
% use default location) Finally, prompts the user if they want to undistort
% the video. If yes, hands runs `create_undistorted_vid_and_frames.m`, 
% otherwise runs `vid_extract_frames.m` to extract the video frames from
% the original video (used in reconstruction). 
%
% In effect, this script is essentially the same as 'calib_import_media.m',
% but not aimed at calibration preparation.
% 
% Note that you may run `create_undistorted_vid_and_frames.m` or 
% `vid_extract_frames.m` directly as well. This script is simply intended
% for user convenience as it auto-converts to mp4, which is required by 
% both scripts. Notice that `create_undistorted_vid_and_frames.m`
% additionally creates different folders for each view, which contain
% differently undistorted frames.

default = load('defaults.mat');

fprintf('Importing media containing object for marking/tracking and reconstruction...\n')

while true
    img_or_vid = input( ...
        '[PROMPT] Import images or video? ("i" = imgs, "v" = vid): ', 's');
    if ~ismember(img_or_vid, {'i', 'v'})
        fprintf('[BAD INPUT] Only "i" and "v" (no quotes) are accepted. Please try again.\n')
        continue
    end
    break
end

% User is importing image(s)
if img_or_vid == 'i'
    
    % Transpose the resulting cell vector to get cell column vectors as 
    % needed by UI filters.
    img_filter = cellfun(@(extension) ['*' extension], default.SUPPORTED_IMG_EXTS, 'UniformOutput', false)';
    
    fprintf('\nChoosing image(s) to import...')
    % Get the source images. Their names may be in ANY text format.
    [src_files, src_dir] = uigetfile( ...
        img_filter, ...
        'Select all images to import (extension dropdown on bottom-right)', ...
        'MultiSelect', 'on' ...
    );

    if ~isa(src_files, 'cell')
        if ~src_files
            error('Operation canceled by user.')
        end
        src_files = cellstr(src_files);  % force single selection to cell
    end

    src_filepaths = fullfile(src_dir, src_files);
    num_src_imgs = numel(src_filepaths);

    fprintf('done.\n')

    % Get the directory to copy images to.
    fprintf('Choosing directory to import the images into...')
    imgs_dir = uigetdir( ...
        '', ...
        'Choose directory to import the images to (cancel = use default directory)' ...
    );

    if ~imgs_dir
        imgs_dir = default.IMGS_DIR;
        if ~isfolder(imgs_dir)
            warn_msg = sprintf( ...
                ['\n[WARNING] The default directory for images was not found and had to be created. This likely' ...
                '\nmeans that the project structure was not setup correctly. Please run "project_setup.m" ' ...
                'and\nensure that the relevant default folder is being created.\n\n'] ...
            );
            warning(warn_msg);
            mkdir(imgs_dir)
        end
        imgs_dir = abspath(imgs_dir);
    end

    fprintf('done.\n')

    % uigetfile with MultiSelect sorts the resulting cell array w.r.t. 
    % platform explorer sort - no need for sequential rename.
    
    fprintf('Checking uniform extension...')
    % First, check for multiple extensions
    src_first_img_ext = nan;
    for i = 1 : num_src_imgs
        src_filepath = src_filepaths{i};
        [~, ~, src_ext] = fileparts(src_filepath);

        % Check for multiple image extensions.
        if isnan(src_first_img_ext)
            src_first_img_ext = src_ext;
        elseif src_ext ~= src_first_img_ext
            error('Multiple image extensions encountered. Make sure all selected images have the same extension.');
        end 
    end
    fprintf('all good.\n')

    % Now, we know all images are the same format, so copy them over.
    fprintf('Copying image(s) to selected directory...')
    copy_path_conflict = false;
    img_filepaths = cell(1, num_src_imgs);
    
    for i = 1 : num_src_imgs
        src_filepath = src_filepaths{i};
        [~, src_base, src_ext] = fileparts(src_filepath);

        img_file = [src_base src_ext];
        img_filepath = fullfile(imgs_dir, img_file);
        img_filepaths{i} = img_filepath;

        if strcmp(src_filepath, img_filepath)
            if ~copy_path_conflict
                copy_path_conflict = true;
            end 
            continue
        end

        copyfile(src_filepath, img_filepath);

    end

    fprintf('done.\n')
    
    if copy_path_conflict
        fprintf(['[WARNING] Attempted to copy one or more files onto themselves.\n' ...
            'Copy instruction was skipped for these paths.\n'])
    end
    
    fprintf('\n\t%-17s: %s\n\t%-17s: %s\n\n', ...
        'Source Imgs Dir', abspath(src_dir), 'Imported Imgs Dir', abspath(imgs_dir) ...
    )

    % Ask if user wants to undistort the images.
    while true
        fprintf(['NOTE: Undistortion requires distortion coefficients from merged BCT file created by ' ...
            '"calib_process_results.m".\n'] ...
        )
        choice_undistort_video = input('[PROMPT] Undistort the imported images? (y/n): ', 's');
        if ~ismember(choice_undistort_video, {'y', 'n'})
            fprintf('\n[BAD INPUT] Only "y" (yes) and "n" (no) are accepted inputs. Please try again.\n')
            continue
        end
        break
    end
    
    if choice_undistort_video == 'y'
        fprintf('\n...launching "create_undistorted_imgs.m" to undistort images w.r.t. each view...\n\n')
        run('create_undistorted_imgs.m');
    else
        fprintf(['\nNEXT STEPS: Manually Marking Points For Reconstruction\n\n- Run "point_marker.m" and ' ...
            'mark target points on object of interest over all views in a single image.\n\n'] ...
        )
    end

% User is importing video
else

    mp4_conversion_applied = false;
    
    fprintf('\nLoading video containing target object...')
    % Transpose the resulting cell vector to get cell column vectors as 
    % needed by UI filters.
    vid_filter = cellfun(@(extension) ['*' extension], default.SUPPORTED_VID_EXTS, 'UniformOutput', false)';
    
    [src_file, src_dir] = uigetfile(vid_filter, 'Locate video containing tracking target');
    
    if ~src_file
        error('Operation canceled by user.')
    end
    
    src_filepath = fullfile(src_dir, src_file);
    fprintf('done.\n')
    
    % Need extension to check and re-adjust filename format.
    [~, ~, src_ext] = fileparts(src_filepath);
    
    % If video extension is not MP4, create a re-encoded MP4 copy of it in
    % the same directory and copy that to calibration directory instead.
    if src_ext ~= default.VID_EXT
        mp4_conversion_applied = true;
        mp4_converted_src = fullfile(src_dir, ['converted' default.VID_EXT]);
        
        fprintf('Converting video to MP4...');
        convert_vid_to_mp4(src_filepath, mp4_converted_src);
    
        fprintf("done.\n\n\t%-15s: %s\n\t%-15s: %s\n\n", ...
            'Source Video', abspath(src_filepath), ...
            'Converted Video', abspath(mp4_src_filepath) ...
        )

        % Switch source to the converted video. This ensures the original
        % video is not affected.
        src_filepath = mp4_converted_src;
    end
    
    [vid_file, vid_dir] = uiputfile( ...
        default.VID_EXT, ...
        'Choose location to save the imported video to (cancel = use default location)', ...
        [default.VID_BASE default.VID_EXT] ...
    );
    
    if ~vid_file
        
        % Need to absolutify path.
        [vid_dir, vid_base, vid_extension] = fileparts(default.VID_PATH);
        
        % If default path has no directories.
        if isempty(vid_dir) && ~isempty(vid_base) && ~isempty(vid_extension)  
            vid_filepath = fullfile(pwd, [vid_base vid_extension]);  % this is already absolute due to pwd
        
        % If default path has directories.
        elseif ~isempty(vid_dir) && ~isempty(vid_base) && ~isempty(vid_extension)

            if ~isfolder(vid_dir)
                mkdir(vid_dir);
            end

            % Since file does not exist yet, we absolutify the dirpath that
            % we just created and append the name of imported video to it.
            vid_dir = abspath(vid_dir);  
            vid_filepath = fullfile(vid_dir, [vid_base vid_extension]);
        else
            error('Default import path does not have a defined basename and extension for the imported video file.')
        end
    
    else
        vid_filepath = fullfile(vid_dir, vid_file);
    end

    if mp4_conversion_applied

        if ~strcmp(src_filepath, vid_filepath)
            movefile(src_filepath, vid_filepath);  % move the converted source file and rename it
            vid_filepath = abspath(vid_filepath);
            fprintf(['Imported MP4-converted copy of original video to project directory.' ...
                '\n\n\t%-14s: %s\n\t%-14s: %s\n\n'], ...
                'Source Video', src_filepath, 'Imported Video', abspath(vid_filepath) ...
            )
        else
            fprintf(['[WARNING] Move Path Conflict: Attempted to copy file or directory onto itself.\n' ...
                'Move instruction was skipped.\n\n'] ...
            )
        end

    else

        if ~strcmp(src_filepath, vid_filepath)
            copyfile(src_filepath, vid_filepath);  % copy the original source file and rename it
            vid_filepath = abspath(vid_filepath);
            fprintf('Imported video to project directory.\n\n\t%-14s: %s\n\t%-14s: %s\n\n', ...
                'Source Video', src_filepath, 'Imported Video', vid_filepath ...
            )

        else
            fprintf(['[WARNING] Copy Path Conflict: Attempted to copy file or directory onto itself.\n' ...
                'Copy instruction was skipped.\n\n'] ...
            )
        end
        
    end
    
    while true
        fprintf(['NOTE: Undistortion requires distortion coefficients from BCT in merged format as produced by ' ...
            '\n"calib_process_results.m".\n'] ...
        )
        choice_undistort_video = input('[PROMPT] Undistort the imported video? (y/n): ', 's');
        if ~ismember(choice_undistort_video, {'y', 'n'})
            fprintf('\n[BAD INPUT] Only "y" (yes) and "n" (no) are accepted inputs. Please try again.\n')
            continue
        end
        break
    end
    
    if choice_undistort_video == 'y'
        fprintf('\n...launching "create_undistorted_vid_and_frames.m" (undistort videos)...\n\n')
        run('create_undistorted_vid_and_frames.m');
    else
        fprintf('\n...launching "vid_extract_frames.m" (extract video frames for reconstruction)...\n\n')
        run('vid_extract_frames.m');    
    end

end
