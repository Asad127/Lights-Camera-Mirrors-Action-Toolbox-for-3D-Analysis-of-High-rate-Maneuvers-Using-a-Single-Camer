%{ 
TERMINOLOGY
===========================================================================
Assume a calibrated single camera, 2-mirror setup (3 sets of intrinsics, 
one for each view). We actually have the option to use either DLT to 
recover the params or load them in directly. Arguably, it is better to use 
the DLT params as this allows maximum compatibility with DLTdv8a. So, we 
use the three sets of calculated DLT coefficients from the csv files 
generated from `filegen_dlt_coefs.m` 

Let the number of views be n_views (=3 in this case). Let the recovered K, 
R, and T from the DLT coefficients via `dlt_to_krt.m` be arrays of 
intrinsics (3, 3 * n_views), rotation matrices (3, 3 * n_views), and 
translation vectors (3, n_views), where each (3, 3) slice represents a 
particular view's parameters.

Let F be the total number of frames in the video, irrespective of whether
the frame actually had data or not. Let f be the current frame number.

Let n_points be the total number of physical points we are tracking over 
frames, irrespective of whether we marked the point in all frames F or a 
subset of F. Let the 3D world coordinates of these physical points be X, an 
array of size (3, n). Let i be the current physical point, such that X_i is 
the (3, 1) coordinate of that point. X_i may be NaN based on user input at
a given frame.

Let x be the complete set of homoegnous coordinates over all views 
corresponding to the pixel locations of all n points in a given frame f. 
Thus, for a frame f, x has size (3, n_views * n_points). x is structured 
such that:
           _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 
          |      _ _ _ _ _      _ _ _ _ _      _ _ _ _ _     |
          |     |         |    |         |    |         |    |
      x = |   3 |  View 1 |  3 |  View 2 |  3 |  View 3 |    |
          |     |  pixels |    |  pixels |    |  pixels |    |
          |     |_ _ _ _ _|    |_ _ _ _ _|    |_ _ _ _ _|    |
          |        n_pts          n_pts          n_pts       |
          |_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ |

The first n_pts entries of x are the homogenous pixel locations of n_pts in 
the FIRST camera/view, the second set of n_pts entries are the pixel 
locations for the second camera, and so on. In other words, we loop over 
points first and camera views second. This is in contrast to DLTdv8a's 
tracked pixel exported format, where the view changes first and points 
second. The conversion from that to this script's expected format is
handled in `process_trackfile_reconst.m`.

We handle x over different frames by putting this structure inside a cell
array of size (F, 1). Thus, if we had 20 frames, we'd have 20 cells, and
each would contain an instance of x .

The setup remains stationary, the object of interest moves around. So, RT 
will remain the same for each view over all frames, but the set of pixels x 
corresponding to the total n physical points in all views will with each 
passing frame as object moves. We get these from DLTdv8a's exported points
as tracked over the frames.

NOTE ON UNDISTORTION AND IMAGE NAMING CONVENTIONS
===========================================================================
Make sure images are undistorted according to the calibration prior to 
using this script. Each view (camera, mirror 1, and mirror 2) should be
calibrated separately prior to running this script, resulting in three 
spearate sets of distortion coefficients (one for each view). 

When running this script, an image at time instace t should be copied as 
many times as there are mirrors (2 copies for a total of 3 images at time t
in this case). The files should be named starting from 1.jpg (original), 
2.jpg (mirror 1), and 3.jpg (mirror 2) for the first image at time t. 
The second image at time instance t+1 would then be saved as 4.jpg, 5.jpg, 
and 6.jpg, and so on. The undistortions to each image should be applied 
corresponding to the dist. coefficients associated with its camera/view.

MIRROR REFLECTION AND THE TOOLBOX'S FORCED RIGHT-HANDEDNESS
===========================================================================
The world X and Y are swapped in the mirrors due to the toolbox's
preservation of right-handedness at all costs. This corrupts the extrinsics
for the mirrors , where the rotation about the established world Y is 
actually the rotation about the world X, and that about X is actually about 
Y. 

 Z          Z'                                 Z'         Z
 |          |                                  |          |
 |_ _ Y     |_ _ X'  (or as it appears)  X' _ _|  MIRROR  |_ _ Y
/          /                                  /          /
X          Y'                               Y'           X

We basically have two solutions which are two sides of the same coin.
Either swap the X and Y in the world coordinate vector (left multiply X 
with permute transform whenever current view is a mirror) OR swap the first
and second columns of the rotation matrix (right multiply Rc with permute
transform just once at start of script). 

The latter is more technically sound and efficient for a large set of data, 
but it makes the rotation mtx non-orthognal (negative determinant). This 
makes us unable to use some functions such as MATLAB's plotCamera, which 
requires Rigid 3D Transforms and rejects negative det rotation  matrices. 
As such, to plot the virtual camera representing a first-reflection mirror 
view, we need to make our own plotting function. 

While swapping the X and Y keeps the rotation mtx +ve determinant, the cam
plotted with plotCamera is still wrong since we know that the virtual cam
is left-handed, whereas the plotted cam is right-handed.

Finally notice that no swapping takes place in the translation vector.
That's because it is already defined in terms of camera coordinates and not
the world coordinates, whereas the rotation matrix is define so as to
operate on world frame and orient it according to camera frame. Thus, only
the rotation matrix needs the swapping. You can verify this:

(TODO) DEBUGGING RECONSTRUCTION ERROR IN REAL UNITS WITH DLTDV
===========================================================================
If reconstructing calibration pattern for debugging purposes, run 
`debug_calib_reconst_dltdv.mat` instead. The known pattern distances can be 
used to easily compute the reconstruction error in terms of real world 
units (mm) there. This script can also be used to do that, but requires 
measuring the real world distances, marking the points in each view, and 
associating the points to the distances beforehand, which can be a bit of 
work.

IMPORTANT FUNCTIONS CALLED
===========================================================================
dlt_to_krt.m
    To convert from DLT params to KRT form if initialized with DLT.
process_trackfile_reconst.m
    Read the flat-format exported tracked pixels (2D points) from DLTdv8a
    in a usable format for this script.
%}

