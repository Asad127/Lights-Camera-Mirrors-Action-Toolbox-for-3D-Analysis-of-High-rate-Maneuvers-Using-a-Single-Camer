import json
from pathlib import Path
from typing import Any, Literal

import cv2
import matplotlib.pyplot as plt
import numpy as np

np.set_printoptions(suppress=True)

BASEDIR = "depth-anything-v2"
SPACE: Literal["world", "camera"] = "world"
PLOT_POINTS = {
    "physical": True,
    "virtual": False,
    "baseline": True,
}
TRANSLATE_MDE_TO_BASELINE_FOR_DISPLAY = True
USE_IMAGE_CENTER_AS_PRINCIPAL_POINT = False
N_VIEWS = 2

PATH_OUTPUT_IMAGE = Path(BASEDIR, "3d_points_per_image.png")
PATH_ANNOTATED_COORDINATES = Path(BASEDIR, "annotated_coordinates.json")
PATH_DEPTH_SCALES = Path(BASEDIR, "depth_scales.json")
PATH_CAMERA_PARAMETERS = Path(BASEDIR, "camera_parameters.json")
PATH_BASELINE_POINTS = Path(BASEDIR, "baseline_world_points.json")

# Load camera parameters
with open(PATH_CAMERA_PARAMETERS, "r") as f:
    camera_parameters = json.load(f)

# Validate number of camera parameter sets
available_views = list(camera_parameters.keys())
required_views = ["physical"] + [f"virtual_{i+1}" for i in range(N_VIEWS - 1)]
if len(available_views) < N_VIEWS:
    print(
        f"Error: Expected {N_VIEWS} camera parameter sets ('physical' + {N_VIEWS-1} virtual), found"
        f" {len(available_views)}: {available_views}"
    )
    raise ValueError("Insufficient camera parameter sets")

# Load annotations, depth scales, and baseline points
with PATH_ANNOTATED_COORDINATES.open("r") as f:
    annotations: list[dict[str, Any]] = json.load(f)

with PATH_DEPTH_SCALES.open("r") as f:
    depth_scales: dict[str, float] = json.load(f)

with PATH_BASELINE_POINTS.open("r") as f:
    baseline_points: list[dict[str, Any]] = json.load(f)

image_3d_points = {}  # filename -> array of (X, Y, Z) points

for annotation in annotations:
    filename: str = annotation["filename"]
    points_2d = np.array(annotation["points"], dtype=np.float32)

    depth_image_name = filename.replace(".jpg", "_depth_scaled.png")
    color_image_path = Path(BASEDIR, "color") / filename
    depth_image_path = Path(BASEDIR, "depth") / depth_image_name

    # Load images
    depth_image = cv2.imread(depth_image_path.as_posix(), cv2.IMREAD_UNCHANGED)
    if depth_image is None:
        print(f"Warning: Could not load depth image {depth_image_path.as_posix()}")
        continue

    color_image = cv2.imread(color_image_path.as_posix())
    if color_image is None:
        print(f"Warning: Could not load color image {color_image_path.as_posix()}")
        continue
    h, w = color_image.shape[:2]

    # Get depth scale
    current_depth_scale = depth_scales.get(depth_image_name)
    if current_depth_scale is None:
        print(f"Warning: No depth scale found for {depth_image_name}")
        continue

    # Split points into views
    points_per_view = len(points_2d) // N_VIEWS
    view_points_2d = [points_2d[i * points_per_view : (i + 1) * points_per_view] for i in range(N_VIEWS)]

    # Assign camera parameters for each view
    view_params = []
    for i in range(N_VIEWS):
        view_key = "physical" if i == 0 else f"virtual_{i}" if f"virtual_{i}" in camera_parameters else "virtual"
        view_params.append({
            "intrinsics": np.array(camera_parameters[view_key]["intrinsics"]["array"], dtype=np.float32),
            "extrinsics": np.array(camera_parameters[view_key]["extrinsics"]["array"], dtype=np.float32),
        })

    # Project to 3D camera space (in millimeters)
    points_3d = []
    for i, (points, params) in enumerate(zip(view_points_2d, view_params)):
        fx, fy = params["intrinsics"][0, 0], params["intrinsics"][1, 1]
        cx, cy = (
            (w / 2, h / 2)
            if USE_IMAGE_CENTER_AS_PRINCIPAL_POINT
            else (params["intrinsics"][0, 2], params["intrinsics"][1, 2])
        )

        depth_values = depth_image[points[:, 1].astype(int), points[:, 0].astype(int)]
        metric_depths = depth_values / current_depth_scale
        x = (points[:, 0] - cx) * metric_depths / fx * 1000
        y = (points[:, 1] - cy) * metric_depths / fy * 1000
        z = metric_depths * 1000
        view_points_3d = np.stack((x, y, z), axis=1)

        if SPACE == "world":
            rotation_matrix_inverse = params["extrinsics"][:3, :3].T
            translation_inverse = -rotation_matrix_inverse @ params["extrinsics"][:3, 3]
            inverse_extrinsics = np.hstack((rotation_matrix_inverse, translation_inverse[:, np.newaxis]))
            homogeneous_points = np.hstack((view_points_3d, np.ones((len(view_points_3d), 1))))
            view_points_3d = (inverse_extrinsics @ homogeneous_points.T).T[:, :3]

        points_3d.append(view_points_3d)

    points_3d = np.vstack(points_3d)
    image_3d_points[filename] = points_3d

