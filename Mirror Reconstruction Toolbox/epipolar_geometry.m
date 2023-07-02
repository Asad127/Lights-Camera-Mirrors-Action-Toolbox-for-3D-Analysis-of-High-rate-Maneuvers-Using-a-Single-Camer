%{
Result figures are saved in the formats:

{Image}_{OriginalViewName}_{ReferenceViewName}-epilines_in_original_view.png
{Image}_{OriginalViewName}_{ReferenceViewName}-epilines_in_reflected_view.png
{Image}_{OriginalViewName}_{ReferenceViewName}-fun_and_plds.mat
    
org means original, and ref means reference. These definitions are such
that l' = Fx describes an epipolar line l' in the reference image for
pixels x in the original image, and l = F'x' describes the epipolar line l 
in the original image corresponding to pixels x' in the reference image.
Notice that F' = transpose(F).
%}
%% PRELIMINARY LOADING STUFF %%
default = load('defaults.mat');

% Load in the image. % Since we are dealing with mirrors, we can load in 
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
[~, img_name, img_ext] = fileparts(img_filepath);
img = imread(img_filepath);
[img_height, img_width, ~] = size(img);  % used later in plotting epilines

% Load in the merged BCT calibration parameters corresponding to the image.
[merged_calib_file, merged_calib_dir] = uigetfile( ...
    ['*' default.BCT_EXT], ...
    'Locate the merged BCT calibration parameters file (cancel = use default location)' ...
);
if ~merged_calib_file
    merged_calib_filepath = default.BCT_MERGED_CALIB_PATH;
else
    merged_calib_filepath = fullfile(merged_calib_dir, merged_calib_file);
end

% Load in the merged poses and images.
view_params = load(merged_calib_filepath);
view_labels = view_params.view_labels;
num_views = numel(view_labels);

% Get all possible view pairs.
view_label_pairs = nchoosek(view_labels, 2);
num_view_pairs = size(view_label_pairs, 1);

% Get the directory to store results, or just use default lcoation.
results_dir = uigetdir('', 'Select directory to store the results in (cancel = use default directory)');
if ~results_dir
    results_dir = sprintf(strrep(default.EPIPOLAR_RESULTS_DIR, filesep, '\\'), 1);
    existing_set_counter = 1;
    while true
        if ~isfolder(results_dir)
            break
        else
            % Update integer counter next to commo nstring part 'set'. 
            % So from set_1 to set_2 and so on.
            existing_set_counter = existing_set_counter + 1;
            [parents, ~] = fileparts(default.EPIPOLAR_RESULTS_DIR);
            new_folder = sprintf(default.EPIPOLAR_RESULTS_FOLDER_FMT, existing_set_counter);
            results_dir = fullfile(parents, new_folder);
        end
    end
end

fprintf('Created total of %d view pair(s) based on the merged calibration file:\n\t', num_view_pairs);
for i = 1 : num_view_pairs
    view_label_pair = view_label_pairs(i, :);
    if i < num_view_pairs
        fprintf('%s --> %s\n\t', default.VIEW_NAMES_LONG{view_label_pair});
    else
        fprintf('%s --> %s\n\n', default.VIEW_NAMES_LONG{view_label_pair});
    end
end

colors = 'bgrcmy';  % color order used in plotting (cycles)

%% CORE FUNCTIONALITY %%

% Mark corresponding points. These points are stored as a homogenous 2D 
% array of size 3xN, where N is the number of marked points. For each 
% view pair, we concatenate the 3xN array across columns, so we end up 
% with a 3xN*L, where L is the largest view label. E.g., [1 3] means L = 
% 3, so we get a 3 x N*3 array. Thus each view pair is represented by a 
% 3xN slice of the array. For views not included (view 2 in our previous 
% example), the slice is filled with NaNs. This way, we ensure that the 
% view indices are always selected appropriately, even when the number 
% of views is not the same as the number of view pairs. This problem 
% does not arise in reconstruction scripts, since we don't deal with 
% combinations of view labels there.

fprintf('Entering point-marking mode...\n\t')
num_pts = input('[PROMPT] Enter the no. of points to mark: ');

hist_marked_pts = zeros(2, num_pts * num_views);
largest_view_label = max(view_labels);
pts_all_views = nan(3, num_pts * largest_view_label);  
for j = 1 : num_views
    k = view_labels(j);
    view_name = default.VIEW_NAMES_LONG{k};
    fprintf('\t>> Mark points in %s view...', lower(view_name))

    pts_view = mark_points(img, view_name, num_pts, colors, hist_marked_pts);
    pts_all_views(:, num_pts*(j-1)+1 : num_pts*j) = pts_view;
    hist_marked_pts(:, num_pts*(j-1)+1 : num_pts*j) = pts_view(1:2, :);

    fprintf('done.\n')