clear
close all
clc


format long g  % fixed notation for non-extreme values

set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultAxesFontSize', 12);
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
fprintf(['Calibrate your camera and mirrors with Bouguet Calibration Toolbox (BCT) prior to ' ... 
    'starting. Have the\nDLT coefficients file for DLTdv8a or merged BCT camera parameters ' ...
    '(intrinsics + extrinsics + distortion)\nready.\n\n'])

fprintf('Locating BCT merged calibration file...')
% INPUT 1: Choose the camera params file (DLT or KRT).
[calib_file, calib_dir] = uigetfile( ...
    ['*', default.BCT_EXT], ...
    'Select merged BCT calibration parameters file (blank = use default location)' ...
);
if ~calib_file
    calib_file = default.BCT_MERGED_CALIB_PATH;
    if ~isfile(calib_file)
        error('The merged BCT calibration parameters file does not exist at default location:\n\t%s', ...
            calib_file)
    end
else
    calib_file = fullfile(calib_dir, calib_file);
end
fprintf('found.\n')

% PROCESS INPUT 1: Extract K, R, and T for each view.
% Some limits for checks.
min_cam_vars = default.NUM_UNIQUE_VARS_PER_CAM * default.MIN_VIEWS + default.NUM_SHARED_VARS_CAMS;
max_cam_vars = default.NUM_UNIQUE_VARS_PER_CAM * default.MAX_VIEWS + default.NUM_SHARED_VARS_CAMS;

% Load the file and get the number of variables (fields) inside it.
view_params = load(calib_file);
num_views = numel(view_params.view_labels);
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
view_labels = view_params.view_labels;
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
        trackfile = fullfile(default.DLTDV_TRACKFILES_DIR, [default.DLTDV_TRACKFILE_2D_BASE default.DLTDV_EXT]);
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
[framewise_tracked_pixels, num_frames, valid_frames, invalid_frames, num_pts] = reconstruction_process_trackfile(trackfile, num_views);
num_valid_frames = length(valid_frames);
fprintf('Total frames: %d\nValid frames: %d\nNo. of physical points: %d\n\n', ...
    num_frames, num_valid_frames, num_pts ...
)

% Delete the known suffix to get the trackfile name prefix.
[~, trackfile_name, ~] = fileparts(trackfile);
trackfile_name_prefix = char(erase( ...
    string(trackfile_name), ...                  % original string
    string(default.DLTDV_TRACKFILE_2D_BASE) ...  % this gets deleted from string
));

