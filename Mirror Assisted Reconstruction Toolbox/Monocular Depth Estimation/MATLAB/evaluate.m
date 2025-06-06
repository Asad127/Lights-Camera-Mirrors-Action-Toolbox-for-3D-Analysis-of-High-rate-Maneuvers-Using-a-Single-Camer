%{
This script evaluates MDE approaches by comparing their metric depth maps with baseline world points. It dynamically
discovers MDE approaches, views, and images from the MDE_ROOT and LCMART_ROOT directories. For each combination,
it extracts metric depths, back-projects to 3D, registers points, computes reprojection and depth errors, and saves
results as .fig, .png, and .csv files.

Just point this script to the root data directory. It will do the rest.
%}

set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultAxesFontSize', 12);
set(groot, 'defaultfigurecolor', [1 1 1]);

FILTER_VIEWS = {'distorted'};

% Supported image extensions for finding color images.
IMG_EXTENSIONS = {'.jpg', '.png', '.tif', '.bmp'};

% Define root directories.
LCMART_ROOT = '../Data/LCMART'; % Adjust if your Data folder is elsewhere
MDE_ROOT = '../Data/MDE';       % Adjust if your Data folder is elsewhere

% Point set registration settings
POINT_SET_REGISTRATION_ALGORITHM = 'horn'; % 'horn' or 'procrustes'
REG_ENABLE_SCALING = true;
REG_ENABLE_TRANSLATION = true;
REG_TRANSLATION_ONLY = false; % If true, overrides above and only translates

% Load the camera calibration parameters.
bct_params_path = fullfile(LCMART_ROOT, 'Calibration', 'bct_params.mat');
if ~isfile(bct_params_path)
    error('Camera calibration file not found: %s', bct_params_path);
end
BCT_PARAMS = load(bct_params_path);

% Define evaluation output directory as evaluation/timestamp.
EVAL_ROOT = fullfile('evaluation', datestr(now, 'yyyy-mm-dd_HH-MM-SS'));
EVAL_3D_DIR = fullfile(EVAL_ROOT, 'images', '3d_summary');
EVAL_2D_DIR = fullfile(EVAL_ROOT, 'images', '2d_reprojection_summary');
EVAL_OVERLAY_DIR = fullfile(EVAL_ROOT, 'images', 'overlays');
EVAL_METRICS_DIR = fullfile(EVAL_ROOT, 'metrics');
EVAL_3D_INDIVIDUAL_DIR = fullfile(EVAL_ROOT, 'images', '3d_individual');
EVAL_2D_INDIVIDUAL_DIR = fullfile(EVAL_ROOT, 'images', '2d_reprojection_individual');
if ~exist(EVAL_3D_DIR, 'dir'), mkdir(EVAL_3D_DIR); end
if ~exist(EVAL_2D_DIR, 'dir'), mkdir(EVAL_2D_DIR); end
if ~exist(EVAL_OVERLAY_DIR, 'dir'), mkdir(EVAL_OVERLAY_DIR); end
if ~exist(EVAL_METRICS_DIR, 'dir'), mkdir(EVAL_METRICS_DIR); end
if ~exist(EVAL_3D_INDIVIDUAL_DIR, 'dir'), mkdir(EVAL_3D_INDIVIDUAL_DIR); end
if ~exist(EVAL_2D_INDIVIDUAL_DIR, 'dir'), mkdir(EVAL_2D_INDIVIDUAL_DIR); end

% Initialize results storage.
results = struct();

% Discover MDE approaches.
if ~exist(MDE_ROOT, 'dir')
    error('MDE_ROOT directory not found: %s', MDE_ROOT);
end
% Get all directories in the MDE_ROOT directory.
mde_approaches_dir = dir(MDE_ROOT);
% Keep only directories.
mde_approaches_dir = mde_approaches_dir([mde_approaches_dir.isdir]);
% Exclude . and ..
mde_approaches_dir = mde_approaches_dir(~ismember({mde_approaches_dir.name}, {'.', '..'}));
% Get the names of the directories.
MDE_APPROACHES_LIST = {mde_approaches_dir.name};

% If no approaches are found, exit.
if isempty(MDE_APPROACHES_LIST)
    fprintf('No MDE approaches found in %s. Exiting.\n', MDE_ROOT);
    return;
end
% Print the number of approaches and their names for debugging purposes.
fprintf('Found %d MDE approaches: %s\n', length(MDE_APPROACHES_LIST), strjoin(MDE_APPROACHES_LIST, ', '));