# Plotting
num_images = len(image_3d_points)
cols = int(np.ceil(np.sqrt(num_images)))
rows = int(np.ceil(num_images / cols))
fig = plt.figure(figsize=(5 * cols, 5 * rows))

for idx, (filename, points_3d) in enumerate(image_3d_points.items()):
    ax = fig.add_subplot(rows, cols, idx + 1, projection="3d")

    # Split points into views
    points_per_view = len(points_3d) // N_VIEWS
    view_points = [points_3d[i * points_per_view : (i + 1) * points_per_view] for i in range(N_VIEWS)]

    # Load baseline points (originally in world space)
    this_image_baseline_points = next(
        (bp["points"] for bp in baseline_points if bp["filename"] == filename and bp["points"]), []
    )
    baseline_points_array = (
        np.array(this_image_baseline_points, dtype=np.float32) if this_image_baseline_points else None
    )

    if baseline_points_array is not None and len(baseline_points_array) > 0 and SPACE == "camera":
        # Use physical extrinsics for baseline transformation
        extrinsics = np.array(camera_parameters["physical"]["extrinsics"]["array"], dtype=np.float32)
        ones = np.ones((len(baseline_points_array), 1))
        homogeneous_baseline = np.hstack((baseline_points_array, ones))
        baseline_points_array = (extrinsics @ homogeneous_baseline.T).T[:, :3]

    # Translation for display (align with physical points)
    if baseline_points_array is not None and len(baseline_points_array) > 0 and TRANSLATE_MDE_TO_BASELINE_FOR_DISPLAY:
        target_points = view_points[0]  # Physical points
        if len(target_points) > 0 and len(baseline_points_array) > 0:
            translation = baseline_points_array[0] - target_points[0]
            for i in range(N_VIEWS):
                view_points[i] += translation

    # Plot points
    colors = ["r", "b", "g"][:N_VIEWS]
    markers = ["o", "^", "s"][:N_VIEWS]
    labels = ["Physical Points"] + [f"Virtual {i+1} Points" for i in range(1, N_VIEWS)]

    for i, points in enumerate(view_points):
        if len(points) > 0 and PLOT_POINTS.get(
            "physical" if i == 0 else f"virtual_{i+1}" if f"virtual_{i+1}" in camera_parameters else "virtual", True
        ):
            ax.scatter(points[0, 0], points[0, 1], points[0, 2], c=colors[i], marker=markers[i])
            ax.scatter(points[1:, 0], points[1:, 1], points[1:, 2], c=colors[i], marker=markers[i], label=labels[i])

    if baseline_points_array is not None and len(baseline_points_array) > 0 and PLOT_POINTS["baseline"]:
        ax.scatter(
            baseline_points_array[0, 0], baseline_points_array[0, 1], baseline_points_array[0, 2], c="c", marker="*"
        )
        ax.scatter(
            baseline_points_array[1:, 0],
            baseline_points_array[1:, 1],
            baseline_points_array[1:, 2],
            c="g",
            marker="*",
            label="Baseline Points",
        )

    ax.set_xlabel("X")
    ax.set_ylabel("Y")
    ax.set_zlabel("Z")
    ax.set_title(f"Points from {filename}")
    ax.legend()

plt.tight_layout()
plt.savefig(PATH_OUTPUT_IMAGE.as_posix())
plt.show()
