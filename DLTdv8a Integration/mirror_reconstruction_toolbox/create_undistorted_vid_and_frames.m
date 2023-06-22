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

default = load('defaults.mat');

% Get image format.
while true

    frame_extension_mapping = struct('b', '.bmp', 'j', '.jpg', 'p', '.png', 't', '.tif');    
    
    helpfmt = [
        'HELP: Supported Image Formats = ' ...
        repmat('%s, ', 1, numel(default.SUPPORTED_IMG_EXTS) - 1) ...
        '%s\n("j" = ".jpg", "p" = ".png", "t" = ".tif", "b" = ".bmp"). ' ...
        'Leave blank to use default image extension.\n'
    ];

    fprintf(helpfmt, default.SUPPORTED_IMG_EXTS{:});

    frame_extension = input(['[PROMPT] Enter image extension for video frames (blank = default ' ...
        'image extension): '], 's');

    if isempty(frame_extension)
        frame_extension = default.IMG_EXT;
    elseif isfield(frame_extension_mapping, frame_extension)
        frame_extension = frame_extension_mapping.(frame_extension);
    else
        fprintf(['[BAD INPUT] Unrecognized extension. Enter either "j" or ".jpg" ' ...
            'for JPG and similarly for other extensions.\n'])
        continue
    end
    
    break
end

% If we did not get into this script from import_vid, we need to ask the
% user to locate the video to undistort.
if ~exist('vid_filepath', 'var')
    vid_filter = cellfun(@(extension) ['*' extension], default.SUPPORTED_VID_EXTS, 'UniformOutput', false)';
    
    [vid_file, vid_dir] = uigetfile(default.VID_EXT, ['Locate MP4 video containing tracking target for ' ...
        'undistortion'], default.DLTDV_VID_DIR ...
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

[view_params_file, view_params_dir] = uigetfile( ...
    ['*' default.BCT_EXT], ...
    'Locate the merged BCT calibration parameters file (cancel = use default location)' ...
);

if ~view_params_file
    view_params_filepath = default.BCT_MERGED_CALIB_PATH;
else
    view_params_filepath = fullfile(view_params_dir, view_params_file);
end

fprintf('Extracting video frames from %s...\n', vid_filepath)
vid_to_frames(vid_filepath, frames_dir, default.VID_FRAMENAME_FMT, frame_extension)
fprintf('Done extracting frames. Frames stored at:\n\t%s\n', frames_dir)

view_params = load(view_params_filepath);

% Get the view labels of the views in the file. This way, we ensure the
% right names are used for the right views. Additionally, bct_params are
% indexed according to the actual label, so these labels are also needed so
% as to pick the correct view's intrinsics and distortion coefficients.
view_labels = view_params.view_labels;
num_views = numel(view_labels);
output_folders = default.UNDISTORTED_FRAME_FOLDERS(view_labels);

for j = 1 : num_views
    k = view_labels(j);  % numbering identity preserved
    fprintf('\n|-- Undistorting Video w.r.t %s: %s --|\n', default.VIEW_NAMES_LONG{k}, vid_filepath)

    fprintf('Undistorting frames w.r.t. %s view\n', default.VIEW_NAMES_LONG{k});

    dist_coefs = view_params.(sprintf('kc_%d', k));
    intrinsics = view_params.(sprintf('KK_%d', k));

    % For originalName_cam_rect.jpg and originalName_mir1_rect.jpg, etc
    % type of outputs. Since frames go in different directories, suffixing
    % them is not necessary. However, undistorted videos are placed into
    % the same folder as the original by default, so we must keep a 
    % suffix for them to avoid overwriting the old one.
    undistorted_img_suffix = ''; 
    undistorted_vid_suffix = ['_' output_folders{j}];

    undistorted_imgs_dir = fullfile(frames_dir, output_folders{j});

    if ~isfolder(undistorted_imgs_dir)
        mkdir(undistorted_imgs_dir);
    end
    
    undistort_imgs( ...
        frames_dir, ...
        dist_coefs, ...
        intrinsics, ...
        undistorted_imgs_dir, ...
        undistorted_img_suffix,...
        false...
    );
    
    fprintf('Stitching undistorted frames back into a video...\n')
    undistorted_vid_filepath = fullfile(vid_dir, [vid_name undistorted_vid_suffix default.VID_EXT]);
    frames_to_vid(undistorted_imgs_dir, undistorted_vid_filepath)
    fprintf('Finished undistorting video.\n\tUndistorted Frames:%s\n\tUndistorted Video:%s\n', ...
        undistorted_imgs_dir, undistorted_vid_filepath ...
    )
end