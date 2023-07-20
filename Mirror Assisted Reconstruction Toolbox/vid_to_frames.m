function vid_to_frames(input_vid, output_dir, frame_name_fmt, frame_ext, start_time_secs, stop_time_secs)
% Extracts numbered frames from a video in a specific format and stores 
% them into the target directory.
% 
% abs means absolute, and rel means relative. Absolute is the frame number
% corresponding to the full-length of the video, whereas rel is specific to
% the interval defined by [start_time_secs stop_time_secs].
%
% TAKES
% ===========================================================================
% input_vid (required):
%     Path to the video file.
% output_dir (optional, default = 'frames'):
%     Path to the directory to store the frames. If not provided, defaults to
%     the input video directory inside a new folder named 'frames'.
% frame_name_fmt (optional):
%     Format of the extracted frame names (filenames). Must contain 2 format
%     identifiers: a %d for the frame number, and %s for output frame's image 
%     extension, which is defined by `frame_ext`. Defaults to whatever is in
%     `defaults.m` (org setting = 'Frame%d').
% frame_ext (optional):
%     Extension to save the frames/images with. Defaults to whatever value
%     for `IMG_EXT` in project's `defaults.m` (org setting = '.jpg') 
% start_time_secs (optional):
%     Starting time of video defined in seconds. Defaults to whatever value
%     for `VID_START_TIME_SECONDS` in project's `defaults.m` (org setting =
%     0, i.e. start of video).
% stop_time_secs (optional):
%     Stopping time of video defined in seconds. Defaults to whatever value
%     for `VID_STOP_TIME_SECONDS` in project's `defaults.m` (org setting =
%     Inf, i.e. end of video).
% 
% RETURNS
% ===========================================================================
% Nothing. Simply creates a directory with the frames inside.

% Set defaults.
default = load('defaults.mat');

switch nargin
    case 0
        input_vid = uigetfile(['*' default.VID_EXT], 'Locate video to extract frames from');

        if ~input_vid
            error('Operation canceled by user.')
        end
        [~, input_dir, ~] = fileparts(input_vid);
        
        output_dir = uigetdir('', ['Choose directory to save extracted frames in (cancel = ' ...
            'place in "frames" folder in video directory)']);

        if ~output_dir
            output_dir = fullfile(input_dir, 'frames');
        end
        
        frame_name_fmt = default.VID_FRAMENAME_FMT;
        frame_ext = default.IMG_EXT;
        start_time_secs = default.VID_START_TIME_SECONDS;
        stop_time_secs = default.VID_STOP_TIME_SECONDS;

    case 1
        [~, input_dir, ~] = fileparts(input_vid);

        output_dir = uigetdir('', ['Choose directory to save extracted frames in (cancel = ' ...
            'place in "frames" folder in video directory)']);
        
        if ~output_dir
            output_dir = fullfile(input_dir, 'frames');
        end

        frame_name_fmt = default.VID_FRAMENAME_FMT;
        frame_ext = default.IMG_EXT;
        start_time_secs = default.VID_START_TIME_SECONDS;
        stop_time_secs = default.VID_STOP_TIME_SECONDS;

    case 2
        frame_name_fmt = default.VID_FRAMENAME_FMT;
        frame_ext = default.IMG_EXT;
        start_time_secs = default.VID_START_TIME_SECONDS;
        stop_time_secs = default.VID_STOP_TIME_SECONDS;

    case 3
        frame_ext = IMG_EXT;
        start_time_secs = default.VID_START_TIME_SECONDS;
        stop_time_secs = default.VID_STOP_TIME_SECONDS;

    case 4
        start_time_secs = default.VID_START_TIME_SECONDS;
        stop_time_secs = default.VID_STOP_TIME_SECONDS;

    case 5
        stop_time_secs = default.VID_STOP_TIME_SECONDS;
end

[input_dir, ~, ~] = fileparts(input_vid);

% We may receive non-UI inputs if this function is called, in which case we 
% need to validate files. However, generally, this won't be the case with
% how the scripts are designed (enforcing UI file/folder inputs).

