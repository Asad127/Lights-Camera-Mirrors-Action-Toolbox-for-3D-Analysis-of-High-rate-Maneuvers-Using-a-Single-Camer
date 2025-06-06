"""
This is just a test script that I used to double-check my implementation of Procrustes analysis. I am not using it here
because it is very barebones in terms of what results it gives, plus it is only an orthognal Procrustes alignment, not a
full alignment. As far as accuracy goes so far, the following code is about the same as the scipy implementation.
"""

import matplotlib.pyplot as plt
import numpy as np
from scipy.spatial import procrustes

if __name__ == "__main__":
    # Nx3 point array.
    # points_query = np.array([
    #     [0.3745, 0.0206, 0.6119],
    #     [0.9507, 0.9699, 0.1395],
    #     [0.7320, 0.8324, 0.2921],
    #     [0.5987, 0.2123, 0.3664],
    #     [0.1560, 0.1818, 0.4561],
    #     [0.1560, 0.1834, 0.7852],
    #     [0.0581, 0.3042, 0.1997],
    #     [0.8662, 0.5248, 0.5142],
    #     [0.6011, 0.4319, 0.5924],
    #     [0.7081, 0.2912, 0.0465],
    # ]).T

    # # Nx3 point array.
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

    # Randomly generate 3D sample points.
    np.random.seed(42)
    points_query = np.random.rand(3, 10)

    # Rotate the points 90 degrees CCW around the z-axis.
    scale_factor = 2.0
    rotation_matrix = np.array([[0, 1, 0], [-1, 0, 0], [0, 0, 1]])
    translation = np.array([[1, 2, 3]]).T

    # 3x3 scaled-rotation matrix encoding both rotation and scaling.
    points_target = scale_factor * (rotation_matrix @ points_query) + translation
    # Add some Gaussian noise to the points.
    points_target += np.random.normal(0, 0.05, points_target.shape)

    # Reshape to procrustes expected shape of Nx3 (for 3D points) or Nx2 (for 2D points).
    points_query = points_query.T
    points_target = points_target.T

    # Standardize with Frobenius norm.
    centroid_query = np.mean(points_query, axis=0)
    centroid_target = np.mean(points_target, axis=0)

    centered_points_query = points_query - centroid_query
    centered_points_target = points_target - centroid_target

    standardized_points_query = centered_points_query / np.sqrt(np.sum(centered_points_query**2))
    # This is equivalent to what Procrustes gives us back.
    # standardized_points_target = centered_points_target / np.sqrt(np.sum(centered_points_target**2))

    # Perform the registration.
    standardized_points_target, registered_standardized_points_query, disparity = procrustes(
        points_target, points_query
    )

    print(disparity)

    # Create a single 3D scatter plot.
    fig = plt.figure(figsize=(8, 6))
    ax = fig.add_subplot(111, projection="3d")

    # Plot query points (blue filled circles).
    ax.scatter(
        standardized_points_query[:, 0],
        standardized_points_query[:, 1],
        standardized_points_query[:, 2],
        c="b",
        marker="o",
        s=50,
        label="Query Points",
    )

    # Plot target points (red filled circles).
    ax.scatter(
        standardized_points_target[:, 0],
        standardized_points_target[:, 1],
        standardized_points_target[:, 2],
        c="r",
        marker="o",
        s=50,
        label="Target Points",
    )

    # Plot registered points query -> target (green hollow circles).
    ax.scatter(
        registered_standardized_points_query[:, 0],
        registered_standardized_points_query[:, 1],
        registered_standardized_points_query[:, 2],
        marker="o",
        s=50,
        facecolors="none",
        edgecolors="g",
        label="Registered Points",
    )

    # Connect query points to registered points with dashed lines. Also connect the query points with the target points
    # with magenta dashed lines.
    for i in range(points_query.shape[0]):
        ax.plot(
            [standardized_points_query[i, 0], registered_standardized_points_query[i, 0]],
            [standardized_points_query[i, 1], registered_standardized_points_query[i, 1]],
            [standardized_points_query[i, 2], registered_standardized_points_query[i, 2]],
            "k--",
            alpha=0.3,
            linewidth=1,
        )
        ax.plot(
            [standardized_points_query[i, 0], standardized_points_target[i, 0]],
            [standardized_points_query[i, 1], standardized_points_target[i, 1]],
            [standardized_points_query[i, 2], standardized_points_target[i, 2]],
            "m--",
            alpha=0.3,
            linewidth=1,
        )

    ax.set_title("3D Point Sets: Original, Transformed, and Registered (Scipy Procrustes)")
    ax.set_xlabel("X")
    ax.set_ylabel("Y")
    ax.set_zlabel("Z")
    ax.grid(True)
    ax.legend()
    ax.set_box_aspect([1, 1, 1])

    plt.tight_layout()
    plt.savefig("3d_alignment_standardized_procrustes.png")
    plt.show()