trackfile_3d_filename = [trackfile_name_prefix default.DLTDV_TRACKFILE_3D_BASE default.DLTDV_EXT];

[file, directory] = uiputfile( ...
    ['*' default.DLTDV_EXT], ...
    'Choose path to save the estimated 3D world points to (cancel = use default location)', ...
    trackfile_3d_filename ...
);

if ~file
    reconstructed_world_pts_filepath = fullfile( ...
        default.RECONSTRUCTION_DIR, ...
        [default.DLTDV_TRACKFILE_3D_BASE default.DLTDV_EXT] ...
    );
else
    reconstructed_world_pts_filepath = fullfile(directory, file);
end

% INPUT 3: Directory containing the video frames.
fprintf('Locating directory containing video frames corresponding to tracked points...')
frames_dir = uigetdir('', 'Locate the directory containing video frames (cancel = use default directory)');
if ~frames_dir
    frames_dir = default.DLTDV_VID_FRAMES_DIR;
    if ~isfolder(frames_dir)
        error('The provided directory does not exist:\n\t%s', frames_dir)
    end
end

has_frames = false;
for i = 1 : numel(default.SUPPORTED_IMG_EXTS)
    img_ext = default.SUPPORTED_IMG_EXTS{i};
    img_filepaths = dir(fullfile(frames_dir, ['*' img_ext]));
    img_filepaths = {img_filepaths.name};
    if ~isempty(img_filepaths)
        has_frames = true;
        break
    end
end

if has_frames
    fprintf('found.\n')
    if num_frames ~= numel(img_filepaths)
        while true
            fprintf('The number of frames from trackfile does not match the number of frames in directory.\n')
            proceed_with_uneuqal_frames = input('[PROMPT] Proceed anyway? (y/n): ', 's');
            if ~ismember(proceed_with_uneuqal_frames, {'y', 'n'})
                fprintf('[BAD PROMPT] Only "y" (yes) and "n" (no) are accepted values. Please try again.\n')
                continue
            end
            break
        end
        if proceed_with_uneuqal_frames == 'n'
            error('Operation canceled by user.')
        end
    end
end

while true
	undistorted_reprojections = input('[PROMPT] Use undistorted frames for pixel reprojections? (y/n): ', 's');
	if ~ismember(undistorted_reprojections, {'y', 'n'})
		fprintf('[BAD PROMPT] Only "y" (yes) and "n" (no) are accepted inputs. Please try again.\n')
		continue
	end
	break
end

if undistorted_reprojections == 'y'
    output_folders = default.UNDISTORTED_FRAME_FOLDERS;
    output_folders = output_folders(view_labels);
    for j = 1 : num_views
        if ~isfolder(fullfile(frames_dir, output_folders{j}))
            err_msg = sprintf(['Undistorted frames were not found in the expected location, i.e., ' ...
                'same directory as original, but separate folders.\nTo ensure proper undistortion ' ...
                'setup, run "create_undistorted_vid_and_fames.m" or "create_undistorted_imgs.m".']);
            error(err_msg)
        end
    end
end

% Set optimizer options.
options = optimoptions('lsqnonlin', 'display', 'off');
options.Algorithm = 'levenberg-marquardt';

figpos_reprojection = {
    [0,0.459259259259259,0.384895833333333,0.540740740740741], ...
    [0,0, 0.384895833333333,0.542592592592593] ... 
};
figpos_reconstruction = [0.375,0,0.493229166666667,0.961111111111111];

% Initialize figures for 2D pixel reprojections.
figH = zeros(1, num_views + 1);

for j = 1 : num_views
    figH(j) = figure('Name', 'Pixel Reprojections', 'Units', 'Normalized', 'Position', figpos_reprojection{j});
end

% Figure for 3D reconstruction.
figH(num_views + 1) = figure('Name', '3D Reconstruction', 'Units', 'Normalized', 'Position', figpos_reconstruction);

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
X_est_homo = zeros(4, num_pts);  % to store the estimated 3D world coordinates
xpp = zeros(3, num_views);       % to store pixels corresponding to each physical point in all views

