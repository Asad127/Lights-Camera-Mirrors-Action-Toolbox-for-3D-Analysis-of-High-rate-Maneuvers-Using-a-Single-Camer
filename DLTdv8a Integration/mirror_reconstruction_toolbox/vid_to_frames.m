function vid_to_frames(input_vid, output_dir, frame_name_fmt, frame_ext, start_time_secs, stop_time_secs)
%{
Extracts numbered frames from a video in a specific format and stores them
into the target directory. The basename of the saved frames is 'frame' by
default.

NOTE: Considered using the base video filename, but ultimately it's much 
better to name the output directory according to the basename instead.

TAKES
=====
vid_path (required):
    Path to the video file.
output_dir (required):
    Path to the directory to store the frames.
frame_name_fmt (optional):
    Format of the extracted frame names (filenames). Must contain 2 format
    identifiers: a %d for the frame number, and %s for output frame's image 
    format, which is defined by frame_ext.
frame_ext (optional):
    Extension to save the frames i.e., images with.
start_time_secs_or_frames:
    Starting time of video defined in units of frame number or seconds.
stop_time_secs_or_frames:
    Stopping time of video defined in units of frame number or seconds.

RETURNS
=======
Nothing. Simply creates a directory with the frames inside.
%}

% Set defaults.
default = load('defaults.mat');

switch nargin
    case 0
        VID_EXTS = {'.mp4', '.avi' '.mov' '.m4v' '.mpg'};
        vid_filter = cellfun(@(extension) ['*' extension], VID_EXTS, 'UniformOutput', false)';
        input_vid = uigetfile(vid_filter, 'Locate video to extract frames from');
        output_dir = uigetdir('', 'Choose directory to save extracted frames in');
        frame_name_fmt = default.VID_FRAMENAME_FMT;
        frame_ext = default.IMG_EXT;
        start_time_secs = default.VID_START_TIME_SECONDS;
        stop_time_secs = default.VID_STOP_TIME_SECONDS;
    case 1
        output_dir = uigetdir('', 'Choose directory to store extracted frames in');
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

if ~isfolder(output_dir)
    mkdir(output_dir);
end

% Read the video file.
vid_obj = VideoReader(input_vid);

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

stop_frame_abs = min(floor(vid_obj.FrameRate * stop_time_secs), vid_obj.NumFrames);
start_frame_abs = max(floor(vid_obj.FrameRate * start_time_secs), 1);

% Rel = relative within the interval. Absolute is the with reference of the
% actual video's full length of frames.
total_frames_rel = stop_frame_abs - start_frame_abs + 1;  % + 1 to include last frame
curr_frame_rel = 1;
curr_frame_abs = start_frame_abs;

st = dbstack;
bar = waitbar(curr_frame_abs/total_frames_rel, ...
    sprintf( ...
        'Extracting video frames: %d/%d (rel) | %d/%d (abs)', ...
        curr_frame_rel, total_frames_rel, start_frame_abs, stop_frame_abs ...
        ), ...
    'Name', st(1).name ...
);

% while hasFrame(vid_obj) && vid_obj.CurrentTime <= stop_time_seconds
while hasFrame(vid_obj) && curr_frame_rel <= total_frames_rel
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