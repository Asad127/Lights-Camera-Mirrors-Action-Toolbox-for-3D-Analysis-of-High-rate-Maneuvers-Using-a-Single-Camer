%% SETUP %%
%{
Mark the corresponding points on a set of at least 2 or at most 3 images
corresponding to a single camera and 2-mirror setup.
%}

default = load('defaults.mat');

fprintf('Locating (non-undistorted) image to mark points on...')
img_filter = cellfun(@(extension) ['*' extension], default.SUPPORTED_IMG_EXTS, 'UniformOutput', false)';
[img_file, img_dir] = uigetfile( ...
    img_filter, ...
    'Locate the non-undistorted image containing the object you want to reconstruct' ...
);
if ~img_file
    error('Operation canceled by user.')
end
img_filepath = fullfile(img_dir, img_file);
[~, img_base, img_extension] = fileparts(img_filepath);
[img_height, img_width, ~] = size(imread(img_filepath));

fprintf('done.\nLocating merged BCT calibration file...')
[merged_calib_file, merged_calib_dir] = uigetfile( ...
    ['*' default.BCT_EXT], ...
    'Select the merged BCT calibration parameters file (cancel = use default location)' ...
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

while true
    num_points = input("[PROMPT] Enter the no. of points to mark: ");
    if num_points <= 0
        fprintf('[BAD INPUT] No. of marked points must be a positive integer > 0.')
        continue
    end
    break
end

fprintf('\nHELP: Only enter "y" if you have the undistorted images or video frames.\n');
while true
	choice = input('[PROMPT] Use undistorted images for point marking? (y/n): ', 's');
    
    if ~ismember(choice, {'y', 'n'})
		fprintf('[BAD INPUT] Only "y" (yes) and "n" (no) are accepted inputs. Please try again.\n')
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
    
            error(['An undistorted frame folder was not found in the expected location:' ...
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

fprintf('NOTE: Press "q" to zoom in, "e" to zoom out, and "r" to reset zoom level. Zooms are around cursor!\n')
fprintf('\nEntering point-marking mode...\n\n')

% x contains all the pixels over all the views. It is pretty much its own
% history.
x = [];
view_names = default.VIEW_NAMES_LONG(view_labels);

for j = 1 : num_views

    hist_exists = true;
    if isempty(x)
        hist_exists = false;
    end

    view_name = view_names{j};
    fprintf("\to %s View - Marking Points: ", view_names{j})

    % Load image and click points to estimate world coordinates of.
    if use_undistorted_imgs
	    img = imread(fullfile(undistorted_img_dirs{j}, img_file));
    end

    figure('Units', 'Normalized', 'Position', [0 0.15 0.8 0.8]);

    imshow(img); hold on;
    % xlabel('x (pixel)'); ylabel('y (pixel)');

    set(gcf, 'Color', 'w');
    set(findall(gcf, '-property', 'FontSize'), 'FontSize', 12);

    % Mark first point's history (i.e., if it's been marked in
    % other views, plot those pixel locations on the image). At
    % any given time, only one point's history is shown.
    if hist_exists
        
        % no. of columns of x shown the number of marked pixels, such that
        % every distinct set of num_points pixels is the pixel locations in
        % a specific view.
        hist_start_idxs = 1 : num_points : size(x, 2);

        % Draw crossed squares to indicate previously marked
        % i'th point in the other view.

        hist_squares = plot( ...
            x(1, hist_start_idxs), ...
            x(2, hist_start_idxs), ...
            'Color', 'b', ...
            'Marker', 'Square', ...
            'MarkerSize', 20, ...
            'linewidth', 2 ...
        );

        hist_crosses = plot( ...
            x(1, hist_start_idxs), ...
            x(2, hist_start_idxs), ...
            'Color', 'b', ...
            'Marker', 'x', ...
            'MarkerSize', 20, ...
            'linewidth', 2 ...
        );

    end

    for i = 1 : num_points
        progress_msg = sprintf("%d/%d...", i, num_points);
        fprintf(progress_msg)
        num_chars = strlength(progress_msg);

        % Update the history markers to show the history
        % of marked points for the current (i'th) point.
        if hist_exists
            set(hist_squares, ...
                'XData', hist_marked_pts(1, hist_start_idxs + i - 1), ...
                'YData', hist_marked_pts(2, hist_start_idxs + i - 1), ...
                'Color', 'b' ...
            );
            set(hist_crosses, ...
                'XData', hist_marked_pts(1, hist_start_idxs + i - 1), ...
                'YData', hist_marked_pts(2, hist_start_idxs + i - 1), ...
                'Color', 'b' ...
            );
        end

        % Update title.
        if j == 1
            title(sprintf('%s View - Marking Points: %d/%d (q = zoom in, e = zoom out, r = zoom reset)', ...
                view_name, i, num_points) ...
            )
        else
            title(sprintf(['%s View - Marking Corresponding Points: %d/%d (q = zoom in, e = zoom out, r ' ...
                '= zoom reset)'], view_name, i, num_points) ...
            )
        end

        % Get the clicks.
        while true
            [x_click, y_click, button] = ginput(1);
            if isempty(button)
                break
            elseif button == 113  % q = zoom in
                % The axis manipulations focus in around cursor location.
                ax = axis; width = ax(2) - ax(1); height = ax(4) - ax(3);
                axis([x_click - width / 2, x_click + width / 2, ...
                    y_click - height / 2, y_click + height / 2] ...
                );
                zoom(2)
            elseif button == 101  % e = zoom out
                ax = axis; width = ax(2) - ax(1); height = ax(4) - ax(3);
                axis([x_click - width / 2, x_click + width / 2, ...
                    y_click - height / 2, y_click + height / 2] ...
                );
                zoom(1/2)
            elseif button == 114  % r = reset zoom
                axis; width = img_width; height = img_height;
                axis([1, width, 1, height]);
                zoom reset
            else
                plot(x_click, y_click, 'r+', 'linewidth', 2, 'MarkerSize', 20);
                x = [x cat(2, x_click, y_click, 1)'];
                break
            end
        end

        % Update command window.
        if i < num_points
            for c = 1 : num_chars
                fprintf("\b")
            end
        end
    end

    % All points are done, delete the helper history points.
    if hist_exists
        delete(hist_squares)
        delete(hist_crosses)
    end

    % Update history.
    hist_marked_pts = x;

    % Reset zoom.
    axis; width = img_width; height = img_height;
    axis([1, width, 1, height]);
    zoom reset

    % Update title.
    title(sprintf('%s View - Marked Points: %d/%d', view_name, i, num_points))
    fprintf('done.\n')
    hold off

    %export_fig(['marked_points_' view_name], '-native', '-c0,NaN,NaN,NaN')

    pause(1);
end

% Save to disk and cleanup.
[marks_file, marks_dir] = uiputfile( ...
    '*.mat', ...
    'Choose path to save the marked points to (cancel = use default location)', ...
    [default.MARKED_POINTS_BASE default.BCT_EXT] ...
);
if ~marks_file
    marks_filepath = fullfile(default.RECONSTRUCTION_DIR, default.MARKED_POINTS_BASE);
else
    marks_filepath = fullfile(marks_dir, marks_file);
end

save(marks_filepath, 'num_points', 'x')
% close all
fprintf(['\nAll done.\n\nNEXT STEPS: 3D World Point Estimation and Reconstruction\n\n' ...
    '- Run "reconstruct_marked_pts_bct.m" to reconstruct the marked points.\n\n'] ...
)