%{
References
----------
1. Procrustes Alignment: https://en.wikipedia.org/wiki/Procrustes_analysis
2. Horn's Absolute Orientation:
    - https://people.csail.mit.edu/bkph/papers/Absolute_Orientation
    - https://www.mathworks.com/matlabcentral/fileexchange/26186-absolute-orientation-horn-s-method
3. Kabsch Algorithm: https://en.wikipedia.org/wiki/Kabsch_algorithm
%}

function registration_params = register_points_3d_procrustes( ...
    points_query, ...
    points_target, ...
    do_scale, ...
    do_translation, ...
    standardize_points, ...
    enforce_valid_rotation, ...
    scale_method ...
)
%{
Register a set of 3D points (query) onto another set of 3D points (target).

The method borrows heavily from Procrustes Analysis, which itself is quite similar to Horn's Quaternion-based method for
Absolute Orientation (it simply does not use quaternions to estimate the rotations). MATLAB has an implementation of the
absor method on File Exchange (FEX) - this gets extremely similar results to that. Empirically based on procrustes.py,
which uses scipy.spatial.procrustes, the results are also similar. However, it should be noted that scipy's procrustes
implementation is primarily orthognal procrustes (it does not allow translation and enforces uniform unity scaling
across both point sets). It's also very barebones compared to FEX, choosing to return just the standardized target
points, the aligned points, and the disparity. This method aims to rectify that.

Parameters
----------
points_query : array_like
    The points to be registered onto target points. Either 3xN or Nx3.
points_target : array_like
    The target points. Either 3xN or Nx3.
do_scale : bool, optional
    If True, scale the points.
do_translation : bool, optional
    If True, translate the points.
standardize_points : bool, optional
    If True, further standardizes the point sets' centroids such that the scales of the two sets are unity, effectively
    removing the effects of scaling.
enforce_valid_rotation : bool, optional
    If True, enforce a valid rotation matrix (i.e., ensure that the determinant = 1). If this is not the case, the
    function will "fix" it by flipping the sign of the last singular vector. If you know that your transformation
    involves something that falsifies this condition (e.g., a permutation transform due to mirror-like reflections),
    set this to False to allow handling such rotations within the SVD. In most cases, it should be left enabled.
scale_method : Literal["trace", "rms"], optional
    The method to use to compute the scaling factor. Ignored if `do_scale` is False.
    - "trace" : Use the trace of the covariance matrix.
    - "rms" : Use the ratio of the RMS deviations. May be more sensitive to outliers.

Returns
-------
RegistrationParams3D
    A struct containing several fields, including registered query points, transformation details, and error metrics.

Notes
-----
At all points other than the computation of translation, the centered points (achieved by subtracting each point set's
points by its centroid) are used. The centroid is simply the mean of the point set across all points in that set.

For standardization, we divide the centered points by the Frobenius norm. The standardized point sets are only used to
compute the rotation. Particularly, the scale is still determined with the non-standardized (centered) points, as
otherwise the scale would be unity by definition.

The scale is computed by rotating the covariance matrix, taking the trace of the result, and dividing by the sum of the
squares of the centered points. Intuitively, this is the ratio of the VARIANCE between the two point sets, with the
trace in the numerator dictating the variance in the "rotated" space (i.e., target space) and the denominator dictating
the variance in the "query" space (i.e., query space). Alternatively, the ratio of the RMS deviations could be used (but
might be more sensitive to outliers).

For translation computation, we use the centroid vector itself (which is within the original, non-centered,
non-standardized coordinate space). Thus, the translation vector is defined in the same space as the input points.
%}

if nargin < 3
    do_scale = true;
end
if nargin < 4
    do_translation = true;
end
if nargin < 5
    standardize_points = true;
end
if nargin < 6
    enforce_valid_rotation = true;
end
if nargin < 7
    scale_method = 'trace';
end

TOLERANCE_NEAR_ZERO = 1e-9;
TOLERANCE_SINGULAR_VALUE_NORM = 0.1;

points_query = double(points_query);
points_target = double(points_target);

% Validate acceptable input shapes.
if ~(size(points_query, 1) == 3 || size(points_query, 2) == 3)
    error('Query points must be 3xN or Nx3.');
end
if ~(size(points_target, 1) == 3 || size(points_target, 2) == 3)
    error('Target points must be 3xN or Nx3.');
end

% Make note of the original input shapes.
output_shape = size(points_query);

% Reshape to 3xN for internal ops.
if size(points_query, 1) ~= 3
    points_query = points_query';
end
if size(points_target, 1) ~= 3
    points_target = points_target';
end

% Ensure the number of points in the two arrays is the same.
if size(points_query, 2) ~= size(points_target, 2)
    error('Query and target point arrays must have the same number of points.');
end

num_points = size(points_query, 2);

% Initialize transformation components to identities.
translation_vector = zeros(3, 1);
scale_factor = 1.0;

% Move all points to the origin by subtracting their centroids. This must be done regardless of whether translation is
% enabled or not as it removes the error introduced by the distance between the two point sets when computing the
% rotation and scale (which are computed prior to translation). When computing translations, we will use the centroids,
% not the centered points to ensure we get a correct translation vector.
centroid_query = mean(points_query, 2);
centroid_target = mean(points_target, 2);

centered_query = points_query - centroid_query;
centered_target = points_target - centroid_target;