if ~isfile(input_vid)
    error('Provided input video path is not a file or does not exist.\nProvided Path: %s', input_vid)
end

if isempty(output_dir)
    output_dir = fullfile(input_dir, 'frames');
end

if ~isfolder(output_dir)
    mkdir(output_dir);
end

% Read the video file.
vid_obj = VideoReader(input_vid);

% Estimate no. of frames in video (not 100% accurate as noted in MATLAB 
% docs), and we would like an exact number to prevent mismatch between
% DLTdv8a's counted number of frames and ours.
est_num_frames = vid_obj.NumFrames;

% HACK: Sub some frames from the estimation to (hopefully) get a valid 
% frame number. Then, read the frame in with the read(vid, framenum) form 
% of the VideoReader read function, which sets the current frame to 
% framenum. Then readFrame from there on until we run out of frames, and 
% that is our actual frame count. This saves you from having to read the
% entire video to get the frame count, and just a few frames.

est_num_frames  = est_num_frames - 5;            
dummy_read = read(vid_obj, est_num_frames); 

while hasFrame(vid_obj)
    frame_in = readFrame(vid_obj);  % read the next frame
    est_num_frames = est_num_frames + 1;
end

total_frames_abs = est_num_frames;  % since we read till no more frames, this is 100% correct
dummy_read = read(vid_obj, 1);    % reset frame to original position

% Set current time to starting seconds.
vid_obj.CurrentTime = start_time_secs;

% Set stop time to full video duration if Inf received. Otherwise, we use
% the user-provided stop time.
if isinf(stop_time_secs)
    stop_time_secs = vid_obj.Duration;
end

% Start frame should always start from 1, since readFrame reads the next
% frame. If current time is 0 (no frames read yet), this makes the start
% frame 0 unless we get a current time of ~0.033, which makes it a 1.
% Rather than mess with the time, we have made it so we get the max of the
% starting_frame vlaue and 1, so we guarantee we start at 1 and not 0.
%
% Similar shenanigans for the stop frame. If it's greater than the reported
% number of frames by VideoReader, we push it down to the no. of reported
% frames instead.

stop_frame_abs = min(floor(vid_obj.FrameRate * stop_time_secs), total_frames_abs);
start_frame_abs = max(floor(vid_obj.FrameRate * start_time_secs), 1);

% Rel = relative within the interval. Absolute is with reference of the
% actual video's full length of frames.

total_frames_rel = stop_frame_abs - start_frame_abs + 1;  % + 1 to include last frame
curr_frame_rel = 1;
curr_frame_abs = start_frame_abs;

st = dbstack;
bar = waitbar(curr_frame_rel/total_frames_rel, ...
    sprintf( ...
        'Extracting video frames: %d/%d (rel) | %d/%d (abs)', ...
        curr_frame_rel, total_frames_rel, start_frame_abs, stop_frame_abs ...
        ), ...
    'Name', st(1).name ...
);

while hasFrame(vid_obj) && vid_obj.CurrentTime <= stop_time_secs
% while hasFrame(vid_obj) && curr_frame_rel <= total_frames_rel
    % Read the next frame.
    frame = readFrame(vid_obj);
    
    % Save the frame as an image file.
    frame_file = sprintf(frame_name_fmt, curr_frame_abs, frame_ext);
    frame_filepath = fullfile(output_dir, frame_file);
    imwrite(frame, frame_filepath);

    curr_frame_abs = curr_frame_abs + 1;
    curr_frame_rel = curr_frame_rel + 1;
    waitbar( ...
        curr_frame_abs/total_frames_rel, ...
        bar, ...
        sprintf( ...
            'Extracting video frames: %d/%d (rel) | %d/%d (abs)', ...
            curr_frame_rel, total_frames_rel, curr_frame_abs, stop_frame_abs ...
        ), ...
        'Name', st(1).name ...
    );
end

waitbar(1, bar, 'Finished!')
pause(1);
close(bar)

end