for i = 1 : num_pts
    
    % Get pixel location of the i'th physical point in all n views. Also, 
    % check if at least 2 views have non-nan values. Otherwise, it is not
    % possible to reconstruct this point.
    views_with_tracked_pixels = zeros(1, num_views);
    for j = 1 : num_views
        xpp(:, j) = x(:, num_pts*(j-1)+i);
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
    proj_pixels_org = x(:, num_pts*(j-1)+1 : j*num_pts);
    
    % Projected pixel locations from estimated world coordinates.
    proj_pixels_est = K(:, 3*(j-1)+1 : 3*j) * [R(:, 3*(j-1)+1 : 3*j) T(:, j)] * X_est_homo; 
    proj_pixels_est = proj_pixels_est./proj_pixels_est(3, :);

    % Read the image in.
    if undistorted_reprojections == 'y'
	    img = imread(fullfile( ...
            frames_dir, ...
            output_folders{j}, ...
            sprintf(default.VID_FRAMENAME_FMT, f, img_ext)) ...
        );
    else
        img = imread(fullfile( ...
            frames_dir, ...
            sprintf(default.VID_FRAMENAME_FMT, f, img_ext)) ...
        );
    end

    % Calculate reprojection error.
    reproj_error = mean(abs(proj_pixels_org - proj_pixels_est), 'all');
    per_view_reproj_error(1, j) = reproj_error;
    
    % Plot the pixels.
    set(0, 'currentfigure', figH(j));
    imshow(img); hold on;
    xlabel('x (pixel)'); 
    ylabel('y (pixel)');
    title(sprintf('Pixel Reprojections for Estimated World Coordinates\nFrame %d/%d', frame_num, num_frames));
    plot(proj_pixels_est(1, :), proj_pixels_est(2, :), 'r*', 'linewidth', 1, 'MarkerSize', 7);
    plot(proj_pixels_org(1, :), proj_pixels_org(2, :), 'bo', 'linewidth', 1, 'MarkerSize', 8);
    legend('est WC reprojections',  'org WC reprojections')
    hold off;
end
fprintf('done.\n')

%% 3D VISUALIZATION - RECONSTRUCTION %%

% Switch to reconstruction figure.
set(0, 'currentfigure', figH(num_views + 1))

% Mark first point in red for reference; rest in blue.
plot3(X_est(1, 1), X_est(2, 1), X_est(3, 1), 'r*');
plot3(X_est(1, 2 : num_pts), X_est(2, 2 : num_pts), X_est(3, 2 : num_pts), 'b*');

title('3D Reconstruction')
xlabel('X_{est} (mm)'); ylabel('Y_{est} (mm)'); zlabel('Z_{est} (mm)');
hold on; grid on;

if f == 1
    % Plot the cameras (original + virtual).
    colors = {'red', 'blue', 'green'};
    labels = {'C', 'M1', 'M2'};
    
    for j = 1 : num_views
        k = view_labels(j);

        % Get the current view's rotation and translation.
        R_cam = R(:, 3*(j-1)+1 : 3*j);
        T_cam = T(:, j);
        if k == 1
            plot_cam( ...
                R_cam, ...
                T_cam, ...
                30, ...
                colors{k}, ...
                labels{k}, ...
                true, ...
                0 ...
            );
        else
            plot_virtual_cam(R_cam, T_cam)
        end
    end
end

for i = 1 : numel(figH)
    tightfig(figH(i));
end

axis equal
drawnow()

%% METRIC PRINTOUT %%

fprintf('\t*** ESTIMATED WORLD COORDS ***\n');
fprintf('\tMean Reprojection Error (OVERALL): %f\n', mean(per_view_reproj_error(1, :), 'all'));
fmt = ['\tMean Reprojection Error (PER-VIEW): ', repmat('%f, ', 1, numel(per_view_reproj_error(1, :)) - 1), '%f\n'];
fprintf(fmt, per_view_reproj_error(1, :));
fmt = ['\tEstimated 3D Points: ', repmat('(%4.4f, %4.4f, %4.4f), ', 1, num_pts - 1), '(%4.4f, %4.4f, %4.4f)\n'];
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

for invalid_frame_idx = reshape(invalid_frames, 1, [])
    framewise_tracked_world_pts{invalid_frame_idx} = nan(3, num_pts);
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
