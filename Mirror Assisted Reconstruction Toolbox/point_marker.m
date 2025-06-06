% Mark corresponding points on 2 or 3 images from a single camera with a 2-mirror setup.
% Supports both distorted and undistorted images. Assumes all images in the set are consistently distorted or undistorted.

% Load defaults
defaults = load('defaults.mat');

% Constants for zooming and panning
ZOOM_INCREMENT = 0.25;                                 % Zoom step size
MIN_ZOOM_LEVEL = -2;                                   % Maximum zoom out level
MAX_ZOOM_LEVEL = 8;                                    % Maximum zoom in level
BOUNDARY_FACTOR = 0.25;                                % Allow 25% beyond image edges for panning/zooming
MOVEMENT_THRESHOLD = 5;                                % Pixel threshold for panning updates
HISTORY_DISPLAY_MODES = {'All', 'Current', 'Last 3'};  % Display modes for history points
HISTORY_DISPLAY_MODE = 1;                              % Display mode selection, one of {'All', 'Current', 'Last 3'}

% Select image file
fprintf('Locating image to mark points on...')
img_filter = cellfun(@(ext) ['*' ext], defaults.SUPPORTED_IMG_EXTS, 'UniformOutput', false)';
[img_file, img_dir] = uigetfile(img_filter, 'Select image to mark points');
if ~img_file, error('Operation canceled by user.'); end
fprintf('done.\n');

img_filepath = fullfile(img_dir, img_file);
[~, ~, img_ext] = fileparts(img_filepath);
img = imread(img_filepath);
[img_height, img_width, ~] = size(img);

% Define explorable canvas bounds
x_bounds = [-img_width * BOUNDARY_FACTOR, img_width * (1 + BOUNDARY_FACTOR)];
y_bounds = [-img_height * BOUNDARY_FACTOR, img_height * (1 + BOUNDARY_FACTOR)];

% Load merged BCT calibration file
fprintf('Locating merged BCT calibration file...')
[calib_file, calib_dir] = uigetfile(['*' defaults.BCT_EXT], 'Select merged BCT calibration file');
if ~calib_file
    calib_filepath = defaults.BCT_MERGED_CALIB_PATH;
    if ~isfile(calib_filepath)
        error(['Merged BCT calibration file not found at default location:\n\t%s\n' ...
               'Solutions:\n\t(1) Locate the file via UI.\n\t(2) Run "calib_process_results.m" first.'], ...
               calib_filepath);
    end
else
    calib_filepath = fullfile(calib_dir, calib_file);
end
fprintf('done.\n\n');

% Load view parameters
view_params = load(calib_filepath);
view_labels = view_params.view_labels;
num_views = numel(view_labels);

% Store camera parameters
cam_params = struct('dist_coefs', {}, 'intrinsics', {});
for i = 1:num_views
    suffix = view_labels(i);
    cam_params(i).dist_coefs = view_params.(['kc_' num2str(suffix)]);
    cam_params(i).intrinsics = view_params.(['KK_' num2str(suffix)]);
end

% Get number of points to mark
num_points = get_num_points();

% Prompt for undistorted images
use_undistorted = ask_use_undistorted();

% Setup undistorted image directories
undistorted_dirs = {};
if use_undistorted
    undistorted_dirs = fullfile(img_dir, defaults.UNDISTORTED_IMG_FOLDERS(view_labels));
    validate_undistorted_dirs(undistorted_dirs, img_ext);
end

% Main point marking loop
fprintf('Entering point-marking mode...\nNOTE: Scroll to zoom, right-click to pan, "u" to undo, "c" to continue, "r" to reset zoom, "h" to toggle history display.\n\n');
x_all_views = [];
history_data = [];
fig_cleanup = gobjects(1);
points_per_view = zeros(1, num_views);

