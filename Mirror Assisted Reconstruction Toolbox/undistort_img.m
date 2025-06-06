function undistorted_img = undistort_img(img, dist_coefs, intrinsics)
%{
Undistort an image using the direct polynomial model for image distortion.

The transformation herein is practically the same as distort_img.m, but with
undistortion being the "forward" map instead of distortion. That is, `img` is a
DISTORTED image (note that if this is an undistorted image, this function will
effectively distort it).

Do not use this like an inverse map to distort_img.m (i.e., starting from a
DISTORTED MAP, you UNDISTORTED it with undistort_img.m, and are now attempting
to RE-DISTORT it with this function); distortion is non-linear and so it is not
invertible. Please use invert_distort_img.m for an iterative algorithm that can
handle that scenario and get you the correct distorted points.

INPUTS
===============================================================================
img:
    HxW (grayscale) or HxWx3 (RGB) matrix representing the distorted image.
dist_coefs:
    1x4 vector of [k1 k2 p1 p2] distortion coefficients.
intrinsics:
    1x4 vector of [fx fy cx cy], or 3x3 matrix of [fx 0 cx; 0 fy cy; 0 0 1], or
    2x3 matrix of [fx 0 cx; 0 fy cy], or 4x1 vector of [fx; fy; cx; cy].

OUTPUTS
===============================================================================
undistorted_img:
    HxW (grayscale) or HxWx3 (RGB) matrix matching the input.

REFERENCE
===============================================================================
- https://www.mathworks.com/help/visionhdl/ug/image-undistort.html
%}

if nargin < 3
    error('Need at least 3 inputs: img, dist_coefs, intrinsics.');
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

is_grayscale = ndims(img) == 2;
if is_grayscale
    % Temporarily convert to RGB.
    img = repmat(img, [1, 1, 3]);
end
% We don't need num_channels in this case.
[H, W, ~] = size(img);

% Store original image class for casting back, interp2 needs double/single.
original_class = class(img);
if ~isa(img, 'double') && ~isa(img, 'single')
    interpolation_img = double(img);
else
    interpolation_img = img;
end

% Unpack the intrinsic camera parameters.
fx = intrinsics(1);
fy = intrinsics(2);
cx = intrinsics(3);
cy = intrinsics(4);

% Unpack the distortion coefficients.
k1 = dist_coefs(1);
k2 = dist_coefs(2);
p1 = dist_coefs(3);
p2 = dist_coefs(4);

% Generate img pixel grid for the undistorted img.
[U_distorted, V_distorted] = meshgrid(1:W, 1:H);

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

% Undistort points in cam coords (add the radial and tangential distortion).
Xc_undistorted_norm = Xc_radial_distortion + Xc_tangential_distortion;
Yc_undistorted_norm = Yc_radial_distortion + Yc_tangential_distortion;

% Map undistorted camera coordinates to img coordinates from earlier.
U_undistorted = Xc_undistorted_norm * fx + cx;
V_undistorted = Yc_undistorted_norm * fy + cy;

% Interpolate the img using the undistorted pixel coordinates. This accounts for
% the floating values that appear post-undistortion. interp2 requires either
% single or double precision floats for operation, so we temporarily convert
% type of the img.
if is_grayscale
    % Image is grayscale.
    interpolated_channel = interp2( ...
        interpolation_img(:, :, 1), ...
        U_undistorted, ...
        V_undistorted, ...
        'cubic', ...
        0 ...
    );
    undistorted_img = repmat(interpolated_channel, [1, 1, 3]);
else
    % Handle RGB image.
    undistorted_img = zeros(H, W, num_channels, 'like', interpolation_img);
    for c = 1 : num_channels
        channel_data = interpolation_img(:, :, c);
        interpolated_channel = interp2( ...
            channel_data, ...
            U_undistorted,  ...
            V_undistorted, ...
            'cubic', ...
            0 ...
        );
        undistorted_img(:, :, c) = interpolated_channel;
    end
end

% Cast back to original image type if necessary.
if ~strcmp(class(undistorted_img), original_class)
    undistorted_img = cast(undistorted_img, original_class);
end

if is_grayscale
    undistorted_img = undistorted_img(:, :, 1);
end

% NOTE:  We don't need the 5 argument variant of interp2 since our sample and
% query grids are the same and we are undistorting the whole image. We can use
% the 5 argument variant with required adjustments if we need to undistort only
% part of the image. Don't crop the image to the region you want to undistort
% first, that would result in the wrong image.
end