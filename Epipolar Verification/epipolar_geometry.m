% TODO: Maybe add SIFT functionality with inlier matching to automate
% feature extraction.

%{
DIRECTORY STRUCTURE
===================
Epipolar_Verification
|   epipolar_geometry.m
|
+---results
|   +---set
|   |       fun_and_plds.mat
|   |
|   \---set_1
|           epilines_in_original_view.png
|           epilines_in_reflected_view.png
|           fun_and_plds.mat
|
\---test_sets
    \---set_1 !!!(OR JUST ITS CONTENTS)!!!
        |   merged_params.mat
        |
        \---images
                1.jpg
                2.jpg
%}
%% PRELIMINARY LOADING STUFF %%
clear all
close all
clc

% Directory parents for easy inputs.
dir_test_sets = "test_sets";            % default: "test_sets"
dir_results = "results";                % default: "results"

% Test set nomenclature.
pose_file_name = "merged_params.mat";   % default: "merged_params.mat"
images_folder_name = "images";          % default: "images"

if ~(isfolder(dir_test_sets))
   error('Test set directory ("%s") does not exist.', dir_test_sets)
end

if ~(isfolder(dir_results))
    fprintf('Created directory to store results.')
    mkdir(dir_results)
end

disp('****************************************')
disp('          RELATIVE DIRECTORIES          ')
disp('****************************************')
fmt = join(["TEST IMAGES AND POSES\t%s", ...
            '\nALL THE RESULTS\t\t\t%s\n\n'], '');

fprintf(fmt, [dir_test_sets, dir_results]);

% Prompt for user input.
test_set_name = input('[PROMPT] Enter the directory containing the images folder merged_params.mat file (from calibration): ', 's');
path_test_set = join([dir_test_sets test_set_name], filesep);
path_pose = join([path_test_set pose_file_name], filesep);
path_images = join([path_test_set images_folder_name], filesep);

% Load in the merged poses and images.
load(path_pose)
img_org_view = imread(join([path_images "1.jpg"], filesep));
img_ref_view = imread(join([path_images "2.jpg"], filesep));

% Resizeing stuff if needed. If not resizing, set s to 1.
% [img_org_view, s, ~] = fit_img_to_screen(img_org_view, 735, 1632);
% [img_ref_view, ~, ~] = fit_img_to_screen(img_ref_view, 735, 1632);
s = 1;

[h, w, ~] = size(img_org_view); % used later in plotting epilines
colors = 'bgrcmy';              % color order used in plotting (cycles)

%% CORE FUNCTIONALITY %%
fprintf('Calculating fundamental matrix...')
[F, e1, e2] = calc_fun_with_abs_pose(KK_1, KK_2, Rc_1, Tc_1, Rc_2, Tc_2, s);

% Flatten the epipoles and non-homgenify for plotting later on.
epipole_org_view = reshape(e1(1:2), [], 2);
epipole_ref_view = reshape(e2(1:2), [], 2);
fprintf(' DONE.')

fprintf('\n\nEntering point-marking mode...\n\t')
npoints = input('[PROMPT] Enter the no. of points to mark: ');

% Mark corresponding points. These points are stored as a homogenous 2D 
% array of size 3xN, where N is npoints. 
%iptsetpref('ImshowBorder','loose');

fprintf('\t>> Mark points in original view...')
pts_org_view = mark_points(img_org_view, 'Original', npoints, colors);
fprintf(' DONE.\n\t>> Mark corresponding points in reflected view...')
pts_ref_view = mark_points(img_ref_view, 'Reflected', npoints, colors);
fprintf(' DONE.\nExiting point-marking mode.\n\n')

close all;

% Find the epilines. Since F is 3x3 and pts are 3xN, result is 3xN where
% each column corresponds to the epiline for that pair of corresponding
% points.
fprintf('Calculating the epilines for the marked points...')
epilines_org_view = F' * pts_ref_view;
epilines_ref_view = F * pts_org_view;
fprintf(' DONE.');

%% PLOTTING STUFF %%
% Plot the epilines and save the results as well.    
% Step-through one-by-one?
fprintf('\nPlotting the results and calculating the point-epiline distances...\n')

%iptsetpref('ImshowBorder','tight');

% Load the figures with images.
org_fig = figure('Name', 'Epilines in Original View', 'NumberTitle', 'off');
imshow(img_org_view); hold on;
set(gcf, 'Color', 'w');
set(findall(gcf,'-property','FontSize'),'FontSize', 18)

ref_fig = figure('Name', 'Epilines in reflected View', 'NumberTitle', 'off');
imshow(img_ref_view); hold on;
set(gcf, 'Color', 'w');
set(findall(gcf,'-property','FontSize'),'FontSize', 18)

pt_line_dists_org = NaN([1 npoints]);
pt_line_dists_ref = NaN([1 npoints]);

% Go point-by-point.
for i = 1 : npoints
    % Color pattern!
    color = colors(mod(i, npoints + 1));
    
    % Draw the epilines and corresponding points on the figures.
    draw_epilines_on_fig(org_fig, [h, w], pts_ref_view(:, i), pts_org_view(:, i), ... 
        epilines_org_view(:, i), color, epipole_org_view);
    draw_epilines_on_fig(ref_fig, [h, w], pts_org_view(:, i), pts_ref_view(:, i), ...
        epilines_ref_view(:, i), color, epipole_ref_view);
    
    % Calculate and store point-line distance.
    pld_org = calc_point_line_distance(pts_org_view(:, i), epilines_org_view(:, i));
    pld_ref = calc_point_line_distance(pts_ref_view(:, i), epilines_ref_view(:, i));
    pt_line_dists_org(1, i) = pld_org;
    pt_line_dists_ref(1, i) = pld_ref;
   
