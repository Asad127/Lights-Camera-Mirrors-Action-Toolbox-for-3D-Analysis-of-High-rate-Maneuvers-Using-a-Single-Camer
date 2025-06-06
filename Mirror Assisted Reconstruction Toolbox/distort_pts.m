function distorted_pts = distort_pts(points, dist_coefs, intrinsics)
%{
Distort 2D points (in an image) using the direct polynomial model for image
distortion.

The transformation herein is practically the same as undistort_pts.m, but with
distortion being the "forward" map instead of undistortion. That is, `points` is
an UNDISTORTED set of 2D points (note that if it is a DISTORTED set of 2D
points, this will "double" the distortion, making its effects more noticeable).

Do not use this like an inverse map to undistort_pts.m (i.e., starting from a
DISTORTED MAP, you UNDISTORTED it with undistort_pts.m, and are now attempting
to RE-DISTORT it with this function); distortion is non-linear and so it is not
invertible. Please use invert_undistort_pts.m for an iterative algorithm that
can handle that scenario and get you the correct distorted points.

INPUTS
===============================================================================
points:
    2xN matrix of [x; y] coordinates to distort. Can also be Nx2.
dist_coefs:
    1x4 vector of [k1 k2 p1 p2] distortion coefficients.
intrinsics:
    1x4 vector of [fx fy cx cy], or 3x3 matrix of [fx 0 cx; 0 fy cy; 0 0 1], or
    2x3 matrix of [fx 0 cx; 0 fy cy], or 4x1 vector of [fx; fy; cx; cy].

OUTPUTS
===============================================================================
distorted_pts:
    Array of distorted [x; y] coordinates. Shape matches input.
%}

if nargin < 3
    error('Need at least 3 inputs: points, dist_coefs, intrinsics.');
end

% Validate inputs.
if size(intrinsics, 1) == 3 && size(intrinsics, 2) == 3
    % Extract from 3x3 matrix [fx 0 cx; 0 fy cy; 0 0 1].
    intrinsics = [intrinsics(1,1) intrinsics(2,2) intrinsics(1,3) intrinsics(2,3)];
elseif size(intrinsics, 1) == 2 && size(intrinsics, 2) == 3
    % Convert from 2x3 [fx 0 cx; 0 fy cy] to 1x4 [fx fy cx cy].
    intrinsics = [intrinsics(1,1) intrinsics(2,2) intrinsics(1,3) intrinsics(2,3)];
elseif size(intrinsics, 1) == 4 && size(intrinsics, 2) == 1
    % Convert from 4x1 [fx; fy; cx; cy] to 1x4 [fx fy cx cy].
    intrinsics = intrinsics';
elseif size(intrinsics, 1) ~= 1 || size(intrinsics, 2) ~= 4
    error('Intrinsics must be a 1x4 vector [fx fy cx cy] or convertible to this format (3x3 or 2x3 intrinsic matrix or 4x1 vector).');
end

if numel(dist_coefs) ~= 5
    error('dist_coefs must be a 1x4 vector [k1 k2 p1 p2].');
end

% Input points (Nx2 or 2xN).
points_across_rows = false;
if size(points, 2) == 2 && size(points,1) ~= 2
    points_across_rows = true;
elseif size(points, 1) ~= 2
    error('Input points must be 2xN or Nx2.');
end

% Unpack intrinsic parameters.
fx = intrinsics(1);
fy = intrinsics(2);
cx = intrinsics(3);
cy = intrinsics(4);

% Unpack distortion coefficients.
k1 = dist_coefs(1);
k2 = dist_coefs(2);
p1 = dist_coefs(3);
p2 = dist_coefs(4);

% Get the current points.
U_undistorted = points(1, :);
V_undistorted = points(2, :);

% Convert from pixel to normalized camera coordinates.
Xc_undistorted_norm = (U_undistorted - cx) / fx;
Yc_undistorted_norm = (V_undistorted - cy) / fy;

% Apply distortion equations.
cam_l2_norm = Xc_undistorted_norm.^2 + Yc_undistorted_norm.^2;

% Radial distortion.
Xc_radial_distortion = Xc_undistorted_norm .* (1 + k1 * cam_l2_norm + k2 * cam_l2_norm.^2);
Yc_radial_distortion = Yc_undistorted_norm .* (1 + k1 * cam_l2_norm + k2 * cam_l2_norm.^2);

% Tangential distortion.
Xc_tangential_distortion = 2 * p1 * Xc_undistorted_norm .* Yc_undistorted_norm + p2 * (cam_l2_norm + 2 * Xc_undistorted_norm.^2);
Yc_tangential_distortion = 2 * p2 * Xc_undistorted_norm .* Yc_undistorted_norm + p1 * (cam_l2_norm + 2 * Yc_undistorted_norm.^2);

% Distort the points.
Xc_distorted_norm = Xc_radial_distortion + Xc_tangential_distortion;
Yc_distorted_norm = Yc_radial_distortion + Yc_tangential_distortion;

% Map distorted camera coordinates back to pixel coordinates.
U_distorted = Xc_distorted_norm * fx + cx;
V_distorted = Yc_distorted_norm * fy + cy;

% Return the distorted points.
distorted_pts = [U_distorted; V_distorted];

% Return the points in the same format as the input points.
if points_across_rows
    distorted_pts = distorted_pts';
end

end