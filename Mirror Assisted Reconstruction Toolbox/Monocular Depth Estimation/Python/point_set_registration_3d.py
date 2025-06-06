"""
References
----------
1. Procrustes Alignment: https://en.wikipedia.org/wiki/Procrustes_analysis
2. Horn's Absolute Orientation:
    - https://people.csail.mit.edu/bkph/papers/Absolute_Orientation
    - https://www.mathworks.com/matlabcentral/fileexchange/26186-absolute-orientation-horn-s-method
3. Kabsch Algorithm: https://en.wikipedia.org/wiki/Kabsch_algorithm
"""

from typing import Literal, NamedTuple, Self
from warnings import warn

import matplotlib.pyplot as plt
import numpy as np

np.set_printoptions(suppress=True)


class RegistrationMetrics3d:
    """Error metrics between the registered query points and the target points.

    Attributes:
        max_error (float): Maximum squared Euclidean distance between corresponding points. lse_error (float): Least
        squares error (sum of squared Euclidean distances). mse_error (float): Mean squared error (LSE divided by number
        of points). rms_error (float): Root mean square error (square root of MSE).
    """

    max_error: float
    """Maximum squared Euclidean distance between corresponding points."""
    lse_error: float
    """Least squares error (sum of squared Euclidean distances)."""
    mse_error: float
    """Mean squared error (LSE divided by number of points)."""
    rms_error: float
    """Root mean square error (square root of MSE)."""

    def __init__(self, registered_query_points: np.ndarray, points_target: np.ndarray):
        self.__call__(registered_query_points, points_target)

    def __call__(self, registered_query_points: np.ndarray, points_target: np.ndarray) -> Self:
        self.max_error, self.lse_error, self.mse_error, self.rms_error = self.compute_metrics(
            registered_query_points, points_target
        )
        return self

    @staticmethod
    def compute_metrics(
        registered_query_points: np.ndarray, points_target: np.ndarray
    ) -> tuple[float, float, float, float]:
        """
        Compute error metrics between registered query points and target points.

        Parameters
        ----------
        registered_query_points : np.ndarray
            Aligned query points, shape (3, N) or (N, 3).
        points_target : np.ndarray
            Target points, shape (3, N) or (N, 3).

        Returns
        -------
            tuple[float, float, float, float]
                A tuple containing the maximum error, least squares error, mean squared error, and root mean squared
                error in that order.
        """
        # Ensure arrays have the same shape.
        if registered_query_points.shape != points_target.shape:
            raise ValueError("Point sets must have the same shape.")

        # Reshape to (3, N).
        if points_target.shape[0] != 3 and points_target.shape[1] != 3:
            raise ValueError("Target points must be 3xN or Nx3.")
        elif registered_query_points.shape[0] != 3 and registered_query_points.shape[1] != 3:
            raise ValueError("Query points must be 3xN or Nx3.")
        elif registered_query_points.shape[0] != 3 and registered_query_points.shape[1] == 3:
            # (N, 3) -> (3, N)
            registered_query_points = registered_query_points.T
            points_target = points_target.T

        # Compute the difference between the registered query points and the target points.
        differences = registered_query_points - points_target
        num_points = differences.shape[1]

        # Compute the squared Euclidean distances for each point (sum over x, y, z).
        squared_distances = np.sum(differences**2, axis=0)

        # Compute metrics.
        max_error = np.max(squared_distances)
        lse_error = np.sum(squared_distances)
        mse_error = lse_error / num_points
        rms_error = np.sqrt(mse_error)

        return max_error, lse_error, mse_error, rms_error

    def get_metrics_as_dict(self) -> dict[str, float]:
        """
        Return metrics as a dictionary.

        Returns
        -------
            dict[str, float]: Dictionary containing 'max_error', 'lse_error', 'mse_error', and 'rms_error'.
        """
        return {
            "max_error": self.max_error,
            "lse_error": self.lse_error,
            "mse_error": self.mse_error,
            "rms_error": self.rms_error,
        }


class RegistrationTransform3d(NamedTuple):
    """
    The rigid (if scaling disabled) or similarity (if scaling enabled) transformation that maps the query points onto
    the target points.
    """

    transformation_matrix: np.ndarray
    """The 3x4 homogeneous transformation matrix that maps the query points onto the target points."""
    rotation_matrix: np.ndarray
    """The 3x3 rotation matrix that maps the query points onto the target points."""
    translation_vector: np.ndarray
    """The 3x1 translation vector that maps the query points onto the target points."""
    scale_factor: float
    """The scalar scaling factor that maps the query points onto the target points."""


