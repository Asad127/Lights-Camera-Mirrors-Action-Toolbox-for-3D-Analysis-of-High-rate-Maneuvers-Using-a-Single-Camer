%{
References
----------
1. Procrustes Alignment: https://en.wikipedia.org/wiki/Procrustes_analysis
2. Horn's Absolute Orientation:
    - https://people.csail.mit.edu/bkph/papers/Absolute_Orientation
    - https://www.mathworks.com/matlabcentral/fileexchange/26186-absolute-orientation-horn-s-method
3. Kabsch Algorithm: https://en.wikipedia.org/wiki/Kabsch_algorithm
%}

function registration_params = register_points_3d_horn( ...
    points_query, points_target, do_scale, do_translation, enforce_valid_rotation ...
)
%{
Register a set of 3D points (query) onto another set of 3D points (target).

Based on Horn's absolute orientation method (absor.m on MATLAB File Exchange).

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
enforce_valid_rotation : bool, optional
    If True, enforce a valid rotation matrix (i.e., ensure that the determinant = 1). This is done by choosing the
    maximum POSITIVE eigenvalue. If no positive eigenvalue is available, the maximum of the ABSOLUTE eignevalues is
    chosen (this could be a negative one, corresponding to permutation/reflection transformations). In most cases,
    this constraint should be enforced (set to True), but if you know your transformation falsifies this, set it to
    False.

Returns
-------
RegistrationParams3D
    A struct containing several fields, including the registered query points, the transformation details, and the
    error metrics.

Notes
-----
At all points other than the computation of translation, the centered points (achieved by subtracting each point
set's points by its centroid) are used. The centroid is simply the mean of the point set across all points in that
set.

The scale is computed by rotating the covariance matrix, taking the trace of the result, and dividing by the sum of
the squares of the centered points. Intuitively, this is the ratio of the VARIANCE between the two point sets, with
the trace in the numerator dictating the variance in the "rotated" space (i.e., target space) and the denominator
dictating the variance in the "query" space (i.e., query space).

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
    enforce_valid_rotation = true;
end
TOLERANCE_NEAR_ZERO = 1e-9;

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

% Compute covariance matrix between axes. This should be 3x3 regardless of the input shapes. We also want the rotation
% to take us from the query set to the target set without any scaling effect, so we use divide by the combined norm
% (norm_query and norm_target would essentially be multiplied to get the combined norm).
covariance_matrix = centered_query * centered_target';

% Terms from the covariance matrix (extract in row-major order ; MATLAB defaults to column-major).
S = reshape(covariance_matrix', [], 1);
Sxx = S(1); Sxy = S(2); Sxz = S(3);
Syx = S(4); Syy = S(5); Syz = S(6);
Szx = S(7); Szy = S(8); Szz = S(9);

% The symmetric 4x4 matrix N_q in Horn's paper, representing the quaternions.
N_q = [
    Sxx + Syy + Szz,          Syz - Szy,           Szx - Sxz,           Sxy - Syx; ...
          Syz - Szy,    Sxx - Syy - Szz,           Sxy + Syx,           Szx + Sxz; ...
          Szx - Sxz,          Sxy + Syx,    -Sxx + Syy - Szz,           Syz + Szy; ...
          Sxy - Syx,          Szx + Sxz,           Syz + Szy,    -Sxx - Syy + Szz ...
];

% Eigenvector corresponding to the largest positive eigenvalue is the optimal quaternion.
[eigenvectors, eigenvalues] = eig(N_q);
eigenvalues = diag(eigenvalues);
is_reflection = false;

if enforce_valid_rotation
    % Find the index of the largest positive eigenvalue.
    [~, max_eigenvalue_index] = max(eigenvalues);
    % If the largest eigenvalue is negative, then find the largest absolute eigenvalue.
    if eigenvalues(max_eigenvalue_index) < 0
        is_reflection = true;
        % Find the largest absolute eigenvalue.
        [~, max_eigenvalue_index] = max(abs(eigenvalues));
        warning(['Largest eigenvalue is negative. This means you have a reflection transformation and should consider ' ...
            'setting `enforce_valid_rotation` to false. We will look for the largest absolute eigenvalue and flip its ' ...
            'sign for now...'] ...
        );
    end
else
    % Find the index of the eigenvalue with largest magnitude.
    [~, max_eigenvalue_index] = max(abs(eigenvalues));
    if eigenvalues(max_eigenvalue_index) < 0
        is_reflection = true;
        warning('Largest eigenvalue is negative. This means you have a reflection transformation.');
    end
end

% Extract the optimal quaternion.
optimal_quaternion = eigenvectors(:, max_eigenvalue_index);

% Convert quaternion to rotation matrix.
q0 = optimal_quaternion(1);
q1 = optimal_quaternion(2);
q2 = optimal_quaternion(3);
q3 = optimal_quaternion(4);

rotation_matrix = [...
    q0^2 + q1^2 - q2^2 - q3^2,      2 * (q1 * q2 - q0 * q3),      2 * (q1 * q3 + q0 * q2); ...
      2 * (q1 * q2 + q0 * q3),    q0^2 - q1^2 + q2^2 - q3^2,      2 * (q2 * q3 - q0 * q1); ...
      2 * (q1 * q3 - q0 * q2),      2 * (q2 * q3 + q0 * q1),    q0^2 - q1^2 - q2^2 + q3^2 ...
];

if is_reflection && ~enforce_valid_rotation
    rotation_matrix = -rotation_matrix;
elseif is_reflection && enforce_valid_rotation
    % Double check the determinant of rotation matrix == 1. If not, flip it.
    if 1 - det(rotation_matrix) > 1e-6
        rotation_matrix = -rotation_matrix;
    end
end

if do_scale
    % NOTE: Ensure the points used here are the non-standardized ones, as the standardized ones will have unit scale. To
    % unstandardize, MULTIPLY by the norm.
    sum_squares_query = sum(centered_query.^2, 'all');
    sum_squares_target = sum(centered_target.^2, 'all');

    if sum_squares_query < TOLERANCE_NEAR_ZERO || sum_squares_target < TOLERANCE_NEAR_ZERO
        fprintf('Query or target points are degenerate with zero norm, setting scale factor to 1.0...\n');
        scale_factor = 1.0;
    else
        % Divide the trace of the product of the rotated covariance matrix by the sum of the squares of the centered
        % points. To unstandardize the trace here, since we're using a potentially standardized rotation and covariance
        % matrix from our rotation computation earlier, we multiply by the norm product squared to unstandardize the
        % trace. See docstring notes for intuition.
        trace_covariance = trace(rotation_matrix * covariance_matrix);
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