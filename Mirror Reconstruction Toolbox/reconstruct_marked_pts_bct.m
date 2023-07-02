%{ 
TERMINOLOGY
===========================================================================
Assume a single camera, 2-mirror setup. The setup remains stationary, the
object of interest moves around. So, KRT will remain the same for each
view but the pixels corresponding to the physical point of interest in each
view will change at every time instant. Since we have mirrors and one cam,
we load in the same image twice/thrice to get the 2-3 views in separate 
figures. Thus, for any given image where the stationary camera assumption
holds true, we define the following terms:

- i'th point, j'th view, k'th view label. Consider image3.jpg:
    + 3.jpg: original camera view (j = 1, k = 1)
    + 3.jpg: first mirror reflection (j = 2, k = 2)
    + 3.jpg: second mirror reflection (j = 3, k = 3)
    + The i'th point is a WORLD point shared between views
    NOTE: j is the view number regardless of the view's label/identity. 
    E.g., if we had 2 views and they were camera and mirror 2, then the
    labels would be 1 and 3, resepectively. In such a case, j is 1 for
    camera and 2 for second mirror, but the labels are clearly 1 and 3. In 
    other words, j is the view relative to the number of views, whereas k
    is the view relative to the view-labeling convention. The labels are 
    preserved in the merged BCT calibration parameters file.

- X_i are the 3D world coordinates corresponding to physical point i
- x_ij are the pixels corresponding to point i in view j (not k). Arrays
  are defined with a specific no. of rows and columns based on the no. of 
  views and use j for indexing. This allows us to save memory by avoiding 
  unnecessarily large arrays with NaNs for non-present view labels.
- [Rc_k | Tc_k] is the pose of view k w.r.t. some reference image from 
  calibration time
- KK_k is the k'th camera's intrinsics (including mirror views)
- R, T, and KK are arrays to store rotation, translation, and intrinsics 
of a view based on the total no. of views. Thus, they are created by
appending the Rc_k, Tc_k, and KK_k for the k'th view to these images, but
they are indexed using j (relative view no.).
%}

%% SETUP %%

default = load('defaults.mat');

% Load the KRT params (calibration) and marked points (`point_marker.m`).
fprintf('Loading BCT merged calibration file...')
[calib_file, calib_dir] = uigetfile( ...
    '*.mat', ...
    'Locate merged BCT calibration parameters file' ...
);
if ~calib_file
    error('Operation canceled by user.')
end
calib_file = fullfile(calib_dir, calib_file);
view_params = load(calib_file);  % loads in the required `KK`, `Rc`, and `Tc` for each view
fprintf('done.\n')

fprintf('Loading file containing marked points...')
[pts_file, pts_dir] = uigetfile( ...
    '*.mat', ...
    'Locate file containing the manually marked corresponding points in the image' ...
);
if ~pts_file
    error('Operation canceled by user.')
end
pts_file = fullfile(pts_dir, pts_file);
marked_points = load(pts_file);  % loads in `num_points` and `x`
fprintf('done.\n')

x = marked_points.x;
num_points = marked_points.num_points;

view_labels = view_params.view_labels;
num_views = numel(view_labels);
view_names = default.VIEW_NAMES_LONG(view_labels);

% Distance between consecutive physical points in real-world units. Comment 
% out if not interested in 3D reconstruction error. If n points marked, it
% should be a n-1 element vector [1->2, 2->3, ..., i->i+1, ..., n-1->n].
% org_dists = [];  

% Set optimizer options.
options = optimoptions('lsqnonlin', 'display', 'off');
options.Algorithm = 'levenberg-marquardt';

% Input which image to use.
fprintf('Loading the image containing the object of interest...')
img_filter = cellfun(@(extension) ['*' extension], default.SUPPORTED_IMG_EXTS, 'UniformOutput', false)';
[img_file, img_dir] = uigetfile( ...
    img_filter, ...
    'Locate the image containing the object you want to reconstruct' ...
);
if ~img_file
    error('Operation canceled by user.')
end
img_filepath = fullfile(img_dir, img_file);
img = imread(img_filepath);
fprintf('done.')

% Load in the camera extrinsics and intrinsics for each view.
R = []; T = []; KK = [];
for j = 1 : num_views
    % Get label k of the j'th view (camera = 1, mirror 1 = 2, mirror 2 = 3)
    % If only had mirrors 1 and 2, k would be 2 and 3.
    k = view_labels(j);  
    R = cat(2, R, view_params.(sprintf('Rc_%d', k)));
    T = cat(2, T, view_params.(sprintf('Tc_%d', k))); 
    KK = cat(2, KK, view_params.(sprintf('KK_%d', k)));
end

%% OPTIMIZATION PER PIXEL FOR N-VIEW WORLD COORDINATE ESTIMATION %%
% Everything below is in homogenous coordinates.
fprintf('\nEstimating world coordinates with lsqnonlin...')

X_init = ones(4, 1);       % initial guess for optimizer
X = zeros(4, num_points);  % to store the estimated 3D world coordinates
xpp = zeros(3, num_views); % to store pixel corresponding to i'th physical point in all views

for i = 1 : num_points
    for j = 1 : num_views
        % Get pixel location of the same physical corner in all n views.
        xpp(:, j) = x(:, num_points*(j-1)+i);
    end
    
    % Estimate the 3D world coordinates.
    Xpp = lsqnonlin( ...
        @(Xpp)reconst_coords_per_px(Xpp, num_views, xpp, KK, R, T), ...
        X_init, [], [], options);

    % Normalize w.r.t homogenous coordinate.
    Xpp = Xpp./Xpp(4);  
    
    % Append to array, will be 4 x num_points by end.
    X(:, i) = Xpp;