class RegistrationParams3d(NamedTuple):
    """Result of 3D registration."""

    registered_query_points: np.ndarray
    """Original query points, registered onto the target points."""
    transform: RegistrationTransform3d
    """Transform mapping the query points onto the target points."""
    metrics: RegistrationMetrics3d
    """Error metrics between the registered query points and the target points."""


def register_points_3d_horn(
    points_query: np.ndarray,
    points_target: np.ndarray,
    do_scale: bool = True,
    do_translation: bool = True,
    enforce_valid_rotation: bool = True,
) -> RegistrationParams3d:
    """
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
        maximum POSITIVE eigenvalue. If this is False, the maximum of the ABSOLUTE eignevalues is chosen (this could be
        a negative one, corresponding to permutation/reflection transformations. In most cases, this constraint should
        be enforced (set to True), but if you know your transformation falsifies this, set it to False.

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
    """
    TOLERANCE_NEAR_ZERO = 1e-9

    points_query = np.asarray(points_query, dtype=np.float64, copy=True)
    points_target = np.asarray(points_target, dtype=np.float64, copy=True)

    # Validate acceptable input shapes.
    if points_query.shape[0] != 3 and points_query.shape[1] != 3:
        raise ValueError("Query points must be 3xN or Nx3.")
    if points_target.shape[0] != 3 and points_target.shape[1] != 3:
        raise ValueError("Target points must be 3xN or Nx3.")

    # Make note of the original input shapes.
    output_shape = points_query.shape

    # Reshape to 3xN for internal ops.
    if points_query.shape[0] != 3:
        points_query = points_query.T
    if points_target.shape[0] != 3:
        points_target = points_target.T

    # Ensure the number of points in the two arrays is the same.
    if points_query.shape[1] != points_target.shape[1]:
        raise ValueError("Query and target point arrays must have the same number of points.")

    num_points = points_query.shape[1]

    # Initialize transformation components to identities.
    rotation_matrix = np.eye(3)
    translation_vector = np.zeros((3, 1))
    scale_factor = 1.0

    # Move all points to the origin by subtracting their centroids. This must be done regardless of whether translation
    # is enabled or not as it removes the error introduced by the distance between the two point sets when computing the
    # rotation and scale (which are computed prior to translation). When computing translations, we will use the
    # centroids, not the centered points to ensure we get a correct translation vector.
    centroid_query: np.ndarray = np.mean(points_query, axis=1, keepdims=True)
    centroid_target: np.ndarray = np.mean(points_target, axis=1, keepdims=True)

    centered_query = points_query - centroid_query
    centered_target = points_target - centroid_target

    # Compute covariance matrix between axes. This should be 3x3 regardless of the input shapes. We also want the
    # rotation to take us from the query set to the target set without any scaling effect, so we use divide by the
    # combined norm (norm_query and norm_target would essentially be multiplied to get the combined norm).
    covariance_matrix = centered_query @ centered_target.T

    # Terms from the covariance matrix in row-major order.
    Sxx, Sxy, Sxz, Syx, Syy, Syz, Szx, Szy, Szz = covariance_matrix.flatten("C")

    # The symmetric 4x4 matrix N_q in Horn's paper, representing the quaternions.

    # fmt: off
    N_q = np.array([
        [Sxx + Syy + Szz,          Syz - Szy,           Szx - Sxz,           Sxy - Syx],
        [      Syz - Szy,    Sxx - Syy - Szz,           Sxy + Syx,           Szx + Sxz],
        [      Szx - Sxz,          Sxy + Syx,    -Sxx + Syy - Szz,           Syz + Szy],
        [      Sxy - Syx,          Szx + Sxz,           Syz + Szy,    -Sxx - Syy + Szz],
    ])
    # fmt: on

    # Eigenvector corresponding to the largest positive eigenvalue is the optimal quaternion. Eigenvectors are columns
    # in 'eigenvectors'.
    eigenvalues, eigenvectors = np.linalg.eig(N_q)
    is_reflection = False
    if enforce_valid_rotation:
        # Find the index of the largest positive eigenvalue.
        max_eigenvalue_index = np.argmax(eigenvalues)

        # If the largest eigenvalue is negative: get the largest absolute eigenvalue instead as a final resort.
        if eigenvalues[max_eigenvalue_index] < 0:
            is_reflection = True
            max_eigenvalue_index = np.argmax(np.abs(eigenvalues))
            warn(
                "Largest eigenvalue is negative. This means you have a reflection transformation and should consider"
                " setting `enforce_valid_rotation` to false. For now, we will keep the eigenvector with the largest"
                " eigenvalue."
            )

    if not enforce_valid_rotation:
        max_eigenvalue_index = np.argmax(np.abs(eigenvalues))
        if eigenvalues[max_eigenvalue_index] < 0:
            is_reflection = True
            warn("Largest absolute eigenvalue has a negative value. This means you have a reflection transformation.")

    # Extract the optimal quaternion. This is in format q = [q0, q1, q2, q3] (scalar-first).
    optimal_quaternion = eigenvectors[:, max_eigenvalue_index]

    # Convert quaternion to rotation matrix. Eigenvectors from np.linalg.eig are already unit norm.
    q0, q1, q2, q3 = optimal_quaternion[0], optimal_quaternion[1], optimal_quaternion[2], optimal_quaternion[3]

    # Convert the quaternion to a rotation matrix. This matrix guaranteed to be a valid rotation matrix.

    # fmt: off
    rotation_matrix = np.array([
        [q0**2 + q1**2 - q2**2 - q3**2,          2 * (q1 * q2 - q0 * q3),          2 * (q1 * q3 + q0 * q2)],
        [      2 * (q1 * q2 + q0 * q3),    q0**2 - q1**2 + q2**2 - q3**2,          2 * (q2 * q3 - q0 * q1)],
        [      2 * (q1 * q3 - q0 * q2),          2 * (q2 * q3 + q0 * q1),    q0**2 - q1**2 - q2**2 + q3**2],
    ])
    # fmt: on

    if is_reflection and not enforce_valid_rotation:
        rotation_matrix = -1.0 * rotation_matrix

    if do_scale:
        # NOTE: Ensure the points used here are the non-standardized ones, as the standardized ones will have unit
        # scale. To unstandardize, MULTIPLY by the norm.

        # Normalization terms (non-standardized).
        sum_squares_query = np.sum(centered_query**2)
        sum_squares_target = np.sum(centered_target**2)

        if sum_squares_query < TOLERANCE_NEAR_ZERO or sum_squares_target < TOLERANCE_NEAR_ZERO:
            print("Query or target points are degenerate with zero norm, setting scale factor to 1.0...")
            scale_factor = 1.0
        else:
            # Divide the trace of the rotated covariance matrix by the sum of the squares of the centered points. See
            # docstring notes for intuition.
            trace_covariance = np.trace(rotation_matrix @ covariance_matrix)
            scale_factor = trace_covariance / sum_squares_query

    scaled_rotation_matrix = scale_factor * rotation_matrix

    if do_translation:
        # Compute translation vector. by first scale-rotating the centroid of the query points to the target centroid's
        # space, then subtracting the transformed query centroid from the target centroid.
        translation_vector = centroid_target - scaled_rotation_matrix @ centroid_query

    # Construct the 3x4 homogeneous transformation matrix.
    homogenous_transformation_matrix = np.column_stack((scaled_rotation_matrix, translation_vector))

    # Construct the 4xN homogenous query points.
    homogenous_query_points = np.vstack((points_query, np.ones(num_points)))

    # Register the query points on top of the target points using the estimated transform. Here, we will use the actual
    # points provided and not the center-transformed ones. The resulting shape is 3xN.
    registered_query_points: np.ndarray = homogenous_transformation_matrix @ homogenous_query_points
    if not registered_query_points.shape == output_shape:
        registered_query_points = registered_query_points.reshape(output_shape)

    # Compute error metrics.
    metrics = RegistrationMetrics3d(registered_query_points, points_target)

    registration_params_3d = RegistrationParams3d(
        registered_query_points=registered_query_points,
        transform=RegistrationTransform3d(
            transformation_matrix=homogenous_transformation_matrix,
            rotation_matrix=rotation_matrix,
            translation_vector=translation_vector,
            scale_factor=scale_factor,
        ),
        metrics=metrics,
    )

    return registration_params_3d


