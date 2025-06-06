clear; close all;

set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultAxesFontSize', 12);
set(groot, 'defaultfigurecolor', [1 1 1]);

try
    undistorted_img = imread('peppers.png');
catch
    fprintf('Example image peppers.png not found. Using synthetic image.\n');
    [X,Y] = meshgrid(1:320, 1:240);
    undistorted_img = uint8(mod(X+Y,256));
    undistorted_img = repmat(undistorted_img, [1,1,3]);
end

H = size(undistorted_img, 1);
W = size(undistorted_img, 2);

% Define camera intrinsics (randomly)
fx = W * 1.2;
fy = W * 1.2;
cx = W / 2;
cy = H / 2;
intrinsics = [fx fy cx cy];

% Define distortion coefficients [k1 k2 p1 p2] - mess around with different
% values, inclduign negatives, to check that the inverse distortion map
% works well too

k1 = 0.6;  % Radial distortion
k2 = 0.4; % Radial distortion
p1 = 0.01; % Tangential distortion
p2 = 0.05; % Tangential distortion
dist_coefs = [k1 k2 p1 p2];

% Distort the image
distorted_img = distort_img(undistorted_img, dist_coefs, intrinsics);

% Undistort the image
undistorted_img_recovered = invert_distort_img(distorted_img, dist_coefs, intrinsics);

% Redistort the image
redistorted_img = distort_img(undistorted_img_recovered, dist_coefs, intrinsics);

% Display results
figure;
subplot(2,2,1); imshow(undistorted_img); title('Original (Undistorted) Image');
subplot(2,2,2); imshow(distorted_img); title('Distorted Image');
subplot(2,2,3); imshow(undistorted_img_recovered); title('Undistorted Image Recovered');
subplot(2,2,4); imshow(redistorted_img); title('Redistorted Image')