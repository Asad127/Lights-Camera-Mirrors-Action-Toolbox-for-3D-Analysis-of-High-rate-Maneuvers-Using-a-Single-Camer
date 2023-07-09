function undistorted_img = undistort_img(img, dist_coefs, intrinsics)
% Undistorts and returns a single undistorted image. This is mainly just 
% the geometrical transformation part, doesn't require MATLAB toolboxes.
% Use it in conjunction with other scripts and functions to save the image, 
% or undistort and save multiple images, or even videos.
% It is different from the undistort image function of BCT in the sense
% that it works on color images. For a grayscale version, see
% undistort_img_gray.m instead.
% See here for math: https://www.mathworks.com/help/visionhdl/ug/image-undistort.html

% Get the size of the input img.
img_size = size(img);

% Get the intrinsic camera parameters.
focal_length    = [intrinsics(1,1) intrinsics(2,2)];  % fx and fy
principal_point = [intrinsics(1,3) intrinsics(2,3)];  % cx and cy

% Generate img pixel grid for the undistorted img.
[U, V] = meshgrid(1:img_size(2), 1:img_size(1));

% Apply distortion correction to original img pixels.
% =========================================================================
% 1. Convert from pixel to normalized camera coordinates.
Xc_norm = (U - principal_point(1)) ./ focal_length(1);
Yc_norm = (V - principal_point(2)) ./ focal_length(2);

% 2. Evaluate the equations (see link under function definition).
r2 = Xc_norm.^2 + Yc_norm.^2;
radial_distortion = 1 + dist_coefs(1) * r2 + dist_coefs(2) * r2.^2;
tangential_distortion_Xc = 2 * dist_coefs(3) * Xc_norm .* Yc_norm + dist_coefs(4) * (r2 + 2 * Xc_norm.^2);
tangential_distortion_Yc = dist_coefs(3) * (r2 + 2 * Yc_norm.^2) + 2 * dist_coefs(4) * Xc_norm .* Yc_norm;

% 3. Undistort the points in camera coordinates.
undistorted_Xc = Xc_norm .* radial_distortion + tangential_distortion_Xc;
undistorted_Yc = Yc_norm .* radial_distortion + tangential_distortion_Yc;

% 4. Map undistorted camera coordinates to img coordinates from earlier.
undistorted_U = undistorted_Xc .* focal_length(1) + principal_point(1);
undistorted_V = undistorted_Yc .* focal_length(2) + principal_point(2);

% 5. Interpolate the img using the undistorted pixel coordinates. 
% This accounts for the floating values that appear post-undistortion. 
% interp2 requires either single or double precision floats for operation,
% so we temporarily convert type of the img.
undistorted_img_r = interp2(double(img(:, :, 1)), undistorted_U, undistorted_V, 'cubic');
undistorted_img_g = interp2(double(img(:, :, 2)), undistorted_U, undistorted_V, 'cubic');
undistorted_img_b = interp2(double(img(:, :, 3)), undistorted_U, undistorted_V, 'cubic');

% 6. Explicit reshape the undistorted img to the original size. Not sure if
% ever needed.
% undistorted_img_r = reshape(undistorted_img_r, img_size(1:2));
% undistorted_img_g = reshape(undistorted_img_g, img_size(1:2));
% undistorted_img_b = reshape(undistorted_img_b, img_size(1:2));

% Convert back to uint8.
undistorted_img_r = uint8(undistorted_img_r);
undistorted_img_g = uint8(undistorted_img_g);
undistorted_img_b = uint8(undistorted_img_b);

undistorted_img = cat(3, undistorted_img_r, undistorted_img_g, undistorted_img_b);
% =========================================================================
% NOTE:  We don't need the 5 argument variant of interp2 since our sample 
% and query grids are the same and we are undistorting the whole image. We 
% can use the 5 argument variant with required adjustments if we need to 
% undistort only part of the image. Don't crop the image to the region you 
% want to undistort first, that would result in the wrong image.
end