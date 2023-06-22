%{ 
TERMINOLOGY
===========================================================================
Assume a single camera, 2-mirror setup. The setup remains stationary, the
object of interest moves around. So, KRT will remain the same for each
view but the pixels corresponding to the physical point of interest in each
view will change at every time instant. At any given time instant, we have
three images labeled as integers, so that the set of images corresponding
to time instance t is {3*(t-1)+1 : t*3}.jpgs.

- i'th point, j'th img, k'th camera/view. Consider images 7, 8, 9.jpg 
corresponding to time instance t = 3.
    + 7.jpg: original camera view (j = 7, k = 1)
    + 8.jpg: first mirror reflection (j = 8, k = 2)
    + 9.jpg: second mirror reflection (j = 9, k = 3)
    + The i'th point is a WORLD point shared between views
    NOTE: We keep 'j' as the image number because at any given point, the
    user might like to reconstruct on images taken at multiple time
    instances or, for example, frames in a video.
- X_i are the 3D world coordinates corresponding to physical point i
- x_ij are the pixels corresponding to point i in image j
- [Rc_k | Tc_k] is the camera pose in view k (corresponding to image j)
- KK_k is the k'th camera's intrinsics (including mirror views)

NOTE ON UNDISTORTION AND IMAGE NAMING CONVENTIONS
===========================================================================
Make sure images are undistorted according to the calibration prior to 
using this script. Each view (camera, mirror 1, and mirror 2) should be
calibrated separately prior to running this script, resulting in three 
spearate sets of distortion coefficients (one for each view). 

When running this script, an image at time instace t should be copied as 
many times as there are mirrors (2 copies for a total of 3 images at time t
in this case). The files should be named starting from 1.jpg (original), 
2.jpg (mirror 1), and 3.jpg (mirror 2) for the first image at time t. 
The second image at time instance t+1 would then be saved as 4.jpg, 5.jpg, 
and 6.jpg, and so on. The undistortions to each image should be applied 
corresponding to the dist. coefficients associated with its camera/view.


DEBUGGING RECONSTRUCTION ERROR IN REAL UNITS
===========================================================================
If reconstructing calibration pattern for debugging purposes, run 
`debug_calib_reconst.mat` instead. The known pattern distances can be used
to easily compute the reconstruction error in terms of real world units 
(mm) there. This script can also be used to do that, but requires measuring
the real world distances, marking the points in each view, and associating 
the points to the distances beforehand, which can be a bit of work.

TODO: Manually swapping X and Y in the X_i vector for mirror views to 
counter the toolbox's forced right-handedness is clumsy and inefficient. A 
much clearer and better fix would be to apply a permutation transform to 
the extrinsic, which won't change for stationary cameras. Note that this
makes the determinant of the rotation NEGATIVE, and any funcitonality that
requires a postiive determinant would thus fail (e.g., `rigidtform3d`). To
swap the axes in those functionalities, use the original extrinsics,  but 
then swap the axes using the `invert` function instead, which will work.

% Homogenous Code Example:
perm_transform = [0 1 0 0; 1 0 0 0; 0 0 1 0; 0 0 0 1];
mirror_extrinsics = [R T] * perm_transform;

% Non-homogenous Code Example:
perm_transform = [0 1 0; 1 0 0; 0 0 1];
mirror_rotation = R * perm_transform
mirror_translation = original_translation
%}

%% SETUP %%
clc
clear all
close all

% Load the KRT params (calibration) and marked points (`point_marker.m`).

load('merged_params.mat');  % loads in `KK`, `R`, `T` for each view
load('marked_points.mat');  % loads in `npoints` and `xj`

% Distance between consecutive physical points in real-world units. Comment 
% out if not interested in 3D reconstruction error. If n points marked, it
% should be a n-1 element vector [1->2, 2->3, ..., i->i+1, ..., n-1->n].
% org_dists = [];  

% Set optimizer options.
options = optimoptions('lsqnonlin', 'display', 'off');
options.Algorithm = 'levenberg-marquardt';

% Input which images to use.
disp("When prompted, enter the image numbers in the form of a vector.") 
disp("For example, [7 8 9] for the 7th, 8th, and 9th images.")
imgs = input("Images to use (min 2, max 3): ");

% Input check!
n_views = numel(imgs);
if n_views > 3 || n_views == 1
    disp('[ERROR] Unsupported number of views. Enter exactly 2 or 3 images.')
    return
end

% Load in the camera extrinsics and intrinsics for each view.
R = []; T = []; KK = [];
for k = 1 : n_views
    % Indexing convenience - img no. `j` for k'th view
    j = imgs(k);  
    eval(['R = [R Rc_' num2str(j) '];']);
    eval(['T = [T Tc_' num2str(j) '];']);  
    eval(['KK = [KK KK_' num2str(j) '];']);
end