for view_idx = 1 : num_views
    view_name = defaults.VIEW_NAMES_LONG{view_labels(view_idx)};
    fprintf('\t%s View - Marked Points: ', view_name);

    % Load image
    current_img = load_view_image(use_undistorted, undistorted_dirs, view_idx, img_filepath, img_file);
    [curr_height, curr_width, ~] = size(current_img);
    validate_image_dimensions(view_name, curr_width, curr_height, img_width, img_height);

    % Setup figure
    fig = setup_figure(view_name);
    ax = axes('Parent', fig);
    imshow(current_img, 'Parent', ax); hold(ax, 'on');

    % Store appdata
    init_appdata( ...
        fig, img_width, img_height, x_bounds, y_bounds, num_points, view_name, HISTORY_DISPLAY_MODE, HISTORY_DISPLAY_MODES, ...
        ZOOM_INCREMENT, MIN_ZOOM_LEVEL, MAX_ZOOM_LEVEL, MOVEMENT_THRESHOLD ...
    );
    setappdata(fig, 'current_view_idx', view_idx);

    % Display history points
    history_handles = display_history_points(fig, ax, history_data, use_undistorted, cam_params, view_idx, num_points);

    % Mark points
    mark_points(fig, ax, view_name, num_points, view_idx);
    points_per_view(view_idx) = getappdata(fig, 'marked_points_in_current_view_count');

    % Save points and cleanup
    points = getappdata(fig, 'x_current_view_data');
    x_all_views = [x_all_views, points];
    history_data = x_all_views;  % Update history data with all points
    fig_cleanup = fig;
    num_points = getappdata(fig, 'session_target_num_points');

    % Clean up history markers
    if getappdata(fig, 'history_exists_this_view') && ~isempty(history_handles) && all(ishandle(history_handles))
        delete(history_handles);
    end

    % Finalize view
    finalize_view(fig, ax, view_name, points, num_points, curr_width, curr_height);
end

% After all views, trim to minimum number of points across all views:
min_points = min(points_per_view);
if min_points == 0
    % Find views with points and keep only those
    valid_views = points_per_view > 0;
    if ~any(valid_views)
        fprintf('\n[ERROR] No views have any points. Clearing all points.\n');
        x_all_views = [];
        num_points = 0;
    else
        fprintf('\n[WARNING] Some views have 0 points. Keeping only views with marked points.\n');
        % Reshape to separate views
        x_all_views = reshape(x_all_views, 3, num_points, []);
        % Keep only valid views
        x_all_views = x_all_views(:,:,valid_views);
        % Reshape back to original format
        x_all_views = reshape(x_all_views, 3, []);
        % Update number of views
        num_views = sum(valid_views);
        fprintf('[INFO] Keeping %d views with marked points.\n', num_views);
    end
else
    fprintf('\n[INFO] Trimming all views to %d points.\n', min_points);
    x_all_views = reshape(x_all_views, 3, []);
    x_all_views = reshape(x_all_views(:,1:min_points*num_views), 3, min_points*num_views);
    num_points = min_points;
end

% Save results
[marks_file, marks_dir] = uiputfile('*.mat', 'Save marked points', fullfile(pwd, [defaults.MARKED_POINTS_BASE defaults.BCT_EXT]));
marks_filepath = get_marks_filepath(marks_file, marks_dir, defaults);
x = x_all_views;
save(marks_filepath, 'num_points', 'x');

% Display next steps
display_next_steps(use_undistorted, marks_filepath);

% Clean up appdata
cleanup_appdata(fig_cleanup);

%% Helper Functions
function n = get_num_points()
    while true
        str = input('[PROMPT] Enter number of points to mark ([] = dynamic for first view): ', 's');
        if isempty(str)
            n = Inf;
            fprintf(['[INFO] Dynamic marking enabled for the first view. Mark points and press "c" to set the number ' ...
                'of points for successive views.\n'] ...
            );
            break;
        end
        n = str2double(str);
        if ~isnan(n) && n > 0 && floor(n) == n
            break;
        end
        fprintf('[BAD INPUT] Number of points must be a positive integer.\n');
    end
end

function use = ask_use_undistorted()
    fprintf(['\nHELP: Enter "y" for undistorted images or video frames.\nThis ONLY APPLIES if you have a specific ' ...
        'directory structure, where the image you selected is in the base directory, and the\nundistorted ones are ' ...
        'specifically designated folders "cam_rect" and "mir1_rect", "mir2_rect" and so on.' ...
        '\nYou can always undistort points later using "undistort_marked_points.m".\n'] ...
    );
    while true
        choice = input('[PROMPT] Use undistorted images? (y/n): ', 's');
        if strcmpi(choice, 'y')
            use = true; break;
        elseif strcmpi(choice, 'n')
            use = false; break;
        end
        fprintf('[BAD INPUT] Enter "y" or "n".\n');
    end
