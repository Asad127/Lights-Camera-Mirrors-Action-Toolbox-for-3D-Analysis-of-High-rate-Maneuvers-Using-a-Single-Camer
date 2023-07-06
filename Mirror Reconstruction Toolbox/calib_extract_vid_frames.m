%{
Part of: BCT Calibration Prep Scripts (2/3)

This script assumes that you have .mp4 calibration video in the project 
directory. If not, run `calib_import_media.m` first. Most of this script
is just user setup for the function `vid_to_frames.m`.

If this script is called from video route in `calib_import_media.m`,
variable 'calib_vid_filepath' will carry over. If so, no need to ask user 
for video file. 

If this script has been run standalone, the user must locate the video.

SCRITPS CALLED
===========================================================================
+ DIRECTLY
calib_select_img_subset.m:
    To choose specific frames from the extracted frames for calibration,
    rename them sequentially, and store them in a separate directory or the
    default directory designated for final set of calibration images.

SCRITPS THAT CALL THIS SCRIPT
===========================================================================
+ DIRECTLY
calib_import_media.m:
    If the calibration media is video, imports calibration video into the 
    project folder and converts it to MP4 if needed. Then hands over control
    to this script for frame extraction.

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

if ~exist('calib_vid_filepath', 'var')

    fprintf( ...
        ['Running calibration frame extraction standalone. This script assumes you have run ' ...
        '"calib_import_media.m"\nwith the video route and that you have an MP4 calibration ' ...
        'video in the project directory.'] ...
    );
    
    [calib_vid_file, calib_vid_dir] = uigetfile( ...
        default.VID_EXT, ...
        'Locate MP4 calibration video (cancel = use default location)', ...
        [default.BCT_CALIB_VID_BASE default.VID_EXT] ...
    );

    if ~calib_vid_file
        calib_vid_filepath = default.BCT_CALIB_VID_PATH;
        if ~isfile(calib_vid_filepath)
            err_msg = sprintf( ...
                ['MP4 calibration video does not exist at default location.' ...
                '\nPossible issues:' ...
                '\n\t(1) Calibration video was not imported at all' ...
                '\n\t(2) Calibration video was not imported to the default directory' ...
                '\n\t(3) Project structure is incorrect' ...
                '\nPossible solutions:' ...
                '\n\t(1) Run "calib_import_media.m" before this script.' ...
                '\n\t(2) Locate video where it was saved or repeat (1) with default values ' ...
                '(leave inputs blank where possible)' ...
                '\n\t(3) Run "project_setup.m" and ensure that the relevant ' ...
                'directory is created'] ...
            );
            error(err_msg);
        end
    else
        calib_vid_filepath = fullfile(calib_vid_dir, calib_vid_file);
    end
    
end

frames_dir = uigetdir( ...
    '', ...
    'Select directory to store extracted calibration video frames in (cancel = use default directory)' ...
);

if ~frames_dir
    frames_dir = default.BCT_CALIB_FRAMES_DIR;
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
    ['[PROMPT] Enter image extension to assign to the extracted calibration frames (blank = ' ...
    'default image extension): '] ...
);

% Extract frames from calibration video.
fprintf('Extracting video frames...\n\n\tFrom: %s\n\t  To: %s\n\n', calib_vid_filepath, frames_dir)

vid_to_frames( ...
    calib_vid_filepath, ...
    frames_dir, ...
    default.VID_FRAMENAME_FMT, ...
    frame_extension, ...
    start_time_seconds, ...
    stop_time_seconds ...
);

fprintf('Done extracting frames.\n\n')

fprintf('...launching "calib_select_img_subset.m" (get vid frames subset as calib images)...\n\n')
run('calib_select_img_subset.m');