import json
from pathlib import Path
from typing import Any, Literal

import cv2
import matplotlib.pyplot as plt
import numpy as np
from point_set_registration_3d import register_points_3d_procrustes

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

PATH_OUTPUT_IMAGE_ORIGINAL = Path(BASEDIR, "3d_points_original.png")
PATH_OUTPUT_IMAGE_ALIGNED = Path(BASEDIR, "3d_points_aligned.png")
PATH_OUTPUT_2D_IMAGE = Path(BASEDIR, "2d_points_per_image.png")

PATH_ANNOTATED_COORDINATES = Path(BASEDIR, "annotated_coordinates.json")
PATH_DEPTH_SCALES = Path(BASEDIR, "depth_scales.json")
PATH_CAMERA_PARAMETERS = Path(BASEDIR, "camera_parameters.json")
PATH_BASELINE_POINTS = Path(BASEDIR, "baseline_world_points.json")
REGISTRATION_ALGORITHM: Literal["procrustes", "horn"] = "procrustes"


def project_to_2d(points3d, intrinsics, extrinsics=None, image_size=None):
    """
    Project 3D points to 2D image coordinates using camera intrinsics and optional extrinsics.
    """
    points3d = np.asarray(points3d)

    if extrinsics is not None:
        homogeneous_points = np.hstack((points3d, np.ones((len(points3d), 1))))
        points_camera = (extrinsics @ homogeneous_points.T).T[:, :3]
    else:
        points_camera = points3d

    points2d = np.dot(points_camera, intrinsics.T)
    points2d = points2d[:, :2] / points2d[:, 2:3]

    if image_size is not None:
        points2d[:, 0] = np.clip(points2d[:, 0], 0, image_size[0] - 1)
        points2d[:, 1] = np.clip(points2d[:, 1], 0, image_size[1] - 1)

    return points2d


# Load camera parameters
with open(PATH_CAMERA_PARAMETERS, "r") as f:
    camera_parameters = json.load(f)

available_views = list(camera_parameters.keys())
required_views = ["physical"] + [f"virtual_{i+1}" for i in range(N_VIEWS - 1)]
if len(available_views) < N_VIEWS:
    print(
        f"Error: Expected {N_VIEWS} camera parameter sets ('physical' + {N_VIEWS-1} virtual), found "
        f"{len(available_views)}: {available_views}"
    )
    raise ValueError("Insufficient camera parameter sets")

# Load annotations, depth scales, and baseline points
with PATH_ANNOTATED_COORDINATES.open("r") as f:
    annotations: list[dict[str, Any]] = json.load(f)

with PATH_DEPTH_SCALES.open("r") as f:
    depth_scales: dict[str, float] = json.load(f)

with PATH_BASELINE_POINTS.open("r") as f:
    baseline_points: list[dict[str, Any]] = json.load(f)

image_3d_points = {}
image_2d_points = {}

