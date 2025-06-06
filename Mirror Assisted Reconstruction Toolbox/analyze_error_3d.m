% The functionality of this script depends on two factors:
% a) points are equally spaced (i.e., distance from point p -> p + 1 is constant for any choice of p).
% b) points are defined on a well-defined, planar surface such such as a chessboard used for calibration (i.e., the
% Euclidean distance defined w.r.t. the world axes between any two points is constant at all points on the surface).
% This is because when a surface is planar, the Euclidean distance (shortest path) between any two points happens to lie
% parallel to the surface and thus measures the distance along the surface. In curves, this is not the case.
%
% . . . . . .        |       . . . . . .
% . . . . . .        |           . . . . . .
% . . . . . .        |              . . . . . .
% . . . . . .        |               . . . . . .
% . . . . . .        |               . . . . . .
%
% Imagine the distance between the two points p(1, 1) and p(2, 1) and the points p(4, 1) and p(5, 2) in both of the
% above surfaces. It is clear than on the left, the distance is the same, while that on the right is different.

set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultAxesFontSize', 14);
set(groot, 'defaultfigurecolor', [1 1 1]);

try
    default = load('defaults.mat');
catch
    default = struct();
    default.FEX_USE_TIGHTFIG = false;
    default.FEX_USE_EXPORTFIG = false;
end

% Global configuration
config = struct();
config.show_plots = true;  % Whether to display plots or render in background

% Load the estimated 3D world points. The file should contain a variable named 'xyzpts' with the 3D coordinates.
[filename, pathname] = uigetfile('*.mat', 'Select the xyzpts.mat file containing the 3D world points');
if filename == 0
    error('No file selected.');
end

% Load the data.
xyzpts = load(fullfile(pathname, filename));
world_points = xyzpts.X_est;

% Get user input for the expected distance between neighboring points.
expected_distance = input('Enter the actual physical distance between neighboring points (in mm): ');

% Compute distances between neighboring points. We'll compute the Euclidean distance between each consecutive pair.
num_points = size(world_points, 2);
distances = zeros(num_points - 1, 1);

for i = 1 : num_points - 1
    % Calculate Euclidean distance between consecutive points.
    distances(i) = norm(world_points(:,i+1) - world_points(:,i));
end

% Calculate errors (difference between measured and expected distances).
errors = abs(distances - expected_distance);

% Calculate statistics about the distances.
mean_distance = mean(distances);
std_distance = std(distances);
var_distance = var(distances);

% Calculate error metrics.
min_error = min(errors);
max_error = max(errors);
mean_error = mean(errors);
rms_error = sqrt(mean(errors.^2));
std_error = std(errors);
var_error = var(errors);

% Calculate standardized metrics
standardized_distances = abs((distances - mean_distance) / std_distance);
standardized_errors = abs((errors - mean_error) / std_error);

% Set very small standardized means to zero
mean_std_dist = mean(standardized_distances);
if abs(mean_std_dist) < 1e-9
    mean_std_dist = 0;
end

mean_std_err = mean(standardized_errors);
if abs(mean_std_err) < 1e-9
    mean_std_err = 0;
end

% Calculate standardized statistics
min_std_dist = min(standardized_distances);
max_std_dist = max(standardized_distances);
std_std_dist = std(standardized_distances);

min_std_err = min(standardized_errors);
max_std_err = max(standardized_errors);
std_std_err = std(standardized_errors);

%% BINNING ANALYSIS
% Configuration for binning
bin_config = struct();
bin_config.num_bins = 10;  % Number of bins for histograms
bin_config.bin_edges = 'auto';  % Can be 'auto' or 'manual'
bin_config.manual_edges = [];  % Set this if using manual bin edges
bin_config.show_histograms = true;  % Whether to show histogram plots
bin_config.normalize = true;  % Whether to normalize histograms

% Calculate bin edges
if strcmp(bin_config.bin_edges, 'auto')
    % For distances
    bin_edges_dist = linspace(min(distances), max(distances), bin_config.num_bins + 1);
    % For errors
    bin_edges_err = linspace(min(errors), max(errors), bin_config.num_bins + 1);
    % For standardized distances
    bin_edges_std_dist = linspace(min(standardized_distances), max(standardized_distances), bin_config.num_bins + 1);
    % For standardized errors
    bin_edges_std_err = linspace(min(standardized_errors), max(standardized_errors), bin_config.num_bins + 1);
