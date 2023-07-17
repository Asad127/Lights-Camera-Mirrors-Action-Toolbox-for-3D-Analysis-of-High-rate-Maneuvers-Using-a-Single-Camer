% Script containing toolbox defaults as loaded in by various other scripts.
% If anything gets messed up, delete this file, make a copy of
% `backup_defaults.m`, and rename the copy to `defaults.m`.
% Each setting has an in-line comment indicating whether it can be changed.
% NONE: May be edited.
% EDIT-UNSAFE: Might cause issues and potentially break a project, or
%   requires edits to other toolbox scripts/functions. EDIT-UNSAFE followed
%   by "if done locally" means this is only edit unsafe if you have an
%   existing project and you amke this edit inside it.
% DO NOT CHANGE: Don't change, this is a critical setting.

% No. of Views and View Labels
% =========================================================================
% Number of cameras/views is interchangeable. Currently, a maximum of 3 and
% minimum of 2 views are supported.

MAX_VIEWS = 3;  % DO NOT CHANGE
MIN_VIEWS = 2;  % DO NOT CHANGE

VIEW_NAMES_LONG = {'Camera', 'Mirror 1', 'Mirror 2'};
VIEW_NAMES_SHORT = {'C', 'M1', 'M2'};

% Supported image and video extensions
% =========================================================================
% NOTE: Non-MP4 videos converted to MP4 in `convert_vid_to_mp4.m`, this
% needs to be changeed to convert to whichever default video format.
SUPPORTED_VID_EXTS = {'.mp4' '.avi' '.mov' '.m4v' '.mpg'};
SUPPORTED_IMG_EXTS = {'.jpg' '.png' '.tif' '.bmp'};

% Calibration Settings
% =========================================================================
% Minimum images required for a barely passable calibration.
MIN_CALIB_IMGS = 10;

% DLTdv8a Settings
% =========================================================================
% Offset due to header row for when saving 3D points in DLTdv8a format.
DLTDV_TRACKFILE_HEADER_OFFSET = 1;  % DO NOT CHANGE

% Default software filenames.
DLTDV_TRACKFILE_2D_BASE = 'xypts';   % DO NOT CHANGE
DLTDV_TRACKFILE_3D_BASE = 'xyzpts';  % DO NOT CHANGE

% MATLAB File Exchange (FEX)
% =========================================================================
% Stephen Cobeldick's natsort: An excellent tool for natural sorting in
% various scenarios. Does not impose filename restrictions which our
% provided sorting function (sortfiles_formatted.m) does. Download here:
% https://www.mathworks.com/matlabcentral/fileexchange/47434-natural-order-filename-sort
FEX_USE_NATSORT = false;

% tightfig: Removes excess space from figures. Download here:
% https://www.mathworks.com/matlabcentral/fileexchange/34055-tightfig-hfig
FEX_USE_TIGHTFIG = false;

% export_fig: Exports figures in excellent quality, plus has some very
% convenient options. Download here:
% https://www.mathworks.com/matlabcentral/fileexchange/23629-export-fig
FEX_USE_EXPORTFIG = false;

% BCT Calibration Processing
% =========================================================================
% Character vector representing default reference img suffix for extrinsics
% from BCT calibration. It's a character, since it may be 'ext' in the event
% the extrinsics reference is not part of the calibration image set and the
% extrinsics were computed via Comp. Extrinsic function of BCT.
EXTRINSICS_REFERENCE_IMG_SUFFIX = '1';

% Number of variables extracted from each BCT calibration output file
% Calib_Results.mat. For details, look at _saved_bct_params.txt.
NUM_UNIQUE_VARS_PER_CAM = 5;  % EDIT-UNSAFE
NUM_SHARED_VARS_CAMS = 2;     % EDIT-UNSAFE

% Permutation transform swaps X and Y (first 2 cols) of rotation matrix to
% force mirror view to be left-handed despite BCT forcing right-handedness.
PERM_TRANSFORM = [0 1 0; 1 0 0; 0 0 1];  % DO NOT CHANGE