def register_points_3d_procrustes(
    points_query: np.ndarray,
    points_target: np.ndarray,
    do_scale: bool = True,
    do_translation: bool = True,
    standardize_points: bool = True,
    enforce_valid_rotation: bool = True,
    scale_method: Literal["trace", "rms"] = "trace",
) -> RegistrationParams3d:
    """
    Register a set of 3D points (query) onto another set of 3D points (target).

    The method borrows heavily from Procrustes Analysis, which itself is quite similar to Horn's Quaternion-based method
    for Absolute Orientation (it simply does not use quaternions to estimate the rotations). MATLAB has an
    implementation of the absor method on File Exchange (FEX) - this gets extremely similar results to that. Empirically
    based on procrustes.py, which uses scipy.spatial.procrustes, the results are also similar. However, it should be
    noted that scipy's procrustes implementation is primarily orthognal procrustes (it does not allow translation and
    enforces uniform unity scaling across both point sets). It's also very barebones compared to FEX, choosing to return
    just the standardized target points, the aligned points, and the disparity. This method aims to rectify that.

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
        If True, further standardizes the point sets' centroids such that the scales of the two sets are unity,
        effectively removing the effects of scaling.
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
        A struct containing several fields, including the registered query points, the transformation details, and the
        error metrics.

    Notes
    -----
    At all points other than the computation of translation, the centered points (achieved by subtracting each point
    set's points by its centroid) are used. The centroid is simply the mean of the point set across all points in that
    set.

    For standardization, we divide the centered points by the Frobenius norm. The standardized point sets are only used
    to compute the rotation. Particularly, the scale is still determined with the non-standardized (centered) points, as
    otherwise the scale would be unity by definition.

    The scale is computed by rotating the covariance matrix, taking the trace of the result, and dividing by the sum of
    the squares of the centered points. Intuitively, this is the ratio of the VARIANCE between the two point sets, with
    the trace in the numerator dictating the variance in the "rotated" space (i.e., target space) and the denominator
    dictating the variance in the "query" space (i.e., query space). Alternatively, the ratio of the RMS deviations
    could be used (but might be more sensitive to outliers).

    For translation computation, we use the centroid vector itself (which is within the original, non-centered,
    non-standardized coordinate space). Thus, the translation vector is defined in the same space as the input points.
    """
    TOLERANCE_NEAR_ZERO = 1e-9
    TOLERANCE_SINGULAR_VALUE_NORM = 0.1

    points_query = np.asarray(points_query, dtype=np.float64, copy=True)
    points_target = np.asarray(points_target, dtype=np.float64, copy=True)

    # Validate acceptable input shapes.
    if points_query.shape[0] != 3 and points_query.shape[1] != 3:
        raise ValueError("Query points must be 3xN or Nx3.")
    if points_target.shape[0] != 3 and points_target.shape[1] != 3:
        raise ValueError("Target points must be 3xN or Nx3.")

    # Make note of the original input shapes.
    output_shape = points_query.shape

    # Reshape to 3xN for internal ops.
    if points_query.shape[0] != 3:
        points_query = points_query.T
    if points_target.shape[0] != 3:
        points_target = points_target.T

    # Ensure the number of points in the two arrays is the same.
    if points_query.shape[1] != points_target.shape[1]:
        raise ValueError("Query and target point arrays must have the same number of points.")

    num_points = points_query.shape[1]

    # Initialize transformation components to identities.
    rotation_matrix = np.eye(3)
    translation_vector = np.zeros((3, 1))
    scale_factor = 1.0

    # Move all points to the origin by subtracting their centroids. This must be done regardless of whether translation
    # is enabled or not as it removes the error introduced by the distance between the two point sets when computing the
    # rotation and scale (which are computed prior to translation). When computing translations, we will use the
    # centroids, not the centered points to ensure we get a correct translation vector.
    centroid_query: np.ndarray = np.mean(points_query, axis=1, keepdims=True)
    centroid_target: np.ndarray = np.mean(points_target, axis=1, keepdims=True)

    centered_query = points_query - centroid_query
    centered_target = points_target - centroid_target

    # Initialize norms to unity so they have no effect if standardization is not performed. This is more memory
    # efficient than maintaining separate copies of standardized/non-standardized points.
    norm_query = 1.0
    norm_target = 1.0
    norm_product = 1.0

    if standardize_points:
        # Standardize the points by dividing by the Frobenius norm.
        norm_query = np.linalg.norm(centered_query, ord="fro")
        norm_target = np.linalg.norm(centered_target, ord="fro")
        norm_product = norm_query * norm_target

        if norm_query > TOLERANCE_NEAR_ZERO and norm_target > TOLERANCE_NEAR_ZERO:
            centered_query /= norm_query
            centered_target /= norm_target

        elif norm_query < TOLERANCE_NEAR_ZERO:
            warn("Query points are degenerate with zero norm, skipping standardization...")

        elif norm_target < TOLERANCE_NEAR_ZERO:
            warn("Target points are degenerate with zero norm, skipping standardization...")

    # Compute covariance matrix between axes. This should be 3x3 regardless of the input shapes. We also want the
    # rotation to take us from the query set to the target set without any scaling effect, so we use divide by the
    # combined norm (norm_query and norm_target would essentially be multiplied to get the combined norm).
    covariance_matrix = (centered_query @ centered_target.T) / norm_product

    # Singular Value Decomposition on the covariance matrix to estimate the rotation matrix. Typically, with the
    # covariance matrix, we'd recover R from U@S@V.T as R = V @ U.T, but we avoid doing two transposes and just
    # transpose the covariance matrix once, thus turning our solution into R = (V @ U.T).T = U @ V.T. svd directly gets
    # us this format for U and V.T, so nothing else needs to be done.
    u, s, vt = np.linalg.svd(covariance_matrix.T)
    if abs(1.0 - s.sum()) > TOLERANCE_SINGULAR_VALUE_NORM:
        if not do_scale:
            warn(
                f"Singular values sum to {s.sum()}, which is off from 1.0 by {1.0 - s.sum()}, which is greater than the"
                f" provided threshold of {TOLERANCE_SINGULAR_VALUE_NORM} for rigid transformation - most likely there"
                " is some non-unity scale involved in the transformation. Consider enabling `do_scale` to solve for"
                " scaling and estimate a similarity transformation instead."
            )
    rotation_matrix = u @ vt

    if np.linalg.det(rotation_matrix) < 0 and enforce_valid_rotation:
        # Ensure proper rotation (determinant = 1).
        print("Rotation matrix determinant is negative, fixing (flipping last singular vector)...")
        vt[-1, :] *= -1
        rotation_matrix = u @ vt

    if do_scale:
        # NOTE: Ensure the points used here are the non-standardized ones, as the standardized ones will have unit
        # scale. To unstandardize, MULTIPLY by the norm.

        # Normalization terms (unstandardized).
        sum_squares_query = np.sum((centered_query * norm_query) ** 2)
        sum_squares_target = np.sum((centered_target * norm_target) ** 2)

        if sum_squares_query < TOLERANCE_NEAR_ZERO or sum_squares_target < TOLERANCE_NEAR_ZERO:
            print("Query or target points are degenerate with zero norm, setting scale factor to 1.0...")
            scale_factor = 1.0

        elif scale_method == "rms":
            # Compute the scaling factor using the ratio of target-to-query point-to-point RMS deviations.
            mean_sum_squares_query = sum_squares_query / num_points
            mean_sum_squares_target = sum_squares_target / num_points
            scale_factor = np.sqrt(mean_sum_squares_target / mean_sum_squares_query)

        elif scale_method == "trace":
            # Divide the trace of the product of the rotated covariance matrix by the sum of the squares of the centered
            # points. To unstandardize the trace here, since we're using a potentially standardized rotation and
            # covariance matrix from our rotation computation earlier, we multiply by the norm product squared to
            # unstandardize the trace. See docstring notes for intuition.
            trace_covariance = np.trace(rotation_matrix @ covariance_matrix) * norm_product**2
            scale_factor = trace_covariance / sum_squares_query

    scaled_rotation_matrix = scale_factor * rotation_matrix

    if do_translation:
        # Compute translation vector. by first scale-rotating the centroid of the query points to the target centroid's
        # space, then subtracting the transformed query centroid from the target centroid.
        translation_vector = centroid_target - scaled_rotation_matrix @ centroid_query

    # Construct the 3x4 homogeneous transformation matrix.
    homogenous_transformation_matrix = np.column_stack((scaled_rotation_matrix, translation_vector))

    # Construct the 4xN homogenous query points.
    homogenous_query_points = np.vstack((points_query, np.ones(num_points)))

    # Register the query points on top of the target points using the estimated transform. Here, we will use the actual
    # points provided and not the center-transformed ones. The resulting shape is 3xN.
    registered_query_points: np.ndarray = homogenous_transformation_matrix @ homogenous_query_points
    if not registered_query_points.shape == output_shape:
        registered_query_points = registered_query_points.reshape(output_shape)

    # Compute error metrics.
    metrics = RegistrationMetrics3d(registered_query_points, points_target)

    registration_params_3d = RegistrationParams3d(
        registered_query_points=registered_query_points,
        transform=RegistrationTransform3d(
            transformation_matrix=homogenous_transformation_matrix,
            rotation_matrix=rotation_matrix,
            translation_vector=translation_vector,
            scale_factor=scale_factor,
        ),
        metrics=metrics,
    )

    return registration_params_3d


