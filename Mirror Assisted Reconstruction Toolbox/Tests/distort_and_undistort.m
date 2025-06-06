% Test script to distort and then undistort points, verifying the process
clear; close all;

set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultAxesFontSize', 12);
set(groot, 'defaultfigurecolor', [1 1 1]);

% Define camera parameters
intrinsics = [800 0 320; 0 800 240]; % fx, fy, cx, cy for a 640x480 image
dist_coefs = [0.2, -0.05, 0.01, 0.01]; % k1, k2, p1, p2

% Generate a grid of points (undistorted)
[x, y] = meshgrid(50:50:600, 50:50:400); % Grid points in pixel coordinates (640x480 image)
points_undistorted = [x(:)'; y(:)']; % 2xN matrix

% Distort the points
points_distorted = distort_pts(points_undistorted, dist_coefs, intrinsics);

% Undistort the points
points_undistorted_recovered = invert_distort_pts(points_distorted, dist_coefs, intrinsics);

% Calculate error
error = sqrt(sum((points_undistorted - points_undistorted_recovered).^2, 1));
max_error = max(error);
mean_error = mean(error);

% Display results
fprintf('Max error: %.6f pixels\n', max_error);
fprintf('Mean error: %.6f pixels\n', mean_error);

% Visualize the points
figure;
plot(points_undistorted(1,:), points_undistorted(2,:), 'bo', 'DisplayName', 'Original (Undistorted)');
hold on;
plot(points_distorted(1,:), points_distorted(2,:), 'rx', 'DisplayName', 'Distorted');
plot(points_undistorted_recovered(1,:), points_undistorted_recovered(2,:), 'k+', 'DisplayName', 'Recovered (Undistorted)');
legend('show');
title('Distortion and Undistortion Test');
xlabel('X (pixels)'); ylabel('Y (pixels)');
grid on;