end

function validate_undistorted_dirs(dirs, ext)
    for i = 1:numel(dirs)
        if ~isfolder(dirs{i})
            error('Undistorted folder not found:\n\t%s\nRun "create_undistorted_imgs.m" first.', dirs{i});
        end
        listing = dir(fullfile(dirs{i}, ['*' ext]));
        if isempty(listing(~ismember({listing.name}, {'.', '..'})))
            error('No images of type %s in folder:\n\t%s', ext, dirs{i});
        end
    end
end

function img = load_view_image(use_undist, dirs, idx, orig_path, img_file)
    if use_undist
        path = fullfile(dirs{idx}, img_file);
        if ~isfile(path)
            error('Image %s not found in %s', img_file, dirs{idx});
        end
        img = imread(path);
    else
        img = imread(orig_path);
    end
end

function validate_image_dimensions(name, w, h, ref_w, ref_h)
    if h ~= ref_h || w ~= ref_w
        warning('Image dimensions for %s (%dx%d) differ from initial (%dx%d).', name, w, h, ref_w, ref_h);
    end
end

function fig = setup_figure(name)
    fig = figure('Units', 'Normalized', 'Position', [0 0.15 0.8 0.8], 'Name', ['Marking Points - ' name], ...
                 'NumberTitle', 'off', 'Color', 'w');
    set(findall(fig, '-property', 'FontSize'), 'FontSize', 12);
    zoom(fig, 'off'); pan(fig, 'off');
end

function init_appdata( ...
    fig, w, h, x_b, y_b, num_points, view_name, history_display_mode, history_display_modes, ZOOM_INCREMENT, MIN_ZOOM_LEVEL, MAX_ZOOM_LEVEL, MOVEMENT_THRESHOLD ...
)
    % Initialize appdata structure
    appdata = struct();

    % Image and view parameters
    appdata.img_width = w;
    appdata.img_height = h;
    appdata.x_min_bound = x_b(1);
    appdata.x_max_bound = x_b(2);
    appdata.y_min_bound = y_b(1);
    appdata.y_max_bound = y_b(2);

    % Zoom and pan parameters
    appdata.ZoomLevel = 0;
    appdata.IsPanning = false;
    appdata.LastMousePos = [];
    appdata.LastUpdateTime = tic;
    appdata.CumulativeDX = 0;
    appdata.CumulativeDY = 0;

    % Point marking parameters
    appdata.point_plot_handles = [];
    appdata.x_current_view_data = [];
    appdata.marked_points_in_current_view_count = 0;
    appdata.num_chars_on_console = 0;
    appdata.session_target_num_points = num_points;
    appdata.current_view_name_str = view_name;
    appdata.ContinueDynamicMarkingFlag = false;

    % History display parameters
    appdata.history_display_mode = history_display_modes{history_display_mode};
    appdata.history_display_modes = history_display_modes;
    appdata.history_enabled = true;

    % Zoom and movement parameters
    appdata.ZOOM_INCREMENT = ZOOM_INCREMENT;
    appdata.MIN_ZOOM_LEVEL = MIN_ZOOM_LEVEL;
    appdata.MAX_ZOOM_LEVEL = MAX_ZOOM_LEVEL;
    appdata.MOVEMENT_THRESHOLD = MOVEMENT_THRESHOLD;

    % Store all fields in figure's appdata
    fields = fieldnames(appdata);
    for i = 1:numel(fields)
        setappdata(fig, fields{i}, appdata.(fields{i}));
    end

    % Set up figure callbacks
    set(fig, 'WindowScrollWheelFcn', @(src, evt) handleScroll(src, evt), ...
             'WindowButtonDownFcn', @(src, evt) handleButtonDown(src, evt), ...
             'WindowButtonMotionFcn', @(src, evt) handleMouseMove(src, evt), ...
             'WindowButtonUpFcn', @(src, evt) handleButtonUp(src, evt), ...
             'WindowKeyPressFcn', @(src, evt) handleKeyPress(src, evt));
end

