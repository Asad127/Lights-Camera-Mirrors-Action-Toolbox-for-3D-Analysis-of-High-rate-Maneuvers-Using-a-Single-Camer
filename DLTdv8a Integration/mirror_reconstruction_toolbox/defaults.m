% Script containing toolbox defaults as loaded in by various other scripts. 
% Only the defaults required by a script are loaded into its workspace.
% Several of these are safely configurable. but be careful with the first
% section marked "DON'T EDIT THESE".

%% !! DON'T EDIT THESE UNLESS YOU KNOW WHAT YOU ARE DOING !!

% Changing these might cause certain parts of the toolbox to stop working
% correctly as they indicate some core design assumptions. However, if the
% idea is to adjust the design, changing these or adding more could be 
% helpful.

% Absolutely do not touch unless extending to n views
% =========================================================================
% Number of cameras/views is interchangeable. Currently, a maximum of 3 and
% minimum of 2 views are supported. 
MAX_VIEWS = 3;
MIN_VIEWS = 2;

VIEW_NAMES_LONG = {'Camera', 'Mirror 1', 'Mirror 2'};
VIEW_NAMES_SHORT = {'C', 'M1', 'M2'};

% Supported image and video extensions
% =========================================================================
% NOTE: Non-MP4 videos converted to MP4.
SUPPORTED_VID_EXTS = {'.mp4' '.avi' '.mov' '.m4v' '.mpg'};  
SUPPORTED_IMG_EXTS = {'.jpg' '.png' '.tif' '.bmp'};

% Calibration Filename and Extracted Video Frame Text Formats
% =========================================================================
% BCT requires numbered filenames and only asks for the non-numbered part.
% Additionally, since we rename the calibration images so that the numbered 
% part is always a consecutive sequence of natural numbers starting from 1 
% (Image1.jpg, Image2.jpg, ...), no blank images are loaded in case of any
% jumps between numbers. That is, if first image was Image 1 and the next was 
% Image 5, BCT would create blank Image2, Image3, and Image4. This will never
% happend with the renamed files!

% Format for calibration images (BCT).
BCT_CALIB_IMGNAME_FMT = 'Image%d%s';

% Format for frames extracted from videos. 
VID_FRAMENAME_FMT = 'Frame%d%s';

% Minimum images required for a barely passable calibration.
MIN_CALIB_IMGS = 10;

% Number of variables extracted from each BCT calibration output file
% Calib_Results.mat. For details, look at _saved_bct_params.txt.
NUM_UNIQUE_VARS_PER_CAM = 5;
NUM_SHARED_VARS_CAMS = 2;

% Mirror view starts at curr_idx + MIRROR_OFFSET. This is because we assume
% the actual camera occupies index 1 wherever pertinent.
MIRROR_OFFSET = 1;

% Offset due to header row for when saving 3D points in DLTdv8a format.
DLTDV_TRACKFILE_HEADER_OFFSET = 1;

% Permutation transform swaps X and Y (first 2 cols) of rotation matrix to 
% force mirror view to be left-handed despite BCT forcing right-handedness. 
PERM_TRANSFORM = [0 1 0; 1 0 0; 0 0 1];

% Default software extensions for relevant files required/output by BCT and
% DLTdv8a. Do not change unless you modify the software to your use case.
BCT_EXT = '.mat';
DLTDV_EXT = '.csv';

% MP4 is most compatible - other video formats supported by MATLAB's 
% VideoReader are converted to this format in the toolbox scripts.
VID_EXT = '.mp4';  

% Default software filenames.
DLTDV_TRACKFILE_2D_BASE = 'xypts';
DLTDV_TRACKFILE_3D_BASE = 'xyzpts';

%% SAFE TO EDIT %%

% File Exchange
% =========================================================================
% Stephen Cobeldick's natsort: An excellent tool for natural sorting in 
% various scenarios. Does not impose filename restrictions described in 
% 'Notes on frame/image filename formats'. You can download here:
% https://www.mathworks.com/matlabcentral/fileexchange/47434-natural-order-filename-sort
FEX_USE_NATSORT = false;

% BCT Calibration Processing
% =========================================================================
% Integer representing number of calibration files (one per view).
NUM_CALIB_FILES = 2;  % CAREFUL! Must be either 2 or 3.

% Character vector representing default reference img suffix for extrinsics 
% from BCT calibration. It's a character, since it may be 'ext' in the event 
% the extrinsics reference is not part of the calibration image set and the
% extrinsics were computed via Comp. Extrinsic function of BCT.
EXTRINSICS_REFERENCE_IMG_SUFFIX = '1';  

