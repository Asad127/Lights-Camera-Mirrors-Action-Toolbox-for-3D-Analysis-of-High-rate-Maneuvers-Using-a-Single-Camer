% Takes a vdeo, extracts frames from it, undistorts the frames using the
% distortion coefficients from the merged BCT camera parameters file, and
% then stitches the undistorted frames back together into a video.
% Maintains frame sequence by sorting on directory reads. 
% 
% The frame extraction is done only once, but undistortion and video 
% creation from undistorted frames are performed as many times as there 
% are views. So in a 2-view case, the images will be undistorted 2 times, 
% first using the distortion coefficients for the first view, and then 
% the 2nd view, and the results are stored in separate folders in the 
% directory where the frames are extracted. The folders are named after 
% the view's label, so cam_rect, mir1_rect, mir2_rect, etc (these are
% also defined in the `create_undistorted_imgs.m` script, which only 
% undistorts selected image files or all images in a given directory.
%
% This script is automatically called by `import_media.m`, which copies a
% video to the project directory and converts it to mp4 (if needed).

default = load('defaults.mat');

% Get format of extracted frames.
frame_extension = prompt_img_extension(['[PROMPT] Enter image extension for video frames (blank ' ...
    '= default image extension): '] ...
);

% If we did not get into this script from `import_media.m`, we need to ask 
% user to locate the video to undistort.
if ~exist('vid_filepath', 'var')
    vid_filter = cellfun(@(extension) ['*' extension], default.SUPPORTED_VID_EXTS, 'UniformOutput', false)';
    
    [vid_file, vid_dir] = uigetfile( ...
        default.VID_EXT, ...
        'Locate MP4 video containing tracking target for undistortion', ...
        default.DLTDV_VID_DIR ...
    );
    
    if ~vid_file
        error('Operation canceled by user.');
    end
    
    vid_filepath = fullfile(vid_dir, vid_file);
end

[vid_dir, vid_name, ~] = fileparts(vid_filepath);

frames_dir = uigetdir('', ['Choose directory to extract the video frames into (cancel = ' ...
    'use default directory)'] ...
);

if ~frames_dir
    frames_dir = default.DLTDV_VID_FRAMES_DIR;
end

[merged_calib_file, merged_calib_dir] = uigetfile( ...
    ['*' default.BCT_EXT], ...
    'Locate the merged BCT calibration parameters file (cancel = use default location)' ...
);

if ~merged_calib_file
    merged_calib_filepath = default.BCT_MERGED_CALIB_PATH;
    if ~isfile(merged_calib_filepath)
        error(['Merged BCT calibration parameters file does not exist at default location:' ...
            '\n\t%s\nPossible Issues:' ...
            '\n\t(1) Merged BCT calibration file was not saved to the default location.' ...
            '\n\t(2) Merged BCT calibration file was not created.' ...
            '\nPossible Solutions:' ...
            '\n\t(1) Use the UI to locate the file wherever it was saved.' ...
            '\n\t(2) Run "calib_process_results.m" before running this script.'], ...
            merged_calib_filepath ...
        )
    end
else
    merged_calib_filepath = fullfile(merged_calib_dir, merged_calib_file);
end

fprintf('Extracting video frames from %s...\n', vid_filepath)
vid_to_frames(vid_filepath, frames_dir, default.VID_FRAMENAME_FMT, frame_extension)
fprintf('Done extracting frames. Frames stored at:\n\t%s\n\n', frames_dir)

view_params = load(merged_calib_filepath);

% Get the view labels of the views in the file. This way, we ensure the
% right names are used for the right views. Additionally, bct_params are
% indexed according to the actual label, so these labels are also needed so
% as to pick the correct view's intrinsics and distortion coefficients.
view_labels = view_params.view_labels;
view_names = default.VIEW_NAMES_LONG(view_labels);

num_views = numel(view_labels);
undistorted_img_folders = default.UNDISTORTED_IMG_FOLDERS(view_labels);

for j = 1 : num_views
    k = view_labels(j);  % numbering identity preserved
    fprintf('|-- Undistorting Video w.r.t %s View --|\n\n', view_names{j}, vid_filepath)
    fprintf('Undistorting extracted frames...\n');

    dist_coefs = view_params.(sprintf('kc_%d', k));
    intrinsics = view_params.(sprintf('KK_%d', k));

    % Undistorted videos are placed into the same folder as the original by 
    % default, so we must keep a suffix for them to avoid overwriting the 
    % old one.
    undistorted_vid_suffix = ['_' undistorted_img_folders{j}];

    undistorted_imgs_dir = fullfile(frames_dir, undistorted_img_folders{j});

    if ~isfolder(undistorted_imgs_dir)
        mkdir(undistorted_imgs_dir);
    end
    
    undistort_imgs( ...
        frames_dir, ...
        dist_coefs, ...
        intrinsics, ...
        undistorted_imgs_dir ...
    );
    
    fprintf('Stitching undistorted frames back into a video...\n')
    
    undistorted_vid_filepath = fullfile(vid_dir, [vid_name undistorted_vid_suffix default.VID_EXT]);
    
    frames_to_vid(undistorted_imgs_dir, undistorted_vid_filepath)
    
    fprintf('Finished undistorting video.\n\n\tUndistorted Frames:%s\n\tUndistorted Video:%s\n\n', ...
        undistorted_imgs_dir, undistorted_vid_filepath ...
    )
end

fprintf('Video and its individual frames have been undistorted w.r.t. all %d views.\n\n', num_views)

fprintf(['NEXT STEPS: Marking/Tracking Points In Images For Reconstruction' ...
    '\n\n- Run "point_marker.m", followed by "reconstruct_marked_pts_bct.m" to reconstruct ' ...
    'manually marked points\n  on the object in a single image (no DLTdv8a required). \n\n- ' ...
    'OR, Run DLTdv8a app from project root, locate the video (either distorted or undistorted) and ' ...
    'begin marking\n  points for tracking. Once done, export (from within DLTdv8a) the tracked ' ...
    '2D points to trackfiles in flat\n  format, and then reconstruct the tracked 2D points with ' ...
    '"reconstruct_tracked_pts_bct.m".\n\n'] ...
)