% Video Settings
% =========================================================================
% By default, cover videos completely from start to end.
VID_START_TIME_SECONDS = 0;
VID_STOP_TIME_SECONDS = Inf;

% Command Window QoL
% =========================================================================
CWLINE_WIDTH = 90;
CWLINE_STYLE = repmat('=', 1, CWLINE_WIDTH);

% File Extensions
% =========================================================================
IMG_EXT = '.jpg';
GUESS_IMG_EXT_WHEN_POSSIBLE = true;

% MP4 is most compatible - other video formats supported by MATLAB's
% VideoReader are converted to this format in the toolbox scripts. THis is
% EDIT-UNSAFE (need to edit `convert_vid_to_mp4.m` if this is changed).

VID_EXT = '.mp4';    % EDIT-UNSAFE

% Default software extensions for relevant files required/output by BCT and
% DLTdv8a. Do not change unless you modify the software to your use case.

BCT_EXT = '.mat';    % EDIT-UNSAFE
DLTDV_EXT = '.csv';  % EDIT-UNSAFE

% File and Folder Name Formats
% =========================================================================
% The following are EDIT-UNSAFE as they may break our sorting function,
% which assumes availability of numeric parts. However, if you have natsort
% from MATLAB FEX and `FEX_USE_NATSORT` is set to true in this file, this
% is safe to edit.

% BCT requires numbered filenames and only asks for the non-numbered part.
% Additionally, since we rename the calibration images so that the numbered
% part is always a consecutive sequence of natural numbers starting from 1
% (Image1.jpg, Image2.jpg, ...), no blank images are loaded in case of any
% jumps between numbers. That is, if first image was Image 1 and the next was
% Image 5, BCT would normally create blank Image2, Image3, and Image4. This
% will never happen with the renamed files!

% Format for calibration images (BCT).
IMGNAME_FMT = 'Image%d%s';  % EDIT-UNSAFE

% Format for frames extracted from videos.
VID_FRAMENAME_FMT = 'Frame%d%s'; % EDIT-UNSAFE

% Epipolar results folder (ensures a new one is created per result set)
EPIPOLAR_RESULTS_FOLDER_FMT = 'set_%d';  % EDIT-UNSAFE

% Directories
% =========================================================================
% Test videos and images (containing object to mark/track points on)
MEDIA_DIR = 'media';  % EDIT-UNSAFE if done locally

% Store all PROJECT videos
VIDS_DIR = fullfile(MEDIA_DIR, 'videos');  % EDIT-UNSAFE if done locally

% Store all frames from PROJECT videos
VID_FRAMES_DIR = fullfile(MEDIA_DIR, 'frames');  % EDIT-UNSAFE if done locally

% Store imported test images
IMGS_DIR = fullfile(MEDIA_DIR, 'images');  % EDIT-UNSAFE if done locally

% DLTdv8a exported trackfiles xypts.csv and xyzpts.csv
DLTDV_TRACKFILES_DIR = 'trackfiles';  % EDIT-UNSAFE if done locally

% BCT calibration-related files and DLT coefficients
BCT_CALIB_DIR = 'calibration';  % EDIT-UNSAFE if done locally

% Images for calib (direct images or chosen from video frames)
BCT_CALIB_IMGS_DIR = fullfile(BCT_CALIB_DIR, 'images');  % EDIT-UNSAFE if done locally

% Store all frames from CALIBRATION videos
BCT_CALIB_FRAMES_DIR = fullfile(BCT_CALIB_DIR, 'frames');  % EDIT-UNSAFE if done locally

% Store previous seected subsets for calibration
BCT_CALIB_SUBSET_HIST_DIR = fullfile(BCT_CALIB_DIR, 'subset_selection_history');  % EDIT-UNSAFE if done locally

% Directory where results of reconstruction script are stored
RECONSTRUCTION_DIR = 'reconstruction';  % EDIT-UNSAFE if done locally

% Epipolar results go here under subfolders with an integer suffix
EPIPOLAR_DIR = 'epipolar';  % EDIT-UNSAFE if done locally