function handles = display_history_points(fig, ax, history, use_undist, cam_params, view_idx, num_points)
    handles = [];
    if view_idx > 1 && ~isempty(history)
        setappdata(fig, 'history_exists_this_view', true);
        data = history;
        if use_undist
            % Apply the distortion profile of the current view to the previous view marked point history to ensure the
            % history of marked points is on the right physical location in the new view.
            data = transform_history_points(data, cam_params, view_idx, num_points);
        end
        setappdata(fig, 'prepared_history_pixel_data', data);

        % Calculate indices for each point set across all previous views
        num_prev_views = view_idx - 1;
        indices = [];
        for i = 1:num_prev_views
            start_idx = 1 + (i-1)*num_points;
            end_idx = i*num_points;
            if end_idx <= size(data, 2)
                indices = [indices, start_idx:end_idx];
            end
        end
        setappdata(fig, 'history_indices_for_ith_point_set', indices);

        if ~isempty(indices)
            % Create plot with actual data
            x_data = data(1, indices);
            y_data = data(2, indices);
            h1 = plot(ax, x_data, y_data, 'b', 'Marker', 'Square', ...
                      'MarkerSize', 20, 'LineWidth', 2, 'LineStyle', 'none');
            h2 = plot(ax, x_data, y_data, 'b', 'Marker', 'x', ...
                      'MarkerSize', 20, 'LineWidth', 2, 'LineStyle', 'none');
            handles = [h1, h2];
            setappdata(fig, 'history_graphics_handles', handles);

            % Initialize history display
            count = getappdata(fig, 'marked_points_in_current_view_count');
            update_history_display(fig, ax, count);
        end
    else
        setappdata(fig, 'history_exists_this_view', false);
    end
end

function data = transform_history_points(data, cam_params, view_idx, num_points)
    for k = 1:view_idx-1
        start_idx = 1 + num_points * (k - 1);
        end_idx = num_points * k;
        if end_idx > size(data, 2), continue; end
        pts = data(1:2, start_idx:end_idx);
        dist_pts = distort_pts(pts, cam_params(k).dist_coefs, cam_params(k).intrinsics);
        undist_pts = invert_distort_pts(dist_pts, cam_params(view_idx).dist_coefs, cam_params(view_idx).intrinsics);
        data(1:2, start_idx:end_idx) = undist_pts;
    end
end

function mark_points(fig, ax, view_name, num_points, view_idx)
    if isinf(num_points) && view_idx == 1
        dynamic_marking(fig, ax, view_name);
    else
        fixed_marking(fig, ax, view_name, num_points);
    end
end

function dynamic_marking(fig, ax, view_name)
    count = 0;
    setappdata(fig, 'marked_points_in_current_view_count', count);
    history_mode = getappdata(fig, 'history_display_mode');
    update_ui(fig, ax, view_name, count, Inf, history_mode);
    while true
        setappdata(fig, 'ContinueDynamicMarkingFlag', false);
        action = waitforbuttonpress;
        if ~ishandle(fig)
            finalize_dynamic_marking(fig);
            break;
        end
        if action == 0 && strcmp(get(fig, 'SelectionType'), 'normal') && ~getappdata(fig, 'IsPanning')
            add_point(fig, ax, view_name, Inf);
            count = getappdata(fig, 'marked_points_in_current_view_count');
            history_mode = getappdata(fig, 'history_display_mode');
            update_ui(fig, ax, view_name, count, Inf, history_mode);
            update_history_display(fig, ax, count);
        end
        if getappdata(fig, 'ContinueDynamicMarkingFlag')
            if count > 0
                setappdata(fig, 'session_target_num_points', count);
                break;
            else
                fprintf('\n[INFO] No points marked. Mark at least one point.\n');
                setappdata(fig, 'ContinueDynamicMarkingFlag', false);
            end
        end
    end
end

function fixed_marking(fig, ax, view_name, target)
    count = getappdata(fig, 'marked_points_in_current_view_count');
    while count < target && ishandle(fig)
        history_mode = getappdata(fig, 'history_display_mode');
        update_ui(fig, ax, view_name, count, target, history_mode);
        if ~ishandle(fig), break; end
        action = waitforbuttonpress;
        if ~ishandle(fig), break; end
        if action == 0 && strcmp(get(fig, 'SelectionType'), 'normal') && ~getappdata(fig, 'IsPanning')
            add_point(fig, ax, view_name, target);
            count = getappdata(fig, 'marked_points_in_current_view_count');
            history_mode = getappdata(fig, 'history_display_mode');
            update_ui(fig, ax, view_name, count, target, history_mode);
            update_history_display(fig, ax, count);
        end
        if getappdata(fig, 'ContinueDynamicMarkingFlag')
            if count > 0
                break;
            else
                fprintf('\n[INFO] No points marked. Mark at least one point.\n');
                setappdata(fig, 'ContinueDynamicMarkingFlag', false);
            end
        end
    end
    finalize_fixed_marking(fig, target);
