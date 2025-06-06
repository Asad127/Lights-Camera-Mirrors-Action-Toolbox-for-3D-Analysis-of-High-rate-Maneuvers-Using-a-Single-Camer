% Script to reconstruct manually marked pixels for all points in an image. Mark points with `point_marker.m`.
%
% If you want to reconstruct manually marked points on a still image, use `reconstruction_marked_pts_bct.m` instead.

%% SETUP %%

format long g

disp('=====================================================================================================')
disp('|           VIRTUAL-CAMERA (MIRROR) BASED 3D RECONSTRUCTION WITH NON-LINEAR LEAST SQUARES           |')
disp('=====================================================================================================')
disp('|                   Intended for use with DLTdv8a and Bouguet Calibration Toolbox                   |')
disp('|                           Supports up to 3 views : 1 camera, 2 mirrors                            |')
disp('=====================================================================================================')
fprintf('Reconstructing manually marked points on objects in a single image/frame.\n\n')

default = load('defaults.mat');

set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultAxesFontSize', 12);
set(groot, 'defaultfigurecolor', [1 1 1]);

% Locate image to use.
fprintf('Locating the non-undistorted image containing the object of interest...')

img_filter = cellfun(@(extension) ['*' extension], default.SUPPORTED_IMG_EXTS, 'UniformOutput', false)';

[img_file, img_dir] = uigetfile( ...
    img_filter, ...
    'Locate non-undistorted image containing the object you want to reconstruct' ...
);

if ~img_file
    error('Operation canceled by user.')
end

img_filepath = fullfile(img_dir, img_file);
[~, img_name, img_extension] = fileparts(img_filepath);

fprintf('done.\n')

% Load file containing marked points.
fprintf('Locating file containing marked points on the image...')

[pts_file, pts_dir] = uigetfile( ...
    '*.mat', ...
    'Locate file containing the manually marked points for each view in the image (cancel = use default location)' ...
);

if ~pts_file
    pts_file = default.MARKED_POINTS_PATH;
else
    pts_file = fullfile(pts_dir, pts_file);
end

marked_points = load(pts_file);  % loads in `num_points` and `x`
x = marked_points.x;
num_points = marked_points.num_points;

fprintf('done.\n')

% Load the KRT params (calibration).
fprintf('Locating merged BCT calibration parameters...')

