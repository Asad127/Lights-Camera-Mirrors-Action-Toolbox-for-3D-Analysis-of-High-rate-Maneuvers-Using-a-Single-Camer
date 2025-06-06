% Script to analyze 2D reprojection errors between original marked points and projected points.
% Takes as input:
% 1. marked_points.mat - Contains original pixel coordinates
% 2. xypts.mat - Contains projected pixel coordinates from estimated world coordinates

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
config.show_plots = true;

% Load the original marked points
[filename_marked, pathname_marked] = uigetfile('*.mat', 'Select the marked_points.mat file containing the original pixel coordinates');
if filename_marked == 0
    error('No file selected.');
end
marked_points = load(fullfile(pathname_marked, filename_marked));
x_org = marked_points.x;  % 3xN matrix with homogeneous coordinates
num_points = marked_points.num_points;

% Load the projected points
[filename_proj, pathname_proj] = uigetfile('*.mat', 'Select the xypts.mat file containing the projected pixel coordinates');
if filename_proj == 0
    error('No file selected.');
end
proj_points = load(fullfile(pathname_proj, filename_proj));
x_proj = proj_points.proj_pixels_est_all;  % 2xN matrix

% Calculate number of views
num_views = size(x_org, 2) / num_points;

% Calculate errors for each point in each view
errors = zeros(2, num_points * num_views);
pixel_distances = zeros(1, num_points * num_views);
for i = 1:num_points * num_views
    % Convert homogeneous coordinates to inhomogeneous for comparison
    x_org_inhomo = x_org(1:2, i) / x_org(3, i);
    errors(:, i) = abs(x_org_inhomo - x_proj(:, i));
    pixel_distances(i) = norm(x_org_inhomo - x_proj(:, i));
end

% Calculate error magnitudes
error_magnitudes = sqrt(sum(errors.^2, 1));

% Calculate statistics
mean_error = mean(error_magnitudes);
std_error = std(error_magnitudes);
var_error = var(error_magnitudes);
rms_error = sqrt(mean(error_magnitudes.^2));

% Calculate standardized metrics
standardized_distances = abs((pixel_distances - mean(pixel_distances)) / std(pixel_distances));
standardized_errors = abs((error_magnitudes - mean_error) / std_error);

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

% Calculate per-view statistics
per_view_mean_error = zeros(1, num_views);
per_view_rms_error = zeros(1, num_views);
per_view_std_error = zeros(1, num_views);

for j = 1:num_views
    view_indices = (j-1)*num_points + 1 : j*num_points;
    per_view_mean_error(j) = mean(error_magnitudes(view_indices));
    per_view_rms_error(j) = sqrt(mean(error_magnitudes(view_indices).^2));
    per_view_std_error(j) = std(error_magnitudes(view_indices));
end

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
    % For pixel distances
    bin_edges_dist = linspace(min(pixel_distances), max(pixel_distances), bin_config.num_bins + 1);
    % For errors
    bin_edges_err = linspace(min(error_magnitudes), max(error_magnitudes), bin_config.num_bins + 1);
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
[counts_dist, bin_edges_dist] = histcounts(pixel_distances, bin_edges_dist);
[counts_err, bin_edges_err] = histcounts(error_magnitudes, bin_edges_err);
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

%% PLOTTING THE RESULTS

fprintf('\nPixel Distance Statistics:\n');
fprintf('Mean distance: %.2f pixels\n', mean(pixel_distances));
fprintf('Standard deviation of distances: %.2f pixels\n', std(pixel_distances));
fprintf('Variance of distances: %.2f pixels²\n', var(pixel_distances));

fprintf('\nStandardized Distance Statistics:\n');
fprintf('Minimum standardized distance: %.2f σ\n', min_std_dist);
fprintf('Maximum standardized distance: %.2f σ\n', max_std_dist);
fprintf('Mean standardized distance: %.2f σ\n', mean_std_dist);
fprintf('Standard deviation of standardized distances: %.2f σ\n', std_std_dist);