end
fprintf('done.\n')

X_est_homo = X;
X_est = X_est_homo(1:3, :);

%% PIXEL REPROJECTION VISUALIZATION %%
fprintf('Reprojecting using the estimated world coordinates... ')
per_view_reproj_error = Inf(1, num_views);

for j = 1 : num_views
    % True pixel locations for all physical points as marked.
    proj_pixels_org = x(:, num_points*(j-1)+1 : j*num_points);
    
    % Projected pixel locations from estimated world coordinates.
    proj_pixels_est = KK(:, 3*(j-1)+1 : 3*j) * [R(:, 3*(j-1)+1 : 3*j) T(:, j)] * X_est_homo; 
    proj_pixels_est = proj_pixels_est./proj_pixels_est(3, :);
    
    % Calculate reprojection error.
    reproj_error = mean(abs(proj_pixels_org - proj_pixels_est), 'all');
    per_view_reproj_error(1, j) = reproj_error;
    
    % Plot them pixels.
    figure(j)
    imshow(img); hold on;
    title('%s: Pixel Projections for Estimated World Coordinates', view_names{j})
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
plot3(X_proj(1, 2 : num_points), X_proj(2, 2 : num_points), X_proj(3, 2 : num_points), 'b*')

% Plot the cameras (original + virtual).
colors = ["red", "blue", "magenta"];
labels = ["C", "M1", "M2"];

for j = 1 : num_views
    k = view_labels(j);
    R_cam = R(:, 3*(j-1)+1 : 3*j);
    T_cam = T(:, j);

    if k == 1
        % Original view. Can use plotCamera since +ve det rotation matrix.
        pose_cam = rigidtform3d(R(:, 3*(j-1)+1 : 3*j), T(:, j));

        % pose_cam is the camera pose in CAMERA coordinates, pose_world is 
        % the camera's pose in WORLD coordinates (inversion of pose_cam). 
        % Note that invert(pose_cam) is equivalent to extr2pose(pose_cam).
        pose_world = invert(pose_cam);

        plotCamera( ...
            'AbsolutePose', pose_world, ...
            'Size', 30, ...
            'Color', 'red', ...
            'Label', 'C', ...
            'AxesVisible', true, ...
            'Opacity', 0.10 ...
        );

    else
        % Virtual mirror view. Can't use plotCamera since negative
        % determinant on rotation matrix (permutation -> left handed frame)

        % Get camera position and orientation w.r.t. the world frame.
        R_world = inv(R_cam);
        T_world = -R_world * T_cam;
        
        % Scale the drawn quivers representing the axes.
        size = 50;
        
        % Camera X-axis orientation plot at the camera center in the world.
        quiver3(T_world(1), T_world(2), T_world(3), ...
            R_world(1,1), R_world(2,1), R_world(3,1), ...
            size, ...
            "r", ...
            "LineWidth", 4, ...
            "HandleVisibility","off" ...
        );
        % text(T_world(1), T_world(2), T_world(3), "X", "FontSize", 14)
        
        % Camera Y-axis orientation plot at the camera center in the world.
        quiver3(T_world(1), T_world(2), T_world(3), ...
            R_world(1,2), R_world(2,2), R_world(3,2), ...
            size, ...
            "g", ...
            "LineWidth", 4, ...
            "HandleVisibility","off" ...
        );
        % text(T_world(1), T_world(2), T_world(3), "Y", "FontSize", 14)
        
        % Camera Z-axis orientation plot at the camera center in the world.
        quiver3(T_world(1), T_world(2), T_world(3), ...
            R_world(1,3), R_world(2,3), R_world(3,3), ...
            size, ...
            "b", ...
            "LineWidth", 4, ...
            "HandleVisibility","off" ...
        );
        % text(T_world(1), T_world(2), T_world(3), "Z", "FontSize", 14)
    end
end
axis equal

%% METRIC PRINTOUT %%
fprintf('\n*** ESTIMATED WORLD COORDS ***\n');
fmt = ['\tMean Reprojection Error (PER-VIEW): ', repmat('%f, ', 1, numel(per_view_reproj_error(1, :))-1), '%f\n'];
fprintf(fmt, per_view_reproj_error(1, :));
fprintf('\tMean Reprojection Error (OVERALL): %f\n', mean(per_view_reproj_error(1, :), 'all'));
% fprintf('\tOriginal Distances: X = %4.4f\n', org_dist)
fmt = ['\tEstimated 3D Points: ', repmat('(%4.4f, %4.4f, %4.4f), ', 1, num_points - 1), '(%4.4f, %4.4f, %4.4f)\n'];
fprintf(fmt, X_proj);

% est_dist = NaN(1, num_points - 1);
% for i = 1 : num_points - 1
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
    for j = 1 : n_views
    
        % Get the actual pixel location of the i'th point in the k'th view.
        true = x(:, j);

        % Use current guess of 3D world points to get the pixel 
        % projections from the forward projection equation.
        pred = K(:, 3*(j-1)+1 : j*3) * [R(:, 3*(j-1)+1 : j*3) T(:, j)] * X;
        
        % Normalize w.r.t. homogenous coordinate.
        pred = pred./pred(3, :);  
        
        % Get the reprojection error and vectorize it.
        reproj_error = true - pred;
        vector_err = [vector_err reproj_error];
    end
    error = vector_err;
end