[merged_calib_file, merged_calib_dir] = uigetfile( ...
    '*.mat', ...
    'Locate merged BCT calibration parameters file (cancel = use default location)' ...
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

view_params = load(merged_calib_filepath);
view_labels = view_params.view_labels;

num_views = numel(view_labels);
view_names = default.VIEW_NAMES_LONG(view_labels);  % keep only the view names whose labels are available

% NOTE: like in `calib_process_results.m`, j is relative in the sense that it represents the number of views without
% care for the view label. k preserves the exact view label. Since the merged calbiration file provides the view labels
% and indexes into the cam params accordingly, we need to use them to extract information. However, our arrays are
% contiguous, and that means, for example, if there are 2 views, even if it was view 1 and view 3, there will always be
% 6 columns in the rot matrix instead of 9, where 1:3 would have been view 1's, 4:6 being nan for view 2, and 7:9 being
% view 3's. Thus, we need the relative count still in order to slice into our arrays properly.

% Load in the camera extrinsics and intrinsics for each view from the merged calibration file.

KK = zeros(3, 3 * num_views); R = zeros(3, 3 * num_views); T = zeros(3, num_views);
for j = 1 : num_views
    % Get label k of the j'th view (camera = 1, mirror 1 = 2, mirror 2 = 3) If only had mirrors 1 and 2, k would be 2
    % and 3.
    k = view_labels(j);

    KK(:, 3*(j-1)+1 : 3*j) = view_params.(sprintf('KK_%d', k));
    R(:, 3*(j-1)+1 : 3*j) = view_params.(sprintf('Rc_%d', k));
    T(:, j) = view_params.(sprintf('Tc_%d', k));
end

fprintf('done.\n')

% Choose path to save reconstruction results to.
fprintf('Choosing base directory to save reconstruction variables to...')

reconstruction_dir = uigetdir( ...
    '', ...
    'Choose base directory to save reconstruction variables to (cancel = use default location)' ...
);

if ~reconstruction_dir
    reconstruction_dir = default.RECONSTRUCTION_DIR;
    if ~isfolder(reconstruction_dir)
        warning(['Reconstruction directory did not exist at default location:' ...
            '\n\t%s\nIt was created, but this indicates the project was not setup correctly.\n' ...
            'Consider repairing project structure by running `project_repair`.'], ...
            default.RECONSTRUCTION_DIR ...
        );
        mkdir(reconstruction_dir)
        reconstruction_dir = abspath(reconstruction_dir);
    end
end

saveloc_dir = fullfile(reconstruction_dir, img_name);

if ~isfolder(saveloc_dir)
    mkdir(saveloc_dir)
end

fprintf('done.\n\n')

% Ask if user wants to use undistorted images.
fprintf('HELP: Only enter "y" if you have the undistorted images/video frames.\n');
while true
	choice = input('[PROMPT] Use undistorted images for reprojections? (y/n): ', 's');

    if ~ismember(choice, {'y', 'n'})
		fprintf('\n[BAD INPUT] Only "y" (yes) and "n" (no) are accepted inputs. Please try again.\n')
		continue
    end

    if choice == 'y'
        use_undistorted_imgs = true;
    else
        use_undistorted_imgs = false;
    end

	break
end

if ~use_undistorted_imgs
    img = imread(img_filepath);
else
    all_undistorted_img_folders = default.UNDISTORTED_IMG_FOLDERS;
    undistorted_img_folders = all_undistorted_img_folders(view_labels);
    undistorted_img_dirs = fullfile(img_dir, undistorted_img_folders);

    % Check that the directories exist, and contain images.
    for i = 1 : numel(undistorted_img_dirs)  % should be equal to num_views

        if ~isfolder(undistorted_img_dirs{i})

            error(['An undistorted image folder was not found in the expected location:' ...
                '\n\t%s\nIn general, they are expected in the same directory as the original image ' ...
                'in separate folders folders.\nTo ensure proper undistortion setup, run ' ...
                '"create_undistorted_vid_and_fames.m" (videos) or\n"create_undistorted_imgs.m" ' ...
                '(images).'], undistorted_img_dirs{i} ...
            );

        else
            % List all image files in the directory.
            img_listing = dir(fullfile(undistorted_img_dirs{i}, ['*' img_extension]));

            % Check if directory even has images.
            if isempty(img_listing(~ismember({img_listing.name}, {'.', '..'})))
                error('Undistorted images folder was found, but has no images.\n\t%s', undistorted_img_dirs{i});
            end
        end
    end
end

% Set optimizer options.
options = optimoptions('lsqnonlin', 'display', 'off');
options.Algorithm = 'levenberg-marquardt';

figpos_reprojection = { ...
    [0,0.621296296296296,0.375,0.283333333333333], ...
    [0,0.362962962962963,0.375,0.283333333333333], ...
    [0,0.04537037037037,0.375,0.283333333333333] ...
};

% figpos_reconstruction = [0.375, 0.15, 0.60, 0.75];
figpos_reconstruction = [0.375,0.047,0.6,0.857];

% Initialize figures for 2D pixel reprojections.
figH = zeros(1, num_views + 1);

for j = 1 : num_views
    figH(j) = figure( ...
        'Name', sprintf('%s - Pixel Reprojections', view_names{j}), ...
        'Units', 'normalized',...
        'Position', figpos_reprojection{j} ...
    );
end

% Figure for 3D reconstruction.
figH(num_views + 1) = figure( ...
    'Name', '3D Reconstruction', ...
    'Units', 'normalized', ...
    'Position', figpos_reconstruction ...
);

%% OPTIMIZATION PER PIXEL FOR N-VIEW WORLD COORDINATE ESTIMATION %%
% Everything below is in homogenous coordinates.
fprintf('\nEstimating world coordinates with lsqnonlin...')

X_init = ones(4, 1);                % initial guess for optimizer
X_est_homo = zeros(4, num_points);  % to store the estimated 3D world coordinates
xpp = zeros(3, num_views);          % to store pixel corresponding to i'th physical point in all views

for i = 1 : num_points
    for j = 1 : num_views
        xpp(:, j) = x(:, num_points*(j-1)+i);
    end

    % Estimate the 3D world coordinates.
    Xpp = lsqnonlin( ...
        @(Xpp)reconst_coords_per_px(Xpp, num_views, xpp, KK, R, T), ...
        X_init, [], [], options);

    % Normalize w.r.t homogenous coordinate.
    Xpp = Xpp./Xpp(4);

    % Append to array, will be 4 x num_points by end.
    X_est_homo(:, i) = Xpp;
end
fprintf('done.\n')

X_est = X_est_homo(1:3, :);

%% PIXEL REPROJECTION VISUALIZATION %%
fprintf('Reprojecting using the estimated world coordinates... ')
per_view_mean_reproj_error = Inf(1, num_views);
per_view_rms_reproj_error = Inf(1, num_views);

% Initialize array to store projected points for all views.
proj_pixels_est_all = zeros(2, num_points * num_views);

for j = 1 : num_views
    % True pixel locations for all physical points as marked.
    proj_pixels_org = x(:, num_points*(j-1)+1 : j*num_points);

    % Projected pixel locations from estimated world coordinates.
    proj_pixels_est = KK(:, 3*(j-1)+1 : 3*j) * [R(:, 3*(j-1)+1 : 3*j) T(:, j)] * X_est_homo;
    proj_pixels_est = proj_pixels_est./proj_pixels_est(3, :);

    % Store projected points for this view.
    proj_pixels_est_all(:, num_points*(j-1)+1 : j*num_points) = proj_pixels_est(1:2, :);

    % Calculate mean reprojection error as well as RMS reprojection error over all points.
    sum_of_squared_pixel_diff_vec = sum((proj_pixels_org - proj_pixels_est).^2, 1);
    reproj_error_vec = sqrt(sum_of_squared_pixel_diff_vec);
    mean_reproj_error = mean(reproj_error_vec);
    rms_reproj_error = sqrt(mean(sum_of_squared_pixel_diff_vec));

    per_view_rms_reproj_error(1, j) = rms_reproj_error;
    per_view_mean_reproj_error(1, j) = mean_reproj_error;
    if use_undistorted_imgs
	    img = imread(fullfile(undistorted_img_dirs{j}, img_file));
    end

    % Plot them pixels.
    figure(figH(j));
    image(img);
    axis off
    hold on;

    title(sprintf('%s - Pixel Projections for Estimated World Coordinates', view_names{j}));
    % xlabel('x (pixel)'); ylabel('y (pixel)');
    plot(proj_pixels_est(1, :), proj_pixels_est(2, :), 'r*', 'linewidth', 1, 'MarkerSize', 7);
    plot(proj_pixels_org(1, :), proj_pixels_org(2, :), 'bo', 'linewidth', 1, 'MarkerSize', 8);
    legend('est WC reprojections',  'org WC reprojections')
    hold off;

end

mean_reproj_error_overall = mean(per_view_mean_reproj_error);
rms_reproj_error_overall = mean(per_view_rms_reproj_error);

fprintf("done.\n")

%% 3D VISUALIZATION - RECONSTRUCTION %%

figure(figH(num_views + 1));

% Mark first point in red for reference; rest in blue.
plot3(X_est(1, 1), X_est(2, 1), X_est(3, 1), 'r*');

title('3D Reconstruction')
xlabel('X_{est} (mm)'); ylabel('Y_{est} (mm)'); zlabel('Z_{est} (mm)');
hold on; grid on;

plot3(X_est(1, 2 : num_points), X_est(2, 2 : num_points), X_est(3, 2 : num_points), 'b*');

% Plot the cameras (original + virtual).
colors = {'red', 'blue', 'magenta'};
labels = {'C', 'M1', 'M2'};

for j = 1 : num_views
    k = view_labels(j);
    R_cam = R(:, 3*(j-1)+1 : 3*j);
    T_cam = T(:, j);

    if k == 1
        % Original view. Can use plotCamera since +ve det rotation matrix.
        pose_cam = rigidtform3d(R(:, 3*(j-1)+1 : 3*j), T(:, j));

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
        % Virtual mirror view. Can't use plotCamera since negative determinant on rotation matrix (permutation -> left
        % handed frame)

        % Get camera position and orientation w.r.t. the world frame.
        R_world = inv(R_cam);
        T_world = -R_world * T_cam;

        % Scale the drawn quivers representing the axes.
        size = 50;

        % Camera X-axis orientation plot at the camera center in the world.
        quiver3(T_world(1), T_world(2), T_world(3), ...
            R_world(1,1), R_world(2,1), R_world(3,1), ...
            size, ...
            "r", ...
            "LineWidth", 4 ...
        );
        % text(T_world(1), T_world(2), T_world(3), "X", "FontSize", 14)

        % Camera Y-axis orientation plot at the camera center in the world.
        quiver3(T_world(1), T_world(2), T_world(3), ...
            R_world(1,2), R_world(2,2), R_world(3,2), ...
            size, ...
            "g", ...
            "LineWidth", 4 ...
        );
        % text(T_world(1), T_world(2), T_world(3), "Y", "FontSize", 14)

        % Camera Z-axis orientation plot at the camera center in the world.
        quiver3(T_world(1), T_world(2), T_world(3), ...
            R_world(1,3), R_world(2,3), R_world(3,3), ...
            size, ...
            "b", ...
            "LineWidth", 4 ...
        );
        % text(T_world(1), T_world(2), T_world(3), "Z", "FontSize", 14)
    end