%% OPTIMIZATION PER PIXEL FOR N-VIEW WORLD COORDINATE ESTIMATION %%
% Everything below is in homogenous coordinates.
fprintf('\nEstimating world coordinates with lsqnonlin: ')

X_init = ones(4, 1);      % initial guess for optimizer
X = zeros(4, npoints);    % to store the estimated 3D world coordinates
xpp = zeros(3, n_views);  % to store pixel corresponding to i'th physical point in all views

for i = 1 : npoints
    for k = 1 : n_views
        % Get pixel location of the same physical corner in all n views.
        xpp(:, k) = xj(:, npoints*(k-1)+i);
    end
    
    % Estimate the 3D world coordinates.
    Xpp = lsqnonlin( ...
        @(Xpp)reconst_coords_per_px(Xpp, n_views, xpp, KK, R, T), ...
        X_init, [], [], options);

    % Normalize w.r.t homogenous coordinate.
    Xpp = Xpp./Xpp(4);  
    
    % Append to array, will be 4 x npoints by end.
    X(:, i) = Xpp;
end
fprintf('done.\n')

%% PIXEL REPROJECTION VISUALIZATION %%
% Everything is still in homogenous coordinates. We will copy `X` to
% `X_proj` for the visualizations to avoid accidents.
fprintf('Reprojecting using the estimated world coordinates... ')
per_view_reproj_error = Inf(1, n_views);

for k = 1 : n_views
   
    % Swap X and Y if mirror views as we estimated them for right-handed 
    % frames using KRT for left-handed frames. So, we need to take them
    % back to right-handed.
    X_proj = X;
    if k > 1
        for i = 1 : npoints
            X_proj(:, i) = [X_proj(2, i); X_proj(1, i); X_proj(3, i); X_proj(4, i)];
        end
    end
    
    % True pixel locations for all physical points as marked.
    proj_pixels_org = xj(:, npoints*(k-1)+1 : k*npoints);
    
    % Projected pixel locations from estimated world coordinates.
    proj_pixels_est = KK(:, 3*(k-1)+1 : 3*k) * [R(:, 3*(k-1)+1 : 3*k) T(:, k)] * X_proj; 
    proj_pixels_est = proj_pixels_est./proj_pixels_est(3, :);

    % Read the image in.
    eval(['img = imread("Image' num2str(imgs(k)) '.jpg");']);
    
    % Calculate reprojection error.
    reproj_error = mean(abs(proj_pixels_org - proj_pixels_est), 'all');
    per_view_reproj_error(1, k) = reproj_error;
    
    % Plot them pixels.
    figure(k)
    imshow(img); hold on;
    title(['View ' num2str(k) ' (Img ' num2str(imgs(k)) ') - Pixel Projections for Estimated World Coordinates'])
    xlabel('x (pixel)'); ylabel('y (pixel)');
    plot(proj_pixels_est(1, :), proj_pixels_est(2, :), 'r*', 'linewidth', 1, 'MarkerSize', 7);
    plot(proj_pixels_org(1, :), proj_pixels_org(2, :), 'bo', 'linewidth', 1, 'MarkerSize', 8);
    legend('correct extrinsics est WC projections',  'original WC projections')

end
fprintf("done.\n")

%% 3D VISUALIZATION - RECONSTRUCTION %%
X_proj = X(1:3, :);

figure(4);
xlabel('X (mm)'); ylabel('Y (mm)'); zlabel('Z (mm)');
hold on; grid on;

% Mark first point in red for reference; rest in blue.
plot3(X_proj(1, 1), X_proj(2, 1), X_proj(3, 1), 'r*')
plot3(X_proj(1, 2 : npoints), X_proj(2, 2 : npoints), X_proj(3, 2 : npoints), 'b*')