fprintf('\nError Statistics:\n');
fprintf('Mean error: %.2f pixels\n', mean_error);
fprintf('RMS error: %.2f pixels\n', rms_error);
fprintf('Standard deviation of errors: %.2f pixels\n', std_error);
fprintf('Variance of errors: %.2f pixels²\n', var_error);

fprintf('\nStandardized Error Statistics:\n');
fprintf('Minimum standardized error: %.2f σ\n', min_std_err);
fprintf('Maximum standardized error: %.2f σ\n', max_std_err);
fprintf('Mean standardized error: %.2f σ\n', mean_std_err);
fprintf('Standard deviation of standardized errors: %.2f σ\n', std_std_err);

fprintf('\nPer-View Error Statistics:\n');
for j = 1:num_views
    fprintf('View %d:\n', j);
    fprintf('  Mean error: %.2f pixels\n', per_view_mean_error(j));
    fprintf('  RMS error: %.2f pixels\n', per_view_rms_error(j));
    fprintf('  Standard deviation: %.2f pixels\n', per_view_std_error(j));
end

% Plot pixel distances
if config.show_plots
    figure('Name', 'Pixel Distance Analysis', 'NumberTitle', 'off');
else
    figure('Name', 'Pixel Distance Analysis', 'NumberTitle', 'off', 'Visible', 'off');
