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
%     Path to the video file or filename (e.g., 'something.mp4') when selected via UI.
% output_dir (optional, default = default.VID_FRAMES_DIR):
%     Path to the directory to store the frames. If not provided, defaults to
%     the value of default.VID_FRAMES_DIR from defaults.mat.
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

% Initialize input_dir for cases where uigetfile is used
input_dir = '';

switch nargin
    case 0
        % Capture both filename and directory from uigetfile
        [input_vid, input_dir] = uigetfile(['*' default.VID_EXT], 'Locate video to extract frames from');
        
        if ~input_vid
            error('Operation canceled by user.')
        end
        % Construct full path for input_vid
        input_vid = fullfile(input_dir, input_vid);
        
        output_dir = uigetdir('', ['Choose directory to save extracted frames in (cancel = ' ...
            'place in default.VID_FRAMES_DIR)']);
        
        if ~output_dir
            output_dir = default.VID_FRAMES_DIR;
        end
        
        frame_name_fmt = default.VID_FRAMENAME_FMT;
        frame_ext = default.IMG_EXT;
        start_time_secs = default.VID_START_TIME_SECONDS;
        stop_time_secs = default.VID_STOP_TIME_SECONDS;

    case 1
        % Extract input_dir from input_vid since it's provided
        [input_dir, ~, ~] = fileparts(input_vid);
        
        output_dir = uigetdir('', ['Choose directory to save extracted frames in (cancel = ' ...
            'place in default.VID_FRAMES_DIR)']);
        
        if ~output_dir
            output_dir = default.VID_FRAMES_DIR;
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
        frame_ext = default.IMG_EXT;
        start_time_secs = default.VID_START_TIME_SECONDS;
        stop_time_secs = default.VID_STOP_TIME_SECONDS;

    case 4
        start_time_secs = default.VID_START_TIME_SECONDS;
        stop_time_secs = default.VID_STOP_TIME_SECONDS;

    case 5
        stop_time_secs = default.VID_STOP_TIME_SECONDS;
end

% If input_dir is not set (non-UI cases), extract it from input_vid
if isempty(input_dir)
    [input_dir, ~, ~] = fileparts(input_vid);
end

% Validate input video file
if ~isfile(input_vid)
    error('Provided input video path is not a file or does not exist.\nProvided Path: %s', input_vid)
end

% Set default output directory if not provided
if isempty(output_dir)
    output_dir = default.VID_FRAMES_DIR;
end

% Create output directory if it doesn't exist
if ~isfolder(output_dir)
    mkdir(output_dir);
end

% Read the video file
vid_obj = VideoReader(input_vid);

% Estimate number of frames
est_num_frames = vid_obj.NumFrames;

% HACK: Sub some frames from the estimation to (hopefully) get a valid 
% frame number
est_num_frames = est_num_frames - 5;            
dummy_read = read(vid_obj, est_num_frames); 

while hasFrame(vid_obj)
    frame_in = readFrame(vid_obj);  % read the next frame
    est_num_frames = est_num_frames + 1;
end

total_frames_abs = est_num_frames;  % since we read till no more frames, this is 100% correct
dummy_read = read(vid_obj, 1);    % reset frame to original position

% Set current time to starting seconds
vid_obj.CurrentTime = start_time_secs;

% Set stop time to full video duration if Inf received
if isinf(stop_time_secs)
    stop_time_secs = vid_obj.Duration;
end

% Calculate start and stop frames
stop_frame_abs = min(floor(vid_obj.FrameRate * stop_time_secs), total_frames_abs);
start_frame_abs = max(floor(vid_obj.FrameRate * start_time_secs), 1);

% Relative frame count within the interval
total_frames_rel = stop_frame_abs - start_frame_abs + 1;  % + 1 to include last frame
curr_frame_rel = 1;
curr_frame_abs = start_frame_abs;

% Initialize progress bar
st = dbstack;
bar = waitbar(curr_frame_rel/total_frames_rel, ...
    sprintf( ...
        'Extracting video frames: %d/%d (rel) | %d/%d (abs)', ...
        curr_frame_rel, total_frames_rel, start_frame_abs, stop_frame_abs ...
        ), ...
    'Name', st(1).name ...
);

% Extract frames
while hasFrame(vid_obj) && vid_obj.CurrentTime <= stop_time_secs
    % Read the next frame
    frame = readFrame(vid_obj);
    
    % Save the frame as an image file
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

% Finalize progress bar
waitbar(1, bar, 'Finished!')
pause(1);
close(bar)

end