else
    bin_edges_dist = bin_config.manual_edges;
    bin_edges_err = bin_config.manual_edges;
    bin_edges_std_dist = bin_config.manual_edges;
    bin_edges_std_err = bin_config.manual_edges;
end

% Calculate histograms
[counts_dist, bin_edges_dist] = histcounts(distances, bin_edges_dist);
[counts_err, bin_edges_err] = histcounts(errors, bin_edges_err);
[counts_std_dist, bin_edges_std_dist] = histcounts(standardized_distances, bin_edges_std_dist);
[counts_std_err, bin_edges_std_err] = histcounts(standardized_errors, bin_edges_std_err);

% Calculate bin centers
bin_centers_dist = (bin_edges_dist(1:end-1) + bin_edges_dist(2:end)) / 2;
bin_centers_err = (bin_edges_err(1:end-1) + bin_edges_err(2:end)) / 2;
bin_centers_std_dist = (bin_edges_std_dist(1:end-1) + bin_edges_std_dist(2:end)) / 2;
bin_centers_std_err = (bin_edges_std_err(1:end-1) + bin_edges_std_err(2:end)) / 2;

% Calculate bin statistics
bin_stats = struct();
bin_stats.distances = struct(...
    'centers', bin_centers_dist, ...
    'counts', counts_dist, ...
    'edges', bin_edges_dist, ...
    'normalized_counts', counts_dist / sum(counts_dist));
bin_stats.errors = struct(...
    'centers', bin_centers_err, ...
    'counts', counts_err, ...
    'edges', bin_edges_err, ...
    'normalized_counts', counts_err / sum(counts_err));
bin_stats.standardized_distances = struct(...
    'centers', bin_centers_std_dist, ...
    'counts', counts_std_dist, ...
    'edges', bin_edges_std_dist, ...
    'normalized_counts', counts_std_dist / sum(counts_std_dist));
bin_stats.standardized_errors = struct(...
    'centers', bin_centers_std_err, ...
    'counts', counts_std_err, ...
    'edges', bin_edges_std_err, ...
    'normalized_counts', counts_std_err / sum(counts_std_err));

% Add binning configuration and statistics to errors_3d struct
errors_3d.bin_config = bin_config;
errors_3d.bin_stats = bin_stats;

%% PLOTTING THE RESULTS.

fprintf('\nDistance Statistics:\n');
fprintf('Mean distance: %.2f mm\n', mean_distance);
fprintf('Standard deviation of distances: %.2f mm\n', std_distance);
fprintf('Variance of distances: %.2f mm²\n', var_distance);

fprintf('\nStandardized Distance Statistics:\n');
fprintf('Minimum standardized distance: %.2f σ\n', min_std_dist);
fprintf('Maximum standardized distance: %.2f σ\n', max_std_dist);
fprintf('Mean standardized distance: %.2f σ\n', mean_std_dist);
fprintf('Standard deviation of standardized distances: %.2f σ\n', std_std_dist);

fprintf('\nError Statistics:\n');
fprintf('Minimum error: %.2f mm\n', min_error);
fprintf('Maximum error: %.2f mm\n', max_error);
fprintf('Mean error: %.2f mm\n', mean_error);
fprintf('RMS error: %.2f mm\n', rms_error);
fprintf('Standard deviation of errors: %.2f mm\n', std_error);
fprintf('Variance of errors: %.2f mm²\n', var_error);

fprintf('\nStandardized Error Statistics:\n');
fprintf('Minimum standardized error: %.2f σ\n', min_std_err);
fprintf('Maximum standardized error: %.2f σ\n', max_std_err);
fprintf('Mean standardized error: %.2f σ\n', mean_std_err);
fprintf('Standard deviation of standardized errors: %.2f σ\n', std_std_err);

% Plot the distances for visualization.
if config.show_plots
    figure('Name', 'Distance Analysis', 'NumberTitle', 'off');
else
    figure('Name', 'Distance Analysis', 'NumberTitle', 'off', 'Visible', 'off');
