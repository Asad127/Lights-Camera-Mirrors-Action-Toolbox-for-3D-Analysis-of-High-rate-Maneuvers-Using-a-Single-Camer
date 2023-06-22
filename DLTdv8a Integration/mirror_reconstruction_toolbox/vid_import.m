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

fprintf('Importing video for DLTdv8a tracking to project directory...\n')

mp4_conversion_applied = false;

% Transpose the resulting cell vector to get cell column vectors as 
% needed by UI filters.
vid_filter = cellfun(@(extension) ['*' extension], default.SUPPORTED_VID_EXTS, 'UniformOutput', false)';

[src_file, src_dir] = uigetfile(vid_filter, 'Locate video containing tracking target');

if ~src_file
    error('Operation canceled by user.')
end

src_filepath = fullfile(src_dir, src_file);

% Need extension to check and re-adjust filename format.
[~, ~, src_ext] = fileparts(src_filepath);

% If video extension is not MP4, create a re-encoded MP4 copy of it in
% the same directory and copy that to calibration directory instead.
if src_ext ~= default.VID_EXT
    mp4_conversion_applied = true;
    mp4_converted_src = fullfile(src_dir, ['converted' default.VID_EXT]);
    convert_vid_to_mp4(src_filepath, mp4_converted_src);

    % Switch source to the converted video. This ensures the original
    % video is not affected.
    src_filepath = mp4_converted_src;
end

[vid_file, vid_dir] = uiputfile( ...
    default.VID_EXT, ...
    'Choose location to save the imported video to (cancel = use default location)', ...
    [default.DLTDV_VID_BASE default.VID_EXT] ...
);

if ~vid_file
    vid_filepath = default.DLTDV_VID_PATH;
else
    vid_filepath = fullfile(vid_dir, vid_file);
end

if mp4_conversion_applied
    movefile(src_filepath, vid_filepath);  % move the converted source file and rename it
else
    copyfile(src_filepath, vid_filepath);  % copy the original source file and rename it
end

while true
    fprintf(['NOTE: Undistortion requires distortion coefficients from BCT in merged format as produced by ' ...
        '\n"calib_process_results.m".\n'] ...
    )
    choice_undistort_video = input('Undistort the imported video? (y/n): ', 's');
    if ~ismember(choice_undistort_video, {'y', 'n'})
        fprintf('[BAD PROMPT] Only "y" (yes) and "n" (no) are accepted inputs. Please try again.\n')
        continue
    end
    break
end

if choice_undistort_video == 'y'
    fprintf(['\n...launching "create_undistorted_vid_and_frames.m" to undistort video and get undistorted frames ' ...
        'for each view...\n'] ...
    )
    run('create_undistorted_vid_and_frames.m');
else
    fprintf('\n...launching "vid_extract_frames.m" to extract video frames (for reconstruction script)...\n')
    run('vid_extract_frames.m');    
end