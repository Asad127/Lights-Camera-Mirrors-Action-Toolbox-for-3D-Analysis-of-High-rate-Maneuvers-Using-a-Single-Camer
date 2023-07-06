% Pretty much the same as `calib_extract_vid_frames.m`, with different 
% default location assumptions, with the exception of subset selection.
% Intended for use in conjunction with `import_media.m` but 
% may also be called separately if the video is already in the project 
% directory and in .mp4 format.

default = load('defaults.mat');

if ~exist('vid_filepath', 'var')

    fprintf( ...
        ['Running video frame extraction standalone. This script assumes you have run ' ...
        '"import_media.m"\nwith the video route and that you have an MP4 calibration ' ...
        'video in the project directory.'] ...
    );
    
    [vid_file, vid_dir] = uigetfile( ...
        default.VID_EXT, ...
        'Locate MP4 video containing tracked objects (cancel = use default location)', ...
        [default.DLTDV_VID_BASE default.VID_EXT] ...
    );

    if ~vid_file
        vid_filepath = default.DLTDV_VID_PATH;
        if ~isfile(vid_filepath)
            err_msg = sprintf( ...
                ['MP4 video does not exist at default location.' ...
                '\nPossible issues:' ...
                '\n\t(1) Video was not imported at all' ...
                '\n\t(2) Video was not imported to the default directory' ...
                '\n\t(3) Project structure is incorrect' ...
                '\nPossible solutions:' ...
                '\n\t(1) Run "import_media.m" before this script.' ...
                '\n\t(2) Locate video where it was saved or repeat (1) with default values ' ...
                '(leave inputs blank where possible)' ...
                '\n\t(3) Run "project_setup.m" and ensure that the relevant ' ...
                'directory is created'] ...
            );
            error(err_msg);
        end
    else
        vid_filepath = fullfile(vid_dir, vid_file);
    end
    
end

frames_dir = uigetdir( ...
    '', ...
    'Select directory to store the extracted calibration video frames in (cancel = use default directory)' ...
);

if ~frames_dir
    frames_dir = default.DLTDV_VID_FRAMES_DIR;
    if ~isfolder(frames_dir)
        fprintf( ...
            ['[WARNING] The default directory for calibration frames was ' ...
            'not found and had to be created. If this\nwas not intentional, ' ...
            'it likely means that the project structure was not setup correctly. ' ...
            'Please run\n"project_setup.m" and ensure that the relevant ' ...
            'directory is created.\n'] ...
        )
        mkdir(frames_dir)  
    end
end

% Start and end timestamps. We use duration method to avoid any and all
% restrictions on hour limits etc. that come with the other methods like
% datetime. Seconds converts the duration to seconds, which is the unit
% required for the VideoReader object's CurrentTime property.
while true
    fprintf( ...
        ['\nHELP: To start from 1 m 30 s, enter "0:1:30" or "00:01:30" (w/o quotes). To begin ' ...
        'from video start, leave blank.\n'] ...
    )

    start_time_hms = input( ...
        '[PROMPT] Enter start timestamp in H:M:S format (blank = from video start): ', 's' ...
    );
    
    if isempty(start_time_hms)
        start_time_seconds = default.VID_START_TIME_SECONDS;
    else
        start_time_seconds = seconds(duration(str2double(strsplit(start_time_hms, ':'))));
    end
    
    fprintf( ...
        ['\nHELP: To end at 1 m 30 s, enter "0:1:30" or "00:01:30" (w/o quotes). To stop ' ...
        'at video end, leave blank.\n'] ...
    )

    stop_time_hms = input( ...
        '[PROMPT] Enter stop timestamp in H:M:S format (blank = until video end): ', 's' ...
    );
    
    if isempty(stop_time_hms)
        stop_time_seconds = default.VID_STOP_TIME_SECONDS;
    else
        stop_time_seconds = seconds(duration(str2double(strsplit(stop_time_hms, ':'))));
    end

    if stop_time_seconds < start_time_seconds
        continue
    end

    break
end

frame_extension = prompt_img_extension( ...
    '[PROMPT] Enter image extension for extracted video frames (blank = default image extension): ' ...
);

% Extract frames from video.
fprintf('Extracting video frames...\n\n\tFrom: %s\n\t  To: %s\n\n', vid_filepath, frames_dir)

vid_to_frames( ...
    vid_filepath, ...
    frames_dir, ...
    default.VID_FRAMENAME_FMT, ...
    frame_extension, ...
    start_time_seconds, ...
    stop_time_seconds ...
);

fprintf('Done extracting frames.\n\n')