% Loop over each MDE approach.
for mde_approach_idx = 1 : length(MDE_APPROACHES_LIST)
    mde_current_approach = MDE_APPROACHES_LIST{mde_approach_idx};
    fprintf('Processing approach: %s\n', mde_current_approach);

    mde_approach_path = fullfile(MDE_ROOT, mde_current_approach);

    % Discover views for this approach.
    views_dir = dir(mde_approach_path);
    views_dir = views_dir([views_dir.isdir]);
    views_dir = views_dir(~ismember({views_dir.name}, {'.', '..'}));
    views_list = {views_dir.name};

    % Filter views.
    views_list = views_list(ismember(views_list, FILTER_VIEWS));

    if isempty(views_list)
        fprintf('  No views found for approach %s. Skipping.\n', mde_current_approach);
        continue;
    end
    fprintf('  Found %d views for %s: %s\n', length(views_list), mde_current_approach, strjoin(views_list, ', '));

    % Loop over each view.
    for view_idx = 1 : length(views_list)
        current_view = views_list{view_idx};
        fprintf('    Processing view: %s\n', current_view);
        % view_name_to_string = containers.Map({'cam_rect', 'mir1_rect'}, {'Camera', 'Mirror'});
        % view_name_resolved = view_name_to_string(current_view)
        if strcmp(current_view, 'distorted')
            if view_idx == 1
                view_name_resolved = 'Camera';
            elseif view_idx == 2
                if num_views == 2
                    view_name_resolved = 'Mirror';
                elseif num_views > 2
                    view_name_resolved = 'Mirror 1';
                end
            elseif view_idx == 3
                view_name_resolved = 'Mirror 2';
            end
        else
            if strcmp(current_view, 'cam_rect')
                view_name_resolved = 'Camera';
            elseif strcmp(current_view, 'mir1_rect')
                if num_views == 2
                    view_name_resolved = 'Mirror';
                elseif num_views > 2
                    view_name_resolved = 'Mirror 1';
                end
            elseif strcmp(current_view, 'mir2_rect')
                view_name_resolved = 'Mirror 2';
            end
        end

        view_path = fullfile(mde_approach_path, current_view);

        % Determine image names from metric_depth.mat for this approach/view.
        metric_depth_mat_path = fullfile(view_path, 'metric_depth.mat');
        if ~isfile(metric_depth_mat_path)
            fprintf('      WARNING: metric_depth.mat not found for %s/%s. Skipping view.\n', ...
                mde_current_approach, ...
                current_view ...
            );
            continue;
        end
        metric_depth_data_all_images = load(metric_depth_mat_path);
        % Stems don't have extensions.
        image_stems_list = fieldnames(metric_depth_data_all_images);

        if isempty(image_stems_list)
            fprintf('      No image data found in metric_depth.mat for %s/%s. Skipping view.\n', ...
                mde_current_approach, ...
                current_view ...
            );
            continue;
        end
        fprintf('      Found %d images for %s/%s: %s\n', ...
            length(image_stems_list), ...
            mde_current_approach, ...
            current_view, ...
            strjoin(image_stems_list, ', ') ...
        );

        % Calculate subplot layout dynamically based on the number of images.
        num_images_for_view = length(image_stems_list);
        [subplot_nrows, subplot_ncols] = calculate_subplot_layout(num_images_for_view);

        % Create summary figures for this approach/view
        fig3d_summary = figure( ...
            'Name', sprintf('%s - %s - All 3D Points', mde_current_approach, current_view), ...
            'Visible', 'off', ...
            'Position', [100 100 1200 900] ...
        );
        fig2d_summary = figure( ...
            'Name', sprintf('%s - %s - All Reprojection Errors', mde_current_approach, current_view), ...
            'Visible', 'off', ...
            'Position', [150 150 1200 900] ...
        );

        % Loop over each image.
        for img_loop_idx = 1 : num_images_for_view
            current_img_name = image_stems_list{img_loop_idx};
            fprintf('      Processing image: %s (%d/%d)\n', current_img_name, img_loop_idx, num_images_for_view);

            % Load baseline world points for this image.
            baseline_xyz_path = fullfile(LCMART_ROOT, 'Reconstruction', current_img_name, 'xyzpts.mat');
            if ~isfile(baseline_xyz_path)
                fprintf( ...
                    '        WARNING: Baseline xyzpts.mat not found for image %s. Skipping image.\n', ...
                    current_img_name ...
                );
                results.(mde_current_approach).(current_view).(current_img_name).error = 'Missing baseline_xyz';
                continue;
            end
            baseline_data = load(baseline_xyz_path);
            % Should be 3xN.
            baseline_world_points = baseline_data.X_est;

            % Load marked points for this image.
            marked_points_path = fullfile(LCMART_ROOT, 'Reconstruction', current_img_name, 'marked_points.mat');
            if ~isfile(marked_points_path)
                fprintf( ...
                    '        WARNING: Marked points .mat not found for image %s. Skipping image.\n', ...
                    current_img_name ...
                );
                results.(mde_current_approach).(current_view).(current_img_name).error = 'Missing marked_points';
                continue;
            end
            marked_points_data = load(marked_points_path);
            % Should be 3xN.
            marked_x = marked_points_data.x;
            % Number of points per view.
            num_points_per_view = marked_points_data.num_points;
            % Number of views.
            num_views = size(marked_x, 2) / num_points_per_view;

            % Check consistency.
            if size(baseline_world_points, 2) ~= num_points_per_view
                fprintf( ...
                    ['        WARNING: Mismatch in number of baseline points (%d) and marked points per view ' ...
                        '(%d) for image %s. Skipping image.\n' ...
                    ], ...
                    size(baseline_world_points, 2), ...
                    num_points_per_view, ...
                    current_img_name ...
                );
                results.(mde_current_approach).(current_view).(current_img_name).error = ...
                    'Baseline/Marked points number mismatch' ...
                ;
                continue;
            end

            % Split marked points based on typical structure (cam_rect first, then mir1_rect). This assumes
            % marked_points.mat stores concatenated points if multiple views exist within it. And that the current
            % 'view' string corresponds to one of these sets.
            if strcmp(current_view, 'distorted')
                if size(marked_x, 2) >= num_points_per_view
                    marked_pixels = marked_x(1:2, 1:num_points_per_view);
                else
                    fprintf( ...
                        '        WARNING: Not enough marked points in cam_rect set for image %s. Skipping image.\n', ...
                        current_img_name ...
                    );
                    results.(mde_current_approach).(current_view).(current_img_name).error = ...
                        'Insufficient distorted marked points' ...
                    ;
                    continue;
                end
            elseif strcmp(current_view, 'cam_rect') || any(strfind(current_view, 'cam'))
                if size(marked_x, 2) >= num_points_per_view
                    marked_pixels = marked_x(1:2, 1:num_points_per_view);
                else
                    fprintf( ...
                        '        WARNING: Not enough marked points in cam_rect set for image %s. Skipping image.\n', ...
                        current_img_name ...
                    );
                    results.(mde_current_approach).(current_view).(current_img_name).error = ...
                        'Insufficient cam_rect marked points' ...
                    ;
                    continue;
                end
            elseif strcmp(current_view, 'mir1_rect') || any(strfind(current_view, 'mir1'))
                if size(marked_x, 2) >= 2 * num_points_per_view
                    marked_pixels = marked_x(1:2, num_points_per_view+1 : 2*num_points_per_view);
                else
                    fprintf( ...
                        ['        WARNING: Not enough marked points for mir1_rect set for image %s (expected ' ...
                            'at least 2 sets). Skipping image.\n' ...
                        ], ...
                        current_img_name ...
                    );
                    results.(mde_current_approach).(current_view).(current_img_name).error = ...
                        'Insufficient mir1_rect marked points' ...
                    ;
                    continue;
                end
            elseif strcmp(current_view, 'mir2_rect') || any(strfind(current_view, 'mir2'))
                if size(marked_x, 2) >= 3 * num_points_per_view
                    marked_pixels = marked_x(1:2, 2*num_points_per_view+1 : 3*num_points_per_view);
                else
                    fprintf(...
                        ['        WARNING: Not enough marked points for mir2_rect set for image %s (expected at ' ...
                        'least 3 sets). Skipping image.\n'], ...
                        current_img_name ...
                    );
                    results.(mde_current_approach).(current_view).(current_img_name).error = ...
                        'Insufficient mir2_rect marked points' ...
                    ;
                    continue;
                end
            else
                fprintf('        WARNING: Unknown view type "%s" for splitting marked points. Skipping image.\n', ...
                    current_view ...
                );
                results.(mde_current_approach).(current_view).(current_img_name).error = ...
                    'Unknown view for marked points' ...
                ;
                continue;
            end

            % Determine camera parameters based on view.
            if strcmp(current_view, 'distorted')
                % In this case, we HAVE to work with the view label for the current view if we're working within a
                % project. Since this script was created with standalone usage in mind, we're going to hardcode this
                % case for now.
                if view_idx == 1
                    KK = BCT_PARAMS.KK_1; Rc = BCT_PARAMS.Rc_1; Tc = BCT_PARAMS.Tc_1;
                elseif view_idx == 2
                    KK = BCT_PARAMS.KK_2; Rc = BCT_PARAMS.Rc_2; Tc = BCT_PARAMS.Tc_2;
                elseif view_idx == 3
                    KK = BCT_PARAMS.KK_3; Rc = BCT_PARAMS.Rc_3; Tc = BCT_PARAMS.Tc_3;
                else
                    error( ...
                        ['Unknown view index. Index to parameter suffix mapping for calibration parameters is ' ...
                            'unclear.' ...
                        ] ...
                    )
                end
            else
                if strcmp(current_view, 'cam_rect')
                    KK = BCT_PARAMS.KK_1; Rc = BCT_PARAMS.Rc_1; Tc = BCT_PARAMS.Tc_1;
                elseif strcmp(current_view, 'mir1_rect')
                    KK = BCT_PARAMS.KK_2; Rc = BCT_PARAMS.Rc_2; Tc = BCT_PARAMS.Tc_2;
                elseif strcmp(current_view, 'mir2_rect')
                    KK = BCT_PARAMS.KK_3; Rc = BCT_PARAMS.Rc_3; Tc = BCT_PARAMS.Tc_3;
                else
                    fprintf( ...
                        '        WARNING: Unknown view "%s" for camera parameters. Skipping image.\n', current_view ...
                    );
                    results.(mde_current_approach).(current_view).(current_img_name).error = ...
                        'Unknown view for camera_params' ...
                    ;
                    continue;
                end
            end

            % Load metric depth map for this image from the already loaded struct.
            metric_depth = metric_depth_data_all_images.(current_img_name);

            % Initialize arrays for estimated 3D points and depths.
            mde_estimated_3d_points_world = zeros(3, num_points_per_view);
            mde_estimated_depths_cam = zeros(1, num_points_per_view);

            for p = 1 : num_points_per_view
                % These are 2D image coordinates (x, y) or (col, row).
                pixel = marked_pixels(1:2, p);

                % Use bilinear interpolation to extract metric depth at the marked pixel. interp2 expects X, Y args as
                % meshgrid-style matrices if Z is a matrix, or X, Y as vectors if Z is a matrix. Here, pixel(1) is col
                % (x), pixel(2) is row (y). Metric depth map might be (rows, cols).
                [img_height, img_width] = size(metric_depth);
                [X_mesh, Y_mesh] = meshgrid(1:img_width, 1:img_height);

                % Clamp pixel coordinates to be within image bounds for interp2
                query_x = max(1, min(pixel(1), img_width));
                query_y = max(1, min(pixel(2), img_height));

                depth_val = interp2(X_mesh, Y_mesh, metric_depth, query_x, query_y, 'linear');

                % Handle cases where interp2 might fail (e.g. NaNs in depth_map near edges).
                if isnan(depth_val)
                    fprintf( ...
                        ['        WARNING: NaN depth from interp2 for point %d at (%.1f, %.1f). Using nearest ' ...
                            'neighbor.\n' ...
                        ], ...
                        p, ...
                        pixel(1), ...
                        pixel(2) ...
                    );
                    depth_val = interp2(X_mesh, Y_mesh, metric_depth, query_x, query_y, 'nearest');
                    % Still NaN, perhaps point is outside valid depth data.
                    if isnan(depth_val)
                        fprintf( ...
                            ['        ERROR: Still NaN depth for point %d even with nearest. Setting depth to a ' ...
                                'large value (e.g. 1000) or skipping point.\n' ...
                            ], ...
                            p ...
                        );
                        % Option: Skip this point, or assign a placeholder. This can skew results.
                        continue
                    end
                end
                mde_estimated_depths_cam(p) = depth_val;

                % Back-project to 3D camera coordinates.
                Xc = (pixel(1) - KK(1,3)) * depth_val / KK(1,1);
                Yc = (pixel(2) - KK(2,3)) * depth_val / KK(2,2);
                Zc = depth_val;

                % Transform to world coordinates using extrinsics.
                camera_point = [Xc; Yc; Zc];
                world_point = Rc' * (camera_point - Tc);
                mde_estimated_3d_points_world(:, p) = world_point;
            end

            % Register the MDE estimated 3D points (query, world) to the baseline world points (target).
            registered_mde_world_points = [];
            registration_params = RegistrationParams3d(); % Instantiated with default transform and NaN metrics

            if REG_TRANSLATION_ONLY
                if num_points_per_view > 0 && size(mde_estimated_3d_points_world,2) > 0 && size(baseline_world_points,2) > 0
                    translation_vec = baseline_world_points(:, 1) - mde_estimated_3d_points_world(:, 1);
                    registered_pts = mde_estimated_3d_points_world + translation_vec;
                    registration_params.registered_query_points = registered_pts;
                    registration_params.transform.rotation_matrix = eye(3);
                    registration_params.transform.translation_vector = translation_vec;
                    registration_params.transform.scale_factor = 1.0;
                    % Shorthand for making the matrix.
                    sr = registration_params.transform.scale_factor * registration_params.transform.rotation_matrix;
                    tv = registration_params.transform.translation_vector
                    registration_params.transform.transformation_matrix = [sr tv; 0 0 0 1];
                    registration_params.metrics = RegistrationMetrics3d(registered_pts, baseline_world_points);
                else
                    % Not enough points or empty inputs, use original MDE points and default transform/NaN metrics.
                    registration_params.registered_query_points = mde_estimated_3d_points_world;
                    % Metrics will be NaN either from default instance of RegistrationParams3d or if
                    % mde_estimated_3d_points_world is empty.
                    if ~(isempty(mde_estimated_3d_points_world) || isempty(baseline_world_points))
                         registration_params.metrics = RegistrationMetrics3d( ...
                             mde_estimated_3d_points_world, baseline_world_points ...
                         );
                    end
                end
            else
                % Require at least 3 points for Horn or Procrustes.
                if num_points_per_view >= 3 && size(mde_estimated_3d_points_world,2) >=3 && size(baseline_world_points,2) >=3
                    try
                        % Query -> Target mapping.
                        query_points = mde_estimated_3d_points_world;
                        target_points = baseline_world_points;

                        if strcmp(POINT_SET_REGISTRATION_ALGORITHM, 'horn')
                            registration_params = register_points_3d_horn( ...
                                query_points, target_points, REG_ENABLE_SCALING, REG_ENABLE_TRANSLATION ...
                            );
                        elseif strcmp(POINT_SET_REGISTRATION_ALGORITHM, 'procrustes')
                            registration_params = register_points_3d_procrustes( ...
                                query_points, target_points, 'Scaling', REG_ENABLE_SCALING, 'Reflection', false ...
                            );
                        else
                            error('Invalid point set registration algorithm: %s', POINT_SET_REGISTRATION_ALGORITHM);
                        end

                    catch ME
                        fprintf( ...
                            '        ERROR during point set registration for %s: %s. Using untransformed points.\n', ...
                            current_img_name, ...
                            ME.message ...
                        );
                        % Use untransformed points.
                        registration_params.registered_query_points = mde_estimated_3d_points_world;
                        % Re-compute metrics based on untransformed points vs baseline (transform remains identity,
                        % default metrics are NaN).
                         if ~(isempty(mde_estimated_3d_points_world) || isempty(baseline_world_points))
                            registration_params.metrics = RegistrationMetrics3d( ...
                                mde_estimated_3d_points_world, baseline_world_points ...
                            );
                         end
                    end

                else
                    fprintf( ...
                        ['        WARNING: Not enough points (%d) for %s registration. Using untransformed MDE ' ...
                            'points.\n' ...
                        ], ...
                        num_points_per_view, ...
                        POINT_SET_REGISTRATION_ALGORITHM ...
                    );
                    % Use untransformed points.
                    registration_params.registered_query_points = mde_estimated_3d_points_world;
                    % Re-compute metrics based on untransformed points vs baseline.
                    if ~(isempty(mde_estimated_3d_points_world) || isempty(baseline_world_points))
                        registration_params.metrics = RegistrationMetrics3d( ...
                            mde_estimated_3d_points_world, baseline_world_points ...
                        );
                    end
                end
            end

            % Retrieve registered points for subsequent use.
            registered_mde_world_points = registration_params.registered_query_points;

            % Print registration results.
            fprintf('        Registration Results for %s:\n', current_img_name);
            fprintf('          Rotation matrix:\n'); disp(registration_params.transform.rotation_matrix);
            fprintf('          Translation vector:\n'); disp(registration_params.transform.translation_vector);
            fprintf('          Scaling factor: %f\n', registration_params.transform.scale_factor);

            % Print registration error metrics.
            fprintf('          Error Metrics (3D Registration, post-reg):\n');
            current_metrics_dict = registration_params.metrics.get_metrics_as_dict();
            fields_metrics = fieldnames(current_metrics_dict);
            for i_metric = 1 : length(fields_metrics)
                fprintf( ...
                    '            - %s: %f\n', ...
                    fields_metrics{i_metric}, ...
                    current_metrics_dict.(fields_metrics{i_metric}) ...
                );
            end

            % Forward-project the registered MDE 3D points to the image plane.
            registered_mde_projected_pixels = zeros(2, num_points_per_view);
            if ~isempty(registered_mde_world_points)
                for p = 1 : num_points_per_view
                    world_pt = registered_mde_world_points(:, p);
                    cam_pt = Rc * world_pt + Tc;
                    registered_mde_projected_pixels(1, p) = KK(1,1) * cam_pt(1) / cam_pt(3) + KK(1,3);
                    registered_mde_projected_pixels(2, p) = KK(2,2) * cam_pt(2) / cam_pt(3) + KK(2,3);
                end
            end

            % ==========================================================================================================
            % COMPUTE MDE REPROJECTION ERROR
            % ==========================================================================================================
            % For a single pixel, the reprojection error is simply the Euclidean distance between 2 pixels (x1, y1) and
            % (x2, y2).
            % px_distance = sqrt((x2 - x1)^2 + (y2 - y1)^2)
            %
            % Assume two pixel point sets of 2xN, each column being a pixel. Let's call these A and B. The vectorized
            % implementation of the reprojection error FOR EACH PIXEL in the set is then:
            % reprojection_error = sqrt(sum((A-B).^2, 1))  --- (Eq. 1)
            %
            % Basically, A - B represents the error (in pixels) per component per pixel. Thus, it still maintains the
            % same shape as the input, i.e., 2xN, except now the first component represents the error in x coordinate,
            % and the second in y coordinate, specifically, (x2-x1) and (y2-y1).
            %
            % (A - B).^2 thus represents the element-wise square errors, in the same 2xN shape. The first component for
            % each column of this array is (x2-x1)^2 and the second component is (y2-y1)^2.
            %
            % sum((A - B).^2, 1) simply sums the two squared components along the columns, i.e., adds the two components
            % in each column, creating a 1xN vector. This basically performs (x2 - x1)^2 + (y2 - y1)^2. This represents
            % the sum of squared differences (SSD) formulation.
            %
            % sqrt(sum((A - B).^2, 1)) takes the square root for each element of the 1xN vector representing the SSD,
            % and returns a 1xN vector as well.
            %
            % We can get the mean based on Eq (1) - as reprojection error is a 1xN vector (each element representing the
            % reprojection error for a single pixel between A and B), the mean is simply:
            % mean_reprojection_error = sum(reprojection_error) / numel(reprojection_error)  % scalar
            %
            % Or, we can simply use MATLAB's mean, which performs the sum and division for us.
            % mean_reprojection_error = mean(reprojection_error)  % scalar
            %
            % Root mean square of a 1xN vector of entities is a scalar defined as:
            % RMS_entity = sqrt(mean(entity.^2)) --- (Eq. 2)
            %
            % In our case, the entity is the reprojection error as modeled in Eq (1).
            % reprojection_error = sqrt(sum((A - B).^2, 1))               % 1xN vector
            % rms_reprojection_error = sqrt(mean(reprojection_error.^2))  % scalar
            %
            % But an alternative formulation with SSD can also be set if the entity is Euclidean distance. Per Eq (1),
            % the outermost operation is a square root. In the RMS definition (Eq. 2), we have the entity's square.
            % Thus, if we cancel out the square with the square root, we can formulate the reprojection error in terms
            % of the sum of squared differences.
            % sum_squared_differences_px = sum((A - B).^2, 1)                  % 1xN vector
            % rms_reprojection_error = sqrt(mean(sum_squared_differences_px))  % scalar
            %
            % We'll use the SSD formulation.

            sum_of_squared_pixel_distances_vec = sum((registered_mde_projected_pixels - marked_pixels).^2, 1);
            mde_reprojection_error_vec = sqrt(sum_of_squared_pixel_distances_vec);
            mde_mean_reprojection_error = mean(mde_reprojection_error_vec);
            mde_rms_reprojection_error = sqrt(mean(sum_of_squared_pixel_distances_vec));

            % Compute MDE depth error (comparing MDE camera depths with baseline camera depths).
            baseline_points_in_cam_frame = Rc * baseline_world_points + Tc;
            true_depths_for_view_cam = baseline_points_in_cam_frame(3, :);

            mde_depth_error_vec = abs(mde_estimated_depths_cam - true_depths_for_view_cam);
            mde_mean_depth_error = mean(mde_depth_error_vec);

            % Store MDE results.
            results.(mde_current_approach).(current_view).(current_img_name).mde_mean_reprojection_error = ...
                mde_mean_reprojection_error ...
            ;
            results.(mde_current_approach).(current_view).(current_img_name).mde_rms_reprojection_error = ...
                mde_rms_reprojection_error ...
            ;
            results.(mde_current_approach).(current_view).(current_img_name).mde_mean_depth_error = ...
                mde_mean_depth_error ...
            ;
            results.(mde_current_approach).(current_view).(current_img_name).registration_metrics = ...
                registration_params.metrics ...
            ;

            % ==========================================================================================================
            % PLOTTING
            % ==========================================================================================================
            % Define a mapping from view name to string.
            mde_approach_to_string = containers.Map( ...
                {'Depth_Anything_V2', 'Metric3D_V2'}, {'Depth Anything V2', 'Metric3D V2'} ...
            );
            img_name_to_string = containers.Map( ...
                {'img1', 'img2', 'img3', 'img4'}, ...
                {'Image 1', 'Image 2', 'Image 3', 'Image 4'} ...
            );
            registration_to_string = containers.Map( ...
                {'horn', 'procrustes', 'translation_only'}, ...
                {'Horn', 'Procrustes', 'Translation'} ...
            );

            % Plot for 3D summary figure.
            figure(fig3d_summary);
            subplot(subplot_nrows, subplot_ncols, img_loop_idx);
            if ~isempty(baseline_world_points)
                scatter3( ...
                    baseline_world_points(1,:), baseline_world_points(2,:), baseline_world_points(3,:), ...
                    36, ...
                    'b', '.', ...
                    'DisplayName', 'Baseline World Points' ...
                );
                hold on;
            end
            if ~isempty(registered_mde_world_points)
                scatter3( ...
                    registered_mde_world_points(1,:), ...
                    registered_mde_world_points(2,:), ...
                    registered_mde_world_points(3,:), ...
                    36, ...
                    'r', '.', ...
                    'DisplayName', 'MDE Registered World Points' ...
                );
            end
            super_title = sprintf('3D World Points\nMDE via %s | %s View | %s Registration', ...
                mde_approach_to_string(mde_current_approach), ...
                view_name_resolved, ...
                registration_to_string(POINT_SET_REGISTRATION_ALGORITHM) ...
            );
            title_str = sprintf(img_name_to_string(current_img_name));
            sgtitle( ...
                super_title, ...
                'Interpreter', 'none', ...
                'FontSize', 14, ...
                'FontName', 'Times New Roman', ...
                'FontWeight', 'bold' ...
            );
            title( ...
                title_str, ...
                'Interpreter', 'none', ...
                'FontSize', 14, ...
                'FontName', 'Times New Roman', ...
                'FontWeight', 'bold' ...
            );
            xlabel('X_w (mm)'); ylabel('Y_w (mm)'); zlabel('Z_w (mm)');
            legend('Location', 'best'); grid on; axis equal; view(3);
            hold off;

            % Create and save individual 3D figure.
            fig3d_individual = figure( ...
                'Name', sprintf('%s - %s - %s 3D Points', mde_current_approach, current_view, current_img_name), ...
                'Visible', 'off', ...
                'Position', [100 100 800 600] ...
            );
            if ~isempty(baseline_world_points)
                scatter3( ...
                    baseline_world_points(1,:), baseline_world_points(2,:), baseline_world_points(3,:), ...
                    36, ...
                    'b', '.', ...
                    'DisplayName', 'Baseline World Points' ...
                );
                hold on;
            end
            if ~isempty(registered_mde_world_points)
                scatter3( ...
                    registered_mde_world_points(1,:), ...
                    registered_mde_world_points(2,:), ...
                    registered_mde_world_points(3,:), ...
                    36, ...
                    'r', '.', ...
                    'DisplayName', 'MDE Registered World Points' ...
                );
            end
            title_str = sprintf('3D World Points | %s', img_name_to_string(current_img_name));
            title( ...
                title_str, ...
                'Interpreter', 'none', ...
                'FontSize', 14, ...
                'FontName', 'Times New Roman', ...
                'FontWeight', 'bold' ...
            );
            xlabel('X_w (mm)'); ylabel('Y_w (mm)'); zlabel('Z_w (mm)');
            legend('Location', 'best'); grid on; axis equal; view(3);
            hold off;

            % Save individual 3D figure
            individual_3d_filename_base = sprintf('%s_%s_%s_3d', mde_current_approach, current_view, current_img_name);
            saveas(fig3d_individual, fullfile(EVAL_3D_INDIVIDUAL_DIR, [individual_3d_filename_base, '.fig']));
            saveas(fig3d_individual, fullfile(EVAL_3D_INDIVIDUAL_DIR, [individual_3d_filename_base, '.png']));
            close(fig3d_individual);

            % Plot for 2D reprojection summary figure.
            figure(fig2d_summary);
            subplot(subplot_nrows, subplot_ncols, img_loop_idx);
            if ~isempty(marked_pixels)
                plot(marked_pixels(1,:), marked_pixels(2,:), 'b.', 'MarkerSize', 12, 'DisplayName', 'Original Marked');
                hold on;
            end
            if ~isempty(registered_mde_projected_pixels)
                plot( ...
                    registered_mde_projected_pixels(1,:), registered_mde_projected_pixels(2,:), ...
                    'r.', ...
                    'MarkerSize', 12, ...
                    'DisplayName', 'MDE Projected' ...
                );
            end
            super_title = sprintf( ...
                '2D Reprojections\nMDE via %s | %s View | %s Registration', ...
                mde_approach_to_string(mde_current_approach), ...
                view_name_resolved, ...
                registration_to_string(POINT_SET_REGISTRATION_ALGORITHM) ...
            );
            title_str = sprintf(img_name_to_string(current_img_name));
            sgtitle( ...
                super_title, ...
                'Interpreter', 'none', ...
                'FontSize', 14, ...
                'FontName', 'Times New Roman', ...
                'FontWeight', 'bold' ...
            );
            title( ...
                title_str, ...
                'Interpreter', 'none', ...
                'FontSize', 14, ...
                'FontName', 'Times New Roman', ...
                'FontWeight', 'bold' ...
            );
            xlabel('X (pixels)'); ylabel('Y (pixels)');
            legend('Location', 'best'); grid on; axis equal;
            % Ensure Y-axis is downward for image coordinates if not already by axis ij.
            set(gca, 'YDir','reverse'); 
            hold off;

            % Create and save individual 2D reprojection figure.
            fig2d_individual = figure( ...
                'Name', sprintf( ...
                    '2D Reprojections\n%s: %s - %s', mde_current_approach, current_view, current_img_name ...
                ), ...
                'Visible', 'off', ...
                'Position', [100 100 800 600] ...
            );
            if ~isempty(marked_pixels)
                plot(marked_pixels(1,:), marked_pixels(2,:), 'b.', 'MarkerSize', 12, 'DisplayName', 'Original Marked');
                hold on;
            end
            if ~isempty(registered_mde_projected_pixels)
                plot( ...
                    registered_mde_projected_pixels(1,:), registered_mde_projected_pixels(2,:), ...
                    'r.', ...
                    'MarkerSize', 12, ...
                    'DisplayName', 'MDE Projected' ...
                );
            end
            title_str = sprintf( ...
                '2D Reprojections | %s View | %s', view_name_resolved, img_name_to_string(current_img_name) ...
            );
            title( ...
                title_str, ...
                'Interpreter', 'none', ...
                'FontSize', 14, ...
                'FontName', 'Times New Roman', ...
                'FontWeight', 'bold' ...
            );
            xlabel('X (pixels)'); ylabel('Y (pixels)');
            legend('Location', 'best'); grid on; axis equal;
            set(gca, 'YDir','reverse');
            hold off;

            % Save individual 2D reprojection figure.
            individual_2d_filename_base = sprintf( ...
                '%s_%s_%s_reproj', mde_current_approach, current_view, current_img_name ...
            );
            saveas(fig2d_individual, fullfile(EVAL_2D_INDIVIDUAL_DIR, [individual_2d_filename_base, '.fig']));
            saveas(fig2d_individual, fullfile(EVAL_2D_INDIVIDUAL_DIR, [individual_2d_filename_base, '.png']));
            close(fig2d_individual);

            % Load the color image for this view and image (from MDE folder) for overlay plot.
            img_for_overlay_path = '';
            for ext_idx = 1 : length(IMG_EXTENSIONS)
                candidate_path = fullfile(view_path, 'color', [current_img_name, IMG_EXTENSIONS{ext_idx}]);
                if isfile(candidate_path)
                    img_for_overlay_path = candidate_path;
                    break;
                end
            end

            if isempty(img_for_overlay_path)
                fprintf( ...
                    '        WARNING: Color image for overlay not found for %s/%s/%s. Skipping overlay plot.\n', ...
                    mde_current_approach, ...
                    current_view, ...
                    current_img_name ...
                );
            else
                img_overlay_base = imread(img_for_overlay_path);

                % Project baseline world points to the image.
                baseline_projected_pixels = zeros(2, num_points_per_view);
                for p = 1:num_points_per_view
                    cam_pt_baseline = Rc * baseline_world_points(:, p) + Tc;
                    baseline_projected_pixels(1, p) = KK(1,1) * cam_pt_baseline(1) / cam_pt_baseline(3) + KK(1,3);
                    baseline_projected_pixels(2, p) = KK(2,2) * cam_pt_baseline(2) / cam_pt_baseline(3) + KK(2,3);
                end

                % Compute baseline reprojection error.
                sum_of_squared_pixel_distances_vec = sum((baseline_projected_pixels - marked_pixels).^2, 1);
                baseline_reprojection_error_vec = sqrt(sum_of_squared_pixel_distances_vec);
                baseline_mean_reprojection_error = mean(baseline_reprojection_error_vec);
                baseline_rms_reprojection_error = sqrt(mean(sum_of_squared_pixel_distances_vec));

                % Store baseline reprojection metrics.
                results.(mde_current_approach).(current_view).(current_img_name).baseline_mean_reprojection_error = ...
                    baseline_mean_reprojection_error ...
                ;
                results.(mde_current_approach).(current_view).(current_img_name).baseline_rms_reprojection_error = ...
                    baseline_rms_reprojection_error ...
                ;

                % Plot overlay figure (individual per image).
                fig_overlay = figure( ...
                    'Name', sprintf( ...
                        '%s - %s - %s Projections', mde_current_approach, current_view, current_img_name ...
                    ), ...
                    'Visible', 'off' ...
                );
                imshow(img_overlay_base);
                hold on;
                plot( ...
                    marked_pixels(1,:), marked_pixels(2,:), ...
                    'bo', ...
                    'MarkerSize', 10, ...
                    'LineWidth', 1.5, ...
                    'DisplayName', 'Marked (Original)' ...
                );
                plot( ...
                    baseline_projected_pixels(1,:), baseline_projected_pixels(2,:), ...
                    'r*', ...
                    'MarkerSize', 10, ...
                    'LineWidth', 1.5, ...
                    'DisplayName', 'Baseline (Projected)' ...
                );
                if ~isempty(registered_mde_projected_pixels)
                    plot( ...
                        registered_mde_projected_pixels(1,:), registered_mde_projected_pixels(2,:), ...
                        'g+', ...
                        'MarkerSize', 10, ...
                        'LineWidth', 1.5, ...
                        'DisplayName', 'MDE (Registered & Projected)' ...
                    );
                end
                xlabel('X (pixels)'); ylabel('Y (pixels)');
                legend('show', 'Location', 'bestoutside');
                title_str = sprintf( ...
                    'Overlayed Image Projections | %s View | %s', ...
                    view_name_resolved, ...
                    img_name_to_string(current_img_name) ...
                );
                title( ...
                    title_str, ...
                    'Interpreter', 'none', ...
                    'FontSize', 14, ...
                    'FontName', 'Times New Roman', ...
                    'FontWeight', 'bold' ...
                );
                axis equal;
                hold off;

                % Save the overlay figure.
                overlay_filename_base = sprintf( ...
                    '%s_%s_%s_overlay', mde_current_approach, current_view, current_img_name ...
                );
                saveas(fig_overlay, fullfile(EVAL_OVERLAY_DIR, [overlay_filename_base, '.fig']));
                saveas(fig_overlay, fullfile(EVAL_OVERLAY_DIR, [overlay_filename_base, '.png']));
                close(fig_overlay);
            end
            fprintf('        Finished processing image %s.\n', current_img_name);
        end

        % Save the 3D and 2D summary figures for this approach/view if any images were processed.
        if num_images_for_view > 0
            summary_3d_filename_base = sprintf('%s_%s_all_3d_plots', mde_current_approach, current_view);
            saveas(fig3d_summary, fullfile(EVAL_3D_DIR, [summary_3d_filename_base, '.fig']));
            saveas(fig3d_summary, fullfile(EVAL_3D_DIR, [summary_3d_filename_base, '.png']));

            summary_2d_filename_base = sprintf('%s_%s_all_reproj_plots', mde_current_approach, current_view);
            saveas(fig2d_summary, fullfile(EVAL_2D_DIR, [summary_2d_filename_base, '.fig']));
            saveas(fig2d_summary, fullfile(EVAL_2D_DIR, [summary_2d_filename_base, '.png']));
        end
        close(fig3d_summary);
        close(fig2d_summary);
        fprintf('    Finished processing view %s for approach %s.\n', current_view, mde_current_approach);
    end 
    fprintf('  Finished processing approach %s.\n', mde_current_approach);