end
x = 1:num_points-1;
plot(x, distances, 'b-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
hold on;
plot([1 num_points-1], [mean_distance mean_distance], 'r--', 'LineWidth', 1.5);
plot([1 num_points-1], [expected_distance expected_distance], 'k--', 'LineWidth', 1.5);
% Add mean and standard deviation bands with dotted lines
upper_bound = mean_distance + std_distance;
lower_bound = max(0, mean_distance - std_distance);  % Ensure non-negative
plot([1 num_points-1], [upper_bound upper_bound], 'g:', 'LineWidth', 1.5);
plot([1 num_points-1], [lower_bound lower_bound], 'g:', 'LineWidth', 1.5);
fill([x fliplr(x)], [upper_bound*ones(size(x)) fliplr(lower_bound*ones(size(x)))], ...
    'g', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
xlabel('Point Pair Index', 'FontSize', 14);
ylabel('Distance (mm)', 'FontSize', 14);
title('Distances Between Consecutive Points', 'FontSize', 18);
legend('Measured Distance', 'Mean Distance', 'Expected Distance', '±1 Std Dev Bounds', '±1 Std Dev Region', 'Location', 'best');
grid on;
set(gca, 'FontSize', 14);

% Plot standardized distances
if config.show_plots
    figure('Name', 'Standardized Distance Analysis', 'NumberTitle', 'off');
else
    figure('Name', 'Standardized Distance Analysis', 'NumberTitle', 'off', 'Visible', 'off');
end
plot(x, standardized_distances, 'b-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
hold on;
plot([1 num_points-1], [0 0], 'r--', 'LineWidth', 1.5);
% Add standard deviation bounds with dotted lines
upper_bound = 1;
lower_bound = 0;  % Since we're using absolute values
plot([1 num_points-1], [upper_bound upper_bound], 'g:', 'LineWidth', 1.5);
plot([1 num_points-1], [lower_bound lower_bound], 'g:', 'LineWidth', 1.5);
fill([x fliplr(x)], [upper_bound*ones(size(x)) fliplr(lower_bound*ones(size(x)))], ...
    'g', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
xlabel('Point Pair Index', 'FontSize', 14);
ylabel('Standardized Distance (σ)', 'FontSize', 14);
title('Standardized Distances Between Consecutive Points', 'FontSize', 18);
legend('Standardized Distance', 'Zero Mean', '±1 Std Dev Bounds', '±1 Std Dev Region', 'Location', 'best');
grid on;
set(gca, 'FontSize', 14);

% Plot the errors for visualization.
if config.show_plots
    figure('Name', 'Error Analysis', 'NumberTitle', 'off');
else
    figure('Name', 'Error Analysis', 'NumberTitle', 'off', 'Visible', 'off');
end
plot(x, errors, 'b-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
hold on;
plot([1 num_points-1], [mean_error mean_error], 'r--', 'LineWidth', 1.5);
plot([1 num_points-1], [0 0], 'k--', 'LineWidth', 1.5);
% Add mean and standard deviation bands with dotted lines
upper_bound = mean_error + std_error;
lower_bound = max(0, mean_error - std_error);  % Ensure non-negative
plot([1 num_points-1], [upper_bound upper_bound], 'g:', 'LineWidth', 1.5);
plot([1 num_points-1], [lower_bound lower_bound], 'g:', 'LineWidth', 1.5);
fill([x fliplr(x)], [upper_bound*ones(size(x)) fliplr(lower_bound*ones(size(x)))], ...
    'g', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
xlabel('Point Pair Index', 'FontSize', 14);
ylabel('Error (mm)', 'FontSize', 14);
title('Errors in Point-to-Point Distances', 'FontSize', 18);
legend('Error', 'Mean Error', 'Zero Error Reference', '±1 Std Dev Bounds', '±1 Std Dev Region', 'Location', 'best');
grid on;
set(gca, 'FontSize', 14);

% Plot standardized errors
if config.show_plots
    figure('Name', 'Standardized Error Analysis', 'NumberTitle', 'off');
else
    figure('Name', 'Standardized Error Analysis', 'NumberTitle', 'off', 'Visible', 'off');
end
plot(x, standardized_errors, 'b-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
hold on;
plot([1 num_points-1], [0 0], 'r--', 'LineWidth', 1.5);
% Add standard deviation bounds with dotted lines
upper_bound = 1;
lower_bound = 0;  % Since we're using absolute values
plot([1 num_points-1], [upper_bound upper_bound], 'g:', 'LineWidth', 1.5);
plot([1 num_points-1], [lower_bound lower_bound], 'g:', 'LineWidth', 1.5);
fill([x fliplr(x)], [upper_bound*ones(size(x)) fliplr(lower_bound*ones(size(x)))], ...
    'g', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
xlabel('Point Pair Index', 'FontSize', 14);
ylabel('Standardized Error (σ)', 'FontSize', 14);
title('Standardized Errors in Point-to-Point Distances', 'FontSize', 18);
legend('Standardized Error', 'Zero Mean', '±1 Std Dev Bounds', '±1 Std Dev Region', 'Location', 'best');
grid on;
set(gca, 'FontSize', 14);

% Add histogram plots if enabled
if bin_config.show_histograms
    % Plot histograms for distances
    if config.show_plots
        figure('Name', 'Distance Distribution', 'NumberTitle', 'off');
    else
        figure('Name', 'Distance Distribution', 'NumberTitle', 'off', 'Visible', 'off');
    end
    hold on;
    if bin_config.normalize
        bar(bin_centers_dist, bin_stats.distances.normalized_counts, 1, 'FaceAlpha', 0.3);
        ylabel('Normalized Frequency', 'FontSize', 14);
    else
        bar(bin_centers_dist, counts_dist, 1, 'FaceAlpha', 0.3);
        ylabel('Count', 'FontSize', 14);
    end
    % Add line plot at bin centers
    plot(bin_centers_dist, bin_stats.distances.normalized_counts, 'r-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
    % Add PDF estimate
    [f, xi] = ksdensity(distances, 'NumPoints', 1000);
    % Scale PDF to match histogram
    f = f * (max(bin_stats.distances.normalized_counts) / max(f));
    % Trim PDF to histogram edges
    valid_indices = xi >= bin_edges_dist(1) & xi <= bin_edges_dist(end);
    plot(xi(valid_indices), f(valid_indices), 'b-', 'LineWidth', 1.5);
    % Set x-axis limit to match histogram edges
    xlim([bin_edges_dist(1) bin_edges_dist(end)]);
    xlabel('Distance (mm)', 'FontSize', 14);
    title('Distribution of Distances', 'FontSize', 18);
    legend('Histogram', 'Bin Centers', 'PDF Estimate', 'Location', 'best');
    grid on;
    set(gca, 'FontSize', 14);

    % Plot histograms for errors
    if config.show_plots
        figure('Name', 'Error Distribution', 'NumberTitle', 'off');
    else
        figure('Name', 'Error Distribution', 'NumberTitle', 'off', 'Visible', 'off');
    end
    hold on;
    if bin_config.normalize
        bar(bin_centers_err, bin_stats.errors.normalized_counts, 1, 'FaceAlpha', 0.3);
        ylabel('Normalized Frequency', 'FontSize', 14);
    else
        bar(bin_centers_err, counts_err, 1, 'FaceAlpha', 0.3);
        ylabel('Count', 'FontSize', 14);
    end
    % Add line plot at bin centers
    plot(bin_centers_err, bin_stats.errors.normalized_counts, 'r-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
    % Add PDF estimate
    [f, xi] = ksdensity(errors, 'NumPoints', 1000);
    % Scale PDF to match histogram
    f = f * (max(bin_stats.errors.normalized_counts) / max(f));
    % Trim PDF to histogram edges
    valid_indices = xi >= bin_edges_err(1) & xi <= bin_edges_err(end);
    plot(xi(valid_indices), f(valid_indices), 'b-', 'LineWidth', 1.5);
    % Set x-axis limit to match histogram edges
    xlim([bin_edges_err(1) bin_edges_err(end)]);
    xlabel('Error (mm)', 'FontSize', 14);
    title('Distribution of Errors', 'FontSize', 18);
    legend('Histogram', 'Bin Centers', 'PDF Estimate', 'Location', 'best');
    grid on;
    set(gca, 'FontSize', 14);

    % Plot histograms for standardized distances
    if config.show_plots
        figure('Name', 'Standardized Distance Distribution', 'NumberTitle', 'off');
    else
        figure('Name', 'Standardized Distance Distribution', 'NumberTitle', 'off', 'Visible', 'off');
    end
    hold on;
    if bin_config.normalize
        bar(bin_centers_std_dist, bin_stats.standardized_distances.normalized_counts, 1, 'FaceAlpha', 0.3);
        ylabel('Normalized Frequency', 'FontSize', 14);
    else
        bar(bin_centers_std_dist, counts_std_dist, 1, 'FaceAlpha', 0.3);
        ylabel('Count', 'FontSize', 14);
    end
    % Add line plot at bin centers
    plot(bin_centers_std_dist, bin_stats.standardized_distances.normalized_counts, 'r-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
    % Add PDF estimate
    [f, xi] = ksdensity(standardized_distances, 'NumPoints', 1000);
    % Scale PDF to match histogram
    f = f * (max(bin_stats.standardized_distances.normalized_counts) / max(f));
    % Trim PDF to histogram edges
    valid_indices = xi >= bin_edges_std_dist(1) & xi <= bin_edges_std_dist(end);
    plot(xi(valid_indices), f(valid_indices), 'b-', 'LineWidth', 1.5);
    % Set x-axis limit to match histogram edges
    xlim([bin_edges_std_dist(1) bin_edges_std_dist(end)]);
    xlabel('Standardized Distance (σ)', 'FontSize', 14);
    title('Distribution of Standardized Distances', 'FontSize', 18);
    legend('Histogram', 'Bin Centers', 'PDF Estimate', 'Location', 'best');
    grid on;
    set(gca, 'FontSize', 14);

    % Plot histograms for standardized errors
    if config.show_plots
        figure('Name', 'Standardized Error Distribution', 'NumberTitle', 'off');
    else
        figure('Name', 'Standardized Error Distribution', 'NumberTitle', 'off', 'Visible', 'off');
    end
    hold on;
    if bin_config.normalize
        bar(bin_centers_std_err, bin_stats.standardized_errors.normalized_counts, 1, 'FaceAlpha', 0.3);
        ylabel('Normalized Frequency', 'FontSize', 14);
    else
        bar(bin_centers_std_err, counts_std_err, 1, 'FaceAlpha', 0.3);
        ylabel('Count', 'FontSize', 14);
    end
    % Add line plot at bin centers
    plot(bin_centers_std_err, bin_stats.standardized_errors.normalized_counts, 'r-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
    % Add PDF estimate
    [f, xi] = ksdensity(standardized_errors, 'NumPoints', 1000);
    % Scale PDF to match histogram
    f = f * (max(bin_stats.standardized_errors.normalized_counts) / max(f));
    % Trim PDF to histogram edges
    valid_indices = xi >= bin_edges_std_err(1) & xi <= bin_edges_std_err(end);
    plot(xi(valid_indices), f(valid_indices), 'b-', 'LineWidth', 1.5);
    % Set x-axis limit to match histogram edges
    xlim([bin_edges_std_err(1) bin_edges_std_err(end)]);
    xlabel('Standardized Error (σ)', 'FontSize', 14);
    title('Distribution of Standardized Errors', 'FontSize', 18);
    legend('Histogram', 'Bin Centers', 'PDF Estimate', 'Location', 'best');
    grid on;
    set(gca, 'FontSize', 14);
end

%% SAVING THE RESULTS.

% Store all figures
figures = findall(0, 'Type', 'figure');
figure_handles = zeros(length(figures), 1);
for i = 1:length(figures)
    figure_handles(i) = figures(i).Number;
end

% Create struct with all analysis results
errors_3d = struct();
errors_3d.distance_stats = struct(...
    'mean', mean_distance, ...
    'std', std_distance, ...
    'var', var_distance, ...
    'min', min(distances), ...
    'max', max(distances));
errors_3d.error_stats = struct(...
    'mean', mean_error, ...
    'std', std_error, ...
    'var', var_error, ...
    'min', min_error, ...
    'max', max_error, ...
    'rms', rms_error);
errors_3d.standardized_distance_stats = struct(...
    'mean', mean_std_dist, ...
    'std', std_std_dist, ...
    'min', min_std_dist, ...
    'max', max_std_dist);
errors_3d.standardized_error_stats = struct(...
    'mean', mean_std_err, ...
    'std', std_std_err, ...
    'min', min_std_err, ...
    'max', max_std_err);
errors_3d.raw_data = struct(...
    'distances', distances, ...
    'errors', errors, ...
    'standardized_distances', standardized_distances, ...
    'standardized_errors', standardized_errors);

errors_3d.figure_handles = figure_handles;
errors_3d.expected_distance = expected_distance;
errors_3d.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');

% Create a errors_3d directory if it doesn't exist in the parent directory of the input xyzpts.mat file.
[parent_dir, ~, ~] = fileparts(pathname);
error_analysis_dir = fullfile(parent_dir, 'error_analysis', '3d');
if ~exist(error_analysis_dir, 'dir')
    mkdir(error_analysis_dir);
end

% Get the base filename without extension
[~, name, ~] = fileparts(filename);

% Save the struct
save(fullfile(error_analysis_dir, [name '_analysis.mat']), 'errors_3d');

% Save the metrics to a text file
fid = fopen(fullfile(error_analysis_dir, [name '_analysis.txt']), 'w');
fprintf(fid, '3D Error Analysis Results\n');
fprintf(fid, '========================\n\n');
fprintf(fid, 'Analysis performed on: %s\n\n', errors_3d.timestamp);
fprintf(fid, 'Expected distance between points: %.2f mm\n\n', expected_distance);

fprintf(fid, 'Distance Statistics:\n');
fprintf(fid, '-------------------\n');
fprintf(fid, 'Mean distance: %.2f mm\n', mean_distance);
fprintf(fid, 'Standard deviation of distances: %.2f mm\n', std_distance);
fprintf(fid, 'Variance of distances: %.2f mm²\n', var_distance);
fprintf(fid, 'Minimum distance: %.2f mm\n', min(distances));
fprintf(fid, 'Maximum distance: %.2f mm\n\n', max(distances));

fprintf(fid, 'Standardized Distance Statistics:\n');
fprintf(fid, '-------------------------------\n');
fprintf(fid, 'Minimum standardized distance: %.2f σ\n', min_std_dist);
fprintf(fid, 'Maximum standardized distance: %.2f σ\n', max_std_dist);
fprintf(fid, 'Mean standardized distance: %.2f σ\n', mean_std_dist);
fprintf(fid, 'Standard deviation of standardized distances: %.2f σ\n\n', std_std_dist);

fprintf(fid, 'Error Statistics:\n');
fprintf(fid, '----------------\n');
fprintf(fid, 'Minimum error: %.2f mm\n', min_error);
fprintf(fid, 'Maximum error: %.2f mm\n', max_error);
fprintf(fid, 'Mean error: %.2f mm\n', mean_error);
fprintf(fid, 'RMS error: %.2f mm\n', rms_error);
fprintf(fid, 'Standard deviation of errors: %.2f mm\n', std_error);
fprintf(fid, 'Variance of errors: %.2f mm²\n\n', var_error);

fprintf(fid, 'Standardized Error Statistics:\n');
fprintf(fid, '----------------------------\n');
fprintf(fid, 'Minimum standardized error: %.2f σ\n', min_std_err);
fprintf(fid, 'Maximum standardized error: %.2f σ\n', max_std_err);
fprintf(fid, 'Mean standardized error: %.2f σ\n', mean_std_err);
fprintf(fid, 'Standard deviation of standardized errors: %.2f σ\n', std_std_err);

% Add binning statistics to the text file
fprintf(fid, '\nBinning Analysis:\n');
fprintf(fid, '----------------\n');
fprintf(fid, 'Number of bins: %d\n', bin_config.num_bins);
fprintf(fid, 'Bin edges type: %s\n\n', bin_config.bin_edges);

fprintf(fid, 'Distance Distribution:\n');
fprintf(fid, '--------------------\n');
for i = 1:length(bin_centers_dist)
    fprintf(fid, 'Bin %d (%.2f mm): %d points (%.2f%%)\n', ...
        i, bin_centers_dist(i), counts_dist(i), ...
        100 * bin_stats.distances.normalized_counts(i));
end
fprintf(fid, '\n');

fprintf(fid, 'Error Distribution:\n');
fprintf(fid, '------------------\n');
for i = 1:length(bin_centers_err)
    fprintf(fid, 'Bin %d (%.2f mm): %d points (%.2f%%)\n', ...
        i, bin_centers_err(i), counts_err(i), ...
        100 * bin_stats.errors.normalized_counts(i));
end
fprintf(fid, '\n');

fprintf(fid, 'Standardized Distance Distribution:\n');
fprintf(fid, '--------------------------------\n');
for i = 1:length(bin_centers_std_dist)
    fprintf(fid, 'Bin %d (%.2f σ): %d points (%.2f%%)\n', ...
        i, bin_centers_std_dist(i), counts_std_dist(i), ...
        100 * bin_stats.standardized_distances.normalized_counts(i));
end
fprintf(fid, '\n');

fprintf(fid, 'Standardized Error Distribution:\n');
fprintf(fid, '------------------------------\n');
for i = 1:length(bin_centers_std_err)
    fprintf(fid, 'Bin %d (%.2f σ): %d points (%.2f%%)\n', ...
        i, bin_centers_std_err(i), counts_std_err(i), ...
        100 * bin_stats.standardized_errors.normalized_counts(i));
end

fclose(fid);

% Save the metrics to a CSV file
% Create table with metrics as rows
metric_names = {
    'Distance_Mean';
    'Distance_Std';
    'Distance_Var';
    'Distance_Min';
    'Distance_Max';
    'StdDistance_Min';
    'StdDistance_Max';
    'StdDistance_Mean';
    'StdDistance_Std';
    'Error_Mean';
    'Error_RMS';
    'Error_Std';
    'Error_Var';
    'Error_Min';
    'Error_Max';
    'StdError_Min';
    'StdError_Max';
    'StdError_Mean';
    'StdError_Std';
    'ExpectedDistance'
};

metric_values = [
    mean_distance;
    std_distance;
    var_distance;
    min(distances);
    max(distances);
    min_std_dist;
    max_std_dist;
    mean_std_dist;
    std_std_dist;
    mean_error;
    rms_error;
    std_error;
    var_error;
    min_error;
    max_error;
    min_std_err;
    max_std_err;
    mean_std_err;
    std_std_err;
    expected_distance
];

% Create table and save as CSV
csv_table = table(metric_names, metric_values, 'VariableNames', {'Metric', 'Value'});
writetable(csv_table, fullfile(error_analysis_dir, [name '_analysis.csv']));

% Display save confirmation
fprintf('\nAnalysis results have been saved to:\n');
fprintf('MAT file: %s\n', fullfile(error_analysis_dir, [name '_analysis.mat']));
fprintf('Text file: %s\n', fullfile(error_analysis_dir, [name '_analysis.txt']));
fprintf('CSV file: %s\n', fullfile(error_analysis_dir, [name '_analysis.csv']));

% Save the figures
for i = 1 : length(figures)
    figure(figure_handles(i));
    % Hide the axes toolbar.
    if ~config.show_plots
        set(gcf, 'toolbar', 'none');
    end

    if default.FEX_USE_EXPORTFIG && default.FEX_USE_TIGHTFIG
        tightfig;
        export_fig(fullfile(error_analysis_dir, [name '_figure_' num2str(i) '.png']), '-native');
        saveas(gcf, fullfile(error_analysis_dir, [name '_figure_' num2str(i) '.png']));
    elseif default.FEX_USE_EXPORTFIG
        export_fig(fullfile(error_analysis_dir, [name '_figure_' num2str(i) '.png']), '-native');
    elseif default.FEX_USE_TIGHTFIG
        tightfig;
        saveas(gcf, fullfile(error_analysis_dir, [name '_figure_' num2str(i) '.png']));
    else
        saveas(gcf, fullfile(error_analysis_dir, [name '_figure_' num2str(i) '.png']));
    end
end