for annotation in annotations:
    filename: str = annotation["filename"]
    points_2d = np.array(annotation["points"], dtype=np.float32)

    depth_image_name = filename.replace(".jpg", "_depth_scaled.png")
    color_image_path = Path(BASEDIR, "color") / filename
    depth_image_path = Path(BASEDIR, "depth") / depth_image_name

    depth_image = cv2.imread(depth_image_path.as_posix(), cv2.IMREAD_UNCHANGED)
    if depth_image is None:
        print(f"Warning: Could not load depth image {depth_image_path.as_posix()}")
        continue

    color_image = cv2.imread(color_image_path.as_posix())
    if color_image is None:
        print(f"Warning: Could not load color image {color_image_path.as_posix()}")
        continue
    h, w = color_image.shape[:2]

    current_depth_scale = depth_scales.get(depth_image_name)
    if current_depth_scale is None:
        print(f"Warning: No depth scale found for {depth_image_name}")
        continue

    points_per_view = len(points_2d) // N_VIEWS
    view_points_2d = [points_2d[i * points_per_view : (i + 1) * points_per_view] for i in range(N_VIEWS)]

    view_params = []
    for i in range(N_VIEWS):
        view_key = "physical" if i == 0 else f"virtual_{i}" if f"virtual_{i}" in camera_parameters else "virtual"
        view_params.append({
            "intrinsics": np.array(camera_parameters[view_key]["intrinsics"]["array"], dtype=np.float32),
            "extrinsics": np.array(camera_parameters[view_key]["extrinsics"]["array"], dtype=np.float32),
        })

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

    # Procrustes alignment with diagnostics
    points_per_view = len(points_3d) // N_VIEWS
    view_points_3d = [points_3d[i * points_per_view : (i + 1) * points_per_view] for i in range(N_VIEWS)]
    physical_points = view_points_3d[0]
    aligned_points_3d = [physical_points]

    # Diagnostic: Print point set statistics
    print(f"\nDiagnostics for {filename}:")
    for i, points in enumerate(view_points_3d):
        if len(points) > 0:
            centroid = np.mean(points, axis=0)
            scale = np.sqrt(np.sum((points - centroid) ** 2) / len(points)) if len(points) > 0 else 0
            print(
                f"View {i} ({['Physical', 'Virtual'][min(i, 1)]}): {len(points)} points, "
                f"Centroid: {centroid}, Scale: {scale}"
            )

    for i in range(1, N_VIEWS):
        if len(view_points_3d[i]) > 0 and len(physical_points) > 0:
            try:
                registration_params = register_points_3d_procrustes(
                    physical_points, view_points_3d[i], apply_scaling=True
                )
                registered_query_points = registration_params.registered_query_points
                transform = registration_params.transform
                metrics = registration_params.metrics
            except Exception as e:
                print(f"Procrustes alignment failed for virtual view {i} of {filename}: {e}")
                aligned_points_3d.append(view_points_3d[i])
        else:
            print(f"Skipping alignment for virtual view {i} of {filename}: Empty point set")
            aligned_points_3d.append(view_points_3d[i])

    aligned_points_3d = np.vstack(aligned_points_3d)
    image_3d_points[filename + "_aligned"] = aligned_points_3d

    points_2d_projected = []
    for i, (points, params) in enumerate(zip(view_points_3d, view_params)):
        extrinsics = params["extrinsics"] if SPACE == "world" else None
        points_2d = project_to_2d(points, params["intrinsics"], extrinsics, image_size=(w, h))
        points_2d_projected.append(points_2d)

    aligned_points_2d_projected = []
    aligned_view_points_3d = [
        aligned_points_3d[i * points_per_view : (i + 1) * points_per_view] for i in range(N_VIEWS)
    ]
    for i, (points, params) in enumerate(zip(aligned_view_points_3d, view_params)):
        extrinsics = params["extrinsics"] if SPACE == "world" else None
        points_2d = project_to_2d(points, params["intrinsics"], extrinsics, image_size=(w, h))
        aligned_points_2d_projected.append(points_2d)

    image_2d_points[filename] = {"original": points_2d_projected, "aligned": aligned_points_2d_projected}

# Plotting 3D points (original)
num_images = len([k for k in image_3d_points if "_aligned" not in k])
cols = int(np.ceil(np.sqrt(num_images)))
rows = int(np.ceil(num_images / cols))
fig_3d_original = plt.figure(figsize=(5 * cols, 5 * rows))

for idx, (key, points_3d) in enumerate((k, v) for k, v in image_3d_points.items() if "_aligned" not in k):
    ax = fig_3d_original.add_subplot(rows, cols, idx + 1, projection="3d")
    filename = key

    points_per_view = len(points_3d) // N_VIEWS
    view_points = [points_3d[i * points_per_view : (i + 1) * points_per_view] for i in range(N_VIEWS)]

    this_image_baseline_points = next(
        (bp["points"] for bp in baseline_points if bp["filename"] == filename and bp["points"]), []
    )
    baseline_points_array = (
        np.array(this_image_baseline_points, dtype=np.float32) if this_image_baseline_points else None
    )

    if baseline_points_array is not None and len(baseline_points_array) > 0 and SPACE == "camera":
        extrinsics = np.array(camera_parameters["physical"]["extrinsics"]["array"], dtype=np.float32)
        ones = np.ones((len(baseline_points_array), 1))
        homogeneous_baseline = np.hstack((baseline_points_array, ones))
        baseline_points_array = (extrinsics @ homogeneous_baseline.T).T[:, :3]

    if baseline_points_array is not None and len(baseline_points_array) > 0 and TRANSLATE_MDE_TO_BASELINE_FOR_DISPLAY:
        target_points = view_points[0]
        if len(target_points) > 0 and len(baseline_points_array) > 0:
            translation = baseline_points_array[0] - target_points[0]
            for i in range(N_VIEWS):
                view_points[i] += translation

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
    ax.set_title(f"Original Points from {filename}")
    ax.legend()