% Plot the cameras (original + virtual).
colors = ["red", "blue", "magenta"];
labels = ["C", "M1", "M2"];
perm_transform = [0 1 0; 1 0 0; 0 0 1];
for k = 1 : n_views
    
    R_cam = R(:, 3*(k-1)+1 : 3*k);
    T_cam = T(:, k);
    if k == 1
        % Original view. Can use plotCamera since +ve det rotation matrix.
        pose_cam = rigidtform3d(R(:, 3*(k-1)+1 : 3*k), T(:, k));

        % pose_cam is the camera pose in CAMERA coordinates, pose_world is 
        % the camera's pose in WORLD coordinates (inversion of pose_cam). 
        % Note that invert(pose_cam) is equivalent to extr2pose(pose_cam).
        pose_world = invert(pose_cam);

    else
        % Virtual mirror view. Can't use plotCamera since 
        R_cam = R_cam * perm_transform;
        % T_cam([1 2], [1 1]) = T_cam([2 1], [1 1]);
        
        R_world = inv(R_cam);
        T_world = -R_world * T_cam;

        % Define the camera size
        cameraSize = 100;
        
        % Define the eight corners of the box relative to the camera position
        corners = cameraSize * [
            -1 -1 -1;  % Corner 1
            -1 -1  1;  % Corner 2
            -1  1 -1;  % Corner 3
            -1  1  1;  % Corner 4
             1 -1 -1;  % Corner 5
             1 -1  1;  % Corner 6
             1  1 -1;  % Corner 7
             1  1  1;  % Corner 8
        ]';
        
        % Apply the camera's rotation and translation to the corners
        corners = R_world * corners + T_world;
        
        % Define the lines connecting the corners of the box
        lines = [
            1 2; 1 3; 1 5;  % Lines connected to Corner 1
            2 4; 2 6;       % Lines connected to Corner 2
            3 4; 3 7;       % Lines connected to Corner 3
            4 8;            % Lines connected to Corner 4
            5 6; 5 7;       % Lines connected to Corner 5
            6 8;            % Lines connected to Corner 6
            7 8;            % Lines connected to Corner 7
        ];
        
        % Plot the camera as a box
        for i = 1:size(lines, 1)
            plot3(corners(1,lines(i,:)), corners(2,lines(i,:)), corners(3,lines(i,:)), 'k-');
        end

        quiver3(T_world(1), T_world(2), T_world(3), R_world(1,1), R_world(2,1), R_world(3,1), cameraSize, 'r');
        quiver3(T_world(1), T_world(2), T_world(3), R_world(1,2), R_world(2,2), R_world(3,2), cameraSize, 'g');
        quiver3(T_world(1), T_world(2), T_world(3), R_world(1,3), R_world(2,3), R_world(3,3), cameraSize, 'b');
        pose_world = invert(pose_cam);
        plotCamera("AbsolutePose", pose_world, "Size", 50, "Color", colors(k), "Label", labels(k), "AxesVisible", true, "Opacity", 0)
    end
end
axis equal

%% METRIC PRINTOUT %%
disp('***CORRECT EXTRINSICS***');
fmt = ['\tMean Reprojection Error (PER-VIEW): ', repmat('%f, ', 1, numel(per_view_reproj_error(1, :))-1), '%f\n'];
fprintf(fmt, per_view_reproj_error(1, :));
fprintf('\tMean Reprojection Error (OVERALL): %f\n', mean(per_view_reproj_error(1, :), 'all'));

% fprintf('\n\t*** ESTIMATED WORLD COORDS ***\n');
% fprintf('\tOriginal Distances: X = %4.4f\n', org_dist)
fmt = ['\tEstimated 3D Points: ', repmat('(%4.4f, %4.4f, %4.4f), ', 1, npoints - 1), '(%4.4f, %4.4f, %4.4f)\n'];
fprintf(fmt, X_proj);

% est_dist = NaN(1, npoints - 1);
% for i = 1 : npoints - 1
%     est_dist(i) = norm(X_est(:, i) - X_est(:, i+1), 2);
% end
% fmt = ['\tNormed Distance Between Neighboring Points: ', repmat('%4.4f, ', 1, numel(est_dist) - 1), '%4.4f\n'];
% fprintf(fmt, est_dist);
% dd=mean(est_dist);
% %fprintf("Mean of est dis is\n:",dd);
% error_dist = est_dist - org_dist;
% fmt = ['\tErrors w.r.t Original Distances: ', repmat('%4.4f, ', 1, numel(est_dist) - 1), '%4.4f\n'];
% fprintf(fmt, error_dist);
% disp(dd)
% fprintf('\n\tMean Distance Error: %4.4f\n', mean(error_dist, 'all'))
% orignan_2d = sqrt(sum((proj_pixels_org - proj_pixels_est).^2));
% figure(20);
% %histogram(error_dist, 20);
% %D=sqrt((y(1)-x(1))^2+(y(2)-x(2))^2);
% histogram(orignan_2d, 110);
% xlabel('X (mm)'); ylabel('Y (mm)'); 
% hold on;

%% FUNCTIONS %%
function error = reconst_coords_per_px(X, n_views, x, K, R, T)
%{ 
We go point-by-point and pixel-by-pixel, so we get three reprojection 
errors (one per view). LSQNONLIN requires a vectored error function and 
not a scalar value. So, we vectorize all three.
%}
    vector_err = [];
    for k = 1 : n_views
    
        % Get the actual pixel location of the i'th point in the k'th view.
        true = x(:, k);
    
        % The mirror-swap for X and Y axes.
        if k == 2
            X = [X(2); X(1); X(3); X(4)];
        end
        
        % Use current guess of 3D world points to get the pixel 
        % projections from the forward projection equation.
        pred = K(:, 3*(k-1)+1 : k*3) * [R(:, 3*(k-1)+1 : k*3) T(:, k)] * X;
        
        % Normalize w.r.t. homogenous coordinate.
        pred = pred./pred(3, :);  
        
        % Get the reprojection error and vectorize it.
        reproj_error = true - pred;
        vector_err = [vector_err reproj_error];
    end
    error = vector_err;
end