end

function add_point(fig, ax, view_name, target)
    mouse_coords = get(ax, 'CurrentPoint');
    pt_x = mouse_coords(1,1); pt_y = mouse_coords(1,2);
    ax_limits = axis(ax);
    if pt_x >= ax_limits(1) && pt_x <= ax_limits(2) && pt_y >= ax_limits(3) && pt_y <= ax_limits(4)
        % Add point to plot
        h = plot(ax, pt_x, pt_y, 'r+', 'LineWidth', 2, 'MarkerSize', 20);
        setappdata(fig, 'point_plot_handles', [getappdata(fig, 'point_plot_handles'), h]);
        % Add point to data
        setappdata(fig, 'x_current_view_data', [getappdata(fig, 'x_current_view_data'), [pt_x; pt_y; 1]]);
        % Update counter based on actual number of points
        count = size(getappdata(fig, 'x_current_view_data'), 2);
        setappdata(fig, 'marked_points_in_current_view_count', count);
        % Update UI and history
        history_mode = getappdata(fig, 'history_display_mode');
        update_ui(fig, ax, view_name, count, target, history_mode);
        update_history_display(fig, ax, count);
        drawnow;
    end
end

function update_ui(fig, ax, view_name, count, target, history_mode)
    % Update console message
    console_msg = sprintf("%d", count);
    if ~isinf(target)
        console_msg = sprintf("%d/%d...", count, target);
        if count > target
            console_msg = sprintf("%d/%d...", target, target);
        end
    end
    num_chars = getappdata(fig, 'num_chars_on_console');
    fprintf(repmat('\b', 1, num_chars));
    fprintf(console_msg);
    setappdata(fig, 'num_chars_on_console', strlength(console_msg));

    % Update title
    title_str = sprintf('%s - Dynamic: %d marked (u:undo, c:continue, r:reset zoom, h:history toggle | %s)', view_name, count);
    if ~isinf(target)
        view_idx = getappdata(fig, 'current_view_idx');
        if view_idx > 1
            title_str = sprintf('%s - Fixed: Corresponding %d/%d (u:undo, c:continue, r:reset zoom, h:history toggle | %s)', view_name, count, target, history_mode);
        else
            title_str = sprintf('%s - Fixed: Marking %d/%d (u:undo, c:continue, r:reset zoom, h:history toggle)', view_name, count, target);
        end
    end
    title(ax, title_str);
end

function finalize_dynamic_marking(fig)
    points = getappdata(fig, 'x_current_view_data');
    count = size(points, 2);
    if count > 0
        fprintf('Finalizing with %d points.\n', count);
        setappdata(fig, 'session_target_num_points', count);
    else
        if ishandle(fig), close(fig); end
        error('Figure closed with no points in dynamic mode. At least one point required.');
    end
end

function finalize_fixed_marking(fig, target)
    if ishandle(fig)
        count = getappdata(fig, 'marked_points_in_current_view_count');
        console_msg = sprintf("%d/%d marked.", count, target);
        if count < target
            console_msg = sprintf("%d/%d (aborted).", count, target);
        end
        fprintf(repmat('\b', 1, getappdata(fig, 'num_chars_on_console')));
        fprintf(console_msg);
        setappdata(fig, 'num_chars_on_console', strlength(console_msg));
    end
end

function finalize_view(fig, ax, view_name, points, target, w, h)
    if ishandle(fig)
        count = size(points, 2);
        axis(ax, [1, w, 1, h]);
        setappdata(fig, 'ZoomLevel', 0);
        title(ax, sprintf('%s - View Complete: %d/%d points marked', view_name, count, target));
        hold(ax, 'off');
        pause(1.5);
        close(fig);
    else
        count = size(points, 2);
        fprintf('Figure for %s closed.\n', view_name);
        if count < target && ~isinf(target)
            warning('View %s closed before marking %d points. Only %d collected.', view_name, target, count);
        elseif isinf(target) && count == 0
            error('First view (dynamic) closed with no points.');
        end
    end
