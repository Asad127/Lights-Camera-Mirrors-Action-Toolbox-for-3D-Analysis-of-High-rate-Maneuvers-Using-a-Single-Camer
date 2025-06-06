function distorted_img = distort_img(img, dist_coefs, intrinsics)
%{
Distorts an image using the direct polynomial model for image distortion.

The transformation herein is practically the same as undistort_img.m, but with
distortion being the "forward" map instead of undistortion. That is, `img` is an
UNDISTORTED image (note that if it is a DISTORTED image, this will "double" the
distortion, making its effects more noticeable).

Do not use this like an inverse map to undistort_img.m (i.e., starting from a
DISTORTED MAP, you UNDISTORTED it with undistort_img.m, and are now attempting
to RE-DISTORT it with this function); distortion is non-linear and so it is not
invertible. Please use invert_undistort_img.m for an iterative algorithm that
can handle that scenario and get you the correct distorted points.

INPUTS
===============================================================================
undistorted_image:
    HxWxChannels matrix representing the undistorted image.
dist_coefs:
    1x4 vector of [k1 k2 p1 p2] distortion coefficients.
intrinsics:
    1x4 vector of [fx fy cx cy], or 3x3 matrix of [fx 0 cx; 0 fy cy; 0 0 1], or
    2x3 matrix of [fx 0 cx; 0 fy cy], or 4x1 vector of [fx; fy; cx; cy].

OUTPUTS
===============================================================================
distorted_image: HxWxChannels matrix of the distorted image.

REFERENCES
===============================================================================
- https://www.mathworks.com/help/visionhdl/ug/image-undistort.html
%}

if nargin < 3
    error('Need at least 3 inputs: undistorted_image, dist_coefs, intrinsics.');
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

[H, W, num_channels] = size(img);

% Store original image class for casting back, interp2 needs double/single
original_class = class(img);
if ~isa(img, 'double') && ~isa(img, 'single')
    interpolation_img = double(img);
else
    interpolation_img = img;
end

% Unpack the intrinsic parameters.
fx = intrinsics(1);
fy = intrinsics(2);
cx = intrinsics(3);
cy = intrinsics(4);

% Unpack the distortion coefficients.
k1 = dist_coefs(1);
k2 = dist_coefs(2);
p1 = dist_coefs(3);
p2 = dist_coefs(4);

% Create a grid of pixel coordinates from the input points.
[U_undistorted, V_undistorted] = meshgrid(1:W, 1:H);

% Convert these target distorted pixel coordinates to normalized distorted
% coordinates.
Xc_undistorted_norm = (U_undistorted - cx) / fx;
Yc_undistorted_norm = (V_undistorted - cy) / fy;

% Apply the direct undistortion formulas to find source normalized undistorted
% coordinates.
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

% Convert these normalized undistorted source coordinates back to pixel
% coordinates.
U_distorted = Xc_distorted_norm * fx + cx;
V_distorted = Yc_distorted_norm * fy + cy;

if is_grayscale
    % Handle grayscale image.
    interpolated_channel = interp2( ...
        interpolation_img(:, :, 1), ...
        U_distorted, ...
        V_distorted, ...
        'cubic', ...
        0 ...
    );
    distorted_img = repmat(interpolated_channel, [1, 1, 3]);
else
    % Handle RGB image.
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

% If the input was grayscale, convert the output back to grayscale.
if is_grayscale
    distorted_img = distorted_img(:, :, 1);
end

end