end
axis equal

%% METRICS AND SAVING RESULTS %%
output_txtfile = fopen(fullfile(saveloc_dir, 'output.txt'), 'w');

fprintf(output_txtfile, '[%s]\n', datetime('now'));
fprintf(output_txtfile, 'Number of Views: %d\n', num_views);
fprintf(output_txtfile, 'Number of Points: %d\n\n', num_points);

fprintf('\n*** ERRORS ***\n');
fprintf(output_txtfile, '*** ERRORS ***\n');

fmt = ['Mean Reprojection Error (PER-VIEW): ', ...
    repmat('%.6f, ', 1, numel(per_view_mean_reproj_error(1, :))-1), ...
    '%.6f\n' ...
];

fprintf(fmt, per_view_mean_reproj_error(1, :));
fprintf(output_txtfile, fmt, per_view_mean_reproj_error(1, :));

fprintf('Mean Reprojection Error (OVERALL): %f\n\n', mean_reproj_error_overall);
fprintf(output_txtfile, 'Mean Reprojection Error (OVERALL): %f\n', mean_reproj_error_overall);

fmt = ['RMS Reprojection Error (PER-VIEW): ', ...
    repmat('%.6f, ', 1, numel(per_view_rms_reproj_error(1, :))-1), ...
    '%.6f\n' ...
];

