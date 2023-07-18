% Result figures are saved in the formats:
% 
% {Image}_{OriginalViewName}_{ReferenceViewName}-epilines_in_original_view.png
% {Image}_{OriginalViewName}_{ReferenceViewName}-epilines_in_reflected_view.png
% {Image}_{OriginalViewName}_{ReferenceViewName}-fun_and_plds.mat
% 
% org means original, and ref means reference. These definitions are such
% that l' = Fx describes an epipolar line l' in the reference image for
% pixels x in the original image, and l = F'x' describes the epipolar line l
% in the original image corresponding to pixels x' in the reference image.
% Notice that F' = transpose(F).
%
% TODO: Potentially upgrade color cycler to select colors sampled from 
% linearly spaced colormap. Compute fundamental matrix before marking pts 
% and show epipolar lines while marking points (for 3rd view, 2 epipolar 
% lines will also intersect at a point, that point will be the pixel 
% location for that point in the 3rd view.

% IDEA DUMP: b = nchoosek(view_labels)
% find(any(b(:,1)==2,1))  % gives the indices where view label 2 is the
% original view and find(any(b(:,2)==2,1)) gives the ones where view label
% 2 is the reference view. Can be useful when plotting history's epilines.

%% PRELIMINARY LOADING STUFF %%
default = load('defaults.mat');

fprintf('Locating the image to mark points and plot epilines on...')
% Load in the image. Since we are dealing with mirrors, we can load in
% the same image multiple times to simulate multiple views, and so just
% need to select one image.
img_filter = cellfun(@(extension) ['*' extension], default.SUPPORTED_IMG_EXTS, 'UniformOutput', false)';
[img_file, img_dir] = uigetfile( ...
    img_filter, ...
    'Locate the image (containing mirrors) to mark points and plot epipolar lines on' ...
);

if ~img_file
    error('Operation canceled by user.')
end

img_filepath = fullfile(img_dir, img_file);
[~, img_base, img_extension] = fileparts(img_filepath);

fprintf('done.\n')

% Preliminary read to get size of images.
[img_height, img_width, ~] = size(imread(img_filepath));  % used in plotting epilines

% Load in the merged BCT calibration parameters corresponding to the image.

fprintf('Locating the merged BCT calibration file...')

[merged_calib_file, merged_calib_dir] = uigetfile( ...
    ['*' default.BCT_EXT], ...
    'Locate the merged BCT calibration parameters file (cancel = use default location)' ...
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

% Load in the merged poses and images.
view_params = load(merged_calib_filepath);

view_labels = view_params.view_labels;
view_names = default.VIEW_NAMES_LONG(view_labels);

num_views = numel(view_labels);

% Get all possible view pairs. This can get a little confusing.
% view_label_pairs = The pairs of view labels, so these preserve the view's
% label or identity. E.g., we have 4 views, so total_view_labels = 
% [1 2 3 4], but let's say we sample a subset [1 3 4], then 
% view_label_pairs = [1-3, 1-4, 3-4]. Notice how there's a missing 2 
% in-between. Nightmare for array indexing as we need to have nan or zero
% elements/slices for missing view labels, but it is necessary to preserve 
% accurate labeling. We also save calib params with this view identity 
% preserved, so it's necessary to get the right params for the respective 
% view as well.

% view_num_pairs = This disregards view labels. Essentially, it always
% takes the NUMBER of views, NOT the LABEL of views as its index reference.
% In the same example, total_view_labels = [1 2 3 4], and we sample subset 
% of view_labels = [1 3 4], then view_nums = [1 2 3], and view_num_pairs 
% = [1-2, 1-3, 2-3]. Thus, it only considers the view number and not the
% actual label. Allows more efficient array indexing, but can't be used to
% accurately label views or extract the right calib parameters.

% In both cases, num_pairs is the same.

view_label_pairs = nchoosek(view_labels, 2);
num_pairs = size(view_label_pairs, 1);

fprintf('Created total of %d view pair(s) based on the merged calibration file:\n\t', num_pairs);

view_num_pairs = zeros(num_pairs, 2);
for i = 1 : num_pairs

    view_label_pair = view_label_pairs(i, :);

    % Get relative view numbers as well. Let view labels = [1 3 4 6], view
    % nums = [1 2 3 4] (since 4 views), view label pair = [3 6] => view num
    % pair = [2 4] is relative view num pair for this label pair.
    
    % Slower
    % [~, view_num_pair, ~] = intersect(view_labels, view_label_pair);  
    
    % Faster
    view_num_pair = arrayfun(@(label) find(view_labels == label), view_label_pair);
    view_num_pairs(i, :) = view_num_pair;
    
    if i < num_pairs
        fprintf('%s --> %s\n\t', view_names{view_num_pair});
    else
        fprintf('%s --> %s\n\n', view_names{view_num_pair});
    end

end

fprintf('Choosing directory to store results in...')

% Get the directory to store results, or just use default lcoation.
results_dir = uigetdir('', 'Select directory to store the results in (cancel = use default directory)');

if ~results_dir
    % Use default location. Find a subolder name that's unique in the form
    % set_{x}, where x = {1, 2, 3, ...}. Once we get a value of x such that
    % no set_{x} exists, we stop and create that folder to save our
    % results. We'll create it later, so if an error comes up, we don't
    % have an empty folder.
    results_dir = sprintf(strrep(default.EPIPOLAR_RESULTS_DIR, filesep, '\\'), 1);
    existing_set_counter = 1;

    while true
        if ~isfolder(results_dir)
            break
        else
            % Update integer counter next to common string part 'set'.
            % So from set_1 to set_2 and so on.
            existing_set_counter = existing_set_counter + 1;
            new_folder = sprintf(default.EPIPOLAR_RESULTS_FOLDER_FMT, existing_set_counter);
            results_dir = fullfile(default.EPIPOLAR_DIR, new_folder);
        end
    end
end

fprintf('done.\n')

fprintf('HELP: Only enter "y" if you have the undistorted images or video frames.\n');
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

colors = 'bgrcmy';  % color order used in plotting (cycles)

%% CORE FUNCTIONALITY %%
num_points = input('[PROMPT] Enter the no. of points to mark: ');

fprintf(['\nEntering point-marking mode...\nNOTE: Press "q" to zoom in, "e" to zoom out, and "r" to reset zoom ' ...
	'level. Zoom is around cursor!\n\n'] ...
 )

hist_marked_pts = zeros(2, num_points * num_views);
pts_all_views = zeros(3, num_points * num_views);

if use_undistorted_imgs
    imgs = cell(1, num_views);
end

% To gather the appropriate intrinsics and extrinsics for each available 
% view so that we can slice with view number rather than view label.
KK = zeros(3, 3 * num_views); R = zeros(3, 3 * num_views); T = zeros(3, num_views); 
   
for j = 1 : num_views

    k = view_labels(j);         % get the view label

    KK(:, 3*(j-1)+1 : 3*j) = view_params.(sprintf('KK_%d', k));
    R(:, 3*(j-1)+1 : 3*j) = view_params.(sprintf('Rc_%d', k));
    T(:, j) = view_params.(sprintf('Tc_%d', k));

    if use_undistorted_imgs
        img = imread(fullfile(undistorted_img_dirs{j}, img_file));
        imgs{j} = img;
    end
    
    pts_view = mark_points(img, view_names{j}, num_points, colors, hist_marked_pts);
    pts_all_views(:, num_points*(j-1)+1 : num_points*j) = pts_view;
    hist_marked_pts(:, num_points*(j-1)+1 : num_points*j) = pts_view(1:2, :);
end

fprintf('\nAll views done. Exiting point-marking mode.\n\n')
% close all

% Create folder if it does not exist.
if ~isfolder(results_dir)
    mkdir(results_dir);
end

% Arrays to store pairwise information for all view pairs.
fun_matrices = zeros(3, 3 * num_pairs);
epipoles_org_view = zeros(num_pairs, 2);
epipoles_ref_view = zeros(num_pairs, 2);

% Find the epilines for each view pair. Since F is 3x3 and pts are 3xN
% (per view pair), the result for a single view pair is 3xN where each
% column corresponds to the epiline for that pair of corresponding pts.
% Thus, we would have a size of 3 x N * num_pairs for the final
% array of epilines, such that first set of `num_points` cols corresponds
% to the epilines for the first view pair and so on. Since we want to
% plot them in both the original and reference image (i.e., l' = Fx and
% l = F'x'), we describe two arrays.
epilines_org_all_view_pairs = zeros(3, num_points * num_pairs);
epilines_ref_all_view_pairs = zeros(3, num_points * num_pairs);

fprintf('Processing %d view pair(s)...\n\n', num_pairs)

for i = 1 : num_pairs

    % Get the view labels in the pair and the names of the views.
    view_num_pair = view_num_pairs(i, :);

    org_view_num = view_num_pair(1);  % original view number
    ref_view_num = view_num_pair(2);  % reference view number

    org_view_name = view_names{org_view_num};
    ref_view_name = view_names{ref_view_num};

    fprintf('Pair %d: %s --> %s\n\tComputing fundamental matrix...', i, org_view_name, ref_view_name)

    % FUNDAMENTAL MATRIX AND EPIPOLES
    % ==================================================================

    % Pair intrinsics
    KK_org = KK(:, 3 * (org_view_num - 1) + 1 : 3 * org_view_num);
    KK_ref = KK(:, 3 * (ref_view_num - 1) + 1 : 3 * ref_view_num);

    % Pair rotations
    Rc_org = R(:, 3 * (org_view_num - 1) + 1 : 3 * org_view_num);
    Rc_ref = R(:, 3 * (ref_view_num - 1) + 1 : 3 * ref_view_num);

    % Pair translations
    Tc_org = T(:, org_view_num);
    Tc_ref = T(:, ref_view_num);

    % Calculate fundamental matrix for pair
    [F, epipole_org, epipole_ref] = calc_fun_with_abs_pose( ...
        KK_org, Rc_org, Tc_org, ...
        KK_ref, Rc_ref, Tc_ref ...
    );

    % Flatten the epipoles and non-homgenify for plotting later on
    epipole_org_view = reshape(epipole_org(1:2), [], 2);
    epipole_ref_view = reshape(epipole_ref(1:2), [], 2);

    % Append to arrays containing F and epipoles for all views.
    fun_matrices(:, 3*(i-1)+1 : 3*i) = F;
    epipoles_org_view(i, :) = epipole_org_view;
    epipoles_ref_view(i, :) = epipole_ref_view;

    % EPILINES
    % ==================================================================
    % Get the points in the original and reference view.
    pts_org_view = pts_all_views(:, num_points*(org_view_num-1)+1 : num_points*org_view_num);
    pts_ref_view = pts_all_views(:, num_points*(ref_view_num-1)+1 : num_points*ref_view_num);

    % Get the corresponding epilines in the original and reference view.
    epilines_org_view = fun_matrices(:, 3*(i-1)+1 : 3*i)' * pts_ref_view;
    epilines_ref_view = fun_matrices(:, 3*(i-1)+1 : 3*i) * pts_org_view;

    % Fill the apropriate slice in the arrays containing all view pairs' epilines.
    epilines_org_all_view_pairs(:, num_points*(i-1)+1 : num_points*i) = epilines_org_view;
    epilines_ref_all_view_pairs(:, num_points*(i-1)+1 : num_points*i) = epilines_ref_view;

    % PLOTTING + POINT LINE DISTANCES
    % ==================================================================
    fprintf('plotting epilines...')
    if use_undistorted_imgs
        img_org = imgs{org_view_num};
        img_ref = imgs{ref_view_num};
    else
        img_org = img;
        img_ref = img;
    end

    win_name_view_pair = sprintf('%s --> %s: ', org_view_name, ref_view_name);

    % Load a pair figures with the image and corresponding view names as
    % the title.
    org_fig_win_name = [win_name_view_pair sprintf('Epilines in %s View', org_view_name)];
    org_fig = figure('Name', org_fig_win_name, 'Units', 'normalized', 'Position', [0 0.2 0.4 0.8]);
    imshow(img_org); hold on;
    set(gcf, 'Color', 'w');
    set(findall(gcf,'-property','FontSize'),'FontSize', 12)

    ref_fig_win_name = [win_name_view_pair sprintf('Epilines in %s View', ref_view_name)];
    ref_fig = figure('Name', ref_fig_win_name, 'Units', 'normalized', 'Position', [0.4 0.2 0.8 0.8]);
    imshow(img_ref); hold on;
    set(gcf, 'Color', 'w');
    set(findall(gcf,'-property','FontSize'),'FontSize', 12)

    fprintf('calculating PLDs...')
    pt_line_dists_org = NaN(1, num_points);
    pt_line_dists_ref = NaN(1, num_points);

    pt_line_dists_org_norm = NaN(1, num_points);
    pt_line_dists_ref_norm = NaN(1, num_points);

    % Go point-by-point
    for p = 1 : num_points

        % Cyclic color pattern.
        color = colors(mod(p, num_points + 1));

        % Draw the epilines and corresponding points on the figures.
        draw_epilines_on_fig(org_fig, [img_height, img_width], pts_ref_view(:, p), pts_org_view(:, p), ...
            epilines_org_view(:, p), color, epipole_org_view ...
        );

        draw_epilines_on_fig(ref_fig, [img_height, img_width], pts_org_view(:, p), pts_ref_view(:, p), ...
            epilines_ref_view(:, p), color, epipole_ref_view ...
        );

        % Calculate and store point-line distances (pixels and normalized)
        pld_org = calc_point_line_distance( ...
            pts_org_view(:, p), ...
            epilines_org_view(:, p) ...
        );
        pld_ref = calc_point_line_distance( ...
            pts_ref_view(:, p), ...
            epilines_ref_view(:, p) ...
        );

        pt_line_dists_org(1, p) = pld_org;
        pt_line_dists_ref(1, p) = pld_ref;

        pt_line_dists_org_norm(1, p) = pld_org / sqrt(img_height^2 + img_width^2);
        pt_line_dists_ref_norm(1, p) = pld_ref / sqrt(img_height^2 + img_width^2);
    end

    % SAVING RESULTS
    % ==================================================================
    fprintf('saving results...')
    org_view_file = sprintf('[%s@%s_%s]-epilines_in_%s.png', ...
        img_base, org_view_name, ref_view_name, org_view_name ...
    );
    ref_view_file = sprintf('[%s@%s_%s]-epilines_in_%s.png', ...
        img_base, org_view_name, ref_view_name, ref_view_name ...
    );
    result_matfile = sprintf('[%s@%s_%s]-fun_and_plds.mat', ...
        img_base, org_view_name, ref_view_name ...
    );

    if default.FEX_USE_EXPORTFIG && default.FEX_USE_TIGHTFIG
        tightfig(org_fig)
        tightfig(ref_fig)
        export_fig(org_fig, fullfile(results_dir, org_view_file), '-native');
        export_fig(ref_fig, fullfile(results_dir, ref_view_file), '-native');

    elseif default.FEX_USE_EXPORTFIG
        export_fig(org_fig, fullfile(results_dir, org_view_file), '-native');
        export_fig(ref_fig, fullfile(results_dir, ref_view_file), '-native');

    elseif default.FEX_USE_TIGHTFIG
        tightfig(org_fig)
        tightfig(ref_fig)
        saveas(org_fig, fullfile(results_dir, org_view_file));
        saveas(ref_fig, fullfile(results_dir, ref_view_file));
   
    else
        saveas(org_fig, fullfile(results_dir, org_view_file));
        saveas(ref_fig, fullfile(results_dir, ref_view_file));
    
    end

    copyfile(img_filepath, fullfile(results_dir, img_file))
    save( ...
        fullfile(results_dir, result_matfile), ...
        'F', 'epipole_org_view', 'epipole_ref_view', 'pts_org_view', ...
        'pts_ref_view', 'epilines_org_view', 'epilines_ref_view', ...
        'pt_line_dists_org', 'pt_line_dists_ref', 'pt_line_dists_org_norm', ...
        'pt_line_dists_ref_norm', 'img_filepath'...
    )
    fprintf('done.\n\tAvg. PLD Over View Pair: %.6f (pixels) | %.6f (normalized)\n\n', ...
        mean([pt_line_dists_org pt_line_dists_ref], 'all'), ...
        mean([pt_line_dists_org_norm pt_line_dists_ref_norm], 'all') ...
    );
end

fprintf('All done. Results saved to:\n\t%s\n\n', abspath(results_dir))

%% FUNCTION SPACE %%

function pld = calc_point_line_distance(point, epiline)
x = point(1); y = point(2);
a = epiline(1); b = epiline(2); c = epiline(3);
pld = abs(a*x + b*y + c) / sqrt(a^2 + b^2);
end


function draw_epilines_on_fig(fig, img_size, source_pt, corr_pt, epiline, color, epipole)

a = epiline(1); b = epiline(2); c = epiline(3);
h = img_size(1); w = img_size(2);

x_left = 0;
x_right = w;
y_left = -(a * x_left + c) / b;
y_right = -(a * x_right + c) / b;

figure(fig);

plot(source_pt(1), source_pt(2), 'Color', color, 'Marker', '+', 'MarkerSize', 20, 'linewidth', 2);
plot(corr_pt(1), corr_pt(2), 'Color', color, 'Marker', 'x', 'MarkerSize', 20, 'linewidth', 2);
line([x_left, x_right], [y_left, y_right], 'Color', color, 'linewidth', 2);

% Custom legend
qw{1} = plot(nan, 'k+', 'MarkerSize', 10, 'linewidth', 2);
qw{2} = plot(nan, 'kx', 'MarkerSize', 10, 'linewidth', 2);
qw{3} = plot(nan, 'k-', 'linewidth', 2);

if ~isempty(epipole) && all(epipole >= [0, 0]) && all(epipole < [h, w])
    qw{4} = plot(nan, 'k-o');
    plot(epipole(1), epipole(2), 'Marker', 'o', 'MarkerSize', 20, 'linewidth', 2)
    legend([qw{:}], {'marked point', 'corr. point', 'corr. epiline', 'epipole'}, 'location', 'northeast')
else
    legend([qw{:}], {'marked point', 'corr. point', 'corr. epiline'}, 'location', 'northeast')
end

end


function pts = mark_points(img, view_name, num_points, colors, hist_marked_pts)

hist_exists = true;
if nnz(hist_marked_pts) == 0
    hist_exists = false;
end

[img_height, img_width, ~] = size(img);

fprintf('\to Mark points in %s view: ', view_name)

figure('Name', sprintf('%s View', view_name), 'NumberTitle', 'off')
imshow(img);
set(gcf, 'Color', 'w');
set(findall(gcf, '-property', 'FontSize'), 'FontSize', 12)
hold on;

% Mark first point's history (i.e., if it's been marked in other views,
% plot those pixel locations on the image). At any given time, only one
% point's history is shown.

if hist_exists

    % No. of columns of history array show no. of marked pixels in all
    % views. Dividing that by no. of physical points (equivalent to no.
    % of pixel locations in one view) gives the no. of views.

    num_views = size(hist_marked_pts, 2) / num_points;

    % Get the nonzero-columns of history, corresponding to previously
    % marked points. Also, get the column index of the first marked
    % point in each view - all cols between consecutive column indices
    % belong to the view indicated by the earlier column index.
    hist_nonzero_columns = find(all(hist_marked_pts));
    view_set_start_idxs = 1 : num_points : num_points * num_views;

    % Narrow it down to get the indices of columns that indicate the
    % FIRST, NON-ZERO marked point in each view.
    hist_start_idxs = intersect(hist_nonzero_columns, view_set_start_idxs);

    % Draw crossed squares to indicate previously marked  point.
    hist_squares_handle = plot( ...
        hist_marked_pts(1, hist_start_idxs), ...
        hist_marked_pts(2, hist_start_idxs), ...
        'Color', colors(1), ...
        'Marker', 'Square', ...
        'MarkerSize', 20, ...
        'linewidth', 2 ...
    );

    hist_crosses_handle = plot( ...
        hist_marked_pts(1, hist_start_idxs), ...
        hist_marked_pts(2, hist_start_idxs), ...
        'Color', colors(1), ...
        'Marker', 'x', ...
        'MarkerSize', 20, ...
        'linewidth', 2 ...
    );
end

pts = NaN([3, num_points]);
for i = 1 : num_points
    progress_msg = sprintf("%d/%d...", i, num_points);
    fprintf(progress_msg)
    num_chars = strlength(progress_msg);

    color = colors(mod(i, num_points + 1));  % color cycler

    % Update the history markers to show the history of marked points
    % for the current (i'th) point.
    if hist_exists
        set(hist_squares_handle, ...
            'XData', hist_marked_pts(1, hist_start_idxs + i - 1), ...
            'YData', hist_marked_pts(2, hist_start_idxs + i - 1), ...
            'Color', color ...
        );
        set(hist_crosses_handle, ...
            'XData', hist_marked_pts(1, hist_start_idxs + i - 1), ...
            'YData', hist_marked_pts(2, hist_start_idxs + i - 1), ...
            'Color', color ...
        );
    end

    % Update title.
    title(sprintf('%s View - Marking Points: %d/%d (q = zoom in, e = zoom out, r = zoom reset)', ...
        view_name, i, num_points) ...
    )

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
            plot(x_click, y_click, 'Color', color, 'Marker', '+', 'MarkerSize', 20, 'linewidth', 2);
            % text(x_click - 10, y_click - 10, num2str(i), 'Color', color, 'FontSize', 18, 'FontName', 'Times');
            pts(:, i) = [x_click, y_click, 1]';
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

if hist_exists
    % All points are done, delete the helper history points.
    delete(hist_squares_handle)
    delete(hist_crosses_handle)
end

% Reset zoom.
axis; width = img_width; height = img_height;
axis([1, width, 1, height]);
zoom reset

% Update title.
title(sprintf('%s View - Marked Points: %d/%d', view_name, i, num_points))
hold off

%export_fig(['marked_points_' view_name], '-native', '-c0,NaN,NaN,NaN')

pause(1);

fprintf('done.\n')

end


function [F, e1, e2] = calc_fun_with_abs_pose(K1, R1, T1, K2, R2, T2)
%{
% Calculate fundamental matrix using the equations from Hartley and
Zisserman's Multi-View Geometry (Chapter 9), minus the world origin at
first camera assumption, which affects P1 and P1_inv (P and P+ in book).

UPDATE: We have now switched to permuting the rotation matrices when
creating the merged calibration parameters file. Swapping X and Y in the
world coordinates or swapping the first two columns of the rotation matrix
via permutation transform [0 1 0; 1 0 0; 0 0 1] as in Rc * perm_transform
is no longer necessary at this point!

OLD: The toolbox forces right-handedness, even when calibrating the mirror
view. This results in the undesired effect that the X and Y axes of the
actual world frame (in the original view) are swapped in reflected view.
The reconstruction scripts swap the world X and Y when estimating the world
coordinates in the reflected view to forcefully swap handedness. We need to
do the same permutation here when drawing epilines.

The determinant of R will be -1 for mirror views as they are left-handed.
%}

% Bunch the extrinsics.
pose1 = [R1 T1];
pose2 = [R2 T2];

% Rescale intrinsic parameters if images were rescaled. Slice to avoid
% 1 at position (i, j) = (3, 3).
% if ~isempty(scale)
%     K1(1:2, :) = K1(1:2, :) .* scale;
%     K2(1:2, :) = K2(1:2, :) .* scale;
% end

% Zisserman's multi-view geometry stuff, minus the camera center at
% first world origin assumption.
P1 = K1 * pose1;
P1_inv = pinv(P1);

P2 = K2 * pose2;
P = P2 * P1_inv;

% Grab the epipoles. We need only e2, but we find e1 as well.
% -R1'*T1 and -R2'T2 show the cameras' centers in world coordinates.
e2 = P2 * [-R1'*T1; 1];
e1 = P1 * [-R2'*T2; 1];

% Normalize the epipoles so they are valid pixel spots.
e2 = reshape(e2 / e2(3), 3, []);
e1 = reshape(e1 / e1(3), 3, []);

F = cross(repmat(e2, 1, 3), P, 1);
F = F / F(3, 3);

end
