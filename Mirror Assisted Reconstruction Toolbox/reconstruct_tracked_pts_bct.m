% Script to reconstruct tracked pixels over frames as provided by DLTdv8a.
% If you want to reconstruct manually marked points on a still image, use
% `reconstruction_marked_pts_bct.m` instead.
%
% IMPORTANT FUNCTIONS CALLED
% =========================================================================
% reconstruction_process_trackfile.m:
%   Processes the DLTdv8a exported trackfile and returns the pixel location
%   of each point over all views and frames in a cell array of size
%   (num_frames, num_points * num_views). This format is accepted by this
%   script.
% save_reconstructed_pts_dltdv8a.m:
%   Saves the estimated 3D world points in DLTdv8a-like format.

format long g  % fixed notation for non-extreme values

set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultAxesFontSize', 16);
set(groot, 'defaultfigurecolor', [1 1 1]);
% txtoptions_bold = {'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold'};
% txtoptions = {'FontName', 'Times New Roman', 'FontSize', 18};

%% SETUP %%

default = load('defaults.mat');

MIN_VIEWS_FOR_RECONSTRUCTION = 2;

disp('=====================================================================================================')
disp('|           VIRTUAL-CAMERA (MIRROR) BASED 3D RECONSTRUCTION WITH NON-LINEAR LEAST SQUARES           |')
disp('=====================================================================================================')
disp('|                   Intended for use with DLTdv8a and Bouguet Calibration Toolbox                   |')
disp('|                           Supports up to 3 views : 1 camera, 2 mirrors                            |')
disp('=====================================================================================================')
fprintf('Script for reconstructing tracked 2D points (via DLTdv8a) in videos.\n\n')