% Initialize norms to unity.
norm_query = 1.0;
norm_target = 1.0;
norm_product = 1.0;

if standardize_points
    % Standardize the points by dividing by the Frobenius norm.
    norm_query = norm(centered_query, 'fro');
    norm_target = norm(centered_target, 'fro');
    norm_product = norm_query * norm_target;

    if norm_query > TOLERANCE_NEAR_ZERO && norm_target > TOLERANCE_NEAR_ZERO
        centered_query = centered_query / norm_query;
        centered_target = centered_target / norm_target;
    elseif norm_query < TOLERANCE_NEAR_ZERO
        warning('Query points are degenerate with zero norm, skipping standardization...');
    elseif norm_target < TOLERANCE_NEAR_ZERO
        warning('Target points are degenerate with zero norm, skipping standardization...');
    end
end

% Compute covariance matrix between axes. This should be 3x3 regardless of the input shapes. We also want the rotation
% to take us from the query set to the target set without any scaling effect, so we use divide by the combined norm
% (norm_query and norm_target would essentially be multiplied to get the combined norm).
covariance_matrix = (centered_query * centered_target') / norm_product;

% Singular Value Decomposition on the covariance matrix to estimate the rotation matrix. Typically, with the covariance
% matrix, we'd recover R from U@S@V.T as R = V @ U.T, but we avoid doing two transposes and just transpose the
% covariance matrix once, thus turning our solution into R = (V @ U.T).T = U @ V.T. svd directly gets us this format for
% U and V.T, so nothing else needs to be done.
[u, s, v] = svd(covariance_matrix');
s = diag(s);
if abs(1.0 - sum(s)) > TOLERANCE_SINGULAR_VALUE_NORM
    if ~do_scale
        warning(['Singular values sum to %f, which is off from 1.0 by %f, which is greater than the ', ...
            'provided threshold of %f for rigid transformation - most likely there is some non-unity ', ...
            'scale involved in the transformation. Consider enabling do_scale to solve for scaling ', ...
            'and estimate a similarity transformation instead.'], ...
            sum(s), 1.0 - sum(s), TOLERANCE_SINGULAR_VALUE_NORM ...
        );
    end
end
rotation_matrix = u * v';

if det(rotation_matrix) < 0 && enforce_valid_rotation
    % Ensure proper rotation (determinant = 1).
    fprintf('Rotation matrix determinant is negative, fixing (flipping last singular vector)...\n');
    v(:, end) = -v(:, end);
    rotation_matrix = u * v';
end

if do_scale
    % NOTE: Ensure the points used here are the non-standardized ones, as the standardized ones will have unit scale. To
    % unstandardize, MULTIPLY by the norm.
    sum_squares_query = sum((centered_query * norm_query).^2, "all");
    sum_squares_target = sum((centered_target * norm_target).^2, "all");

    if sum_squares_query < TOLERANCE_NEAR_ZERO || sum_squares_target < TOLERANCE_NEAR_ZERO
        fprintf('Query or target points are degenerate with zero norm, setting scale factor to 1.0...\n');
        scale_factor = 1.0;
    elseif strcmp(scale_method, 'rms')
        % Compute the scaling factor using the ratio of target-to-query point-to-point RMS deviations.
        mean_sum_squares_query = sum_squares_query / num_points;
        mean_sum_squares_target = sum_squares_target / num_points;
        scale_factor = sqrt(mean_sum_squares_target / mean_sum_squares_query);
    elseif strcmp(scale_method, 'trace')
        % Divide the trace of the product of the rotated covariance matrix by the sum of the squares of the centered
        % points. To unstandardize the trace here, since we're using a potentially standardized rotation and covariance
        % matrix from our rotation computation earlier, we multiply by the norm product squared to unstandardize the
        % trace. See docstring notes for intuition.
        trace_covariance = trace(rotation_matrix * covariance_matrix) * norm_product^2;
        scale_factor = trace_covariance / sum_squares_query;
    end
end

scaled_rotation_matrix = scale_factor * rotation_matrix;

if do_translation
    % Compute translation vector. by first scale-rotating the centroid of the query points to the target centroid's
    % space, then subtracting the transformed query centroid from the target centroid.
    translation_vector = centroid_target - scaled_rotation_matrix * centroid_query;
end

% Construct the 3x4 homogeneous transformation matrix.
homogenous_transformation_matrix = [scaled_rotation_matrix, translation_vector];

% Construct the 4xN homogenous query points.
homogenous_query_points = [points_query; ones(1, num_points)];

% Register the query points on top of the target points.
registered_query_points = homogenous_transformation_matrix * homogenous_query_points;
if ~isequal(size(registered_query_points), output_shape)
    registered_query_points = reshape(registered_query_points, output_shape);
end

% Compute error metrics.
metrics = RegistrationMetrics3d(registered_query_points, points_target);

% Create RegistrationTransform3d object.
transform = RegistrationTransform3d;
transform.transformation_matrix = homogenous_transformation_matrix;
transform.rotation_matrix = rotation_matrix;
transform.translation_vector = translation_vector;
transform.scale_factor = scale_factor;

% Create RegistrationParams3d object.
registration_params = RegistrationParams3d;
registration_params.registered_query_points = registered_query_points;
registration_params.transform = transform;
registration_params.metrics = metrics;

end