% By default, if the user is working with only 2 views, it is assumed one 
% of them is the actual camera (i.e., both views aren't mirror views). The
% user will have to specify if this is not the case where pertinent.
CAMERA_VIEW_PRESENT = 1;

% Number of the latest subset selections to keep a record of. Once this
% length is exceeded, newer ones replace oldest ones. History is useful if
% you are comparing different calibrations to get the best one or if you
% would like to reproduce/debug reuslts quickly.
BCT_SUBSET_IMGS_HIST_LEN = 3;

% Video Settings
% =========================================================================
% By default, cover videos completely from start to end.
VID_START_TIME_SECONDS = 0;  
VID_STOP_TIME_SECONDS = Inf;

% Command Window QoL
% =========================================================================
HIDE_PROMPT_HELP = false;
CWLINE_WIDTH = 90;
CWLINE_STYLE = repmat('=', 1, CWLINE_WIDTH);

% Directories
% =========================================================================
% Store all PROJECT videos
DLTDV_VID_DIR = 'videos';

% Store all frames from PROJECT videos
DLTDV_VID_FRAMES_DIR = 'videoframes';

% DLTdv8a exported trackfiles xypts.csv and xyzpts.csv
DLTDV_TRACKFILES_DIR = 'trackfiles';

% BCT calibration-related files and DLT coefficients
BCT_CALIB_DIR = 'calibration';  

% Images for calib (direct images or chosen from video frames)
BCT_CALIB_IMGS_DIR = fullfile(BCT_CALIB_DIR, 'images');

% Store all frames from CALIBRATION videos
BCT_CALIB_FRAMES_DIR = fullfile(BCT_CALIB_DIR, 'frames');

% Store previous seected subsets for calibration.
BCT_CALIB_SUBSET_HIST_DIR = fullfile(BCT_CALIB_DIR, 'subset_selection_history');

% Directory where results of reconstruction script are stored.
RECONSTRUCTION_DIR = 'reconstruction';

% Undistortion output frame folder names
UNDISTORTED_FRAME_FOLDERS = {'cam_rect', 'mir1_rect', 'mir2_rect'};

% File Basenames
% =========================================================================
% Calibration video name
BCT_CALIB_VID_BASE = 'calib';

% DLTdv8a video name
DLTDV_VID_BASE = 'projvid';

% Merged BCT parameters (all views in one)
BCT_MERGED_CALIB_BASE = 'bct_params';

% Camera BCT calibration result
BCT_CAM_CALIB_BASE = 'Calib_Results_cam';  

% Mirrors BCT calibration result. Since multiple mirrors, all accesses must 
% be done with sprintf. %d should evaluate to 1 or 2 for mirrors 1 and 2.
BCT_MIR_CALIB_BASE_FMT = 'Calib_Results_mir%d'; 

% 11 DLT coefficients file for DLTdv8a. Created from BCT params for each 
% view separately and then merged into one csv file.
DLT_COEFS_BASE = 'dlt_coefs';

% File Extensions
% =========================================================================
IMG_EXT = '.jpg';

% Filepaths, composed using the dirs, filenames, and extensions. Don't
% change these directly, consider changing their components.
% =========================================================================

% Path to the merged BCT calibration parameters file, combining only the
% needed parts of the camera and mirror calibrations into one file.
% BCT_MERGED_CALIB_PATH = strrep(fullfile(BCT_CALIB_DIR, ...
% [BCT_MERGED_CALIB_BASE BCT_EXT]),  '\', '\\');
BCT_MERGED_CALIB_PATH = fullfile(BCT_CALIB_DIR, [BCT_MERGED_CALIB_BASE BCT_EXT]);

% Path to the camera's calibration result files.
% BCT_CAM_CALIB_PATH = strrep(fullfile(BCT_CALIB_DIR, ...
% [BCT_CAM_CALIB_BASE BCT_EXT]),  '\', '\\');
BCT_CAM_CALIB_PATH = fullfile(BCT_CALIB_DIR, [BCT_CAM_CALIB_BASE BCT_EXT]);

% Path to the mirror's calibration result files (must be sprintf'd since
% BCT_MIR_CALIB_BASE_FMT contains formatting identifiers.
% BCT_MIR_CALIB_PATH = strrep(fullfile(BCT_CALIB_DIR, ...
% [BCT_MIR_CALIB_BASE_FMT BCT_EXT]),  '\', '\\');
BCT_MIR_CALIB_PATH = fullfile(BCT_CALIB_DIR, [BCT_MIR_CALIB_BASE_FMT BCT_EXT]);

% Calibration video import path.
BCT_CALIB_VID_PATH = fullfile(BCT_CALIB_DIR, [BCT_CALIB_VID_BASE, VID_EXT]);

% Path to the saved 11 DLT Coefficients file (Dltdv8a ready).
% DLT_COEFS_PATH = strrep(fullfile(BCT_CALIB_DIR, ...
% [DLT_COEFS_BASE DLTDV_EXT]),  '\', '\\');
DLT_COEFS_PATH = fullfile(BCT_CALIB_DIR, [DLT_COEFS_BASE DLTDV_EXT]);

% Path to the video that's going to be used in DLTdv8a.
DLTDV_VID_PATH = fullfile(DLTDV_VID_DIR, [DLTDV_VID_BASE VID_EXT]);