end

function path = get_marks_filepath(file, dir, defaults)
    if ~file
        path = fullfile(defaults.RECONSTRUCTION_DIR, [defaults.MARKED_POINTS_BASE defaults.BCT_EXT]);
        if ~isfolder(defaults.RECONSTRUCTION_DIR)
            try
                mkdir(defaults.RECONSTRUCTION_DIR);
            catch e
                warning('Could not create directory %s: %s\nSaving to current directory.', ...
                        defaults.RECONSTRUCTION_DIR, e.message);
                path = fullfile(pwd, [defaults.MARKED_POINTS_BASE defaults.BCT_EXT]);
            end
        end
    else
        path = fullfile(dir, file);
    end
end

function display_next_steps(use_undist, path)
    steps = {};
    if ~use_undist
        steps{end+1} = sprintf('NEXT STEPS:\n\tREQUIRED for undistorted reconstruction:\n\t\t- Run "undistort_marked_points.m".');
    else
        steps{end+1} = sprintf('NEXT STEPS:\n\tPoints are in undistorted coordinates.');
    end
    steps{end+1} = sprintf('\t3D Reconstruction:\n\t\t- Run "reconstruct_marked_pts_bct.m".');
    fprintf('\nAll done. Results saved to: %s\n\n', path);
    cellfun(@(s) fprintf('%s\n\n', s), steps);
end

function cleanup_appdata(fig)
    % Clean up all appdata fields from the figure.
    if ishandle(fig)
        fields = fieldnames(getappdata(fig));
        for i = 1:numel(fields)
            rmappdata(fig, fields{i});
        end
    end
end

%% Callback Functions
function handleButtonDown(fig, ~)
    ax = gca(fig);
    if getappdata(fig, 'IsPanning'), return; end
    if strcmp(get(fig, 'SelectionType'), 'alt')
        pos = get(ax, 'CurrentPoint');
        lims = axis(ax);
        if pos(1,1) >= lims(1) && pos(1,1) <= lims(2) && pos(1,2) >= lims(3) && pos(1,2) <= lims(4)
            setappdata(fig, 'IsPanning', true);
            setappdata(fig, 'LastMousePos', pos(1,1:2));
            setappdata(fig, 'LastUpdateTime', tic);
            setappdata(fig, 'CumulativeDX', 0);
            setappdata(fig, 'CumulativeDY', 0);
            set(fig, 'WindowScrollWheelFcn', '');
        end
    end
end

function handleMouseMove(fig, ~)
    if ~getappdata(fig, 'IsPanning') || toc(getappdata(fig, 'LastUpdateTime')) < 0.03, return; end
    ax = gca(fig);
    pos = get(ax, 'CurrentPoint');
    last_pos = getappdata(fig, 'LastMousePos');
    if isempty(last_pos), return; end

    dx = pos(1,1) - last_pos(1);
    dy = pos(1,2) - last_pos(2);
    acc_dx = getappdata(fig, 'CumulativeDX') + dx;
    acc_dy = getappdata(fig, 'CumulativeDY') + dy;
    setappdata(fig, 'CumulativeDX', acc_dx);
    setappdata(fig, 'CumulativeDY', acc_dy);

    lims = axis(ax);
    ax_pos = getpixelposition(ax);
    data_span = [lims(2) - lims(1), lims(4) - lims(3)];
    pixels_per_unit = [ax_pos(3) / data_span(1), ax_pos(4) / data_span(2)];
    moved_pixels = abs([acc_dx * pixels_per_unit(1), acc_dy * pixels_per_unit(2)]);

    if max(moved_pixels) < getappdata(fig, 'MOVEMENT_THRESHOLD')
        setappdata(fig, 'LastMousePos', pos(1,1:2));
        return;
    end

    w = lims(2) - lims(1);
    h = lims(4) - lims(3);
    new_lims = lims - [acc_dx, acc_dx, acc_dy, acc_dy];
    new_lims(1) = max(getappdata(fig, 'x_min_bound'), min(new_lims(1), getappdata(fig, 'x_max_bound') - w));
    new_lims(2) = new_lims(1) + w;
    new_lims(3) = max(getappdata(fig, 'y_min_bound'), min(new_lims(3), getappdata(fig, 'y_max_bound') - h));
    new_lims(4) = new_lims(3) + h;

    if new_lims(2) > new_lims(1) + eps && new_lims(4) > new_lims(3) + eps
        axis(ax, new_lims);
        drawnow('limitrate');
        setappdata(fig, 'CumulativeDX', 0);
        setappdata(fig, 'CumulativeDY', 0);
        current_point = get(ax, 'CurrentPoint');
        setappdata(fig, 'LastMousePos', current_point(1,1:2));
        setappdata(fig, 'LastUpdateTime', tic);
    end
