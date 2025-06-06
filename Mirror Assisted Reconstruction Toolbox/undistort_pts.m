function undistorted_pts = undistort_pts(points, dist_coefs, intrinsics)
%{
Undistort 2D points (in an image) using the direct polynomial model for image
distortion.

The transformation herein is practically the same as distort_pts.m, but with
undistortion being the "forward" map instead of distortion. That is, `points` is
an UNDISTORTED set of 2D points (note that if it is an UNDISTORTED set of 2D
points, this will effectively distort them).

Do not use this like an inverse map to distort_pts.m (i.e., starting from an
UNDISTORTED set of 2D points, you DISTORT it with distort_pts.m, and are now
attempting to RE-UNDISTORT it with this function); undistortion is non-linear
and so it is not invertible. Please use invert_distort_pts.m for an iterative
algorithm that can handle that scenario and get you the correct undistorted
points.

INPUTS
===============================================================================
points:
    2xN matrix of [x; y] coordinates to undistort.
dist_coefs:
    1x4 vector of [k1 k2 p1 p2] distortion coefficients.
intrinsics:
    2x3 matrix of [fx 0 cx; 0 fy cy] camera intrinsics.

OUTPUTS
===============================================================================
undistorted_pts:
    2xN matrix of undistorted [x; y] coordinates.

REFERENCE
===============================================================================
- https://www.mathworks.com/help/visionhdl/ug/image-undistort.html
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

% Handle input points format. Mostly, we expect points across columns (2xN or
% Nx2), but this function also supports points across rows (Nx2). That is, in
% point across columns, each 2D point is a single column, while across rows,
% each 2D point is a single row. For operations, we temporarily force them to be
% across columns.
points_across_rows = false;
if size(points, 2) == 2 && size(points,1) ~= 2
    points_across_rows = true;
elseif size(points, 1) ~= 2
    error('Input points must be 2xN or Nx2.');
end

% Get the current distorted points.
U_distorted = points(1, :);
V_distorted = points(2, :);

% Convert from pixel to normalized camera coordinates.
Xc_distorted_norm = (U_distorted - cx) / fx;
Yc_distorted_norm = (V_distorted - cy) / fy;

% Compute the l2 norm of the distorted point.
cam_l2_norm = Xc_distorted_norm.^2 + Yc_distorted_norm.^2;

% Compute the radial distortion.
Xc_radial_distortion = Xc_distorted_norm .* (1 + k1 * cam_l2_norm + k2 * cam_l2_norm.^2);
Yc_radial_distortion = Yc_distorted_norm .* (1 + k1 * cam_l2_norm + k2 * cam_l2_norm.^2);

% Compute the tangential distortion.
Xc_tangential_distortion = 2 * p1 * Xc_distorted_norm .* Yc_distorted_norm + p2 * (cam_l2_norm + 2 * Xc_distorted_norm.^2);
Yc_tangential_distortion = 2 * p2 * Xc_distorted_norm .* Yc_distorted_norm + p1 * (cam_l2_norm + 2 * Yc_distorted_norm.^2);

% Undistort the points in cam coords (add the radial and tangential distortion).
Xc_undistorted_norm = Xc_radial_distortion + Xc_tangential_distortion;
Yc_undistorted_norm = Yc_radial_distortion + Yc_tangential_distortion;

% Map undistorted camera coordinates back to pixel coordinates.
U_undistorted = Xc_undistorted_norm * fx + cx;
V_undistorted = Yc_undistorted_norm * fy + cy;

% Return the undistorted points.
undistorted_pts = [U_undistorted; V_undistorted];

if points_across_rows
    undistorted_pts = undistorted_pts';
end

end