fprintf('Locating BCT merged calibration file...')
% INPUT 1: Choose the camera params file (DLT or KRT).
[merged_calib_file, merged_calib_dir] = uigetfile( ...
    ['*', default.BCT_EXT], ...
    'Select merged BCT calibration parameters file (blank = use default location)' ...
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
fprintf('found.\n')

% PROCESS INPUT 1: Extract K, R, and T for each view.
% Some limits for checks.
min_cam_vars = default.NUM_UNIQUE_VARS_PER_CAM * default.MIN_VIEWS + default.NUM_SHARED_VARS_CAMS;
max_cam_vars = default.NUM_UNIQUE_VARS_PER_CAM * default.MAX_VIEWS + default.NUM_SHARED_VARS_CAMS;

% Load the file, get view names for available view labels, and check file integrity.
view_params = load(merged_calib_filepath);
view_labels = view_params.view_labels;

view_names = default.VIEW_NAMES_LONG(view_labels);
view_names = view_names(view_labels);  % keep only the view names whose labels are available

num_views = numel(view_labels);
num_fields = numel(fieldnames(view_params));

% Check: Can't have more than 3 or less than 2 cams (views)
% if num_fields < min_cam_vars || num_fields > max_cam_vars
%     error('Expected at least %d field vars, and at most %d.\n', min_cam_vars, max_cam_vars);
% elseif num_views < default.MIN_VIEWS || num_views > default.MAX_VIEWS
%     error('Number of views (%d) disagrees with the maximum (%d) and minimum number of views (%d).\n', ...
%         num_views, default.MAX_VIEWS, default.MIN_VIEWS ...
%     )
% end

fprintf('Determined no. of cameras/views: %d\n', num_views)
fprintf('Expected Field Variables: %d | Received Field Variables: %d\n', ...
    default.NUM_UNIQUE_VARS_PER_CAM * num_views + default.NUM_SHARED_VARS_CAMS, num_fields ...
)

K = NaN(3, 3*num_views); R = NaN(3, 3*num_views); T = NaN(3, num_views);
fprintf('Extracting intrinsics and extrinsics from KRT file...')

% Again, like in `calib_process_results.m`, j is relative in the sense
% that it represents the number of views without care for the view label.
% k preserves the exact view label. Since the merged calbiration file
% provides the view labels and indexes into the cam params accordingly,
% we need to use them to extract information. However, our arrays are
% contiguous, and that means, for example, if there are 2 views, even if
% it was view 1 and view 3, there will always be 6 columns in the rot
% matrix instead of 9, where 1:3 would have been view 1's, 4:6 being nan
% for view 2, and 7:9 being view 3's. Thus, we need the relative count
% still in order to slice into our arrays properly.
for j = 1 : num_views
    k = view_labels(j);
    K(:, 3*(j-1)+1 : 3*j) = view_params.(sprintf('KK_%d', k));
    R(:, 3*(j-1)+1 : 3*j) = view_params.(sprintf('Rc_%d', k));  % -ve determinant for mirror views
    T(:, j) = view_params.(sprintf('Tc_%d', k));
end
fprintf('done.\n\n')

% INPUT 2: Choose the file containing the tracked points pixel locations.
fprintf('Locating DLTdv8a exported trackfile containing tracked points...')
while true
    [trackfile_file, trackfile_dir] = uigetfile( ...
        ['*' default.DLTDV_EXT], ...
        'Select DLTdv8a exported flat-format file of tracked pixels (cancel = use default location)' ...
    );
    if ~trackfile_file
        trackfile = fullfile(default.DLTDV_TRACKFILES_DIR, ...
            [default.DLTDV_TRACKFILE_2D_BASE default.DLTDV_EXT] ...
        );
        if ~isfile(trackfile)
            error('The DLTdv8a exported trackfile does not exist at default location:\n\t%s', trackfile)
        end
    else
        trackfile = fullfile(trackfile_dir, trackfile_file);
    end
    break
end
fprintf('found.\n')

% PROCESS INPUT 2: Get them into a format acceptable for this script and
% extract some useful information.
[framewise_tracked_pixels, num_frames, mask_nan_rows, num_points] = ...
    reconstruction_process_trackfile(trackfile, num_views);

valid_frame_idxs = find(~mask_nan_rows);
invalid_frame_idxs = find(mask_nan_rows);

num_valid_frames = length(valid_frame_idxs);

fprintf('Total frames: %d\nValid frames: %d\nNo. of physical points: %d\n\n', ...
    num_frames, num_valid_frames, num_points ...
)

% Delete the known suffix to get the trackfile name prefix.
[~, trackfile_name, ~] = fileparts(trackfile);

trackfile_name_prefix = char( ...
    erase( ...
        string(trackfile_name), ...                  % original string
        string(default.DLTDV_TRACKFILE_2D_BASE) ...  % this gets deleted from string
    ) ...
);

trackfile_3d_filename = [trackfile_name_prefix default.DLTDV_TRACKFILE_3D_BASE default.DLTDV_EXT];

[file, directory] = uiputfile( ...
    ['*' default.DLTDV_EXT], ...
    'Choose path to save the estimated 3D world points to (cancel = use default location)', ...
    trackfile_3d_filename ...
);

if ~file
    reconstructed_world_pts_filepath = fullfile(default.RECONSTRUCTION_DIR, trackfile_3d_filename);
else
    reconstructed_world_pts_filepath = fullfile(directory, file);
end

[reconstruction_dir, ~, ~] = fileparts(reconstructed_world_pts_filepath);

% INPUT 3: Directory containing the video frames.
fprintf('Locating directory containing video frames corresponding to tracked points...')
frames_dir = uigetdir('', ['Locate the directory containing non-undistorted video frames ' ...
    '(cancel = use default directory)'] ...
);
if ~frames_dir
    frames_dir = default.VID_FRAMES_DIR;
    if ~isfolder(frames_dir)
        error('The provided directory does not exist:\n\t%s', frames_dir)
    end
end

if default.GUESS_IMG_EXT_WHEN_POSSIBLE
    frame_extension = guess_img_extension(frames_dir, default.SUPPORTED_IMG_EXTS);
else
    frame_extension = prompt_img_extension('[PROMPT] Enter the frame extension (blank = use default):');
end

% Check if the directory contains any images and load their filepaths.
frames_listing = dir(fullfile(frames_dir, ['*' frame_extension]));

% Get rid of '.' and '..' from listing
frames_listing = frames_listing(~ismember({frames_listing.name}, {'.', '..'}));

% The following check takes place in `guess_img_extension.m`, but not in
% `prompt_img_extension.m` as that is also used to determine output img
% extensions, not just for input files.
if isempty(frames_listing)
    error('No frames with extension "%s" were found in the directory:\n\t%s', ...
        frame_extension, frames_dir ...
    )
end

frame_files = {frames_listing.name};

if num_frames ~= numel(frame_files)
    while true
        fprintf(['\n[WARNING] The number of frames from trackfile does not match the number of ' ...
            'frames in directory.\n\tFrames Detected In Directory = %d\n\tFrames Detected In ' ...
            'Trackfile = %d\n'], ...
            numel(frame_files), num_frames ...
        )
        proceed_with_uneuqal_frames = input('[PROMPT] Proceed anyway? (y/n): ', 's');
        if ~ismember(proceed_with_uneuqal_frames, {'y', 'n'})
            fprintf('[BAD PROMPT] Only "y" (yes) and "n" (no) are accepted values. Please try again.\n')
            continue
        end
        break
    end
    if proceed_with_uneuqal_frames == 'n'
        error('Operation canceled by user.')
    else
        minimum_frames = min(num_frames, numel(frame_files));
        maximum_frames = max(num_frames, numel(frame_files));
        fprintf('Only plotting data for %d/%d available frames.\n\n', minimum_frames, maximum_frames)
    end
else
    fprintf('done.\n\n');
end

% Ask if user wants to use undistorted images.
fprintf('HELP: Only enter "y" if you have the undistorted images or video frames.\n');
while true
	choice = input('[PROMPT] Use undistorted video frames for reprojections? (y/n): ', 's');

    if ~ismember(choice, {'y', 'n'})
		fprintf('[BAD INPUT] Only "y" (yes) and "n" (no) are accepted inputs. Please try again.\n')
		continue
    end

    if choice == 'y'
        use_undistorted_frames = true;
    else
        use_undistorted_frames = false;
    end

	break
end

if use_undistorted_frames
    all_undistorted_frame_folders = default.UNDISTORTED_IMG_FOLDERS;
    undistorted_frame_folders = all_undistorted_frame_folders(view_labels);
    undistorted_frame_dirs = fullfile(frames_dir, undistorted_frame_folders);

    % Check that the directories exist, and contain images.
    for i = 1 : numel(undistorted_frame_dirs)  % should be equal to num_views

        if ~isfolder(undistorted_frame_dirs{i})

            error(['An undistorted frames folder was not found in the expected location:' ...
                '\n\t%s\nIn general, they are expected in the same directory as the original image ' ...
                'in separate folders folders.\nTo ensure proper undistortion setup, run ' ...
                '"create_undistorted_vid_and_fames.m" (videos) or\n"create_undistorted_imgs.m" ' ...
                '(images).'], undistorted_frame_dirs{i} ...
            );

        else
            % List all image files in the directory.
            img_listing = dir(fullfile(undistorted_frame_dirs{i}, ['*' frame_extension]));

            % Check if directory even has images.
            if isempty(img_listing(~ismember({img_listing.name}, {'.', '..'})))
                error('Undistorted frames folder was found, but has no images.\n\t%s', ...
                    undistorted_frame_dirs{i} ...
                );
            end
        end
    end
end

% Create colormap for frame visualization.
% All frames will use the colormap for consistency and flexibility.
if num_valid_frames > 1
    % Create colormap for all frames.
    all_frames_colors = colormap('nebula');
    % Interpolate colors for all frames.
    color_indices = linspace(1, size(all_frames_colors, 1), num_valid_frames);
    all_frames_colors_interp = interp1(1:size(all_frames_colors, 1), all_frames_colors, color_indices);
else
    all_frames_colors_interp = [1, 0, 0]; % Default red for single frame.
end

% Set optimizer options.
options = optimoptions('lsqnonlin', 'display', 'off');
options.Algorithm = 'levenberg-marquardt';

% 2x2 layout positions to fill the screen with margins.
% Top row: 2D reprojection plots
% Bottom row: 3D reconstruction plots
% Adding 5% margin on all sides (0.05 = 5% margin)
margin = 0.05;
fig_width = 0.40; % 0.5 - 2*margin
fig_height = 0.40; % 0.5 - 2*margin

% Calculate center position and spacing for tight grouping
center_x = 0.5 - fig_width/2;
center_y = 0.5 - fig_height/2;
spacing_h = 0.0005; % Horizontal spacing between figures
spacing_v = 0.052; % Vertical spacing between figures

figpos_2x2 = { ...
    [center_x - fig_width/2 - spacing_h/2, center_y + fig_height/2 + spacing_v/2, fig_width, fig_height], ...     % Top-left: First 2D reprojection
    [center_x + fig_width/2 + spacing_h/2, center_y + fig_height/2 + spacing_v/2, fig_width, fig_height], ...     % Top-right: Second 2D reprojection (if exists)
    [center_x - fig_width/2 - spacing_h/2, center_y - fig_height/2 - spacing_v/2, fig_width, fig_height], ...     % Bottom-left: 3D reconstruction
    [center_x + fig_width/2 + spacing_h/2, center_y - fig_height/2 - spacing_v/2, fig_width, fig_height] ...      % Bottom-right: 3D points only
};


% Initialize figures for 2D pixel reprojections.
figH = zeros(1, num_views + 1);

% Close any existing figures to start fresh.
close all;

for j = 1 : num_views
    figH(j) = figure( ...
        'Name', sprintf('%s - Pixel Reprojections', view_names{j}), ...
        'Units', 'Normalized',...
        'Position', figpos_2x2{j}, ...
        'NumberTitle', 'off' ...
    );
end

% Figure for 3D reconstruction.
figH(num_views + 1) = figure( ...
    'Name', '3D Reconstruction w/ Cameras', ...
    'Units', 'Normalized', ...
    'Position', figpos_2x2{3}, ...
    'NumberTitle', 'off' ...
);

% Figure for 3D points only.
figH(num_views + 2) = figure( ...
    'Name', '3D Reconstruction', ...
    'Units', 'Normalized', ...
    'Position', figpos_2x2{4}, ...
    'NumberTitle', 'off' ...
);

% f x 2 cell vector to store estimated world coordinates of all tracked
% physical points in each frame. Each cell contains a 3 x n_pts array
% corresponding to the 3D world coordinates of the tracked points.
framewise_tracked_world_pts = cell(num_frames, 1);
last_valid_frame = valid_frame_idxs(end);

% Open output file for writing metadata and metrics.
output_txtfile = fopen(fullfile(reconstruction_dir, 'output.txt'), 'w');

% Initialize arrays to store error statistics for CSV output.
overall_mean_errors = zeros(1, num_valid_frames);
overall_rms_errors = zeros(1, num_valid_frames);
per_view_mean_errors = zeros(num_views, num_valid_frames);
per_view_rms_errors = zeros(num_views, num_valid_frames);

% Pre-allocate arrays for 3D reconstruction visualization.
all_X_est = zeros(3, num_points, num_valid_frames);
all_frame_colors = zeros(num_valid_frames, 3);
all_marker_styles = cell(1, num_valid_frames);
all_marker_sizes = zeros(1, num_valid_frames);

% Pre-allocate per-view error arrays.
per_view_mean_reproj_errors = zeros(num_views, num_valid_frames);
per_view_rms_reproj_errors = zeros(num_views, num_valid_frames);

% Print metadata at the start.
fprintf(output_txtfile, '[%s]\n', datetime('now'));
fprintf(output_txtfile, 'Number of Views: %d\n', num_views);
fprintf(output_txtfile, 'Total Frames: %d\n', num_frames);
fprintf(output_txtfile, 'Valid Frames: %d (%d-%d)\n', num_valid_frames, valid_frame_idxs(1), valid_frame_idxs(end));
fprintf(output_txtfile, 'Number of Points per Frame: %d\n', num_points);
fprintf(output_txtfile, 'Use Undistorted Images: %s\n\n', string(use_undistorted_frames));

% Create colormap for frame visualization.
% Start and end frames will be special (blue crosses and red crosses).
% Middle frames will use 'nebula' colormap with circles.
if num_valid_frames > 2
    % Create colormap for middle frames (excluding first and last).
    middle_frames_colors = colormap('nebula');
    % Interpolate colors for the number of middle frames.
    middle_frame_indices = 2:(num_valid_frames-1);
    color_indices = linspace(1, size(middle_frames_colors, 1), length(middle_frame_indices));
    middle_frames_colors_interp = interp1(1:size(middle_frames_colors, 1), middle_frames_colors, color_indices);
else
    middle_frames_colors_interp = [];
end

for f = 1 : num_valid_frames
%% OPTIMIZATION PER POINT FOR N-VIEW WORLD COORDINATE ESTIMATION %%
x = framewise_tracked_pixels{f, 1};
frame_num = framewise_tracked_pixels{f, 2};

% Everything below is in homogenous coordinates.
fprintf('\nEstimating world coordinates with lsqnonlin: ')

X_init = ones(4, 1);             % initial guess for optimizer
X_est_homo = zeros(4, num_points);  % to store the estimated 3D world coordinates
xpp = zeros(3, num_views);       % to store pixels corresponding to each physical point in all views

for i = 1 : num_points

    % Get pixel location of the i'th physical point in all n views. Also,
    % check if at least 2 views have non-nan values. Otherwise, it is not
    % possible to reconstruct this point.
    views_with_tracked_pixels = zeros(1, num_views);
    for j = 1 : num_views
        xpp(:, j) = x(:, num_points*(j-1)+i);
        if ~isnan(xpp(1, j))
            views_with_tracked_pixels(j) = 1;
        end
    end
    views_with_tracked_pixels = find(views_with_tracked_pixels);

    % If not more than 2 views with nan, we skip this one.
    if numel(views_with_tracked_pixels) < MIN_VIEWS_FOR_RECONSTRUCTION
        X_est_homo(:, i) = nan(1, 4);    % fill with nan
        continue
    end

    % Estimate the 3D world coordinates.
    Xpp = lsqnonlin( ...
        @(Xpp)reconst_coords_per_px(Xpp, views_with_tracked_pixels, xpp, K, R, T), ...
        X_init, [], [], options);

    % Normalize w.r.t homogenous coordinate.
    Xpp = Xpp./Xpp(4);

    % Append to array of all pts, will be 4 x n_pts by end.
    X_est_homo(:, i) = Xpp;
end

% Make a non-homogenous version and store to framewise cell array.
X_est = X_est_homo(1:3, :);
framewise_tracked_world_pts{frame_num} = X_est;

fprintf('done.\n')

%% PIXEL REPROJECTION WITH ESTIMATED WORLD POINTS %%

fprintf('Reprojecting using the estimated world coordinates... ')

% Pre-allocate arrays for reprojection data.
all_proj_pixels_org = zeros(3, num_points, num_views, num_valid_frames);
all_proj_pixels_est = zeros(3, num_points, num_views, num_valid_frames);
all_images = cell(num_views, num_valid_frames);

for j = 1 : num_views
    % True pixel locations for all physical points as marked.
    proj_pixels_org = x(:, num_points*(j-1)+1 : j*num_points);

    % Projected pixel locations from estimated world coordinates.
    proj_pixels_est = K(:, 3*(j-1)+1 : 3*j) * [R(:, 3*(j-1)+1 : 3*j) T(:, j)] * X_est_homo;
    proj_pixels_est = proj_pixels_est./proj_pixels_est(3, :);

    % Read the image in.
    if use_undistorted_frames
	    img = imread(fullfile( ...
            undistorted_frame_dirs{j}, ...
            sprintf(default.VID_FRAMENAME_FMT, valid_frame_idxs(f), frame_extension)) ...
        );
    else
        img = imread( ...
            fullfile( ...
                frames_dir, ...
                sprintf(default.VID_FRAMENAME_FMT, valid_frame_idxs(f), frame_extension) ...
            ) ...
        );
    end

    % Calculate mean reprojection error as well as RMS reprojection error over all points.
    sum_of_squared_pixel_diff_vec = sum((proj_pixels_org - proj_pixels_est).^2, 1);
    reproj_error_vec = sqrt(sum_of_squared_pixel_diff_vec);
    mean_reproj_error = mean(reproj_error_vec);
    rms_reproj_error = sqrt(mean(sum_of_squared_pixel_diff_vec));

    per_view_mean_reproj_errors(j, f) = mean_reproj_error;
    per_view_rms_reproj_errors(j, f) = rms_reproj_error;

    % Store data for later use.
    all_proj_pixels_org(:, :, j, f) = proj_pixels_org;
    all_proj_pixels_est(:, :, j, f) = proj_pixels_est;
    all_images{j, f} = img;

    % Plot the pixels.
    set(0, 'currentfigure', figH(j));

    % Use imagesc instead of imshow to prevent automatic figure resizing.
    imagesc(img); axis image; axis off;
    hold on;
    title(sprintf('%s: Pixel Reprojections for Estimated World Coordinates\nFrame %d/%d', ...
        view_names{j}, frame_num, num_frames) ...
    );
    plot(proj_pixels_est(1, :), proj_pixels_est(2, :), 'r*', 'linewidth', 1, 'MarkerSize', 7);
    plot(proj_pixels_org(1, :), proj_pixels_org(2, :), 'bo', 'linewidth', 1, 'MarkerSize', 8);
    legend('est WC reprojections',  'org WC reprojections')
    hold off;

    % Store error statistics for CSV output.
    per_view_mean_errors(j, f) = mean_reproj_error;
    per_view_rms_errors(j, f) = rms_reproj_error;
end
mean_reproj_error_overall = mean(per_view_mean_reproj_errors(:, f));
rms_reproj_error_overall = mean(per_view_rms_reproj_errors(:, f));

% Store overall error statistics for CSV output.
overall_mean_errors(f) = mean_reproj_error_overall;
overall_rms_errors(f) = rms_reproj_error_overall;

fprintf('done.\n')

%% 3D VISUALIZATION - RECONSTRUCTION %%

% Store current frame data for later visualization.
all_X_est(:, :, f) = X_est;

% Determine marker style and color based on frame position.
if f == 1
    % First frame: colored cross using colormap.
    frame_color = all_frames_colors_interp(f, :);
    marker_style = 'x';
    marker_size = 18;
elseif f == num_valid_frames
    % Last frame: colored cross using colormap.
    frame_color = all_frames_colors_interp(f, :);
    marker_style = 'x';
    marker_size = 18;
else
    % Middle frames: colored circles using nebula colormap.
    frame_color = all_frames_colors_interp(f, :);
    marker_style = 'o';
    marker_size = 6;
end

% Store visualization parameters.
all_frame_colors(f, :) = frame_color;
all_marker_styles{f} = marker_style;
all_marker_sizes(f) = marker_size;

% Switch to reconstruction figure.
set(0, 'currentfigure', figH(num_views + 1))

% Only clear and set up the figure on the first frame.
if f == 1
    clf; % Clear the figure only once at the beginning.

    % Set up the figure properties first.
    title('3D Reconstruction w/ Cameras')
    xlabel('X_{est} (mm)'); ylabel('Y_{est} (mm)'); zlabel('Z_{est} (mm)');
    axis equal
    hold on; % Keep the figure open for adding points.

    % Plot the cameras (original + virtual) only once, after figure setup.
    for j = 1 : num_views
        k = view_labels(j);
        R_cam = R(:, 3*(j-1)+1 : 3*j);
        T_cam = T(:, j);

        if k == 1
            % Original view. Can use plotCamera since +ve det rotation matrix.
            pose_cam = rigidtform3d(R_cam, T_cam);

            % pose_cam is the camera pose in CAMERA coordinates, pose_world is the camera's pose in WORLD coordinates
            % (inversion of pose_cam). Note that invert(pose_cam) is equivalent to extr2pose(pose_cam).
            pose_world = invert(pose_cam);

            plotCamera( ...
                'AbsolutePose', pose_world, ...
                'Size', 30, ...
                'Color', 'red', ...
                'Label', 'C', ...
                'AxesVisible', true, ...
                'Opacity', 0.10 ...
            );

        else
            % Virtual mirror view. Can't use plotCamera since negative determinant on rotation matrix.
            % Use the enhanced plot_virtual_cam function for better visualization.
            plot_virtual_cam(R_cam, T_cam);
        end
    end
end

% Plot all points for current frame with appropriate styling.
if f == 1 || f == num_valid_frames
    % For start/end frames, use crosses with colormap color.
    for i = 1:num_points
        plot3(X_est(1, i), X_est(2, i), X_est(3, i), marker_style, 'Color', frame_color, 'MarkerSize', marker_size, 'LineWidth', 2);
    end
else
    % For middle frames, use colored circles.
    for i = 1:num_points
        plot3(X_est(1, i), X_est(2, i), X_est(3, i), marker_style, 'Color', frame_color, 'MarkerSize', marker_size, 'LineWidth', 1);
    end
end

grid on;
drawnow()

%% 3D POINTS-ONLY VISUALIZATION %%

% Switch to points-only figure.
set(0, 'currentfigure', figH(num_views + 2))

% Only clear and set up the figure on the first frame.
if f == 1
    clf; % Clear the figure only once at the beginning.

    % Set up the figure properties first.
    title('3D Reconstruction')
    xlabel('X_{est} (mm)'); ylabel('Y_{est} (mm)'); zlabel('Z_{est} (mm)');
    axis equal
    hold on; % Keep the figure open for adding points.
end

% Use pre-allocated data for consistency.
frame_color = all_frame_colors(f, :);
marker_style = all_marker_styles{f};
marker_size = all_marker_sizes(f);

% Adjust marker size for points-only plot (larger crosses).
if f == 1 || f == num_valid_frames
    marker_size = 18;
end

% Plot all points for current frame with appropriate styling.
if f == 1 || f == num_valid_frames
    % For start/end frames, use crosses with colormap color.
    for i = 1:num_points
        plot3(X_est(1, i), X_est(2, i), X_est(3, i), marker_style, 'Color', frame_color, 'MarkerSize', marker_size, 'LineWidth', 2);
    end
else
    % For middle frames, use colored filled circles.
    for i = 1:num_points
        plot3(X_est(1, i), X_est(2, i), X_est(3, i), marker_style, 'Color', frame_color, 'MarkerSize', marker_size, 'LineWidth', 1, 'MarkerFaceColor', frame_color);
    end
end

% Dynamically adjust the plot to ensure all drawn points are visible.
if f == 1
    % Set initial view limits based on first frame.
    xlim([min(X_est(1, :)) - 10, max(X_est(1, :)) + 10]);
    ylim([min(X_est(2, :)) - 10, max(X_est(2, :)) + 10]);
    zlim([min(X_est(3, :)) - 10, max(X_est(3, :)) + 10]);
else
    % Update limits to include new points.
    current_xlim = xlim;
    current_ylim = ylim;
    current_zlim = zlim;

    new_xlim = [min(current_xlim(1), min(X_est(1, :)) - 10), max(current_xlim(2), max(X_est(1, :)) + 10)];
    new_ylim = [min(current_ylim(1), min(X_est(2, :)) - 10), max(current_ylim(2), max(X_est(2, :)) + 10)];
    new_zlim = [min(current_zlim(1), min(X_est(3, :)) - 10), max(current_zlim(2), max(X_est(3, :)) + 10)];

    xlim(new_xlim);
    ylim(new_ylim);
    zlim(new_zlim);
end

grid on;
drawnow()

% Save 3D reconstruction figures as .fig files for later viewing.
if f == num_valid_frames
    % Save the main 3D reconstruction figure (with cameras).
    fig_3d_cameras_filename = '3d_reconstruction_with_cameras.fig';
    fig_3d_cameras_filepath = fullfile(reconstruction_dir, fig_3d_cameras_filename);
    saveas(figH(num_views + 1), fig_3d_cameras_filepath);

    % Save the 3D points-only figure.
    fig_3d_points_filename = '3d_reconstruction_points_only.fig';
    fig_3d_points_filepath = fullfile(reconstruction_dir, fig_3d_points_filename);
    saveas(figH(num_views + 2), fig_3d_points_filepath);
end

%% METRIC PRINTOUT %%
fprintf('\nFRAME %d / %d (relative) ; %d / %d (absolute)\n', f, num_valid_frames, frame_num, last_valid_frame);
fprintf(output_txtfile, '\nFRAME %d / %d (relative) ; %d / %d (absolute)\n', f, num_valid_frames, frame_num, last_valid_frame);
fprintf('\t*** ERRORS ***\n');
fprintf(output_txtfile, '\t*** ERRORS ***\n');
fprintf('\tMean Reprojection Error (OVERALL): %f\n', mean_reproj_error_overall);
fprintf(output_txtfile, '\tMean Reprojection Error (OVERALL): %f\n', mean_reproj_error_overall);
fmt = ['\tMean Reprojection Error (PER-VIEW): ', repmat('%f, ', 1, numel(per_view_mean_reproj_errors(:, f)) - 1), '%f\n'];
fprintf(fmt, per_view_mean_reproj_errors(:, f));
fprintf(output_txtfile, fmt, per_view_mean_reproj_errors(:, f));
fprintf('\tRMS Reprojection Error (OVERALL): %f\n', rms_reproj_error_overall);
fprintf(output_txtfile, '\tRMS Reprojection Error (OVERALL): %f\n', rms_reproj_error_overall);
fmt = ['\tRMS Reprojection Error (PER-VIEW): ', repmat('%f, ', 1, numel(per_view_rms_reproj_errors(:, f)) - 1), '%f\n'];
fprintf(fmt, per_view_rms_reproj_errors(:, f));
fprintf(output_txtfile, fmt, per_view_rms_reproj_errors(:, f));
fmt = ['\tEstimated 3D Points: ', repmat('(%4.4f, %4.4f, %4.4f), ', 1, num_points - 1), '(%4.4f, %4.4f, %4.4f)\n'];
fprintf(fmt, X_est);
fprintf(output_txtfile, fmt, X_est);

end

%% FINAL STEPS %%

% Close the output file.
fclose(output_txtfile);

% Save reprojection error statistics to CSV files.
% Overall errors CSV with statistics
[overall_variances, overall_std_devs] = calculate_error_statistics(overall_mean_errors, overall_rms_errors);
overall_errors_table = table((1:num_valid_frames)', overall_mean_errors', overall_rms_errors', overall_variances', overall_std_devs', ...
    'VariableNames', {'Frame', 'MeanError', 'RMSError', 'Variance', 'StdDev'});
writetable(overall_errors_table, fullfile(reconstruction_dir, 'reprojection_errors.csv'));

% Per-view errors CSV with statistics
% Pre-allocate: num_valid_frames * num_views rows × 6 columns (Frame, View, MeanError, RMSError, Variance, StdDev)
per_view_errors_data = zeros(num_valid_frames * num_views, 6);
row_idx = 1;

for f = 1:num_valid_frames
    for j = 1:num_views
        % Get the mean and RMS errors for this frame and view
        view_mean_error = per_view_mean_errors(j, f);
        view_rms_error = per_view_rms_errors(j, f);
        if view_rms_error > 0
            view_variance = view_rms_error^2 - view_mean_error^2;
            view_std_dev = sqrt(view_variance);
        else
            view_variance = 0;
            view_std_dev = 0;
        end

        % Add statistics for this frame and view
        per_view_errors_data(row_idx, :) = [valid_frame_idxs(f), j, view_mean_error, view_rms_error, view_variance, view_std_dev];
        row_idx = row_idx + 1;
    end
end

per_view_errors_table = array2table(per_view_errors_data, ...
    'VariableNames', {'Frame', 'View', 'MeanError', 'RMSError', 'Variance', 'StdDev'});
writetable(per_view_errors_table, fullfile(reconstruction_dir, 'reprojection_errors_per_view.csv'));

for invalid_frame_idx = reshape(invalid_frame_idxs, 1, [])
    framewise_tracked_world_pts{invalid_frame_idx} = nan(3, num_points);
end
save_reconstructed_pts_dltdv8a( ...
    framewise_tracked_world_pts, ...
    reconstructed_world_pts_filepath ...
);

%% FUNCTIONS %%
function error = reconst_coords_per_px(X, views_with_pixels, x, K, R, T)
%{
We go point-by-point and pixel-by-pixel, so we get three reprojection
errors (one per view). LSQNONLIN requires a vectored error function and
not a scalar value. So, we vectorize all three.
%}
    vector_err = [];
    for j = views_with_pixels

        % Get the actual pixel location of the i'th point in the j'th view.
        target = x(:, j);

        % Use current guess of 3D world points to get the pixel
        % projections from the forward projection equation.
        pred = K(:, 3*(j-1)+1 : j*3) * [R(:, 3*(j-1)+1 : j*3) T(:, j)] * X;

        % Normalize w.r.t. homogenous coordinate.
        pred = pred./pred(3, :);

        % Get the reprojection error and vectorize it.
        reproj_error = target - pred;
        vector_err = [vector_err reproj_error];
    end
    error = vector_err;
end

function [variances, std_devs] = calculate_error_statistics(mean_errors, rms_errors)
%{
Calculate variance and standard deviation from mean and RMS errors.
This function converts the recover_stdev_and_var.m script into a reusable function.

INPUTS:
    mean_errors: Array of mean reprojection errors for each frame
    rms_errors: Array of RMS reprojection errors for each frame

OUTPUTS:
    variances: Array of variances for each frame
    std_devs: Array of standard deviations for each frame
%}
    % Get the number of frames
    num_frames = length(mean_errors);

    % Initialize arrays to store variance and standard deviation
    variances = zeros(1, num_frames);
    std_devs = zeros(1, num_frames);

    % Compute variance and standard deviation for each frame
    for i = 1:num_frames
        variances(i) = rms_errors(i)^2 - mean_errors(i)^2;
        std_devs(i) = sqrt(variances(i));
    end
end