end

function handleButtonUp(fig, ~)
    if getappdata(fig, 'IsPanning')
        setappdata(fig, 'IsPanning', false);
        set(fig, 'WindowScrollWheelFcn', @(src, evt) handleScroll(src, evt));
    end
end

function handleScroll(fig, evt)
    if toc(getappdata(fig, 'LastUpdateTime')) < 0.03 && evt.VerticalScrollCount ~= 0, return; end
    ax = gca(fig);
    pos = get(ax, 'CurrentPoint');
    lims = axis(ax);
    if pos(1,1) < lims(1) || pos(1,1) > lims(2) || pos(1,2) < lims(3) || pos(1,2) > lims(4), return; end

    zoom = getappdata(fig, 'ZoomLevel');
    new_zoom = zoom + (evt.VerticalScrollCount < 0) - (evt.VerticalScrollCount > 0);
    new_zoom = max(getappdata(fig, 'MIN_ZOOM_LEVEL'), min(new_zoom, getappdata(fig, 'MAX_ZOOM_LEVEL')));
    if new_zoom == zoom, return; end
    setappdata(fig, 'ZoomLevel', new_zoom);

    zf = (1 - getappdata(fig, 'ZOOM_INCREMENT'))^new_zoom;
    if new_zoom < 0, zf = (1 + getappdata(fig, 'ZOOM_INCREMENT'))^abs(new_zoom); end

    w = getappdata(fig, 'img_width') * zf;
    h = getappdata(fig, 'img_height') * zf;
    xp = (pos(1,1) - lims(1)) / (lims(2) - lims(1));
    yp = (pos(1,2) - lims(3)) / (lims(4) - lims(3));

    new_lims = [pos(1,1) - w * xp, pos(1,1) + w * (1 - xp), pos(1,2) - h * yp, pos(1,2) + h * (1 - yp)];
    new_lims(1) = max(getappdata(fig, 'x_min_bound'), min(new_lims(1), getappdata(fig, 'x_max_bound') - w));
    new_lims(2) = new_lims(1) + w;
    new_lims(3) = max(getappdata(fig, 'y_min_bound'), min(new_lims(3), getappdata(fig, 'y_max_bound') - h));
    new_lims(4) = new_lims(3) + h;

    if new_lims(2) > new_lims(1) + eps && new_lims(4) > new_lims(3) + eps
        axis(ax, new_lims);
        drawnow('limitrate');
        setappdata(fig, 'LastUpdateTime', tic);
    else
        setappdata(fig, 'ZoomLevel', zoom);
    end
end