end
fprintf('All views done. Exiting point-marking mode.\n\n')
close all

mkdir(results_dir);

% Arrays to store pairwise information for all view pairs.
fun_matrices = zeros(3, 3 * num_view_pairs);
epipoles_org_view = zeros(num_view_pairs, 2);
epipoles_ref_view = zeros(num_view_pairs, 2);

% Find the epilines for each view pair. Since F is 3x3 and pts are 3xN 
% (per view pair), the result for a single view pair is 3xN where each 
% column corresponds to the epiline for that pair of corresponding pts. 
% Thus, we would have a size of 3 x N * num_view_pairs for the final 
% array of epilines, such that first set of `num_pts` cols corresponds 
% to the epilines for the first view pair and so on. Since we want to 
% plot them in both the original and reference image (i.e., l' = Fx and 
% l = F'x'), we describe two arrays.
epilines_org_all_view_pairs = zeros(3, num_pts * num_view_pairs);
epilines_ref_all_view_pairs = zeros(3, num_pts * num_view_pairs);

fprintf(['Calculating fundamental matrix, epipoles, epilines, and point-line ' ...
    'distances for %d view pair(s)...\n'], num_view_pairs ...
)

for i = 1 : num_view_pairs
    
    % Get the view labels in the pair and the names of the views.
    view_label_pair = view_label_pairs(i, :);
    
    org_view_label = view_label_pair(1);  % original view label
    ref_view_label = view_label_pair(2);  % reference view label

    org_view_name = default.VIEW_NAMES_LONG{org_view_label};
    ref_view_name = default.VIEW_NAMES_LONG{ref_view_label};

    fprintf('Pair %d: %s --> %s\n\tComputing...', i, org_view_name, ref_view_name)
    
    % FUNDAMENTAL MATRIX AND EPIPOLES
    % ==================================================================

    % Pair intrinsics
    KK_org = view_params.(sprintf('KK_%d', org_view_label));
    KK_ref = view_params.(sprintf('KK_%d', ref_view_label));
    
    % Pair rotations
    Rc_org = view_params.(sprintf('Rc_%d', org_view_label));
    Rc_ref = view_params.(sprintf('Rc_%d', ref_view_label));
    
    % Pair translations
    Tc_org = view_params.(sprintf('Tc_%d', org_view_label));
    Tc_ref = view_params.(sprintf('Tc_%d', ref_view_label));
    
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
    pts_org_view = pts_all_views(:, num_pts*(org_view_label-1)+1 : num_pts*org_view_label);
    pts_ref_view = pts_all_views(:, num_pts*(ref_view_label-1)+1 : num_pts*ref_view_label);
    
    % Get the corresponding epilines in the original and reference view.
    epilines_org_view = fun_matrices(:, 3*(i-1)+1 : 3*i)' * pts_ref_view;
    epilines_ref_view = fun_matrices(:, 3*(i-1)+1 : 3*i) * pts_org_view;
    
    % Fill the apropriate slice in the arrays containing all view pairs' epilines.
    epilines_org_all_view_pairs(:, num_pts*(i-1)+1 : num_pts*i) = epilines_org_view;
    epilines_ref_all_view_pairs(:, num_pts*(i-1)+1 : num_pts*i) = epilines_ref_view;

    % PLOTTING + POINT LINE DISTANCES
    % ==================================================================
    win_name_view_pair = sprintf('%s --> %s: ', org_view_name, ref_view_name);

    % Load a pair figures with the image and corresponding view names as
    % the title.
    org_fig_win_name = [win_name_view_pair sprintf('Epilines in %s View', org_view_name)];
    org_fig = figure('Name', org_fig_win_name, 'Units', 'normalized', 'Position', [0 0.2 0.4 0.8]);
    imshow(img); hold on;
    set(gcf, 'Color', 'w');
    set(findall(gcf,'-property','FontSize'),'FontSize', 18)
    
    ref_fig_win_name = [win_name_view_pair sprintf('Epilines in %s View', ref_view_name)];
    ref_fig = figure('Name', ref_fig_win_name, 'Units', 'normalized', 'Position', [0.4 0.2 0.8 0.8]);
    imshow(img); hold on;
    set(gcf, 'Color', 'w');
    set(findall(gcf,'-property','FontSize'),'FontSize', 18)
    
    pt_line_dists_org = NaN(1, num_pts);
    pt_line_dists_ref = NaN(1, num_pts);

    % Go point-by-point an
    for p = 1 : num_pts
        % Cyclic color pattern.
        color = colors(mod(p, num_pts + 1));
        
        % Draw the epilines and corresponding points on the figures.
        draw_epilines_on_fig(org_fig, [img_height, img_weight], pts_ref_view(:, p), pts_org_view(:, p), ... 
            epilines_org_view(:, p), color, epipole_org_view ...
        );

        draw_epilines_on_fig(ref_fig, [img_height, img_weight], pts_org_view(:, p), pts_ref_view(:, p), ...
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
    end
    
    % SAVING RESULTS
    % ==================================================================
    org_view_file = sprintf('%s_%s_%s-epilines_in_%s.png', ...
        img_name, org_view_name, ref_view_name, org_view_name ...
    );
    ref_view_file = sprintf('%s_%s_%s-epilines_in_%s.png', ...
        img_name, org_view_name, ref_view_name, ref_view_name ...
    );
    result_matfile = sprintf('%s_%s_%s-fun_and_plds.mat', ...
        img_name, org_view_name, ref_view_name ...
    );

    % If you have export_fig from file exchange, this is better quality.
    % export_fig(org_fig, org_view_file, '-native');
    % export_fig(ref_fig, ref_view_file, '-native');

    saveas(org_fig, fullfile(results_dir, org_view_file));
    saveas(ref_fig, fullfile(results_dir, ref_view_file));
    copyfile(img_filepath, fullfile(results_dir, img_file))
    save( ...
        fullfile(results_dir, result_matfile), ...
        'F', 'epipole_org_view', 'epipole_ref_view', 'pts_org_view', ...
        'pts_ref_view', 'epilines_org_view', 'epilines_ref_view', ...
        'pt_line_dists_org', 'pt_line_dists_ref', 'img_filepath' ...
    )
    fprintf('done.\n\tAverage Point-Line Distance Over Both Views: %.6f (pixels) | %.6f (normalized)\n\n', ...
        mean([pt_line_dists_org pt_line_dists_ref], 'all'), ...
        mean([pt_line_dists_org pt_line_dists_ref], 'all') / sqrt(img_height^2 + img_width^2) ...
    );
end

fprintf('All done! You may view all the results at:\n\t%s\n', results_dir)

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


function pts = mark_points(img, view_name, num_pts, colors, hist_marked_pts)

hist_exists = true;
if nnz(hist_marked_pts) == 0
    hist_exists = false;
end

[img_height, img_width, ~] = size(img);

figure('Name', sprintf('%s View', view_name), 'NumberTitle', 'off')
imshow(img); 
hold on;
set(gcf, 'Color', 'w');
set(findall(gcf, '-property', 'FontSize'), 'FontSize', 18)

if hist_exists
    num_views = size(hist_marked_pts, 2) / num_pts;
    hist_nonzero_columns = find(all(hist_marked_pts));
    view_set_start_idxs = 1 : num_pts : num_pts * num_views;
    hist_start_idxs = [];
    for i = view_set_start_idxs
        if ~ismember(i, hist_nonzero_columns)
            continue
        end
        hist_start_idxs(end + 1) = i;
    end
    hist_views = numel(hist_start_idxs);
    fprintf('history available for %d views', hist_views)
    hist_squares = plot(hist_marked_pts(1, hist_start_idxs), hist_marked_pts(2, hist_start_idxs), 'Color', colors(1), 'Marker', 'Square', 'MarkerSize', 20, 'linewidth', 2);
    hist_crosses = plot(hist_marked_pts(1, hist_start_idxs), hist_marked_pts(2, hist_start_idxs), 'Color', colors(1), 'Marker', 'x', 'MarkerSize', 20, 'linewidth', 2);
end

pts = NaN([3, num_pts]);
for i = 1 : num_pts
    color = colors(mod(i, num_pts + 1));  % color cycler

    if hist_exists
        set(hist_squares, ...
            'XData', hist_marked_pts(1, hist_start_idxs + i - 1), ...
            'YData', hist_marked_pts(2, hist_start_idxs + i - 1), ...
            'Color', color ...
        );
        set(hist_crosses, ...
            'XData', hist_marked_pts(1, hist_start_idxs + i - 1), ...
            'YData', hist_marked_pts(2, hist_start_idxs + i - 1), ...
            'Color', color ...
        );
    end
    
    title(sprintf('%s View - Mark points: %d/%d (q = zoom in, e = zoom out, r = zoom reset)', ...
        view_name, i, num_pts) ...
    )
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
            ax = axis; width = img_width; height = img_height;
            axis([1, width, 1, height]);
            zoom reset
        else
            plot(x_click, y_click, 'Color', color, 'Marker', '+', 'MarkerSize', 20, 'linewidth', 2);
            % text(x_click - 10, y_click - 10, num2str(i), 'Color', color, 'FontSize', 18, 'FontName', 'Times');
            pts(:, i) = [x_click, y_click, 1]';
            break
        end
    end

    fprintf('%d...', i)
    if mod(i, 10) == 0
        fprintf("\n\t\t\t\t")
    end
end

pause(0.2);
%export_fig(['marked_points_' view_name], '-native', '-c0,NaN,NaN,NaN')

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