plt.tight_layout()
plt.savefig(PATH_OUTPUT_IMAGE_ORIGINAL.as_posix())

# Plotting 3D points (aligned)
fig_3d_aligned = plt.figure(figsize=(5 * cols, 5 * rows))
for idx, (key, points_3d) in enumerate((k, v) for k, v in image_3d_points.items() if "_aligned" in k):
    ax = fig_3d_aligned.add_subplot(rows, cols, idx + 1, projection="3d")
    filename = key.replace("_aligned", "")

    points_per_view = len(points_3d) // N_VIEWS
    view_points = [points_3d[i * points_per_view : (i + 1) * points_per_view] for i in range(N_VIEWS)]

    this_image_baseline_points = next(
        (bp["points"] for bp in baseline_points if bp["filename"] == filename and bp["points"]), []
    )
    baseline_points_array = (
        np.array(this_image_baseline_points, dtype=np.float32) if this_image_baseline_points else None
    )

    if baseline_points_array is not None and len(baseline_points_array) > 0 and SPACE == "camera":
        extrinsics = np.array(camera_parameters["physical"]["extrinsics"]["array"], dtype=np.float32)
        ones = np.ones((len(baseline_points_array), 1))
        homogeneous_baseline = np.hstack((baseline_points_array, ones))
        baseline_points_array = (extrinsics @ homogeneous_baseline.T).T[:, :3]

    if baseline_points_array is not None and len(baseline_points_array) > 0 and TRANSLATE_MDE_TO_BASELINE_FOR_DISPLAY:
        target_points = view_points[0]
        if len(target_points) > 0 and len(baseline_points_array) > 0:
            translation = baseline_points_array[0] - target_points[0]
            for i in range(N_VIEWS):
                view_points[i] += translation

    colors = ["r", "b", "g"][:N_VIEWS]
    markers = ["o", "^", "s"][:N_VIEWS]
    labels = ["Physical Points"] + [f"Aligned Virtual {i+1} Points" for i in range(1, N_VIEWS)]

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
    ax.set_title(f"Aligned Points from {filename}")
    ax.legend()

plt.tight_layout()
plt.savefig(PATH_OUTPUT_IMAGE_ALIGNED.as_posix())

# Plotting 2D projections on color images
fig_2d = plt.figure(figsize=(5 * cols, 5 * rows))
for idx, (filename, points_data) in enumerate(image_2d_points.items()):
    color_image_path = Path(BASEDIR, "color") / filename
    color_image = cv2.imread(color_image_path.as_posix())
    color_image = cv2.cvtColor(color_image, cv2.COLOR_BGR2RGB)
    h, w = color_image.shape[:2]

    ax = fig_2d.add_subplot(rows, cols, idx + 1)
    ax.imshow(color_image)

    colors = ["r", "b", "g"][:N_VIEWS]
    markers = ["o", "^", "s"][:N_VIEWS]
    labels = ["Physical Points"] + [f"Virtual {i+1} Points" for i in range(1, N_VIEWS)]

    for i, points in enumerate(points_data["original"]):
        if len(points) > 0 and PLOT_POINTS.get(
            "physical" if i == 0 else f"virtual_{i+1}" if f"virtual_{i+1}" in camera_parameters else "virtual", True
        ):
            ax.scatter(
                points[0, 0],
                points[0, 1],
                c=colors[i],
                marker=markers[i],
                s=100,
            )
            ax.scatter(points[1:, 0], points[1:, 1], c=colors[i], marker=markers[i], s=50, label=labels[i])

    for i, points in enumerate(points_data["aligned"][1:], start=1):
        if len(points) > 0 and PLOT_POINTS.get(
            f"virtual_{i+1}" if f"virtual_{i+1}" in camera_parameters else "virtual", True
        ):
            ax.scatter(
                points[0, 0],
                points[0, 1],
                c=colors[i],
                marker=markers[i],
                s=100,
                edgecolors="k",
            )
            ax.scatter(
                points[1:, 0],
                points[1:, 1],
                c=colors[i],
                marker=markers[i],
                s=50,
                edgecolors="k",
                label=f"Aligned Virtual {i} Points",
            )

    ax.set_xlim(0, w)
    ax.set_ylim(h, 0)
    ax.set_title(f"2D Points on {filename}")
    ax.legend()

plt.tight_layout()
plt.savefig(PATH_OUTPUT_2D_IMAGE.as_posix())
plt.show()
