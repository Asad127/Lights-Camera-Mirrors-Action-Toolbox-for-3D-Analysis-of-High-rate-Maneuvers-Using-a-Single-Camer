%% SETUP %%
%{
Mark the corresponding points on a set of at least 2 or at most 3 images corresponding to a single camera and 2-mirror
setup.

If working on undistorted images, it is assumed that all views' images are undistorted., and there are no distorted
images in the entire set.
%}

default = load('defaults.mat');

% Define zoom constants.
ZOOM_FACTOR = 2.0;  % Double/halve the size on each zoom step.
MAX_ZOOM_IN = 5;  % Maximum zoom in level (positive).
MAX_ZOOM_OUT = 2;  % Maximum zoom out level (negative).
MAX_ZOOM_BOUNDS = 1.15;  % Maximum zoom bounds relative to image size.

fprintf('Locating (non-undistorted) image to mark points on...')
img_filter = cellfun( ...
    @(extension) ['*' extension], ...
    default.SUPPORTED_IMG_EXTS, ...
    'UniformOutput', false ...
)';
[img_file, img_dir] = uigetfile( ...
    img_filter, ...
    'Locate the non-undistorted image on which to mark points' ...
);

if ~img_file
    error('Operation canceled by user.')
end

img_filepath = fullfile(img_dir, img_file);
[~, img_base, img_extension] = fileparts(img_filepath);
[img_height, img_width, ~] = size(imread(img_filepath));

% Need the calibration to get the view labels.
fprintf('done.\nLocating merged BCT calibration file...')
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

fprintf('done.\n\n')

view_params = load(merged_calib_filepath);
view_labels = view_params.view_labels;
num_views = numel(view_labels);

% Store camera parameters for each view so we can transform the undistortions for the marked points between views.clear
cam_params = struct();
for i = 1 : num_views
    suffix = view_labels(i);
    % kc = distortion coefficients.
    cam_params(i).dist_coefs = view_params.(['kc_' num2str(suffix)]);
    % KK = intrinsics array.
    cam_params(i).intrinsics = view_params.(['KK_' num2str(suffix)]);
end

while true
    num_points = input(['[PROMPT] Enter the no. of points to mark ' ...
        '([] = dynamic marking): '] ...
    );
    if isempty(num_points)
        % Dynamic marking indicated with Inf points initially
        num_points = Inf;
        fprintf(['[INFO] Dynamic marking enabled. Mark points and press "c" ' ...
            'to continue to next view.\n'] ...
        );
        break
    elseif num_points <= 0
        fprintf(['[BAD INPUT] No. of marked points must be a positive integer ' ...
            '> 0.\n'] ...
        );
        continue
    end
    break
end

fprintf(['\nHELP: Only enter "y" if you have the undistorted images or video ' ...
    'frames.\nIf you do not mark points on the undistorted images here, you ' ...
    'can still undistort them for rendering on the undistorted\nimage with the ' ...
    '"undistort_marked_points.m" function. This option is purely for your ' ...
    'marking preference.\n'] ...
);

while true
    choice = input('[PROMPT] Use undistorted images for point marking? (y/n): ', 's');
    if ~ismember(choice, {'y', 'n'})
        fprintf(['[BAD INPUT] Only "y" (yes) and "n" (no) are accepted ' ...
            'inputs. Please try again.\n'] ...
        )
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

    if numel(undistorted_img_dirs) ~= num_views
        error(['Number of undistorted image directories does not match number ' ...
            'of views.'] ...
        );
    end

    % Check that the directories exist, and contain images.
    for i = 1 : numel(undistorted_img_dirs)
        if ~isfolder(undistorted_img_dirs{i})
            error(['An undistorted frame folder was not found in the expected ' ...
                'location:\n\t%s\nIn general, they are expected in the same ' ...
                'directory as the original image in separate folders folders.' ...
                '\nTo ensure proper undistortion setup, run ' ...
                '"create_undistorted_vid_and_fames.m" (videos) or\n' ...
                '"create_undistorted_imgs.m" (images).'], ...
                undistorted_img_dirs{i} ...
            );
        else
            % List all image files in the directory.
            img_listing = dir(fullfile(undistorted_img_dirs{i}, ['*' img_extension]));
            % Check if directory even has images.
            if isempty(img_listing(~ismember({img_listing.name}, {'.', '..'})))
                error(['Undistorted images folder was found, but has no ' ...
                    'images.\n\t%s'], ...
                    undistorted_img_dirs{i} ...
                );
            end
        end
    end