end
x = 1:num_points*num_views;
plot(x, pixel_distances, 'b-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
hold on;
plot([1 num_points*num_views], [mean(pixel_distances) mean(pixel_distances)], 'r--', 'LineWidth', 1.5);
% Add mean and standard deviation bands with dotted lines
upper_bound = mean(pixel_distances) + std(pixel_distances);
lower_bound = max(0, mean(pixel_distances) - std(pixel_distances));  % Ensure non-negative
plot([1 num_points*num_views], [upper_bound upper_bound], 'g:', 'LineWidth', 1.5);
plot([1 num_points*num_views], [lower_bound lower_bound], 'g:', 'LineWidth', 1.5);
fill([x fliplr(x)], [upper_bound*ones(size(x)) fliplr(lower_bound*ones(size(x)))], ...
    'g', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
xlabel('Point Index', 'FontSize', 14);
ylabel('Pixel Distance', 'FontSize', 14);
title('Pixel Distances Between Original and Projected Points', 'FontSize', 18);
legend('Pixel Distance', 'Mean Distance', '±1 Std Dev Bounds', '±1 Std Dev Region', 'Location', 'best');
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
plot([1 num_points*num_views], [0 0], 'r--', 'LineWidth', 1.5);
% Add standard deviation bounds with dotted lines
upper_bound = 1;
lower_bound = 0;  % Since we're using absolute values
plot([1 num_points*num_views], [upper_bound upper_bound], 'g:', 'LineWidth', 1.5);
plot([1 num_points*num_views], [lower_bound lower_bound], 'g:', 'LineWidth', 1.5);
fill([x fliplr(x)], [upper_bound*ones(size(x)) fliplr(lower_bound*ones(size(x)))], ...
    'g', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
xlabel('Point Index', 'FontSize', 14);
ylabel('Standardized Distance (σ)', 'FontSize', 14);
title('Standardized Pixel Distances', 'FontSize', 18);
legend('Standardized Distance', 'Zero Mean', '±1 Std Dev Bounds', '±1 Std Dev Region', 'Location', 'best');
grid on;
set(gca, 'FontSize', 14);

% Plot error magnitudes
if config.show_plots
    figure('Name', 'Error Analysis', 'NumberTitle', 'off');
else
    figure('Name', 'Error Analysis', 'NumberTitle', 'off', 'Visible', 'off');
end
plot(x, error_magnitudes, 'b-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
hold on;
plot([1 num_points*num_views], [mean_error mean_error], 'r--', 'LineWidth', 1.5);
% Add mean and standard deviation bands with dotted lines
upper_bound = mean_error + std_error;
lower_bound = max(0, mean_error - std_error);  % Ensure non-negative
plot([1 num_points*num_views], [upper_bound upper_bound], 'g:', 'LineWidth', 1.5);
plot([1 num_points*num_views], [lower_bound lower_bound], 'g:', 'LineWidth', 1.5);
fill([x fliplr(x)], [upper_bound*ones(size(x)) fliplr(lower_bound*ones(size(x)))], ...
    'g', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
xlabel('Point Index', 'FontSize', 14);
ylabel('Error Magnitude (pixels)', 'FontSize', 14);
title('2D Reprojection Error Magnitudes', 'FontSize', 18);
legend('Error Magnitude', 'Mean Error', '±1 Std Dev Bounds', '±1 Std Dev Region', 'Location', 'best');
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
plot([1 num_points*num_views], [0 0], 'r--', 'LineWidth', 1.5);
% Add standard deviation bounds with dotted lines
upper_bound = 1;
lower_bound = 0;  % Since we're using absolute values
plot([1 num_points*num_views], [upper_bound upper_bound], 'g:', 'LineWidth', 1.5);
plot([1 num_points*num_views], [lower_bound lower_bound], 'g:', 'LineWidth', 1.5);
fill([x fliplr(x)], [upper_bound*ones(size(x)) fliplr(lower_bound*ones(size(x)))], ...
    'g', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
xlabel('Point Index', 'FontSize', 14);
ylabel('Standardized Error (σ)', 'FontSize', 14);
title('Standardized 2D Reprojection Errors', 'FontSize', 18);
legend('Standardized Error', 'Zero Mean', '±1 Std Dev Bounds', '±1 Std Dev Region', 'Location', 'best');
grid on;
set(gca, 'FontSize', 14);

% Add histogram plots if enabled
if bin_config.show_histograms
    % Plot histograms for pixel distances
    if config.show_plots
        figure('Name', 'Pixel Distance Distribution', 'NumberTitle', 'off');
    else
        figure('Name', 'Pixel Distance Distribution', 'NumberTitle', 'off', 'Visible', 'off');
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
    [f, xi] = ksdensity(pixel_distances, 'NumPoints', 1000);
    % Scale PDF to match histogram
    f = f * (max(bin_stats.distances.normalized_counts) / max(f));
    % Trim PDF to histogram edges
    valid_indices = xi >= bin_edges_dist(1) & xi <= bin_edges_dist(end);
    plot(xi(valid_indices), f(valid_indices), 'b-', 'LineWidth', 1.5);
    % Set x-axis limit to match histogram edges
    xlim([bin_edges_dist(1) bin_edges_dist(end)]);
    xlabel('Pixel Distance', 'FontSize', 14);
    title('Distribution of Pixel Distances', 'FontSize', 18);
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
    [f, xi] = ksdensity(error_magnitudes, 'NumPoints', 1000);
    % Scale PDF to match histogram
    f = f * (max(bin_stats.errors.normalized_counts) / max(f));
    % Trim PDF to histogram edges
    valid_indices = xi >= bin_edges_err(1) & xi <= bin_edges_err(end);
    plot(xi(valid_indices), f(valid_indices), 'b-', 'LineWidth', 1.5);
    % Set x-axis limit to match histogram edges
    xlim([bin_edges_err(1) bin_edges_err(end)]);
    xlabel('Error Magnitude (pixels)', 'FontSize', 14);
    title('Distribution of 2D Reprojection Errors', 'FontSize', 18);
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
    title('Distribution of Standardized Pixel Distances', 'FontSize', 18);
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
    title('Distribution of Standardized 2D Reprojection Errors', 'FontSize', 18);
    legend('Histogram', 'Bin Centers', 'PDF Estimate', 'Location', 'best');
    grid on;
    set(gca, 'FontSize', 14);
end

%% SAVING THE RESULTS

% Create error_analysis/2d directory in the parent directory of xypts.mat
[parent_dir, ~, ~] = fileparts(pathname_proj);
error_analysis_dir = fullfile(parent_dir, 'error_analysis', '2d');
if ~exist(error_analysis_dir, 'dir')
    mkdir(error_analysis_dir);
end

% Store all figures
figures = findall(0, 'Type', 'figure');
figure_handles = zeros(length(figures), 1);
for i = 1:length(figures)
    figure_handles(i) = figures(i).Number;
end

% Create struct with all analysis results
errors_2d = struct();
errors_2d.distance_stats = struct(...
    'mean', mean(pixel_distances), ...
    'std', std(pixel_distances), ...
    'var', var(pixel_distances), ...
    'min', min(pixel_distances), ...
    'max', max(pixel_distances));
errors_2d.error_stats = struct(...
    'mean', mean_error, ...
    'std', std_error, ...
    'var', var_error, ...
    'min', min(error_magnitudes), ...
    'max', max(error_magnitudes), ...
    'rms', rms_error);
errors_2d.standardized_distance_stats = struct(...
    'mean', mean_std_dist, ...
    'std', std_std_dist, ...
    'min', min_std_dist, ...
    'max', max_std_dist);
errors_2d.standardized_error_stats = struct(...
    'mean', mean_std_err, ...
    'std', std_std_err, ...
    'min', min_std_err, ...
    'max', max_std_err);
errors_2d.per_view_stats = struct(...
    'mean', per_view_mean_error, ...
    'rms', per_view_rms_error, ...
    'std', per_view_std_error);
errors_2d.bin_config = bin_config;
errors_2d.bin_stats = bin_stats;
errors_2d.raw_data = struct(...
    'pixel_distances', pixel_distances, ...
    'error_magnitudes', error_magnitudes, ...
    'standardized_distances', standardized_distances, ...
    'standardized_errors', standardized_errors, ...
    'errors', errors);
errors_2d.figure_handles = figure_handles;
errors_2d.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');

% Get the base filename without extension
[~, name, ~] = fileparts(filename_proj);

% Save the struct
save(fullfile(error_analysis_dir, [name '_analysis.mat']), 'errors_2d');

% Save the metrics to a text file
fid = fopen(fullfile(error_analysis_dir, [name '_analysis.txt']), 'w');
fprintf(fid, '2D Error Analysis Results\n');
fprintf(fid, '========================\n\n');
fprintf(fid, 'Analysis performed on: %s\n\n', errors_2d.timestamp);

fprintf(fid, 'Pixel Distance Statistics:\n');
fprintf(fid, '-----------------------\n');
fprintf(fid, 'Mean distance: %.2f pixels\n', mean(pixel_distances));
fprintf(fid, 'Standard deviation of distances: %.2f pixels\n', std(pixel_distances));
fprintf(fid, 'Variance of distances: %.2f pixels²\n', var(pixel_distances));
fprintf(fid, 'Minimum distance: %.2f pixels\n', min(pixel_distances));
fprintf(fid, 'Maximum distance: %.2f pixels\n\n', max(pixel_distances));

fprintf(fid, 'Standardized Distance Statistics:\n');
fprintf(fid, '-------------------------------\n');
fprintf(fid, 'Minimum standardized distance: %.2f σ\n', min_std_dist);
fprintf(fid, 'Maximum standardized distance: %.2f σ\n', max_std_dist);
fprintf(fid, 'Mean standardized distance: %.2f σ\n', mean_std_dist);
fprintf(fid, 'Standard deviation of standardized distances: %.2f σ\n\n', std_std_dist);

fprintf(fid, 'Error Statistics:\n');
fprintf(fid, '----------------\n');
fprintf(fid, 'Mean error: %.2f pixels\n', mean_error);
fprintf(fid, 'RMS error: %.2f pixels\n', rms_error);
fprintf(fid, 'Standard deviation of errors: %.2f pixels\n', std_error);
fprintf(fid, 'Variance of errors: %.2f pixels²\n', var_error);
fprintf(fid, 'Minimum error: %.2f pixels\n', min(error_magnitudes));
fprintf(fid, 'Maximum error: %.2f pixels\n\n', max(error_magnitudes));

fprintf(fid, 'Standardized Error Statistics:\n');
fprintf(fid, '----------------------------\n');
fprintf(fid, 'Minimum standardized error: %.2f σ\n', min_std_err);
fprintf(fid, 'Maximum standardized error: %.2f σ\n', max_std_err);
fprintf(fid, 'Mean standardized error: %.2f σ\n', mean_std_err);
fprintf(fid, 'Standard deviation of standardized errors: %.2f σ\n\n', std_std_err);

fprintf(fid, 'Per-View Error Statistics:\n');
fprintf(fid, '------------------------\n');
for j = 1:num_views
    fprintf(fid, 'View %d:\n', j);
    fprintf(fid, '  Mean error: %.2f pixels\n', per_view_mean_error(j));
    fprintf(fid, '  RMS error: %.2f pixels\n', per_view_rms_error(j));
    fprintf(fid, '  Standard deviation: %.2f pixels\n', per_view_std_error(j));
end

% Add binning statistics to the text file
fprintf(fid, '\nBinning Analysis:\n');
fprintf(fid, '----------------\n');
fprintf(fid, 'Number of bins: %d\n', bin_config.num_bins);
fprintf(fid, 'Bin edges type: %s\n\n', bin_config.bin_edges);

fprintf(fid, 'Pixel Distance Distribution:\n');
fprintf(fid, '-------------------------\n');
for i = 1:length(bin_centers_dist)
    fprintf(fid, 'Bin %d (%.2f pixels): %d points (%.2f%%)\n', ...
        i, bin_centers_dist(i), counts_dist(i), ...
        100 * bin_stats.distances.normalized_counts(i));
end
fprintf(fid, '\n');

fprintf(fid, 'Error Distribution:\n');
fprintf(fid, '------------------\n');
for i = 1:length(bin_centers_err)
    fprintf(fid, 'Bin %d (%.2f pixels): %d points (%.2f%%)\n', ...
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
    'PixelDistance_Mean';
    'PixelDistance_Std';
    'PixelDistance_Var';
    'PixelDistance_Min';
    'PixelDistance_Max';
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
    'StdError_Std'
};

metric_values = [
    mean(pixel_distances);
    std(pixel_distances);
    var(pixel_distances);
    min(pixel_distances);
    max(pixel_distances);
    min_std_dist;
    max_std_dist;
    mean_std_dist;
    std_std_dist;
    mean_error;
    rms_error;
    std_error;
    var_error;
    min(error_magnitudes);
    max(error_magnitudes);
    min_std_err;
    max_std_err;
    mean_std_err;
    std_std_err
];

% Add per-view statistics
for j = 1:num_views
    metric_names = [metric_names; {
        sprintf('View%d_MeanError', j);
        sprintf('View%d_RMSError', j);
        sprintf('View%d_StdError', j)
    }];
    metric_values = [metric_values; [
        per_view_mean_error(j);
        per_view_rms_error(j);
        per_view_std_error(j)
    ]];
end

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
    if ~config.show_plots
        % Hide the axes toolbar.
        set(gcf, 'toolbar', 'none');
    end

    if default.FEX_USE_EXPORTFIG && default.FEX_USE_TIGHTFIG
        tightfig;
        export_fig(fullfile(error_analysis_dir, [name '_figure_' num2str(i) '.png']), '-native');
    elseif default.FEX_USE_EXPORTFIG
        export_fig(fullfile(error_analysis_dir, [name '_figure_' num2str(i) '.png']), '-native');
    elseif default.FEX_USE_TIGHTFIG
        tightfig;
        saveas(gcf, fullfile(error_analysis_dir, [name '_figure_' num2str(i) '.png']));
    else
        saveas(gcf, fullfile(error_analysis_dir, [name '_figure_' num2str(i) '.png']));
    end
end