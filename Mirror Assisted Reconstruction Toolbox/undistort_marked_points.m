% Load default paths and settings.
default = load('defaults.mat');

% Load the marked points.
fprintf('Loading marked points...')
[marks_file, marks_dir] = uigetfile( ...
    '*.mat', ...
    'Select the marked points file (cancel = use default location)', ...
    [default.MARKED_POINTS_BASE default.BCT_EXT] ...
);

if ~marks_file
    marks_filepath = fullfile(default.RECONSTRUCTION_DIR, [default.MARKED_POINTS_BASE default.BCT_EXT]);
else
    marks_filepath = fullfile(marks_dir, marks_file);
end

if ~isfile(marks_filepath)
    error(['Marked points file does not exist at:\n\t%s'], marks_filepath);
end

marked_data = load(marks_filepath);
x_original = marked_data.x;
num_points = marked_data.num_points;
fprintf('done.\n')

% Load the camera calibration parameters.
fprintf('Loading camera calibration parameters...')
[merged_calib_file, merged_calib_dir] = uigetfile( ...
    ['*' default.BCT_EXT], ...
    ['Select the merged BCT calibration parameters file (cancel = use default ' ...
    'location)'] ...
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
fprintf('done.\n')

% Store camera parameters for each view.
cam_params = struct();
for i = 1 : num_views
    suffix = view_labels(i);
    % kc = distortion coefficients.
    cam_params(i).dist_coefs = view_params.(['kc_' num2str(suffix)]);
    % KK = intrinsics array.
    cam_params(i).intrinsics = view_params.(['KK_' num2str(suffix)]);
end

% Undistort points for each view.
fprintf('Undistorting points...')
undistorted_x = zeros(size(x_original));
points_per_view = num_points;

for i = 1 : num_views
    % Get the points for this view.
    view_start_idx = (i-1) * points_per_view + 1;
    view_end_idx = i * points_per_view;
    view_points = x_original(1:2, view_start_idx:view_end_idx);

    % Undistort the points.
    undistorted_view_points = undistort_points( ...
        view_points, ...
        cam_params(i).dist_coefs, ...
        cam_params(i).intrinsics ...
    );

    % Store the undistorted points.
    undistorted_x(1:2, view_start_idx:view_end_idx) = undistorted_view_points;
    undistorted_x(3, view_start_idx:view_end_idx) = 1;  % Homogeneous coordinate.
end
fprintf('done.\n')

% Save the undistorted points.
fprintf('Saving undistorted points...')
[undist_marks_file, undist_marks_dir] = uiputfile( ...
    '*.mat', ...
    'Choose path to save the undistorted points to (cancel = use default location)', ...
    [default.MARKED_POINTS_BASE '_undistorted' default.BCT_EXT] ...
);

if ~undist_marks_file
    undist_marks_filepath = fullfile(default.RECONSTRUCTION_DIR, ...
        [default.MARKED_POINTS_BASE '_undistorted' default.BCT_EXT]);
else
    undist_marks_filepath = fullfile(undist_marks_dir, undist_marks_file);
end
x = undistorted_x;
save(undist_marks_filepath, 'num_points', 'x')
fprintf('done.\n')

fprintf('\nUndistorted points saved to: %s\n', undist_marks_filepath);
