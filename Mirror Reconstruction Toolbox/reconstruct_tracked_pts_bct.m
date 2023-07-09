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
if num_fields < min_cam_vars || num_fields > max_cam_vars
    error('Expected at least %d field vars, and at most %d.\n', min_cam_vars, max_cam_vars);
elseif num_views < default.MIN_VIEWS || num_views > default.MAX_VIEWS
    error('Number of views (%d) disagrees with the maximum (%d) and minimum number of views (%d).\n', ...
        num_views, default.MAX_VIEWS, default.MIN_VIEWS ...
    )
end

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
        'Select DLTdv8a exported flat-format file of tracked pixels w/o extension (cancel = use default location)' ...
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
    reconstructed_world_pts_filepath = fullfile( ...
        default.RECONSTRUCTION_DIR, ...
        [trackfile_3d_filename default.DLTDV_EXT] ...
    );
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
	choice = input('[PROMPT] Use undistorted video frames for point marking? (y/n): ', 's');
    
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

% Set optimizer options.
options = optimoptions('lsqnonlin', 'display', 'off');
options.Algorithm = 'levenberg-marquardt';

figpos_reprojection = { ...
    [0,0.459259259259259,0.384895833333333,0.540740740740741], ...
    [0,0, 0.384895833333333,0.542592592592593], ...
    [0.384895833333333,0.542592592592593,0.384895833333333,0.44] ...
};

figpos_reconstruction = [0.375,0,0.493229166666667,0.961111111111111];

% Initialize figures for 2D pixel reprojections.
figH = zeros(1, num_views + 1);

for j = 1 : num_views
    figH(j) = figure( ...
        'Name', sprintf('%s - Pixel Reprojections', view_names{j}), ...
        'Units', 'Normalized',...
        'Position', figpos_reprojection{j} ...
    );
end

% Figure for 3D reconstruction.
figH(num_views + 1) = figure( ...
    'Name', '3D Reconstruction', ...
    'Units', 'Normalized', ...
    'Position', figpos_reconstruction ...
);

% f x 2 cell vector to store estimated world coordinates of all tracked
% physical points in each frame. Each cell contains a 3 x n_pts array
% corresponding to the 3D world coordinates of the tracked points.
framewise_tracked_world_pts = cell(num_frames, 1);

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
per_view_reproj_error = Inf(1, num_views);

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
            sprintf(default.VID_FRAMENAME_FMT, f, frame_extension)) ...
        );
    else
        img = imread( ...
            fullfile( ...
                frames_dir, ...
                sprintf(default.VID_FRAMENAME_FMT, f, frame_extension) ...
            ) ...
        );
    end

    % Calculate reprojection error.
    reproj_error = mean(abs(proj_pixels_org - proj_pixels_est), 'all');
    per_view_reproj_error(1, j) = reproj_error;

    % Plot the pixels.
    set(0, 'currentfigure', figH(j));
    imshow(img); hold on;
    % xlabel('x (pixel)'); ylabel('y (pixel)');
    title(sprintf('%s: Pixel Reprojections for Estimated World Coordinates\nFrame %d/%d', ...
        view_names{j}, frame_num, num_frames) ...
    );
    plot(proj_pixels_est(1, :), proj_pixels_est(2, :), 'r*', 'linewidth', 1, 'MarkerSize', 7);
    plot(proj_pixels_org(1, :), proj_pixels_org(2, :), 'bo', 'linewidth', 1, 'MarkerSize', 8);
    legend('est WC reprojections',  'org WC reprojections')
    hold off;
end
mean_reproj_error = mean(per_view_reproj_error, 'all'); 
fprintf('done.\n')

%% 3D VISUALIZATION - RECONSTRUCTION %%

% Switch to reconstruction figure.
set(0, 'currentfigure', figH(num_views + 1))

% Mark first point in red for reference; rest in blue.
plot3(X_est(1, 1), X_est(2, 1), X_est(3, 1), 'r*');

title('3D Reconstruction')
xlabel('X_{est} (mm)'); ylabel('Y_{est} (mm)'); zlabel('Z_{est} (mm)');
hold on; grid on;

plot3(X_est(1, 2 : num_points), X_est(2, 2 : num_points), X_est(3, 2 : num_points), 'b*');

if f == 1
    % Plot the cameras (original + virtual).
    colors = {'red', 'blue', 'green'};
    labels = {'C', 'M1', 'M2'};

    for j = 1 : num_views
        k = view_labels(j);

        % Get the current view's rotation and translation. Technically, we
        % need the camera w.r.t world, but Computer Vision Toolbox's
        % plotCamera function automatically handles that.
        R_cam = R(:, 3*(j-1)+1 : 3*j);
        T_cam = T(:, j);
        if k == 1
            plot_cam( ...
                R_cam, ...
                T_cam, ...
                30, ...         % size of plotted camera
                colors{k}, ...  % color of plotted camera
                labels{k}, ...  % label of plotted camera (annotation)
                true, ...       % whether the camera XYZ frame is shown
                0 ...           % opacity of camera, 0 = transparent
            );
        else
            % This does not use plotCamera, and just plots the camera axes.
            % red = x, green = y, blue = z axes. In the function, you'll
            % find the aforementioned inversion to get the camera in world
            % coordinates reference.
            plot_virtual_cam(R_cam, T_cam)
        end
    end
end

% for i = 1 : numel(figH)
%     tightfig(figH(i));
% end

axis equal
drawnow()

%% METRIC PRINTOUT %%

fprintf('\t*** ERRORS ***\n');
fprintf('\tMean Reprojection Error (OVERALL): %f\n', mean(per_view_reproj_error(1, :), 'all'));
fmt = ['\tMean Reprojection Error (PER-VIEW): ', repmat('%f, ', 1, numel(per_view_reproj_error(1, :)) - 1), '%f\n'];
fprintf(fmt, per_view_reproj_error(1, :));
fmt = ['\tEstimated 3D Points: ', repmat('(%4.4f, %4.4f, %4.4f), ', 1, num_points - 1), '(%4.4f, %4.4f, %4.4f)\n'];
fprintf(fmt, X_est);

%% 3D RECONSTRUCTION ERROR: Comment if not required. %%
% Distance between consecutive physical points in real-world units. Comment
% out if not interested in 3D reconstruction error. If n points marked, it
% should be a n-1 element vector [1->2, 2->3, ..., i->i+1, ..., n-1->n].
% org_dists = [];

% est_dist = NaN(1, n_pts - 1);
% for i = 1 : n_pts - 1
%     est_dist(i) = norm(X_est(:, i) - X_est(:, i+1), 2);
% end
% fmt = ['\tNormed Distance Between Neighboring Points: ', repmat('%4.4f, ', 1, numel(est_dist) - 1), '%4.4f\n'];
% fprintf(fmt, est_dist);
% dd=mean(est_dist);
% %fprintf('Mean of est dis is\n:',dd);
% error_dist = est_dist - org_dist;
% fmt = ['\tErrors w.r.t Original Distances: ', repmat('%4.4f, ', 1, numel(est_dist) - 1), '%4.4f\n'];
% fprintf(fmt, error_dist);
% disp(dd)
% fprintf('\n\tMean Distance Error: %4.4f\n', mean(error_dist, 'all'))
% orignan_2d = sqrt(sum((proj_pixels_org - proj_pixels_est).^2));
% figure(5);
% %histogram(error_dist, 20);
% %D=sqrt((y(1)-x(1))^2+(y(2)-x(2))^2);
% histogram(orignan_2d, 110);
% xlabel('X (mm)'); ylabel('Y (mm)');
% hold on;

end

%% FINAL STEPS %%

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
