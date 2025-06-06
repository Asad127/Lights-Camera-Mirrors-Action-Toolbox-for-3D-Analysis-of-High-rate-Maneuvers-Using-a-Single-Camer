function distorted_pts = invert_undistort_pts(points, dist_coefs, intrinsics, max_iterations, tolerance)
%{
Invert undistorted points to recover the original distorted points using an
iterative fixed-point algorithm. This function computes distorted points such
that applying the undistortion transform (with the same distortion coefficients
and intrinsics) to the output distorted points will recover the input
undistorted points.

Effectively computes the inverse map of undistort_pts.m.

The main idea is to use the given undistorted points as the initial guess for
the distorted points, then iteratively refine the guess by applying the forward
undistortion to the estimated distorted points and comparing the result to the
original undistorted points.

INPUTS
===============================================================================
points:
    2xN matrix of [x; y] undistorted pixel coordinates. Can also be Nx2, will be
    handled internally.
dist_coefs:
    1x4 vector of [k1 k2 p1 p2] distortion coefficients.
intrinsics:
    1x4 vector of [fx fy cx cy], or 3x3 matrix of [fx 0 cx; 0 fy cy; 0 0 1], or
    2x3 matrix of [fx 0 cx; 0 fy cy], or 4x1 vector of [fx; fy; cx; cy].
max_iterations: (Optional)
    Maximum number of iterations for the solver. Default: 20.
tolerance: (Optional)
    Tolerance for convergence on normalized coordinates. Default: 1e-8.

OUTPUTS
===============================================================================
distorted_pts:
    Matrix of distorted [x; y] pixel coordinates. Shape matches input.
%}

% Set default values for max_iterations and tolerance if not provided.
if nargin < 3
    error('Need at least 3 inputs: points, dist_coefs, intrinsics.');
end
if nargin < 4
    max_iterations = 20;
end
if nargin < 5
    tolerance = 1e-8;
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

% Handle input points format.
points_across_rows = false;
if size(points, 2) == 2 && size(points,1) ~= 2
    points = points';
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

% Get the current undistorted points.
U_undistorted = points(1, :);
V_undistorted = points(2, :);

% Convert from pixel to normalized camera coordinates.
Xc_init_undistorted_norm = (U_undistorted - cx) / fx;
Yc_init_undistorted_norm = (V_undistorted - cy) / fy;

% Set up the initial estimate for the distorted coordinates as the current
% undistorted coordinates.
Xc_current_distorted_norm = Xc_init_undistorted_norm;
Yc_current_distorted_norm = Yc_init_undistorted_norm;

% Iteratively refine the estimate for the distorted coordinates.
for iter = 1 : max_iterations
    cam_current_l2_norm = Xc_current_distorted_norm.^2 + Yc_current_distorted_norm.^2;
    radial_distortion_factor = 1 + k1 * cam_current_l2_norm + k2 * cam_current_l2_norm.^2;

    % Invert the radial distortion factor as well for the update step. Also add
    % safeguard to avoid NaN/Inf due to near-zero values of the factor.
    radial_distortion_factor_inv = 1 ./ radial_distortion_factor;
    radial_distortion_factor_inv(abs(radial_distortion_factor) < 1e-8) = 1;

    % Compute radial distortion.
    Xc_radial_distortion = Xc_current_distorted_norm .* radial_distortion_factor;
    Yc_radial_distortion = Yc_current_distorted_norm .* radial_distortion_factor;

    % Compute tangential distortion.
    Xc_tangential_distortion = 2 * p1 * Xc_current_distorted_norm .* Yc_current_distorted_norm + p2 * (cam_current_l2_norm + 2 * Xc_current_distorted_norm.^2);
    Yc_tangential_distortion = 2 * p2 * Xc_current_distorted_norm .* Yc_current_distorted_norm + p1 * (cam_current_l2_norm + 2 * Yc_current_distorted_norm.^2);

    % Compute undistorted coordinates from the current distorted coordinates.
    Xc_undistorted_norm = Xc_radial_distortion + Xc_tangential_distortion;
    Yc_undistorted_norm = Yc_radial_distortion + Yc_tangential_distortion;

    % Compute error between target undistorted coordinates and current estimate.
    Xc_delta = Xc_init_undistorted_norm - Xc_undistorted_norm;
    Yc_delta = Yc_init_undistorted_norm - Yc_undistorted_norm;

    % Update the distorted coordinates using the error. This is the fastest and
    % the most accurate update equation from all I checked. Most likely because
    % it linearly models the distortion inverse (subbing the tangential and
    % dividing by the radial, which you'll notice are typically added and
    % multiplied otherwise).
    Xc_current_distorted_norm = (Xc_init_undistorted_norm - Xc_tangential_distortion) .* radial_distortion_factor_inv;
    Yc_current_distorted_norm = (Yc_init_undistorted_norm - Yc_tangential_distortion) .* radial_distortion_factor_inv;

    % OLDER UPDATE STEP
    % Xc_current_undistorted_norm = Xc_current_undistorted_norm + (Xc_delta - Xc_tangential_distortion) .* radial_distortion_factor_inv;
    % Yc_current_undistorted_norm = Yc_current_undistorted_norm + (Yc_delta - Yc_tangential_distortion) .* radial_distortion_factor_inv;

    % Check convergence.
    max_delta = max([abs(Xc_delta(:)); abs(Yc_delta(:))]);
    if max_delta < tolerance
        break;
    end
end

% Warn if convergence wasn't achieved.
if iter == max_iterations && max_delta >= tolerance
    warning('Inversion did not converge within %d iterations. Max error: %.2e', max_iterations, max_delta);
end

% Map distorted normalized coordinates back to pixel coordinates.
U_distorted = Xc_current_distorted_norm * fx + cx;
V_distorted = Yc_current_distorted_norm * fy + cy;

distorted_pts = [U_distorted; V_distorted];

% If points were originally across rows, convert back.
if points_across_rows
    distorted_pts = distorted_pts';
end

end