end 

% Save results to CSV.
results_table_data = {};
approaches_processed = fieldnames(results);
for mde_approach_idx = 1:length(approaches_processed)
    approach_name_res = approaches_processed{mde_approach_idx};
    if ~isstruct(results.(approach_name_res)), continue; end

    views_processed = fieldnames(results.(approach_name_res));
    for view_idx = 1:length(views_processed)
        view_name_res = views_processed{view_idx};
        if ~isstruct(results.(approach_name_res).(view_name_res)), continue; end

        images_processed = fieldnames(results.(approach_name_res).(view_name_res));
        for img_idx = 1:length(images_processed)
            img_name_res = images_processed{img_idx};
            data_entry = results.(approach_name_res).(view_name_res).(img_name_res);

            % Check if this entry was skipped due to an error
            if isfield(data_entry, 'error')
                fprintf( ...
                    'Skipping CSV entry for %s/%s/%s due to error: %s\n', ...
                    approach_name_res, ...
                    view_name_res, ...
                    img_name_res, ...
                    data_entry.error ...
                );
                mde_mean_reproj_err = NaN; mde_rms_reproj_err = NaN; mde_mean_depth_err = NaN;
                base_mean_reproj_err = NaN; base_rms_reproj_err = NaN;
            else
                mde_mean_reproj_err  = data_entry.mde_mean_reprojection_error;
                mde_rms_reproj_err   = data_entry.mde_rms_reprojection_error;
                mde_mean_depth_err   = data_entry.mde_mean_depth_error;
                base_mean_reproj_err = data_entry.baseline_mean_reprojection_error; % May not exist if overlay skipped
                base_rms_reproj_err  = data_entry.baseline_rms_reprojection_error;  % May not exist if overlay skipped
                if ~isfield(data_entry, 'baseline_mean_reprojection_error')
                    base_mean_reproj_err = NaN; base_rms_reproj_err = NaN;
                end

            end

            results_table_data = [results_table_data; ...
                {approach_name_res, view_name_res, img_name_res, ...
                mde_mean_reproj_err, mde_rms_reproj_err, mde_mean_depth_err, ...
                base_mean_reproj_err, base_rms_reproj_err} ...
            ];
        end
    end
end

if ~isempty(results_table_data)
    results_table = cell2table(results_table_data, ...
        'VariableNames', {'Approach', 'View', 'Image', ...
        'MDE_MeanReprojectionError', 'MDE_RMSReprojectionError', 'MDE_MeanDepthError', ...
        'Baseline_MeanReprojectionError', 'Baseline_RMSReprojectionError'});
    csv_path = fullfile(EVAL_METRICS_DIR, 'evaluation_summary_results.csv');
    writetable(results_table, csv_path);
    fprintf('Evaluation complete. Results summary saved to %s\n', csv_path);
else
    fprintf('No results to save to CSV.\n');
end

fprintf('All processing finished.\n');

function [nrows, ncols] = calculate_subplot_layout(num_plots)
% Changed from == 0 to <=0 for robustness.
if num_plots <= 0 
    % Default to 1x1 grid.
    nrows = 1; ncols = 1;
    return;
end
ncols = ceil(sqrt(num_plots));
nrows = ceil(num_plots / ncols);
end