end

if strcmp(test_set_name, '') == 1
    test_set_name = 'set';
end

if ~isfolder(join([dir_results test_set_name], filesep))
    mkdir(join([dir_results test_set_name], filesep));
end

fprintf('\t>> Saving results to "%s/%s"...', [dir_results test_set_name]);

% If you have export_fig from file exchange, this is better quality.
% export_fig(org_fig, join([dir_results test_set_name 'epilines_in_original_view.png'], filesep), '-native');
% export_fig(ref_fig, join([dir_results test_set_name 'epilines_in_reflected_view.png'], filesep), '-native');

saveas(org_fig, join([dir_results test_set_name 'epilines_in_original_view.png'], filesep));
saveas(ref_fig, join([dir_results test_set_name 'epilines_in_reflected_view.png'], filesep));
save(join([dir_results test_set_name 'fun_and_plds.mat'], filesep), 'F', 'epipole_org_view', 'epipole_ref_view', 'pts_org_view', 'pts_ref_view', 'epilines_org_view', 'epilines_ref_view', 'pt_line_dists_org', 'pt_line_dists_ref', 'path_test_set')

fprintf(' DONE.\n\t>> Average Point-Line Distance Over Both Views: %6.8f\n', mean([pt_line_dists_org pt_line_dists_ref], 'all'));
fprintf('[NOTE] You may view the results in the respective folders. Terminating.\n')

%% FUNCTION SPACE %%
function pld = calc_point_line_distance(point, epiline)
x = point(1); y = point(2);
a = epiline(1); b = epiline(2); c = epiline(3);
pld = abs(a*x + b*y + c) / sqrt(a^2 + b^2);
return
end


function [] = draw_epilines_on_fig(fig, img_size, source_pt, corr_pt, epiline, color, epipole)
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

return
end


function pts = mark_points(img, view_name, npoints, colors)
figure('Name', join([view_name ' View']), 'NumberTitle', 'off')

imshow(img); title([view_name ' View - Click on ' num2str(npoints) ' points'])
hold on;

set(gcf, 'Color', 'w');
set(findall(gcf,'-property','FontSize'),'FontSize',18)

pts = NaN([3, npoints]);
for i = 1 : npoints
    color = colors(mod(i, npoints + 1));
    [x_click, y_click] = ginput(1);
    plot(x_click, y_click, 'Color', color, 'Marker', '+', 'MarkerSize', 20, 'linewidth', 2);
    %text(x_click - 20, y_click - 20, num2str(i), 'Color', color, 'FontSize', 18);
    pts(:, i) = [x_click y_click 1]';
    fprintf('%d...', i)
end

pause(0.2);
%export_fig(join(['marked_points_' view_name], ''), '-native', '-c0,NaN,NaN,NaN')

return

end


% To fit on widescreen; these may be high-res images!
function [resized_img, scale_factor, major_scaling_dim] ...
    = fit_img_to_screen(img, max_height, max_width)

[height, width, ~] = size(img);
scale_height = height / max_height;
scale_width = width / max_width;

% Does image even need scaling?
if scale_height <= 1.0 && scale_width <= 1.0
    resized_img = img;
    scale_factor = 1;
    major_scaling_dim = NaN;
    return
% Is image height more out of bounds than height?
elseif scale_height > scale_width
    target_size = [max_height NaN];
    scale_factor = 1/scale_height;
    major_scaling_dim = 1;
% Is image width more out of bounds than height?
elseif scale_width > scale_height
    target_size = [NaN max_width];
    scale_factor = 1/scale_width;
    major_scaling_dim = 2;
% 1:1 aspect ratio, scaling dimension does not matter.
else
    target_size = [NaN max_width];
    scale_factor = 1/scale_width;
    major_scaling_dim = NaN;
end

resized_img = imresize(img, target_size);
return 

end


function [F, e1, e2] = calc_fun_with_abs_pose(K1, K2, R1, T1, R2, T2, s)
%{
% Calculate fundamental matrix using the equations from Hartley and 
Zisserman's Multi-View Geometry (Chapter 9), minus the world origin at 
first camera assumption, which affects P1 and P1_inv (P and P+ in book). 

The toolbox forces right-handedness, even when calibrating the mirror view. 
This results in the undesired effect that the X and Y axes of the actual 
world frame (in the original view) are swapped in the reflected view. The
reconstruction scripts swap the world X and Y when estimating the world 
coordinates in the reflected view to forcefully swap the handedness. We 
need to do the same permutation here when drawing epilines.

The determinant of R will be -1 when permuted. It swaps the X and Y axes.
%}

% Bunch the extrinsics.
pose1 = [R1 T1];
pose2 = [R2 T2];

% Rescale intrinsic parameters if images were rescaled. Slice to avoid
% 1 at position (i, j) = (3, 3).
if ~isempty(s)
    K1(1:2, :) = K1(1:2, :) .* s;
    K2(1:2, :) = K2(1:2, :) .* s;
end
perm_transform = [0 1 0 0; 1 0 0 0; 0 0 1 0; 0 0 0 1];

pose2 = [pose2; [0 0 0 1]];      % make 4x4 for permutation
pose2 = pose2 * perm_transform;  % mirror swap
pose2 = pose2(1:3, :);           % reset to 3x4 matrix

% Zisserman's multi-view geometry stuff, minus the camera center at first
% world origin assumption.
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
return

end