fprintf(fmt, per_view_rms_reproj_error(1, :));
fprintf(output_txtfile, fmt, per_view_rms_reproj_error(1, :));

fprintf('RMS Reprojection Error (OVERALL): %f\n\n', rms_reproj_error_overall);
fprintf(output_txtfile, 'Mean Reprojection Error (OVERALL): %f\n', rms_reproj_error_overall);

fprintf(output_txtfile, '\n*** ESTIMATED WORLD COORDS ***\n');
for i = 1 : num_points
    fprintf(output_txtfile, 'Point %d: (%4.4f, %4.4f, %4.4f)\n', i, X_est(:, i));
end

fclose(output_txtfile);

% Save some stuff.
copyfile(img_filepath, fullfile(saveloc_dir, img_file))

save(fullfile(saveloc_dir, ['xyzpts' default.BCT_EXT]), 'X_est');
save(fullfile(saveloc_dir, 'reprojection_errors.mat'), 'per_view_mean_reproj_error', 'mean_reproj_error');
save(fullfile(saveloc_dir, 'xypts.mat'), 'proj_pixels_est_all');

savefig(fullfile(saveloc_dir, 'reconstruction.fig'))


for j = 1 : num_views
    save_filepath = fullfile(saveloc_dir, sprintf('pixel_reprojections_%s.png', view_names{j}));
    figure(figH(j))
    % Hide the axes toolbar.
    set(gcf, 'toolbar', 'none');

    if default.FEX_USE_EXPORTFIG && default.FEX_USE_TIGHTFIG
        tightfig;
        export_fig(save_filepath, '-native');
    elseif default.FEX_USE_EXPORTFIG
        export_fig(save_filepath, '-native');
    elseif default.FEX_USE_TIGHTFIG
        tightfig;
        saveas(gcf, save_filepath);
    else
        saveas(gcf, save_filepath);
    end

end

fprintf('Saved results to: %s\n\n', abspath(saveloc_dir));

%% FUNCTIONS %%
function error = reconst_coords_per_px(X, n_views, x, K, R, T)
%{
We go point-by-point and pixel-by-pixel, so we get three reprojection errors (one per view). LSQNONLIN requires a
vectored error function and not a scalar value. So, we vectorize all three.
%}
    vector_err = [];
    for j = 1 : n_views

        % Get the actual pixel location of the i'th point in the j'th view.
        true = x(:, j);

        % Use current guess of 3D world points to get the pixel projections from the forward projection equation.
        pred = K(:, 3*(j-1)+1 : j*3) * [R(:, 3*(j-1)+1 : j*3) T(:, j)] * X;

        % Normalize w.r.t. homogenous coordinate.
        pred = pred./pred(3, :);

        % Get the reprojection error and vectorize it.
        reproj_error = true - pred;
        vector_err = [vector_err reproj_error];
    end
    error = vector_err;
end
