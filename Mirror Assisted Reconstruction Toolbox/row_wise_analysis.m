% Row-wise distance computation (mean and RMS). Give this baddie a 3xN estimated world points file (typically ending 
% with xyzpts.mat), make sure that it's a well defined, regular pattern such that for any give pair of consecutive 
% points, p and p + 1, the distance between them is always constant (e.g., checker corners), set the number of rows and
% number of points per row, and let it rip.

[filename, pathname] = uigetfile('*.mat', 'Select the xyzpts.mat file containing the 3D world points');
if filename == 0
    error('No file selected.');
end
xyzpts = load(fullfile(pathname, filename));
X_est = xyzpts.X_est;
num_points = size(X_est, 2);
points_per_row = 6;
total_rows = num_points / 6;
intervals_start = 1 : points_per_row : num_points;
ground_truth_distance = 24;  % mm

mean_distance_per_row = zeros(1, total_rows);
rms_distance_per_row = zeros(1, total_rows);
mean_error_per_row = zeros(1, total_rows);
rms_error_per_row = zeros(1, total_rows);
for row_start = intervals_start
    % Store the pair distances. If N points, then going p2-p1, p3-p2, ..., p(N)-p(N-1) we'll get N-1 distance pairs.
    pair_distances = zeros(1, points_per_row - 1);
    pair_errors = zeros(1, points_per_row - 1);
    for p = 1 : points_per_row - 1
        % For each point, get its next point, and get the norm of its difference.
        this_point_index = row_start + (p - 1);
        next_point_index = row_start + p;
        this_point_X = X_est(:, this_point_index);
        next_point_X = X_est(:, next_point_index);
        % Distance between the two points: ||p2-p1||_2 = sqrt((x2-x1)^2 + (y2-y1)^2)
        distance = norm(next_point_X - this_point_X); 
        pair_distances(p) = distance;
        pair_errors(p) = abs(ground_truth_distance - distance);
    end
    % Get the mean distance for this row.
    this_row_index = (row_start - 1) / points_per_row + 1;
    mean_distance_per_row(this_row_index) = mean(pair_distances);
    rms_distance_per_row(this_row_index) = sqrt(mean(pair_distances.^2));
    mean_error_per_row(this_row_index) = mean(pair_errors);
    rms_error_per_row(this_row_index) = sqrt(mean(pair_errors.^2));
end

for r = 1 : total_rows
    mean_distance = mean_distance_per_row(1, r);
    rms_distance = rms_distance_per_row(1, r);
    mean_error = mean_error_per_row(1, r);
    rms_error = rms_error_per_row(1, r);
    fprintf('Mean distance on row %d: %.6f\n', r, mean_distance);
    fprintf('RMS distance on row %d: %.6f\n', r, rms_distance);
    fprintf('Mean error on row %d: %.6f\n', r, mean_error);
    fprintf('RMS error on row %d: %.6f\n\n', r, rms_error);
end
