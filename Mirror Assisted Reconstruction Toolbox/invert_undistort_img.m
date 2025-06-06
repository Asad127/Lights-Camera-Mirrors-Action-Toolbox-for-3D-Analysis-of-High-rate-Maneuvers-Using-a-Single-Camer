function distorted_img = invert_undistort_img(img, dist_coefs, intrinsics, max_iterations, tolerance)
%{
Invert an undistorted image to recover the original distorted image using an
iterative fixed-point algorithm. This function computes distorted image
coordinates such that applying the undistortion transform (with the same
distortion coefficients and intrinsics) to the output distorted image will
recover the input undistorted image.

Effectively computes the inverse map of undistort_img.m.

The main idea is to use the given undistorted image coordinates as the initial
guess for the distorted coordinates, then iteratively refine the guess by
applying the forward undistortion to the estimated distorted coordinates and
comparing the result to the original undistorted coordinates.

INPUTS
===============================================================================
img:
    HxW (grayscale) or HxWxChannels (e.g., RGB) matrix representing the
    undistorted input image.
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
distorted_img:
    HxW or HxWxChannels matrix of the distorted image.

REFERENCES
===============================================================================
- https://stackoverflow.com/a/68706787/23466407
- https://www.mathworks.com/help/visionhdl/ug/image-undistort.html
%}

% Set default values for max_iterations and tolerance if not provided.
if nargin < 3
    error('Need at least 3 inputs: img, dist_coefs, intrinsics.');
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

if ndims(img) < 2 || ndims(img) > 3
    error('img must be HxW (grayscale) or HxWxChannels (e.g., RGB).');
end

% Get image dimensions and determine if grayscale
is_grayscale = ndims(img) == 2;
if is_grayscale
    img = repmat(img, [1, 1, 3]); % Convert to RGB for consistency
end
original_class = class(img);
[H, W, num_channels] = size(img);

% Convert to double for interpolation
if ~isa(img, 'double') && ~isa(img, 'single')
    interpolation_img = double(img);
else
    interpolation_img = img;
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

% Create a grid of pixel coordinates representing the input undistorted image.
[U_undistorted, V_undistorted] = meshgrid(1:W, 1:H);

% Convert the grid of pixel coordinates to normalized camera coordinates.
Xc_init_undistorted_norm = (U_undistorted - cx) / fx;
Yc_init_undistorted_norm = (V_undistorted - cy) / fy;

% Set the initial estimate for the distorted normalized coordinates as the
% undistorted normalized coordinates.
Xc_current_distorted_norm = Xc_init_undistorted_norm;
Yc_current_distorted_norm = Yc_init_undistorted_norm;

% Iteratively refine the estimate for the distorted coordinates.
for iter = 1 : max_iterations
    cam_current_l2_norm = Xc_current_distorted_norm.^2 + Yc_current_distorted_norm.^2;
    radial_distortion_factor = 1 + k1 * cam_current_l2_norm + k2 * cam_current_l2_norm.^2;

    % Invert the radial distortion factor with safeguard to avoid NaN/Inf.
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

% Convert converged distorted normalized coordinates back to pixel coordinates.
U_distorted = Xc_current_distorted_norm * fx + cx;
V_distorted = Yc_current_distorted_norm * fy + cy;

% Interpolate from the input undistorted image.
if is_grayscale
    % For grayscale, interpolate a single channel (since all are the same).
    interpolated_img = interp2( ...
        interpolation_img(:, :, 1), ...
        U_distorted, ...
        V_distorted, ...
        'cubic', ...
        0 ...
    );
    distorted_img = repmat(interpolated_img, [1, 1, 3]);
else
    % For RGB, interpolate each channel separately.
    distorted_img = zeros(H, W, num_channels, 'like', interpolation_img);
    for c = 1 : num_channels
        channel_data = interpolation_img(:, :, c);
        interpolated_channel = interp2( ...
            channel_data, ...
            U_distorted, ...
            V_distorted, ...
            'cubic', ...
            0 ...
        );
        distorted_img(:, :, c) = interpolated_channel;
    end
end

% Cast back to original image type if necessary.
if ~strcmp(class(distorted_img), original_class)
    distorted_img = cast(distorted_img, original_class);
end

% If grayscale, convert back to 2D.
if is_grayscale
    distorted_img = distorted_img(:, :, 1);
end

end