if __name__ == "__main__":
    DO_SCALE = True
    DO_TRANSLATION = True
    ENFORCE_VALID_ROTATION = False
    STANDARDIZE_POINTS = True
    SCALE_METHOD = "trace"
    ALGORITHM = "horn"

    # Nx3 point array.
    points_query = np.array([
        [0.3745, 0.0206, 0.6119],
        [0.9507, 0.9699, 0.1395],
        [0.7320, 0.8324, 0.2921],
        [0.5987, 0.2123, 0.3664],
        [0.1560, 0.1818, 0.4561],
        [0.1560, 0.1834, 0.7852],
        [0.0581, 0.3042, 0.1997],
        [0.8662, 0.5248, 0.5142],
        [0.6011, 0.4319, 0.5924],
        [0.7081, 0.2912, 0.0465],
    ]).T

    # Nx3 point array.
    # points_target = np.array([
    #     [1.0614, 1.1852, 4.3310],
    #     [2.8919, 0.0975, 3.3190],
    #     [2.6486, 0.4920, 3.6441],
    #     [1.5486, 0.8581, 3.8376],
    #     [1.4406, 1.6648, 3.9315],
    #     [1.4082, 1.7212, 4.6226],
    #     [1.6005, 1.8573, 3.3308],
    #     [2.0066, 0.2697, 3.9805],
    #     [1.8838, 0.8055, 4.0514],
    #     [1.5712, 0.5678, 3.0528],
    # ]).T

    # # Randomly generate 3D sample points.
    # np.random.seed(42)
    # points_query = np.random.rand(3, 10)

    # Transform the query points.
    scale_factor = 2.0
    rotation_matrix = np.array([[0, 1, 0], [1, 0, 0], [0, 0, 1]])
    translation = np.array([[1, 2, 3]]).T

    # np.dot(points_query, rotation_matrix.T) -> Nx3 is the same as np.dot(rotation_matrix, points_query.T) -> 3xN.

    # 3x3 scaled-rotation matrix encoding both rotation and scaling.
    points_target = scale_factor * rotation_matrix @ points_query + translation
    # # Add some Gaussian noise to the points.
    # points_target += np.random.normal(0, 0.05, points_target.shape)

    # Perform the registration.
    if ALGORITHM == "procrustes":
        registration_params = register_points_3d_procrustes(
            points_query,
            points_target,
            do_scale=DO_SCALE,
            do_translation=DO_TRANSLATION,
            standardize_points=STANDARDIZE_POINTS,
            enforce_valid_rotation=ENFORCE_VALID_ROTATION,
            scale_method=SCALE_METHOD,
        )
    elif ALGORITHM == "horn":
        registration_params = register_points_3d_horn(
            points_query,
            points_target,
            do_scale=DO_SCALE,
            do_translation=DO_TRANSLATION,
            enforce_valid_rotation=ENFORCE_VALID_ROTATION,
        )

    registered_query_points = registration_params.registered_query_points
    # Print results.
    print(f"Rotation matrix:\n{registration_params.transform.rotation_matrix}")
    print(f"Translation vector: {registration_params.transform.translation_vector}")
    print(f"Scaling factor: {registration_params.transform.scale_factor}")
    print(
        "Error Metrics:\n"
        f"  - {'\n  - '.join([f'{k}: {v}' for k, v in registration_params.metrics.get_metrics_as_dict().items()])}"
    )

    # Create a single 3D scatter plot.
    fig = plt.figure(figsize=(8, 6))
    ax = fig.add_subplot(111, projection="3d")

    # Plot query points (blue filled circles).
    ax.scatter(
        points_query[0, :],
        points_query[1, :],
        points_query[2, :],
        c="b",
        marker="o",
        s=50,
        label="Query Points",
    )

    # Plot target points (red filled circles).
    ax.scatter(
        points_target[0, :],
        points_target[1, :],
        points_target[2, :],
        c="r",
        marker="o",
        s=50,
        label="Target Points",
    )

    # Plot registered points query -> target (green hollow circles).
    ax.scatter(
        registered_query_points[0, :],
        registered_query_points[1, :],
        registered_query_points[2, :],
        marker="o",
        s=50,
        facecolors="none",
        edgecolors="g",
        label="Registered Points",
    )

    # Connect query points to registered points with dashed lines. Also connect the query points with the target points
    # with magenta dashed lines.
    for i in range(points_query.shape[1]):
        ax.plot(
            [points_query[0, i], registered_query_points[0, i]],
            [points_query[1, i], registered_query_points[1, i]],
            [points_query[2, i], registered_query_points[2, i]],
            "k--",
            alpha=0.3,
            linewidth=1,
        )
        ax.plot(
            [points_query[0, i], points_target[0, i]],
            [points_query[1, i], points_target[1, i]],
            [points_query[2, i], points_target[2, i]],
            "m--",
            alpha=0.3,
            linewidth=1,
        )

    ax.set_title("3D Point Registration: Original Coordinate Space")
    ax.set_xlabel("X")
    ax.set_ylabel("Y")
    ax.set_zlabel("Z")
    ax.grid(True)
    ax.legend()
    ax.set_box_aspect([1, 1, 1])

    plt.tight_layout()
    plt.savefig("3d_alignment.png")

    # In another figure, draw them standardized.
    fig_standardized = plt.figure(figsize=(8, 6))
    ax_standardized = fig_standardized.add_subplot(111, projection="3d")

    centroid_query = np.mean(points_query, axis=1, keepdims=True)
    centroid_target = np.mean(points_target, axis=1, keepdims=True)
    centroid_registered_query_points = np.mean(registered_query_points, axis=1, keepdims=True)

    centered_points_query = points_query - centroid_query
    centered_points_target = points_target - centroid_target
    centered_registered_points = registered_query_points - centroid_registered_query_points

    points_query_standardized = centered_points_query / np.sqrt(np.sum(centered_points_query**2))
    points_target_standardized = centered_points_target / np.sqrt(np.sum(centered_points_target**2))
    registered_points_standardized = centered_registered_points / np.sqrt(np.sum(centered_registered_points**2))

    # Plot query points (blue filled circles).
    ax_standardized.scatter(
        points_query_standardized[0, :],
        points_query_standardized[1, :],
        points_query_standardized[2, :],
        c="b",
        marker="o",
        s=50,
        label="Query Points",
    )

    # Plot target points (red filled circles).
    ax_standardized.scatter(
        points_target_standardized[0, :],
        points_target_standardized[1, :],
        points_target_standardized[2, :],
        c="r",
        marker="o",
        s=50,
        label="Target Points",
    )

    # Plot registered points query -> target (green hollow circles).
    ax_standardized.scatter(
        registered_points_standardized[0, :],
        registered_points_standardized[1, :],
        registered_points_standardized[2, :],
        marker="o",
        s=50,
        facecolors="none",
        edgecolors="g",
        label="Registered Points",
    )

    # Connect query points to registered points with dashed lines. Also connect the query points with the target points
    # with magenta dashed lines.
    for i in range(points_query.shape[1]):
        ax_standardized.plot(
            [points_query_standardized[0, i], registered_points_standardized[0, i]],
            [points_query_standardized[1, i], registered_points_standardized[1, i]],
            [points_query_standardized[2, i], registered_points_standardized[2, i]],
            "k--",
            alpha=0.3,
            linewidth=1,
        )
        ax_standardized.plot(
            [points_query_standardized[0, i], points_target_standardized[0, i]],
            [points_query_standardized[1, i], points_target_standardized[1, i]],
            [points_query_standardized[2, i], points_target_standardized[2, i]],
            "m--",
            alpha=0.3,
            linewidth=1,
        )

    ax_standardized.set_title("3D Point Registration: Standardized Coordinate Space")
    ax_standardized.set_xlabel("X")
    ax_standardized.set_ylabel("Y")
    ax_standardized.set_zlabel("Z")
    ax_standardized.grid(True)
    ax_standardized.legend()
    ax_standardized.set_box_aspect([1, 1, 1])

    plt.tight_layout()
    plt.savefig("3d_alignment_standardized.png")
    plt.show()