function handleKeyPress(fig, evt)
    ax = gca(fig);
    switch evt.Key
        case 'h'
            % Toggle history display mode
            if getappdata(fig, 'history_exists_this_view')
                mode = getappdata(fig, 'history_display_mode');
                modes = getappdata(fig, 'history_display_modes');
                current_idx = find(strcmp(modes, mode));
                next_idx = mod(current_idx, length(modes)) + 1;
                setappdata(fig, 'history_display_mode', modes{next_idx});
                count = getappdata(fig, 'marked_points_in_current_view_count');
                update_history_display(fig, ax, count);
                % fprintf('\n[INFO] History display mode changed to: %s\n', modes{next_idx});
            else
                % fprintf('\n[INFO] No history available for this view.\n');
            end
        case 'u'
            pts = getappdata(fig, 'x_current_view_data');
            handles = getappdata(fig, 'point_plot_handles');
            if ~isempty(pts) && ~isempty(handles)
                % Remove the last point
                delete(handles(end));
                setappdata(fig, 'point_plot_handles', handles(1:end-1));
                setappdata(fig, 'x_current_view_data', pts(:, 1:end-1));

                % After removing, get the updated count
                updated_pts = getappdata(fig, 'x_current_view_data');
                count = size(updated_pts, 2);
                setappdata(fig, 'marked_points_in_current_view_count', count);

                % Update UI and history
                history_mode = getappdata(fig, 'history_display_mode');
                update_ui(fig, ax, getappdata(fig, 'current_view_name_str'), count, getappdata(fig, 'session_target_num_points'), history_mode);
                update_history_display(fig, ax, count);
            end
        case 'c'
            count = getappdata(fig, 'marked_points_in_current_view_count');
            if count > 0
                setappdata(fig, 'ContinueDynamicMarkingFlag', true);
                if isinf(getappdata(fig, 'session_target_num_points'))
                    setappdata(fig, 'session_target_num_points', count);
                    fprintf(repmat('\b', 1, getappdata(fig, 'num_chars_on_console')));
                    fprintf('\nDynamic marking complete. %d points set as target.\n', count);
                    setappdata(fig, 'num_chars_on_console', 0);
                else
                    fprintf('\n[INFO] Continuing with %d points in this view.\n', count);
                end
            else
                fprintf('\n[BAD INPUT] Mark at least one point before pressing "c".\n');
            end
        case 'r'
            img = findobj(ax, 'Type', 'image');
            if ~isempty(img)
                [h, w, ~] = size(img(1).CData);
                axis(ax, [1, w, 1, h]);
            else
                axis(ax, [1, getappdata(fig, 'img_width'), 1, getappdata(fig, 'img_height')]);
            end
            setappdata(fig, 'ZoomLevel', 0);
            drawnow;
    end
end

function update_history_display(fig, ax, count)
    history_handles = getappdata(fig, 'history_graphics_handles');
    if ~isempty(history_handles) && all(ishandle(history_handles))
        data = getappdata(fig, 'prepared_history_pixel_data');
        view_idx = getappdata(fig, 'current_view_idx');
        num_points = getappdata(fig, 'session_target_num_points');
        num_prev_views = view_idx - 1;
        mode = getappdata(fig, 'history_display_mode');

        % fprintf('\n[DEBUG] History Display:\n');
        % fprintf('  Mode: %s\n', mode);
        % fprintf('  Current count: %d\n', count);
        % fprintf('  Number of previous views: %d\n', num_prev_views);
        % fprintf('  Total points in history: %d\n', size(data, 2));

        visible_indices = [];
        switch mode
            case 'All'
                % Show all points from previous views up to current count
                for i = 1 : num_prev_views
                    start_idx = 1 + (i-1)*num_points;
                    end_idx = min(i*num_points, start_idx + count - 1);
                    if end_idx <= size(data, 2)
                        visible_indices = [visible_indices, start_idx:end_idx];
                    end
                end
            case 'Current'
                % Show only the current point's history across all views
                idx = count + 1; % The point currently being marked
                for i = 1:num_prev_views
                    pt_idx = idx + (i-1)*num_points;
                    if pt_idx <= size(data, 2)
                        visible_indices = [visible_indices, pt_idx];
                    end
                end
            case 'Last 3'
                % Show last 3 points' history across all views
                idx = count + 1; % The point currently being marked
                for i = 1:num_prev_views
                    for offset = 0:2
                        pt_idx = idx - offset + (i-1)*num_points;
                        if pt_idx >= 1 && pt_idx <= size(data, 2)
                            visible_indices = [visible_indices, pt_idx];
                        end
                    end
                end
        end

        % fprintf('  Selected indices: %s\n', mat2str(visible_indices));

        % Update plot with selected indices
        if ~isempty(visible_indices)
            x_data = data(1, visible_indices);
            y_data = data(2, visible_indices);
            set(history_handles(1), 'XData', x_data, 'YData', y_data);
            set(history_handles(2), 'XData', x_data, 'YData', y_data);
        else
            % Hide the history markers if no indices are selected
            set(history_handles(1), 'XData', [], 'YData', []);
            set(history_handles(2), 'XData', [], 'YData', []);
        end

        % Update title to show current mode
        title_str = get(get(ax, 'Title'), 'String');
        mode_str = sprintf(' [History: %s]', mode);
        if ~contains(title_str, '[History:')
            title_str = [title_str, mode_str];
        else
            title_str = regexprep(title_str, '\[History:.*\]', mode_str);
        end
        title(ax, title_str);

        % Force redraw
        drawnow;
    end
end