% Director sto store results of epipolar verification in
EPIPOLAR_RESULTS_DIR = fullfile(EPIPOLAR_DIR, EPIPOLAR_RESULTS_FOLDER_FMT);  % EDIT-UNSAFE if done locally

% Undistortion output frame folder names
UNDISTORTED_IMG_FOLDERS = {'cam_rect', 'mir1_rect', 'mir2_rect'};  % EDIT-UNSAFE if done locally

% File Basenames
% =========================================================================
% Calibration video name
BCT_CALIB_VID_BASE = 'calib';  % EDIT-UNSAFE if done locally

% DLTdv8a video name
VID_BASE = 'projvid';  % EDIT-UNSAFE if done locally

% Merged BCT parameters (all views in one)
BCT_MERGED_CALIB_BASE = 'bct_params';  % EDIT-UNSAFE if done locally

% 11 DLT coefficients file for DLTdv8a. Created from BCT params for each
% view separately and then merged into one csv file.
DLT_COEFS_BASE = 'dlt_coefs';  % EDIT-UNSAFE if done locally

% Manually marked points with `point_marker.m`
MARKED_POINTS_BASE = 'marked_points';  % EDIT-UNSAFE if done locally

% Filepaths, composed using the dirs, filenames, and extensions. Don't
% change these directly, consider changing their components.
% =========================================================================

% Path to the merged BCT calibration parameters file, combining only the
% needed parts of the camera and mirror calibrations into one file.
% BCT_MERGED_CALIB_PATH = strrep(fullfile(BCT_CALIB_DIR, ...
% [BCT_MERGED_CALIB_BASE BCT_EXT]),  '\', '\\');
BCT_MERGED_CALIB_PATH = fullfile(BCT_CALIB_DIR, [BCT_MERGED_CALIB_BASE BCT_EXT]);  % EDIT-UNSAFE if done locally

%  !!! THE FOLLOWING 2 ARE UNUSED!!! Part of an older design philosophy
%  that did not support view identities. Might be a way to incorporate them
%  later though.
% -------------------------------------------------------------------------
% Path to the camera's calibration result files.
% BCT_CAM_CALIB_PATH = strrep(fullfile(BCT_CALIB_DIR, ...
% [BCT_MERGED_CALIB_BASE BCT_EXT]),  '\', '\\');
BCT_CAM_CALIB_PATH = fullfile(BCT_CALIB_DIR, [BCT_MERGED_CALIB_BASE BCT_EXT]);  % EDIT-UNSAFE if done locally

% Path to the mirror's calibration result files (must be sprintf'd since
% BCT_MIR_CALIB_BASE_FMT contains formatting identifiers.
% BCT_MIR_CALIB_PATH = strrep(fullfile(BCT_CALIB_DIR, ...
% [BCT_MIR_CALIB_BASE_FMT BCT_EXT]),  '\', '\\');
BCT_MIR_CALIB_PATH = fullfile(BCT_CALIB_DIR, [BCT_MIR_CALIB_BASE_FMT BCT_EXT]);  % EDIT-UNSAFE if done locally
% -------------------------------------------------------------------------

% Calibration video import path.
BCT_CALIB_VID_PATH = fullfile(BCT_CALIB_DIR, [BCT_CALIB_VID_BASE, VID_EXT]);  % EDIT-UNSAFE if done locally

% Path to the saved 11 DLT Coefficients file (Dltdv8a ready).
% DLT_COEFS_PATH = strrep(fullfile(BCT_CALIB_DIR, ...
% [DLT_COEFS_BASE DLTDV_EXT]),  '\', '\\');
DLT_COEFS_PATH = fullfile(BCT_CALIB_DIR, [DLT_COEFS_BASE DLTDV_EXT]);  % EDIT-UNSAFE if done locally

% Path to the video that's going to be used in DLTdv8a.
VID_PATH = fullfile(VIDS_DIR, [VID_BASE VID_EXT]);  % EDIT-UNSAFE if done locally

% Path to the marked points
MARKED_POINTS_PATH = fullfile(RECONSTRUCTION_DIR, [MARKED_POINTS_BASE BCT_EXT]);  % EDIT-UNSAFE if done locally