end

fprintf(['\nEntering point-marking mode...\nNOTE: Press "q" to zoom in, ' ...
    '"e" to zoom out, "r" to reset zoom level, and "u" to undo last point. ' ...
    'Zoom is around cursor!\n\n'] ...
)

% x contains all the pixels over all the views.
x = [];
view_names = default.VIEW_NAMES_LONG(view_labels);
points_per_view = zeros(1, numel(view_labels));

for j = 1 : num_views
    marked_views = j - 1;
    history_exists = true;
    if isempty(x)
        history_exists = false;
    end

    view_name = view_names{j};
    fprintf("\to %s View - Marked Points: ", view_names{j})

    % Load image and click points to estimate world coordinates of.
    if use_undistorted_imgs
        img = imread(fullfile(undistorted_img_dirs{j}, img_file));
    end

    figure('Units', 'Normalized', 'Position', [0 0.15 0.8 0.8]);
    imshow(img); hold on;
    % xlabel('x (pixel)'); ylabel('y (pixel)');

    set(gcf, 'Color', 'w');
    set(findall(gcf, '-property', 'FontSize'), 'FontSize', 12);
    zoom off;

    % Initialize zoom tracking variables.
    current_zoom = 0;

    % Mark first point's history (i.e., if it's been marked in other views, plot those pixel locations on the image). At
    % any given time, only one point's history is shown.
    if history_exists
        if use_undistorted_imgs
            % In this case, we have to "transform" the history points (that were marked with distortion correction for
            % those views) by the undistortion for the current view. This involves two steps: (a) distorting the marked
            % undistorted points back to the original distorted locations, and (b) undistorting them with the distortion
            % correction for the current view.

            % To do so, we'll exploit the fact that each view has the same number of marked points (that are assumed to
            % be visible in all views), and that we know how many views have been marked so far.
            for k = 1 : marked_views
                history_start_stop_indices = [1 + num_points * (k - 1),  num_points * k];
                % Get all the points marked in the k'th view.
                undistorted_pts_k = history_marked_pts(1 : 2, history_start_stop_indices(1) : history_start_stop_indices(2));
                % Apply the distortion.
                distorted_pts_k = distort_pts( ...
                    undistorted_pts_k, ...
                    cam_params(k).dist_coefs, ...
                    cam_params(k).intrinsics ...
                );
                % We use the iterative method to undistort the points with the constraint that the computed undistorted
                % points map back to the distorted points to correctly recover the inverse undistortion map for the
                % above distortion operation. undistorted_pts_k_test = invert_distort_pts( ... distorted_pts_k, ...
                % cam_params(k).dist_coefs, ... cam_params(k).intrinsics ... );
                undistorted_pts_k_for_view_j = invert_distort_pts( ...
                    distorted_pts_k, ...
                    cam_params(j).dist_coefs, ...
                    cam_params(j).intrinsics ...
                );
                % DEBUG: Print all points. fprintf('\nundistorted_pts_k: %s\n', mat2str(undistorted_pts_k));
                % fprintf('distorted_pts_k: %s\n', mat2str(distorted_pts_k)); fprintf('undistorted_pts_k_test: %s\n',
                % mat2str(undistorted_pts_k_test)); fprintf('undistorted_pts_k_for_view_j: %s\n',
                % mat2str(undistorted_pts_k_for_view_j));

                % Update the history of marked points.
                history_marked_pts(1 : 2, history_start_stop_indices(1) : history_start_stop_indices(2)) = undistorted_pts_k_for_view_j;
            end
        end

        % No. of columns of x shown the number of marked pixels, such that every distinct set of num_points pixels is
        % the pixel locations in a specific view.
        history_start_idxs = 1 : num_points : size(x, 2);

        % Draw crossed squares to indicate the first marked point in the other views.
        history_squares = plot( ...
            x(1, history_start_idxs), ...
            x(2, history_start_idxs), ...
            'Color', 'b', ...
            'Marker', 'Square', ...
            'MarkerSize', 20, ...
            'linewidth', 2 ...
        );
        history_crosses = plot( ...
            x(1, history_start_idxs), ...
            x(2, history_start_idxs), ...
            'Color', 'b', ...
            'Marker', 'x', ...
            'MarkerSize', 20, ...
            'linewidth', 2 ...
        );
    end

    marked_points = [];

    % If num_points is Inf, engage dynamic marking.
    if isinf(num_points) && j == 1
        while true
            % Update progress message based on marked points.
            progress_msg = sprintf("%d", size(marked_points, 2));
            fprintf(progress_msg)
            num_chars = strlength(progress_msg);
            % Update title (maintain dynamic format until 'c' is pressed).
            title( ...
                sprintf( ...
                    '%s View - Marked Points: %d (q = zoom in, e = zoom out, r = zoom reset, u = undo, c = continue)', ...
                    view_name, ...
                    size(marked_points, 2) ...
                ) ...
            );
            % Get the clicks.
            exit = false;
            while true
                [x_click, y_click, button] = ginput(1);
                if isempty(button)
                    fprintf('\nFigure closed. Continuing with %d points marked.\n', size(x, 2));
                    exit = true;
                    if size(marked_points, 2) == 0
                        error('[ERROR] No points marked. At least one point must be marked before continuing.');
                    end
                    break

                elseif button == 113  % q = zoom in
                    if current_zoom < MAX_ZOOM_IN
                        % Get current axis limits.
                        ax = axis;
                        width = ax(2) - ax(1);
                        height = ax(4) - ax(3);

                        % Calculate new dimensions.
                        new_width = width / ZOOM_FACTOR;
                        new_height = height / ZOOM_FACTOR;

                        % Set new axis limits centered on cursor position.
                        axis([x_click - new_width/2, x_click + new_width/2, ...
                            y_click - new_height/2, y_click + new_height/2] ...
                        );
                        current_zoom = current_zoom + 1;
                    end

                elseif button == 101  % e = zoom out
                    if current_zoom > -MAX_ZOOM_OUT
                        % Get current axis limits.
                        ax = axis;
                        width = ax(2) - ax(1);
                        height = ax(4) - ax(3);

                        % Calculate new dimensions.
                        new_width = width * ZOOM_FACTOR;
                        new_height = height * ZOOM_FACTOR;

                        % Set new axis limits centered on cursor position.
                        axis([x_click - new_width/2, x_click + new_width/2, ...
                            y_click - new_height/2, y_click + new_height/2] ...
                        );
                        current_zoom = current_zoom - 1;
                    end

                elseif button == 114  % r = reset zoom
                    axis([1, img_width, 1, img_height]);
                    current_zoom = 0;

                elseif button == 117  % u = undo
                    % Do nothing if points array is empty.
                    if isempty(x)
                        continue
                    end

                    % Store current zoom level and view.
                    ax = axis;
                    current_view = [ax(1), ax(2), ax(3), ax(4)];

                    % Remove the last point.
                    marked_points = marked_points(:, 1 : end - 1);

                    % Prepare to redraw without showing intermediate states.
                    hold off;
                    clf;
                    image(img);
                    hold on;

                    % Redraw all remaining points.
                    for k = 1 : size(marked_points, 2) - 1
                        plot(marked_points(1, k), marked_points(2, k), 'r+', 'linewidth', 2, 'MarkerSize', 20);
                    end

                    % Restore zoom level and update display.
                    axis(current_view);
                    % Only draw once at the end.
                    drawnow;
                    break;

                elseif button == 99  % c = continue
                    fprintf('\nContinuing with %d points marked.\n', size(marked_points, 2));
                    if isempty(marked_points)
                        fprintf('[BAD INPUT] No points marked yet. Mark at least one point before continuing.\n');
                        continue
                    end
                    num_points = size(marked_points, 2);
                    exit = true;
                    fprintf('Fixed %d points set for subsequent views.\n', size(marked_points, 2));
                    break;

                elseif button == 1  % Left click only
                    plot(x_click, y_click, 'r+', 'linewidth', 2, 'MarkerSize', 20);
                    marked_points = [marked_points cat(2, x_click, y_click, 1)'];
                    break;
                end
            end
            % Update number of points.
            for c = 1 : num_chars
                fprintf("\b")
            end
            if exit
                break;
            end
        end

    else
        % Fixed number of points for first view or subsequent views.
        while true
            % Update progress message.
            progress_msg = sprintf("%d/%d...", size(marked_points, 2), num_points);
            fprintf(progress_msg)
            num_chars = strlength(progress_msg);

            if size(marked_points, 2) == num_points
                break
            end

            % Update the history markers to show the history of the current point to be marked over all the previous
            % views.
            if history_exists
                for idx = history_start_idxs
                    set(history_squares, ...
                        'XData', history_marked_pts(1, idx + size(marked_points, 2)), ...
                        'YData', history_marked_pts(2, idx + size(marked_points, 2)), ...
                        'Color', 'b' ...
                    );
                    set(history_crosses, ...
                        'XData', history_marked_pts(1, idx + size(marked_points, 2)), ...
                        'YData', history_marked_pts(2, idx + size(marked_points, 2)), ...
                        'Color', 'b' ...
                    );
                end
            end

            % Update title.
            if j == 1
                title( ...
                    sprintf( ...
                        ['%s View - Marking Points: %d/%d (q = zoom in, e = ' ...
                        'zoom out, r = zoom reset, u = undo, c = continue)'], ...
                        view_name, size(marked_points, 2), num_points ...
                    ) ...
                );
            else
                title( ...
                    sprintf( ...
                        ['%s View - Marking Corresponding Points: %d/%d (q = zoom in, e = ' ...
                        'zoom out, r = zoom reset, u = undo, c = continue)'], ...
                        view_name, size(marked_points, 2), num_points ...
                    ) ...
                );
            end

            % Get the clicks.
            exit = false;
            while true
                [x_click, y_click, button] = ginput(1);
                if isempty(button)
                    exit = true;
                    break

                elseif button == 113  % q = zoom in
                    if current_zoom < MAX_ZOOM_IN
                        % Get current axis limits.
                        ax = axis;
                        width = ax(2) - ax(1);
                        height = ax(4) - ax(3);

                        % Calculate new dimensions.
                        new_width = width / ZOOM_FACTOR;
                        new_height = height / ZOOM_FACTOR;

                        % Set new axis limits centered on cursor position.
                        axis([x_click - new_width/2, x_click + new_width/2, ...
                            y_click - new_height/2, y_click + new_height/2] ...
                        );
                        current_zoom = current_zoom + 1;
                    end

                elseif button == 101  % e = zoom out
                    if current_zoom > -MAX_ZOOM_OUT
                        % Get current axis limits.
                        ax = axis;
                        width = ax(2) - ax(1);
                        height = ax(4) - ax(3);

                        % Calculate new dimensions.
                        new_width = width * ZOOM_FACTOR;
                        new_height = height * ZOOM_FACTOR;

                        % Set new axis limits centered on cursor position.
                        axis([x_click - new_width/2, x_click + new_width/2, ...
                            y_click - new_height/2, y_click + new_height/2] ...
                        );
                        current_zoom = current_zoom - 1;
                    end

                elseif button == 114  % r = reset zoom
                    axis([1, img_width, 1, img_height]);
                    current_zoom = 0;

                elseif button == 117  % u = undo
                    % Continue if the points array is empty.
                    if isempty(marked_points)
                        continue
                    end

                    % Store current zoom level and view.
                    ax = axis;
                    current_view = [ax(1), ax(2), ax(3), ax(4)];

                    % Remove the last point.
                    marked_points = marked_points(:, 1 : end - 1);

                    % Prepare to redraw without showing intermediate states.
                    hold off;
                    clf;
                    image(img);
                    hold on;

                    % Update the history.
                    if history_exists
                        for idx = history_start_idxs
                            history_squares = plot( ...
                                x(1, idx + size(marked_points, 2)), ...
                                x(2, idx + size(marked_points, 2)), ...
                                'Color', 'b', ...
                                'Marker', 'Square', ...
                                'MarkerSize', 20, ...
                                'linewidth', 2 ...
                            );
                            history_crosses = plot( ...
                                x(1, idx + size(marked_points, 2)), ...
                                x(2, idx + size(marked_points, 2)), ...
                                'Color', 'b', ...
                                'Marker', 'x', ...
                                'MarkerSize', 20, ...
                                'linewidth', 2 ...
                            );
                        end
                    end

                    % Redraw all remaining points.
                    for k = 1 : size(marked_points, 2)
                        plot(marked_points(1, k), marked_points(2, k), 'r+', 'linewidth', 2, 'MarkerSize', 20);
                    end

                    % Restore zoom level and update display.
                    axis(current_view);

                    % Only draw once at the end.
                    drawnow;
                    break

                elseif button == 99  % c = continue
                    fprintf('\nContinuing with %d points marked.\n', size(marked_points, 2));
                    exit = true;
                    if ~isempty(marked_points)
                        % Only update num_points in the first view.
                        if j == 1
                            num_points = size(marked_points, 2);
                            fprintf('Fixed %d points set for subsequent views.\n', num_points);
                        end
                    else
                        fprintf('[BAD INPUT] No points marked yet. Mark at least one point before continuing.\n');
                        continue
                    end
                    break

                elseif button == 1  % Left click only
                    plot(x_click, y_click, 'r+', 'linewidth', 2, 'MarkerSize', 20);
                    marked_points = [marked_points cat(2, x_click, y_click, 1)'];
                    break
                end
            end

            % Update command window.
            for c = 1 : num_chars
                fprintf("\b")
            end

            if exit
                break
            end
        end
        hold off
        pause(1);
    end

    % Append marked points to x array.
    x = [x marked_points];
    points_per_view(j) = size(marked_points, 2);

    % All points are done, delete the helper history points.
    if history_exists
        delete(history_squares)
        delete(history_crosses)
    end

    % Update history.
    history_marked_pts = x;

    % Reset zoom.
    axis; width = img_width; height = img_height;
    axis([1, width, 1, height]);
    current_zoom = 0;
end

% After all views are done, trim excess points if needed.
min_points = min(points_per_view);
if min_points < num_points
    if min_points == 0
        % If any view has 0 points, we need to clear all points.
        fprintf('\nOne or more views have 0 points. Clearing all points.\n');
        x = [];
        num_points = 0;
    else
        fprintf('\nTrimming excess points to match minimum points per view (%d).\n', min_points);
        % Reshape x to separate points by view.
        x_by_view = reshape(x, 3, min_points, []);
        % Take only the minimum number of points from each view.
        x = reshape(x_by_view(:, 1:min_points, :), 3, []);
        num_points = min_points;
    end
end

% Save to disk and cleanup.
[marks_file, marks_dir] = uiputfile( ...
    '*.mat', ...
    'Choose path to save the marked points to (cancel = use default location)', ...
    [default.MARKED_POINTS_BASE default.BCT_EXT] ...
);
if ~marks_file
    marks_filepath = fullfile(default.RECONSTRUCTION_DIR, [default.MARKED_POINTS_BASE default.BCT_EXT]);
else
    marks_filepath = fullfile(marks_dir, marks_file);
end

save(marks_filepath, 'num_points', 'x')
steps = {};
if use_undistorted_imgs
    steps{end + 1} = sprintf('NEXT STEPS:\n\tOPTIONAL: Undistort Marked Points\n\t\t- Run "undistort_marked_points.m" to undistort the marked points per-view if you plan to reconstruct points in the undistorted image.');
end
steps{end + 1} = sprintf('\t3D World Point Estimation and Reconstruction\n\t\t- Run "reconstruct_marked_pts_bct.m" to reconstruct the marked points.');

fprintf('\nAll done. Results: %s\n\n', abspath(marks_filepath));
for i = 1:length(steps)
    fprintf('%s\n\n', steps{i});
end
